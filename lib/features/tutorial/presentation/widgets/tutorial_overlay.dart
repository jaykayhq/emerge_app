import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

class TutorialStepInfo {
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final Alignment alignment;

  const TutorialStepInfo({
    required this.title,
    required this.description,
    this.targetKey,
    this.alignment = Alignment.center,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStepInfo> steps;
  final VoidCallback onCompleted;
  final ScrollController? scrollController;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onCompleted,
    this.scrollController,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStepIndex = 0;
  bool _isScrolling = false;

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _isScrolling = true;
      });
      // Scroll to target after a brief delay to let the state update
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToTarget();
      });
    } else {
      widget.onCompleted();
    }
  }

  void _scrollToTarget() {
    final step = widget.steps[_currentStepIndex];
    if (step.targetKey == null) {
      setState(() => _isScrolling = false);
      return;
    }

    final context = step.targetKey!.currentContext;
    if (context == null) {
      // Widget not built yet, retry after a delay
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _scrollToTarget();
      });
      return;
    }

    try {
      Scrollable.ensureVisible(
        context,
        alignment: 0.5, // Center the target
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      // Mark scrolling complete after animation finishes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _isScrolling = false);
      });
    } catch (e) {
      // If ensureVisible fails (e.g., not in a Scrollable), just show the highlight
      setState(() => _isScrolling = false);
    }
  }

  @override
  void initState() {
    super.initState();
    // Scroll to first target after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _scrollToTarget();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStepIndex];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred background with hole
          if (step.targetKey != null && !_isScrolling)
            _TutorialHolePainter(targetKey: step.targetKey!)
          else
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),

          // Content Card
          Align(
            alignment: step.alignment,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: GoogleFonts.splineSans(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(12),
                        Text(
                          step.description,
                          style: GoogleFonts.splineSans(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const Gap(24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_currentStepIndex + 1} / ${widget.steps.length}',
                              style: GoogleFonts.splineSans(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            TextButton(
                              onPressed: _isScrolling ? null : _nextStep,
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF2BEE79),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isScrolling
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.black,
                                      ),
                                    )
                                  : Text(
                                      _currentStepIndex <
                                              widget.steps.length - 1
                                          ? 'NEXT'
                                          : 'GOT IT',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialHolePainter extends StatefulWidget {
  final GlobalKey targetKey;

  const _TutorialHolePainter({required this.targetKey});

  @override
  State<_TutorialHolePainter> createState() => _TutorialHolePainterState();
}

class _TutorialHolePainterState extends State<_TutorialHolePainter> {
  Rect? _targetRect;
  bool _hasAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
  }

  void _updateRect() {
    if (_hasAttempted && _targetRect != null) return;
    _hasAttempted = true;

    final renderObject = widget.targetKey.currentContext?.findRenderObject();

    // Only RenderBox widgets can be highlighted - slivers use a different
    // rendering architecture that doesn't support simple bounds extraction
    if (renderObject is! RenderBox) {
      debugPrint(
        'TutorialOverlay: Target widget must be a RenderBox, '
        'got ${renderObject.runtimeType}. '
        'Wrapping the target in a SizedBox or Container may help.',
      );
      return;
    }

    // After the is! check, Dart's type narrowing ensures renderObject is RenderBox
    final box = renderObject;
    final offset = box.localToGlobal(Offset.zero);
    setState(() {
      _targetRect = offset & box.size;
    });
  }

  @override
  void didUpdateWidget(_TutorialHolePainter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetKey != widget.targetKey) {
      _targetRect = null;
      _hasAttempted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateRect());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == null) return const SizedBox.shrink();

    return Stack(
      children: [
        // Dark background with hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned.fromRect(
                rect: _targetRect!.inflate(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Glow/Focus Ring
        Positioned.fromRect(
          rect: _targetRect!.inflate(8),
          child:
              Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2BEE79),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2BEE79).withValues(alpha: 0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  )
                  .animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.02, 1.02),
                    duration: 1.seconds,
                  ),
        ),
      ],
    );
  }
}
