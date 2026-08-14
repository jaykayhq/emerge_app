import 'dart:async';

import 'package:emerge_app/core/utils/app_logger.dart';
import 'package:emerge_app/features/narrator/domain/services/guide_card_placement.dart';
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
/// rects instantly (except during the 200ms post-advance glide window). A
/// target that is unmounted or off-screen yields no hole — the card-only step
/// still advances. A target that mounts after its step started (e.g. a
/// stream-gated subtree) gains its hole on the next frame, without waiting
/// for a scroll or an advance.
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
  bool _visible = false;
  int _step = 0;
  bool _animateHole = false;
  bool _holeAvailable = false;
  bool _advancing = false;
  final List<ScrollPosition> _scrollPositions = [];
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _hostKey = GlobalKey();
  double? _cardHeight;
  Timer? _measureTimer;

  List<NarratorGuideStep> get _steps =>
      NarratorGuideRegistry.forNode(widget.nodeId)?.steps ?? const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  Future<void> _maybeShow() async {
    final controller = ref.read(narratorGuideControllerProvider);
    if (await controller.shouldShow(widget.nodeId) && mounted) {
      setState(() => _visible = true);
      _attachScrollListeners();
      // The card grows while the typewriter wraps to extra lines, and the
      // host has no rebuild per tick — re-measure periodically so the card
      // is repositioned as it grows, then goes quiet once the height
      // stabilizes (`_measureCardHeight` setStates only on change).
      _measureTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        _measureCardHeight();
      });
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

  void _onScroll() {
    if (mounted) setState(() {}); // re-resolve hole rect next paint
  }

  @override
  void dispose() {
    _measureTimer?.cancel();
    for (final position in _scrollPositions) {
      position.removeListener(_onScroll);
    }
    super.dispose();
  }

  Rect? _rectFor(String targetKey) {
    final ctx = widget.targets[targetKey]?.currentContext;
    final box = ctx?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    final globalRect = box.localToGlobal(Offset.zero) & box.size;
    final hostRect = _hostBounds;
    final rect = hostRect == null
        ? globalRect
        : globalRect.shift(-hostRect.topLeft);
    final viewport =
        Offset.zero & (hostRect?.size ?? MediaQuery.sizeOf(context));
    return viewport.overlaps(rect) ? rect : null;
  }

  Rect? get _hostBounds {
    final renderObject = _hostKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  /// Conservative first-frame estimate of the guide card height (before the
  /// card has laid out). Over-estimating is safe: it only adds gap above the
  /// target; under-estimating would let the card overlap it.
  double _estimateGuideCardHeight(String script) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final availableWidth = MediaQuery.sizeOf(context).width - 48;
    final charsPerLine = (availableWidth / 6).floor().clamp(10, 70);
    final lineCount = (script.length / charsPerLine).ceil().clamp(1, 8);
    return (230 + lineCount * 26) * textScale;
  }

  void _measureCardHeight() {
    if (!mounted) return;
    final ctx = _cardKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached) return;
    final height = box.size.height;
    if (_cardHeight != height) {
      setState(() => _cardHeight = height);
    }
  }

  void _advance() {
    if (_advancing) return;
    if (_step < _steps.length - 1) {
      setState(() {
        _step++;
        _animateHole = false;
        _holeAvailable = false;
        _cardHeight = null;
        _advancing = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_revealCurrentStep());
      });
    } else {
      _finish();
    }
  }

  Future<void> _revealCurrentStep() async {
    if (!mounted || _step >= _steps.length) return;

    final targetContext =
        widget.targets[_steps[_step].targetKey]?.currentContext;
    if (targetContext != null) {
      try {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.45,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (_) {
        // The card-only fallback remains usable if a target leaves the tree
        // while its scrollable is rebuilding.
        AppLogger.d(
          'Narrator guide target could not be scrolled; using card fallback',
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _advancing = false;
      _animateHole = true;
    });
  }

  Future<void> _finish() async {
    _measureTimer?.cancel();
    _advancing = false;
    try {
      await ref.read(narratorGuideControllerProvider).markSeen(widget.nodeId);
    } catch (_) {
      // Best-effort: never block dismissal on storage failure.
    }
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final step = _visible && _step < steps.length ? steps[_step] : null;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (_visible) {
      // Targets may mount after the first frame (e.g. stream-gated list
      // subtrees), and Scrollable.maybeOf only walks ancestors — re-attach
      // scroll listeners after every build while showing. The
      // ScrollPosition-identity dedupe keeps this idempotent.
      //
      // A late-mounting target's own rebuild doesn't touch the host, so also
      // re-resolve the current step's rect here: a step that started card-only
      // gains its hole as soon as its target exists, without waiting for a
      // scroll or an advance. `_holeAvailable` guards the setState so the
      // every-frame callback stays quiescent once the hole is up.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _attachScrollListeners();
        final step = _visible && _step < _steps.length ? _steps[_step] : null;
        if (step != null &&
            !_holeAvailable &&
            _rectFor(step.targetKey) != null) {
          setState(() => _holeAvailable = true);
        }
      });
      if (step != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _measureCardHeight(),
        );
      }
    }

    // The guide card and its InkWell/IconButton need a Material ancestor. The
    // host's Stack sits beside the screen's Scaffold (which may wrap the
    // screen's content or live above it in the route), so give the overlay a
    // self-contained transparent Material — visually a no-op, but it keeps the
    // card from crashing with "No Material widget found" on screens whose
    // Scaffold is nested elsewhere.
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        key: _hostKey,
        children: [
          widget.child,
          if (step != null)
            Positioned.fill(child: _spotlight(steps, step, reduceMotion)),
          if (step != null) _buildGuideCard(step),
        ],
      ),
    );
  }

  Widget _buildGuideCard(NarratorGuideStep step) {
    final targetRect = _rectFor(step.targetKey);
    final screenSize = _hostBounds?.size ?? MediaQuery.sizeOf(context);
    final cardHeight = _cardHeight ?? _estimateGuideCardHeight(step.script);
    final position = guideCardPositionFor(
      targetRect: targetRect,
      screenSize: screenSize,
      cardHeight: cardHeight,
      margin: 16,
      topInset: 0,
      bottomInset: 0,
    );
    return Positioned(
      left: 16,
      right: 16,
      top: position.top,
      bottom: position.bottom,
      child: NarratorGuideCard(
        key: _cardKey,
        script: step.script,
        stepIndex: _step,
        stepCount: _steps.length,
        onAdvance: _advance,
        onSkip: _finish,
      ),
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
      // (TweenAnimationBuilder also requires a non-null tween end, so a
      // vanished target must bypass the animated builder entirely.) Clear the
      // glide flag here too — with no animated builder, onEnd never fires, and
      // a target re-mounting mid-step must jump, not glide. Also clear
      // `_holeAvailable` so the post-frame callback can re-arm the setState
      // that restores the hole once the target comes back.
      _animateHole = false;
      _holeAvailable = false;
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
        if (mounted && _animateHole) {
          setState(() => _animateHole = false);
        }
      },
      builder: (context, rect, _) =>
          CustomPaint(painter: SpotlightPainter(holeRect: rect)),
    );
  }
}

/// Null-safe rect tween: first step (null begin) jumps straight to the hole;
/// a vanished target (null end) hides the hole without animating.
class _RectTween extends Tween<Rect?> {
  _RectTween({required super.begin, required super.end});

  @override
  Rect? lerp(double t) {
    if (begin == null) return end;
    if (end == null) return null;
    return Rect.lerp(begin!, end!, t);
  }
}
