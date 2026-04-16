import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../providers/insights_provider.dart';

// ── Study Time Bar Chart ───────────────────────────────────────────────────────

class StudyTimeBarChart extends StatelessWidget {
  final List<DailyStatPoint> points;
  final InsightsFilter filter;

  const StudyTimeBarChart({
    super.key,
    required this.points,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (points.isEmpty) return _emptyState(isDark);

    final filledPoints = _fillMissingDays(points, filter);
    final maxY = filledPoints.fold<double>(
          0,
          (m, p) => p.studyMinutes > m ? p.studyMinutes : m,
        ) *
        1.25;
    final capY = maxY < 10 ? 60.0 : maxY;

    final barGroups = filledPoints.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: p.studyMinutes,
            width: _barWidth(filledPoints.length),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            gradient: p.studyMinutes > 0
                ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  )
                : null,
            color: p.studyMinutes == 0
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.06))
                : null,
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: capY,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: capY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: capY / 4,
                getTitlesWidget: (value, _) => Text(
                  _formatMinLabel(value),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= filledPoints.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _xLabel(filledPoints[idx].date, filter),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedLight,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor:
                  isDark ? AppColors.card : AppColors.cardLight,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final mins = rod.toY;
                return BarTooltipItem(
                  _formatMinLabel(mins),
                  AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
        swapAnimationCurve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _emptyState(bool isDark) => SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No study sessions recorded.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
          ),
        ),
      );

  double _barWidth(int count) {
    if (count <= 1) return 32;
    if (count <= 7) return 20;
    if (count <= 14) return 12;
    return 8;
  }

  String _formatMinLabel(double mins) {
    if (mins >= 60) {
      return '${(mins / 60).toStringAsFixed(1)}h';
    }
    return '${mins.round()}m';
  }

  String _xLabel(DateTime date, InsightsFilter filter) {
    switch (filter) {
      case InsightsFilter.daily:
        return DateFormat('HH:mm').format(date);
      case InsightsFilter.weekly:
        return DateFormat('EEE').format(date);
      case InsightsFilter.monthly:
        return DateFormat('d').format(date);
    }
  }
}

// ── Focus Score Line Chart ─────────────────────────────────────────────────────

class FocusScoreLineChart extends StatelessWidget {
  final List<DailyStatPoint> points;
  final InsightsFilter filter;

  const FocusScoreLineChart({
    super.key,
    required this.points,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filled = _fillMissingDays(points, filter);
    final hasValues = filled.any((p) => p.focusScore > 0);

    if (!hasValues) return _emptyState(isDark);

    final spots = filled.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.focusScore);
    }).toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.focus,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: filled.length <= 10,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.secondary,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.25),
                    AppColors.secondary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 25,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color:
                        isDark ? AppColors.textMuted : AppColors.textMutedLight,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= filled.length) {
                    return const SizedBox.shrink();
                  }
                  // show labels every N items to avoid crowding
                  final step = filled.length <= 7 ? 1 : (filled.length ~/ 6);
                  if (idx % step != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _xLabel(filled[idx].date, filter),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedLight,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor:
                  isDark ? AppColors.card : AppColors.cardLight,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        s.y.toStringAsFixed(1),
                        AppTextStyles.bodySmall.copyWith(
                          color: AppColors.focus,
                          fontWeight: FontWeight.w600,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  Widget _emptyState(bool isDark) => SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Focus data will appear here.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
          ),
        ),
      );

  String _xLabel(DateTime date, InsightsFilter filter) {
    switch (filter) {
      case InsightsFilter.daily:
        return DateFormat('HH:mm').format(date);
      case InsightsFilter.weekly:
        return DateFormat('EEE').format(date);
      case InsightsFilter.monthly:
        return DateFormat('d').format(date);
    }
  }
}

// ── Subject Distribution Bars ──────────────────────────────────────────────────

class SubjectDistributionBars extends StatelessWidget {
  final Map<String, double> distribution; // subject → minutes

  const SubjectDistributionBars({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (distribution.isEmpty) {
      return Center(
        child: Text(
          'Complete tasks to see contribution.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
          ),
        ),
      );
    }

    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalMins = sorted.fold<double>(0, (s, e) => s + e.value);

    final palette = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.focus,
    ];

    return Column(
      children: sorted.asMap().entries.map((entry) {
        final idx = entry.key;
        final e = entry.value;
        final pct = totalMins > 0 ? e.value / totalMins : 0.0;
        final color = palette[idx % palette.length];
        final h = e.value ~/ 60;
        final m = (e.value % 60).round();
        final timeStr = h > 0 ? '${h}h ${m}m' : '${m}m';

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.07),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Shared helper: fill missing days in a range ────────────────────────────────

List<DailyStatPoint> _fillMissingDays(
  List<DailyStatPoint> points,
  InsightsFilter filter,
) {
  final days = _daysForFilter(filter);
  final now = DateTime.now();
  final result = <DailyStatPoint>[];

  for (int i = days - 1; i >= 0; i--) {
    final date = DateTime(now.year, now.month, now.day - i);
    final existing = points.where((p) =>
        p.date.year == date.year &&
        p.date.month == date.month &&
        p.date.day == date.day);
    if (existing.isNotEmpty) {
      result.add(existing.first);
    } else {
      result.add(DailyStatPoint(date: date, studyMinutes: 0, focusScore: 0));
    }
  }
  return result;
}

int _daysForFilter(InsightsFilter filter) {
  switch (filter) {
    case InsightsFilter.daily:
      return 1;
    case InsightsFilter.weekly:
      return 7;
    case InsightsFilter.monthly:
      return 30;
  }
}
