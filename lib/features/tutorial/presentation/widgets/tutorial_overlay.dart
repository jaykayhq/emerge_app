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
  Rect? _targetRect;

  void _nextStep() {
    if (_currentStepIndex < widget.steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _isScrolling = true;
        _targetRect = null;
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
    if (!mounted) return;
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
        if (mounted) {
          setState(() => _isScrolling = false);
          _calculateTargetRect();
        }
      });
    } catch (e) {
      // If ensureVisible fails (e.g., not in a Scrollable), just show the highlight
      if (mounted) {
        setState(() => _isScrolling = false);
        _calculateTargetRect();
      }
    }
  }

  void _calculateTargetRect() {
    if (!mounted) return;
    final step = widget.steps[_currentStepIndex];
    if (step.targetKey == null) {
      if (_targetRect != null) {
        setState(() => _targetRect = null);
      }
      return;
    }

    final renderObject = step.targetKey!.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;

    final overlay = context.findRenderObject();
    if (overlay is! RenderBox) return;

    final offset = renderObject.localToGlobal(Offset.zero, ancestor: overlay);
    final newRect = offset & renderObject.size;

    if (_targetRect != newRect) {
      setState(() {
        _targetRect = newRect;
      });
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

  Alignment _getDynamicAlignment(TutorialStepInfo step) {
    if (_targetRect == null) return step.alignment;

    final screenHeight = MediaQuery.of(context).size.height;
    final targetCenterY = _targetRect!.center.dy;

    // Place the card in the larger space
    if (targetCenterY > screenHeight / 2) {
      return Alignment.topCenter;
    } else {
      return Alignment.bottomCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateTargetRect();
      });
    }

    final step = widget.steps[_currentStepIndex];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred background with hole
          if (step.targetKey != null && !_isScrolling && _targetRect != null)
            _TutorialHoleStatic(targetRect: _targetRect!)
          else
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),

          // Content Card
          SafeArea(
            child: Align(
              alignment: _getDynamicAlignment(step),
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
          ),
        ],
      ),
    );
  }
}

class _TutorialHoleStatic extends StatelessWidget {
  final Rect targetRect;

  const _TutorialHoleStatic({required this.targetRect});

  @override
  Widget build(BuildContext context) {
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
                rect: targetRect.inflate(8),
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
          rect: targetRect.inflate(8),
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
