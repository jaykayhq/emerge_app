import 'package:emerge_app/core/theme/emerge_colors.dart';
import 'package:emerge_app/features/rating/data/repositories/feedback_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final String userId;
  final int rating;

  const FeedbackScreen({super.key, required this.userId, required this.rating});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(feedbackRepositoryProvider)
        .submitFeedback(
          userId: widget.userId,
          rating: widget.rating,
          message: message,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _submitting = false;
        _error = failure.message;
      }),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks — your feedback helps us improve.')),
        );
        try {
          context.pop();
        } catch (_) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Help us improve',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const Gap(8),
            const Text('What got in the way?',
                style: TextStyle(color: Colors.white60)),
            const Gap(24),
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 2000,
              style: const TextStyle(color: Colors.white),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tell us what would have made this better…',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Gap(16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            FilledButton(
              onPressed: (_submitting || _controller.text.trim().isEmpty)
                  ? null
                  : _submit,
              style: FilledButton.styleFrom(backgroundColor: EmergeColors.teal),
              child: _submitting
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Submit',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
