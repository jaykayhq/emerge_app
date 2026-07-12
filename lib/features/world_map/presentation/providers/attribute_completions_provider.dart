import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:emerge_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:emerge_app/features/habits/presentation/providers/habit_providers.dart';

part 'attribute_completions_provider.g.dart';

@riverpod
Future<List<int>> attributeCompletions(
  Ref ref,
  String attributeName,
) async {
  final user = await ref.watch(authStateChangesProvider.future);
  
  if (user.isEmpty) {
    return List.filled(7, 0);
  }

  final repository = ref.watch(habitRepositoryProvider);
  
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 6));
  
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final completionsEither = await repository.getCompletionsBetweenDates(
    user.id,
    startDay,
    endDay,
  );

  final List<int> xpPerDay = List.filled(7, 0);
  
  completionsEither.fold(
    (failure) {
      // Do nothing, returns array of 0s
    },
    (completions) {
      for (final comp in completions) {
        if (comp.attribute.toLowerCase() == attributeName.toLowerCase()) {
          final compDate = comp.completedAt;
          final difference = DateTime(now.year, now.month, now.day)
              .difference(DateTime(compDate.year, compDate.month, compDate.day))
              .inDays;
          if (difference >= 0 && difference < 7) {
            xpPerDay[6 - difference] += comp.xpGained;
          }
        }
      }
    },
  );

  return xpPerDay;
}
