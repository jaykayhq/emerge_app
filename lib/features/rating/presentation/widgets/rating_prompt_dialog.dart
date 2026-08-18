import 'package:flutter/material.dart';

typedef RatingCallback = void Function(int rating);

Future<void> showRatingPromptDialog(
  BuildContext context, {
  required RatingCallback onRating,
  required VoidCallback onNotNow,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1B1B2F),
      title: const Text(
        'How is Emerge going?',
        style: TextStyle(color: Colors.white),
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (i) {
          final star = i + 1;
          return Semantics(
            label: 'Rate $star stars',
            child: IconButton(
              icon: const Icon(
                Icons.star_border,
                color: Colors.amber,
                size: 36,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onRating(star);
              },
            ),
          );
        }),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNotNow();
          },
          child: const Text('Not now', style: TextStyle(color: Colors.white54)),
        ),
      ],
    ),
  );
}
