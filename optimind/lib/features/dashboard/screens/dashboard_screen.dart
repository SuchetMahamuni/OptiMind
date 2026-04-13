import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/models/user_model.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/app_utils.dart';
import '../widgets/dashboard_shimmer.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/summary_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // late final user;
  UserModel? user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Provider.of<DashboardProvider>(context, listen: false).fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    user = authProvider.user;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.data == null) {
            return const DashboardShimmer();
          }

          if (provider.error != null && provider.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final data = provider.data!;
          final effectiveGoalMinutes = settingsProvider.useAdaptiveGoal 
              ? data.goalMinutes 
              : settingsProvider.customGoalMinutes;

          return RefreshIndicator(
            onRefresh: _loadData,
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  FocusScoreCard(
                    score: data.focusScore,
                    label: data.focusLabel,
                    scoreColor: AppUtils.getFocusScoreColor(data.focusScore.toInt()),
                  ),
                  const SizedBox(height: 24),
                  DailyGoalCard(
                    goalMinutes: effectiveGoalMinutes,
                    currentMinutes: data.totalStudyTimeToday ~/ 60,
                    rationale: settingsProvider.useAdaptiveGoal 
                        ? data.goalRationale 
                        : "Focus on your personal target",
                  ),
                  const SizedBox(height: 24),
                  SmartNudgeCard(message: data.nudgeMessage),
                  const SizedBox(height: 32),
                  Text(
                    "Activity Summary",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  SummaryGrid(
                    studySeconds: data.totalStudyTimeToday,
                    streak: data.currentStreak,
                    pendingTasks: data.pendingTasks,
                    completedTasks: data.completedTasks,
                  ),
                  const SizedBox(height: 120), // Space for bottom nav
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppUtils.getGreeting(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              user?.username ?? 'Student',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ),
      ],
    );
  }
}
