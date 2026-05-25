import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:emerge_app/features/companion/domain/entities/companion_message.dart';
import 'package:emerge_app/features/companion/domain/entities/persona_config.dart';

class CompanionInlineCard extends StatefulWidget {
  final CompanionMessage message;
  final PersonaConfig persona;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const CompanionInlineCard({
    super.key,
    required this.message,
    required this.persona,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  State<CompanionInlineCard> createState() => _CompanionInlineCardState();
}

class _CompanionInlineCardState extends State<CompanionInlineCard> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _dismissTimer?.cancel();
        widget.onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.persona.accentColor.withValues(alpha: 0.1),
              Colors.black.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.persona.accentColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: widget.persona.accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  widget.persona.name[0],
                  style: TextStyle(
                    color: widget.persona.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.persona.name,
                    style: GoogleFonts.splineSans(
                      color: widget.persona.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    widget.message.message,
                    style: GoogleFonts.splineSans(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: widget.persona.accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}
