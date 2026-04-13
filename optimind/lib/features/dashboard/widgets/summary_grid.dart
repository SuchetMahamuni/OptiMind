import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SummaryGrid extends StatelessWidget {
  final int studySeconds;
  final int streak;
  final int pendingTasks;
  final int completedTasks;

  const SummaryGrid({
    super.key, 
    required this.studySeconds, 
    required this.streak,
    required this.pendingTasks,
    required this.completedTasks,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildSummaryItem(context, "Today's Study", _formatTime(studySeconds), Icons.history_edu, AppColors.primary),
        _buildSummaryItem(context, "Streak", "$streak Days", Icons.local_fire_department, Colors.orange),
        _buildSummaryItem(context, "Pending", "$pendingTasks Tasks", Icons.assignment_late_outlined, AppColors.error),
        _buildSummaryItem(context, "Completed", "$completedTasks Tasks", Icons.assignment_turned_in_outlined, AppColors.success),
      ],
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color:  theme.colorScheme.inverseSurface)),
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int mins = (seconds % 3600) ~/ 60;
    return '${hours}h ${mins}m';
  }
}
