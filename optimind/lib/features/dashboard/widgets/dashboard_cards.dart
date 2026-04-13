import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/linear_progress_bar.dart';

class FocusScoreCard extends StatelessWidget {
  final double score;
  final String label;
  final Color scoreColor;

  const FocusScoreCard({
    super.key, 
    required this.score, 
    required this.label,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppCard(
      title: "Focus Score",
      titleColor:  theme.colorScheme.inverseSurface,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scoreColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scoreColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  color: scoreColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${score.toInt()}',
                style: theme.textTheme.headlineMedium?.copyWith(color:  theme.colorScheme.inverseSurface),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Goal for today",
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                Text(
                  "Maintain >80 for optimal results",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DailyGoalCard extends StatelessWidget {
  final int goalMinutes;
  final int currentMinutes;
  final String rationale;

  const DailyGoalCard({
    super.key, 
    required this.goalMinutes, 
    required this.currentMinutes,
    required this.rationale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final double progress = goalMinutes > 0 
        ? (currentMinutes / goalMinutes).clamp(0.0, 1.0) 
        : 0.0;
    final int percentage = (progress * 100).toInt();

    return AppCard(
      title: "Daily Goal",
      titleColor:  theme.colorScheme.inverseSurface,
      trailing: Text(
        "$percentage%",
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, color: colorScheme.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${currentMinutes ~/ 60}h ${currentMinutes % 60}m / ${goalMinutes ~/ 60}h ${goalMinutes % 60}m',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color:  theme.colorScheme.inversePrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressBar(
            value: progress,
            gradientColors: [
              colorScheme.secondary,
              colorScheme.secondaryContainer,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rationale,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class SmartNudgeCard extends StatelessWidget {
  final String message;

  const SmartNudgeCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          colors: [
            colorScheme.surface, 
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PRO TIP", 
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: colorScheme.primary,
                  ),
                ),
                Text(message, style: theme.textTheme.bodyMedium?.copyWith(color:  colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
