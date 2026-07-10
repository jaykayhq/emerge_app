import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/core/drift/database.dart';

part 'attribute_completions_provider.g.dart';

@riverpod
Future<List<int>> attributeCompletions(
  Ref ref,
  String attributeName,
) async {
  final user = await ref.watch(authStateChangesProvider.future);

  final dao = ref.watch(habitCompletionsDaoProvider);
  
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 6));
  
  final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
  final endStr = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

  final completions = await dao.getBetweenDates(user.id, startStr, endStr);

  final List<int> xpPerDay = List.filled(7, 0);
  
  for (final comp in completions) {
    if (comp.attribute?.toLowerCase() == attributeName.toLowerCase()) {
      final compDate = DateTime.parse(comp.completedAt);
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(compDate.year, compDate.month, compDate.day))
          .inDays;
      if (difference >= 0 && difference < 7) {
        xpPerDay[6 - difference] += comp.xpGained;
      }
    }
  }

  return xpPerDay;
}
