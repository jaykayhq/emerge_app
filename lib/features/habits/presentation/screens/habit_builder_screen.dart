import 'package:emerge_app/core/presentation/widgets/growth_background.dart';
import 'package:emerge_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class HabitBuilderScreen extends ConsumerStatefulWidget {
  const HabitBuilderScreen({super.key});

  @override
  ConsumerState<HabitBuilderScreen> createState() => _HabitBuilderScreenState();
}

class _HabitBuilderScreenState extends ConsumerState<HabitBuilderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GrowthBackground(
      appBar: AppBar(
        title: const Text('Habit Builder'),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Stack'),
            Tab(text: 'Blueprints'),
          ],
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondaryDark,
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [_MyStackTab(), _BlueprintsTab()],
      ),
    );
  }
}

class _MyStackTab extends StatefulWidget {
  @override
  State<_MyStackTab> createState() => _MyStackTabState();
}

class _MyStackTabState extends State<_MyStackTab> {
  // Mock data for drag-and-drop
  final List<String> _habits = [
    'Morning Meditation',
    'Drink Water',
    'Read 10 Pages',
    'Workout',
    'Journaling',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Drag and drop to reorder your habit stack.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondaryDark),
          ),
        ),
        Expanded(
          child: ReorderableListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final String item = _habits.removeAt(oldIndex);
                _habits.insert(newIndex, item);
              });
            },
            children: [
              for (int index = 0; index < _habits.length; index++)
                Card(
                  key: Key('$index'),
                  color: AppTheme.surfaceDark,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppTheme.textSecondaryDark.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      _habits[index],
                      style: const TextStyle(
                        color: AppTheme.textMainDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.drag_handle,
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlueprintsTab extends StatelessWidget {
  final List<Map<String, dynamic>> _blueprints = const [
    {
      'title': 'Morning Routine',
      'description': 'Start your day with energy and focus.',
      'habits': 5,
      'icon': Icons.wb_sunny,
    },
    {
      'title': 'Deep Work Protocol',
      'description': 'Maximize productivity and minimize distractions.',
      'habits': 4,
      'icon': Icons.psychology,
    },
    {
      'title': 'Nightly Wind Down',
      'description': 'Prepare for a restful sleep.',
      'habits': 3,
      'icon': Icons.nights_stay,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _blueprints.length,
      separatorBuilder: (context, index) => const Gap(16),
      itemBuilder: (context, index) {
        final blueprint = _blueprints[index];
        return Card(
          color: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    blueprint['icon'] as IconData,
                    color: AppTheme.secondary,
                    size: 32,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blueprint['title'] as String,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMainDark,
                            ),
                      ),
                      const Gap(4),
                      Text(
                        blueprint['description'] as String,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '${blueprint['habits']} habits',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Imported ${blueprint['title']} blueprint',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.download,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
