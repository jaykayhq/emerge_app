import 'package:flutter/material.dart';

/// Typeahead habit suggestions.
///
/// When [query] is empty, renders a 2-column curated grid. As the user types,
/// renders an inline filtered dropdown. Selecting an item calls [onSelected].
class HabitSuggestionsGrid extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSelected;
  final String query;

  const HabitSuggestionsGrid({
    super.key,
    required this.suggestions,
    required this.onSelected,
    this.query = '',
  });

  @override
  Widget build(BuildContext context) {
    final filtered = query.isEmpty
        ? suggestions
        : suggestions
            .where((s) => s.toLowerCase().contains(query.toLowerCase()))
            .toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    // Inline dropdown for typed queries.
    if (query.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: filtered
              .take(5)
              .map((s) => ListTile(
                    dense: true,
                    title: Text(
                      s,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onTap: () => onSelected(s),
                  ))
              .toList(),
        ),
      );
    }

    // Grid for empty query.
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => onSelected(filtered[index]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: Colors.cyanAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  filtered[index],
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
