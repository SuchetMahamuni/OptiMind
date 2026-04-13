import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/app_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.insightsTitle,
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 32),
              AppCard(
                title: AppStrings.weeklyOverview,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.bar_chart_outlined, size: 48, color: AppColors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'No productivity data tracked yet.',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppCard(
                color: AppColors.surface,
                title: AppStrings.weakAreaDetection,
                hasShadow: false,
                child: Text(
                  'Keep using OptiMind to discover your patterns.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
