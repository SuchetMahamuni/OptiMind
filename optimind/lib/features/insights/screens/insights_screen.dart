import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/insights_provider.dart';
import '../widgets/chart_widgets.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsightsProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.background : AppColors.backgroundLight,
      body: SafeArea(
        child: Consumer<InsightsProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor:
                  isDark ? AppColors.card : AppColors.cardLight,
              onRefresh: provider.fetchAll,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insights',
                                style: AppTextStyles.h1.copyWith(
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                'Your study patterns at a glance',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Refresh icon
                          IconButton(
                            onPressed: provider.fetchAll,
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Time filter tabs ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: _FilterTabs(
                        selected: provider.selectedFilter,
                        onSelect: provider.setFilter,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // ── Error banner ────────────────────────────────────────
                  if (provider.errorMessage != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: _ErrorBanner(
                          message: provider.errorMessage!,
                          onRetry: provider.fetchAll,
                          isDark: isDark,
                        ),
                      ),
                    ),

                  // ── Content ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: provider.isLoading
                          ? _ShimmerContent(isDark: isDark)
                          : _InsightsContent(
                              provider: provider,
                              isDark: isDark,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Filter Tabs ──────────────────────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  final InsightsFilter selected;
  final void Function(InsightsFilter) onSelect;
  final bool isDark;

  const _FilterTabs({
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color:
            isDark ? AppColors.surface : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: InsightsFilter.values.map((filter) {
          final isSelected = filter == selected;
          final label = switch (filter) {
            InsightsFilter.daily => 'Daily',
            InsightsFilter.weekly => 'Weekly',
            InsightsFilter.monthly => 'Monthly',
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Main Content ─────────────────────────────────────────────────────────────

class _InsightsContent extends StatelessWidget {
  final InsightsProvider provider;
  final bool isDark;

  const _InsightsContent({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Show placeholder / empty state when no data at all
    if (!provider.hasData && provider.errorMessage == null) {
      return _EmptyState(isDark: isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Streak Card ───────────────────────────────────────────────
        _StreakCard(
          currentStreak: provider.currentStreak,
          bestStreak: provider.bestStreak,
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        // ── Study Time Chart ──────────────────────────────────────────
        _InsightCard(
          isDark: isDark,
          icon: Icons.access_time_rounded,
          iconColor: AppColors.primary,
          label: 'Study Time',
          subtitle: provider.totalStudyTimeFormatted,
          subtitleLabel: 'Total in range',
          child: StudyTimeBarChart(
            points: provider.statPoints,
            filter: provider.selectedFilter,
          ),
        ),
        const SizedBox(height: 20),

        // ── Focus Score Chart ─────────────────────────────────────────
        _InsightCard(
          isDark: isDark,
          icon: Icons.psychology_rounded,
          iconColor: AppColors.focus,
          label: 'Focus Score',
          subtitle:
              provider.avgFocusScore > 0
                  ? '${provider.avgFocusScore.toStringAsFixed(1)} avg'
                  : '—',
          subtitleLabel: 'Average score',
          child: FocusScoreLineChart(
            points: provider.statPoints,
            filter: provider.selectedFilter,
          ),
        ),
        const SizedBox(height: 20),

        // ── Interruptions ─────────────────────────────────────────────
        _InterruptionsCard(provider: provider, isDark: isDark),
        const SizedBox(height: 20),

        // ── Task Contribution ─────────────────────────────────────────
        _InsightCard(
          isDark: isDark,
          icon: Icons.pie_chart_outline_rounded,
          iconColor: AppColors.success,
          label: 'Task Contribution',
          subtitle: null,
          subtitleLabel: null,
          child: SubjectDistributionBars(
            distribution: provider.subjectDistribution,
          ),
        ),
      ],
    );
  }
}

// ── Streak Card ───────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;
  final bool isDark;

  const _StreakCard({
    required this.currentStreak,
    required this.bestStreak,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Flame icon with glow
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$currentStreak ${currentStreak == 1 ? 'day' : 'days'}',
                style: AppTextStyles.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Current streak',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '🏆 $bestStreak',
                style: AppTextStyles.h3.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Best streak',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Interruptions Card ────────────────────────────────────────────────────────

class _InterruptionsCard extends StatelessWidget {
  final InsightsProvider provider;
  final bool isDark;

  const _InterruptionsCard({required this.provider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = provider.totalInterruptions;
    final avg = provider.avgInterruptionsPerSession;
    final cardBg = isDark ? AppColors.card : AppColors.cardLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  color: AppColors.warning,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Interruptions',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatPill(
                  value: '$total',
                  label: 'Total',
                  color: AppColors.warning,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatPill(
                  value: avg == 0 ? '0' : avg.toStringAsFixed(1),
                  label: 'Avg / session',
                  color: AppColors.error,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          if (provider.interruptionPoints.isNotEmpty) ...[
            const SizedBox(height: 20),
            _InterruptionsBar(
              points: provider.interruptionPoints,
              filter: provider.selectedFilter,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _InterruptionsBar extends StatelessWidget {
  final List<SessionInterruptionPoint> points;
  final InsightsFilter filter;
  final bool isDark;

  const _InterruptionsBar({
    required this.points,
    required this.filter,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Group by day and sum interruptions
    final Map<String, int> byDay = {};
    for (final p in points) {
      final key =
          '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}';
      byDay[key] = (byDay[key] ?? 0) + p.interruptions;
    }

    if (byDay.isEmpty) return const SizedBox.shrink();

    final maxVal =
        byDay.values.fold<int>(0, (m, v) => v > m ? v : m).toDouble();
    if (maxVal == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Per Day\nDate',
          style: AppTextStyles.bodySmall.copyWith(
            color:
                isDark ? AppColors.textMuted : AppColors.textMutedLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ...byDay.entries.map((e) {
          final pct = e.value / maxVal;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    e.key.substring(8), // day number
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : Colors.black.withValues(alpha: 0.07),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.warning),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${e.value}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Reusable Insight Card ─────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final String? subtitleLabel;
  final Widget child;
  final bool isDark;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.subtitleLabel,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.card : AppColors.cardLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
                alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (subtitle != null && subtitleLabel != null)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: iconColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: '  $subtitleLabel',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ── Shimmer Loading ───────────────────────────────────────────────────────────

class _ShimmerContent extends StatelessWidget {
  final bool isDark;
  const _ShimmerContent({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200;
    final highlightColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          _shimmerBox(120),
          const SizedBox(height: 20),
          _shimmerBox(232),
          const SizedBox(height: 20),
          _shimmerBox(200),
          const SizedBox(height: 20),
          _shimmerBox(160),
          const SizedBox(height: 20),
          _shimmerBox(180),
        ],
      ),
    );
  }

  Widget _shimmerBox(double height) => Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
      );
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No data yet',
              style: AppTextStyles.h3.copyWith(
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete study sessions\nto view your insights.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
