import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../tasks/providers/task_provider.dart';
import '../models/session_model.dart';
import '../providers/session_provider.dart';
import '../widgets/timer_display.dart';
import '../widgets/water_filling_progress.dart';
import '../../../providers/navigation_provider.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  bool _isSessionExited = false;
  bool _isCompletionDialogShown = false;
  bool isTask = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(context, listen: false).fetchSessions();
    });
  }

  void _checkTaskCompletion(BuildContext context, SessionProvider provider) {
    if (provider.sessionProgress >= 1.0 &&
        !_isCompletionDialogShown &&
        provider.currentTaskId != null &&
        provider.state == SessionState.active) {
      _isCompletionDialogShown = true;
      Future.microtask(() => _showTaskCompletedDialog(context, provider));
    }
  }

  Future<void> _showTaskCompletedDialog(
    BuildContext context,
    SessionProvider provider,
  ) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text("Task Completed?"),
            content: const Text(
              "You've reached your estimated time. Would you like to mark this task as complete and finish the session?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, "continue"),
                child: const Text("NO, CONTINUE"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, "complete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("YES, FINISH"),
              ),
            ],
          ),
    );

    if (result == "complete" && context.mounted) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      if (provider.currentTaskId != null) {
        await taskProvider.toggleComplete(provider.currentTaskId!);
      }
      provider.endSession(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = Provider.of<SessionProvider>(context);
    final theme = Theme.of(context);

    // Check for completion dialog
    _checkTaskCompletion(context, sessionProvider);

    return PopScope(
      canPop: !sessionProvider.isActive,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await _showExitConfirmation(context);
        if (shouldExit == true && context.mounted) {
          setState(() {
            _isSessionExited = true;
          });
          sessionProvider.endSession(false);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildContent(context, sessionProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SessionProvider provider) {
    switch (provider.state) {
      case SessionState.idle:
        return _buildIdleState(context, provider);
      case SessionState.active:
      case SessionState.paused:
        return _buildActiveState(context, provider);
      case SessionState.summary:
        return _buildSummaryState(context, provider);
    }
  }

  Future<void> triggerRefresh() async {
    await _refreshKey.currentState?.show();
  }

  Widget _buildIdleState(BuildContext context, SessionProvider provider) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: () => provider.fetchSessions(),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.sessionsTitle,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Manage your study priorities",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading && provider.sessions.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.sessions.isEmpty)
                SliverFillRemaining(child: _buildEmptyState(context, provider))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final sessionElement = provider.sortedSessions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SessionCard(
                          session: sessionElement,
                          provider: provider,
                        ),
                      );
                    }, childCount: provider.sessions.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _isSessionExited = false;
            _isCompletionDialogShown = false;
          });
          provider.startSession();
        },
        backgroundColor: theme.colorScheme.primary,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: const Text(
          AppStrings.startSessionButton,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SessionProvider provider) {
    final theme = Theme.of(context);

    return Padding(
      key: const ValueKey('idle'),
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology, size: 100, color: Colors.blueGrey),
          const SizedBox(height: 32),
          Text(
            "Ready to Focus?",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Find a quiet place and start your session.",
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 48),
          AppButton(
            text: AppStrings.startSessionButton,
            onPressed: () {
              setState(() {
                _isSessionExited = false;
                _isCompletionDialogShown = false;
              });
              provider.startSession();
            },
            isFullWidth: false,
            icon: Icons.play_arrow_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveState(BuildContext context, SessionProvider provider) {
    String? taskSubject;
    int? estimatedTime;
    if (provider.currentTaskId != null) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final task =
          taskProvider.tasks
              .where((t) => t.id == provider.currentTaskId)
              .firstOrNull;
      taskSubject = task?.subject;
      estimatedTime = task?.estimatedTime;
    }

    return Padding(
      key: const ValueKey('active'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () async {
                  final shouldExit = await _showExitConfirmation(context);
                  if (shouldExit == true) {
                    setState(() {
                      _isSessionExited = true;
                    });
                    provider.endSession(false);
                  }
                },
              ),
              _buildInterruptionBadge(context, provider),
            ],
          ),
          if (taskSubject != null) ...[
            const SizedBox(height: 16),
            Text(
              taskSubject,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const Spacer(),

            Stack(
              alignment: Alignment.center,
              children: [
                WaterFillingProgress(
                  progress:
                      provider.targetDuration != null
                          ? provider.sessionProgress
                          : 0.0,
                  size: 280,
                ),
                // const SizedBox(height: 32),
                TimerDisplay(
                  seconds: provider.elapsedSeconds,
                  isActive: provider.state == SessionState.active,
                  isTask: true,
                  estimatedTime:
                      (estimatedTime ??
                          60), // Temporary fix assuming estimatedTime is in minutes
                ),
              ],
            ),
          ] else ...[
            const Spacer(),
            TimerDisplay(
              seconds: provider.elapsedSeconds,
              isActive: provider.state == SessionState.active,
              isTask: false,
            ),
          ],

          const Spacer(),
          _buildActiveControls(context, provider),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInterruptionBadge(
    BuildContext context,
    SessionProvider provider,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            "${provider.interruptionCount} Distractions",
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveControls(BuildContext context, SessionProvider provider) {
    return Column(
      children: [
        AppButton(
          text: "I got distracted",
          onPressed: provider.addInterruption,
          isSecondary: true,
          icon: Icons.bolt_outlined,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                FloatingActionButton.large(
                  elevation: 0,
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  foregroundColor: Colors.redAccent,
                  onPressed: () async {
                    final shouldEnd = await _showEndConfirmation(context, provider);
                    if (shouldEnd == true) {
                      _isSessionExited = false;
                      provider.endSession(true);
                    }
                  },
                  child: const Icon(Icons.stop_rounded),
                ),
                const SizedBox(height: 8),
                Text(
                  "Stop Session",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(width: 40),
            Column(
              children: [
                FloatingActionButton.large(
                  elevation: 4,
                  backgroundColor:
                      provider.state == SessionState.paused
                          ? Colors.green
                          : Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  onPressed:
                      provider.state == SessionState.paused
                          ? provider.resumeSession
                          : provider.pauseSession,
                  child: Icon(
                    provider.state == SessionState.paused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.state == SessionState.paused ? "Resume" : "Pause",
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryState(BuildContext context, SessionProvider provider) {
    final theme = Theme.of(context);
    int? taskID;

    return Center(
      key: const ValueKey('summary'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              (_isSessionExited)
                  ? Icons.exit_to_app_outlined
                  : Icons.celebration_rounded,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              (_isSessionExited) ? "Session Exited" : "Session Complete!",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            _buildSummaryRow(
              context,
              "TOTAL TIME",
              _formatSummaryTime(provider.elapsedSeconds),
            ),
            const Divider(height: 48),
            _buildSummaryRow(
              context,
              "INTERRUPTIONS",
              "${provider.interruptionCount}",
            ),
            const SizedBox(height: 60),
            AppButton(
              text: (_isSessionExited) ? "Okay" : "Done",
              onPressed: () {
                // Refresh tasks to update progress bars
                taskID = provider.currentTaskId;
                provider.reset();
                Provider.of<TaskProvider>(context, listen: false).fetchTasks();
                Provider.of<SessionProvider>(context, listen: false).fetchSessions();
                if (taskID != null) {
                  Navigator.pop(context);
                } else {
                  Provider.of<NavigationProvider>(context,listen: false).setIndex(4);
                }


              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<bool?> _showExitConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Abandon Session?"),
            content: const Text(
              "Your current progress will not be saved. Are you sure you want to exit?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Keep Going"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Exit"),
              ),
            ],
          ),
    );
  }

  Future<bool?> _showEndConfirmation(BuildContext context, SessionProvider provider) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Stop Session?"),
            content: Text(
              (provider.currentTaskId != null)
                  ? "Are you ready to complete your focus period and save the stats for this task?"
                  : "Are you ready to complete your focus period?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Continue"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Stop"),
              ),
            ],
          ),
    );
  }

  String _formatSummaryTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    if (h > 0) return "${h}h ${m}m";
    return "${m}m ${seconds % 60}s";
  }
}

class _SessionCard extends StatelessWidget {
  final SessionModel session;
  final SessionProvider provider;

  const _SessionCard({required this.session, required this.provider});

  Color _getInterruptionColor(int duration, int interruptions) {
    double distractionRate = duration / interruptions;
    if (distractionRate <= 3) {
      return Colors.greenAccent;
    } else if (distractionRate > 3 && distractionRate <= 6) {
      return Colors.amber.shade300;
    } else {
      return Colors.amber.shade900;
    }
  }

  Future<void> _viewSession(BuildContext context) async {
    final task = Provider.of<TaskProvider>(context,listen: false).tasks.where((t) => t.id == session.taskId).firstOrNull;
    String details =
        "Subject: ${task?.subject ?? "None"}\nStart: ${session.startTime}\nEnd: ${session.endTime}\nDuration: ${session.duration}\nInterruptions: ${session.interruptions}";
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Session Details"),
            content: Text(details),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("OKAY"),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final sessionProvider = Provider.of<SessionProvider>(
        context,
        listen: false,
      );
      sessionProvider.startSession(
        taskId: task?.id,
        targetDuration: task?.estimatedTime,
        startFrom: task?.totalSecondsSpent,
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
    final priorityColor = _getInterruptionColor(
      session.duration,
      session.interruptions,
    );

    return Dismissible(
      key: Key(session.id.toString()),
      direction: DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      // onDismissed: (_) => Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            _viewSession(context);
          },
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Priority Accent Line
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 1.0),
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
                                provider.formatTime(session.duration),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: null,
                                  color: theme.colorScheme.inverseSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(
                              context,
                              Icons.play_arrow_outlined,
                              DateFormat(
                                'MMM d, HH:mm',
                              ).format(session.startTime),
                            ),
                            const SizedBox(width: 16),
                            _buildInfoChip(
                              context,
                              Icons.access_alarms_rounded,
                              DateFormat(
                                'MMM d, HH:mm',
                              ).format(session.endTime),
                            ),
                          ],
                        ),
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
