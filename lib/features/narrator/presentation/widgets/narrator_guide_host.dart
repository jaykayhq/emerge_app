import 'package:emerge_app/features/narrator/domain/services/narrator_guide_registry.dart';
import 'package:emerge_app/features/narrator/presentation/providers/narrator_guide_controller.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/narrator_guide_card.dart';
import 'package:emerge_app/features/narrator/presentation/widgets/spotlight_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps a screen and shows its first-visit narrator guide.
///
/// [targets] maps registry `targetKey`s to [GlobalKey]s of the widgets the
/// spotlight should highlight. Rects are resolved via
/// `RenderBox.localToGlobal` (the overlay Stack sits in the same coordinate
/// space as the screen), so no route/Overlay indirection is needed. The hole
/// glides between steps (200ms); scrolls of the target's scrollable re-resolve
/// rects instantly. A target that is unmounted or off-screen yields no hole —
/// the card-only step still advances.
///
/// The overlay shows from the very first frame (the gate is checked in a
/// post-frame callback, so a disabled or already-seen guide is removed before
/// the next frame) — this lets the typewriter start typing immediately instead
/// of waiting a frame for the gate. All step cards stay mounted (offstage) so
/// advancing never restarts a script mid-typing; each card types its own
/// script once in the background and is revealed when its turn comes.
class NarratorGuideHost extends ConsumerStatefulWidget {
  final String nodeId;
  final Map<String, GlobalKey> targets;
  final Widget child;

  const NarratorGuideHost({
    super.key,
    required this.nodeId,
    required this.targets,
    required this.child,
  });

  @override
  ConsumerState<NarratorGuideHost> createState() => _NarratorGuideHostState();
}

class _NarratorGuideHostState extends ConsumerState<NarratorGuideHost> {
  // Optimistic: the overlay is on the tree from the first frame so the
  // typewriter gets a head start; the gate check right after that frame hides
  // it again when the guide must not show.
  bool _visible = true;
  int _step = 0;
  bool _animateHole = false;
  final List<ScrollPosition> _scrollPositions = [];

  List<NarratorGuideStep> get _steps =>
      NarratorGuideRegistry.forNode(widget.nodeId)?.steps ?? const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    final controller = ref.read(narratorGuideControllerProvider);
    if (!mounted) return;
    if (await controller.shouldShow(widget.nodeId)) {
      // Rebuild so the spotlight re-resolves target rects now that the
      // wrapped screen's widgets (and their GlobalKeys) are mounted.
      setState(() => _visible = true);
      _attachScrollListeners();
    } else {
      setState(() => _visible = false);
    }
  }

  void _attachScrollListeners() {
    for (final key in widget.targets.values) {
      final ctx = key.currentContext;
      if (ctx == null) continue;
      final position = Scrollable.maybeOf(ctx)?.position;
      if (position != null && !_scrollPositions.contains(position)) {
        _scrollPositions.add(position);
        position.addListener(_onScroll);
      }
    }
  }

  void _onScroll() => setState(() {}); // re-resolve hole rect next paint

  @override
  void dispose() {
    for (final position in _scrollPositions) {
      position.removeListener(_onScroll);
    }
    super.dispose();
  }

  Rect? _rectFor(String targetKey) {
    final ctx = widget.targets[targetKey]?.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _advance() {
    if (_step < _steps.length - 1) {
      setState(() {
        _step++;
        _animateHole = true;
      });
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await ref.read(narratorGuideControllerProvider).markSeen(widget.nodeId);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final step = _visible && _step < steps.length ? steps[_step] : null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Stack(
      children: [
        widget.child,
        if (step != null)
          Positioned.fill(child: _spotlight(steps, step, reduceMotion)),
        if (step != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.paddingOf(context).bottom,
            child: Stack(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Offstage(
                    offstage: i != _step,
                    child: NarratorGuideCard(
                      script: steps[i].script,
                      stepIndex: i,
                      stepCount: steps.length,
                      onAdvance: _advance,
                      onSkip: _finish,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _spotlight(
    List<NarratorGuideStep> steps,
    NarratorGuideStep step,
    bool reduceMotion,
  ) {
    final end = _rectFor(step.targetKey);
    if (end == null) {
      // Target unmounted or off-screen: card-only step, no hole.
      return const CustomPaint(painter: SpotlightPainter());
    }
    return TweenAnimationBuilder<Rect?>(
      tween: _RectTween(
        begin: _step == 0 ? null : _rectFor(steps[_step - 1].targetKey),
        end: end,
      ),
      duration: _animateHole && !reduceMotion
          ? const Duration(milliseconds: 200)
          : Duration.zero,
      curve: Curves.easeInOut,
      onEnd: () {
        if (_animateHole) setState(() => _animateHole = false);
      },
      builder: (context, rect, _) =>
          CustomPaint(painter: SpotlightPainter(holeRect: rect)),
    );
  }
}

/// Null-safe rect tween: first step (null begin) jumps straight to the hole.
/// `TweenAnimationBuilder` requires a non-null `end`, so the host only passes
/// tweens for steps whose target rect resolved.
class _RectTween extends Tween<Rect?> {
  _RectTween({required super.begin, required super.end});

  @override
  Rect? lerp(double t) {
    if (begin == null) return end;
    if (end == null) return null;
    return Rect.lerp(begin!, end!, t);
  }
}
