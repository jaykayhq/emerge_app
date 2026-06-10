import 'package:flutter/material.dart';

/// Data class representing a single explanatory point within the coach mark.
class CoachItemData {
  final IconData icon;
  final String title;
  final String body;

  const CoachItemData({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// A reusable glassmorphic feature coach mark overlay.
///
/// Designed to onboard users to new screens or features, displaying
/// a dark violet (#12122A) panel with an animated fade-in, customizable
/// titles, highlight items, and a call-to-action button.
class FeatureCoachMark extends StatefulWidget {
  final String title;
  final Color primaryColor;
  final List<CoachItemData> items;
  final VoidCallback onDismiss;
  final IconData titleIcon;

  const FeatureCoachMark({
    super.key,
    required this.title,
    required this.primaryColor,
    required this.items,
    required this.onDismiss,
    this.titleIcon = Icons.help_outline,
  });

  @override
  State<FeatureCoachMark> createState() => _FeatureCoachMarkState();
}

class _FeatureCoachMarkState extends State<FeatureCoachMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                // Prevent taps on the card itself from dismissing
                onTap: () {},
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12122A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(
                                alpha: 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.titleIcon,
                              color: widget.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dismiss hint
                          const Text(
                            'Tap anywhere to close',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Explanatory items
                      ...widget.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CoachItemRow(
                              icon: item.icon,
                              color: widget.primaryColor,
                              title: item.title,
                              body: item.body,
                            ),
                          )),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "GOT IT — LET'S GO",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single explanatory row inside the coach-mark card
class _CoachItemRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _CoachItemRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
