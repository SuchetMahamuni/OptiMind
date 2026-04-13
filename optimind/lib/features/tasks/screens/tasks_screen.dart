import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/app_card.dart';
import '../../sessions/providers/session_provider.dart';
import '../../sessions/screens/sessions_screen.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import '../widgets/task_progress_bar.dart';
import 'add_task_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  Future<void> triggerRefresh() async {
    await _refreshKey.currentState?.show();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: () => taskProvider.fetchTasks(),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tasksTitle,
                        style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Manage your study priorities",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (taskProvider.isLoading && taskProvider.tasks.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (taskProvider.tasks.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(context),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = taskProvider.sortedTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _TaskCard(task: task),
                        );
                      },
                      childCount: taskProvider.tasks.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => const AddTaskScreen())
        ),
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
     final theme = Theme.of(context);
     return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, 
            size: 80, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            AppStrings.emptyTasksText,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Tap + to stay productive",
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;

  const _TaskCard({required this.task});

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.deepOrange;
      case 'medium': return Colors.amber.shade700;
      case 'low': return Colors.lightBlue;
      default: return Colors.grey;
    }
  }

  Future<void> _startSessionForTask(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Start Session"),
        content: Text("Begin a focus session for '${task.subject}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("NOT NOW"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text("START"),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final sessionProvider = Provider.of<SessionProvider>(context, listen: false);
      sessionProvider.startSession(
        taskId: task.id,
        targetDuration: task.estimatedTime,
        startFrom: task.totalSecondsSpent,
      );
      
      // Navigate to SessionsScreen (assuming it's handled via the app shell index or direct push)
      // Since it's a prominent requirement, we'll push it directly to ensure context.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SessionsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _getPriorityColor(task.priority);

    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: task.isCompleted ? null : () => _startSessionForTask(context),
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority Accent Line
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: task.isCompleted ? 0.3 : 1.0),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.subject,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                  color: task.isCompleted ? theme.colorScheme.onSurfaceVariant :  theme.colorScheme.inverseSurface,
                                ),
                              ),
                            ),
                            if (!task.isCompleted)
                              Checkbox(
                                value: task.isCompleted,
                                onChanged: (_) => Provider.of<TaskProvider>(context, listen: false).toggleComplete(task.id),
                                activeColor: theme.colorScheme.primary,
                                shape: const CircleBorder(),
                              )
                            else
                              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 24),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(
                              context, 
                              Icons.calendar_today_outlined, 
                              task.deadline != null 
                                  ? DateFormat('MMM d, HH:mm').format(task.deadline!) 
                                  : "No deadline"
                            ),
                            const SizedBox(width: 16),
                            _buildInfoChip(
                              context, 
                              Icons.timer_outlined, 
                              "${task.estimatedTime / 60}m"
                            ),
                          ],
                        ),
                        if (!task.isCompleted && task.progressPercentage > 0) ...[
                          const SizedBox(height: 16),
                          TaskProgressBar(progress: task.progressPercentage),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
