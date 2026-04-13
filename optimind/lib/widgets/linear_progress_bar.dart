import 'package:flutter/material.dart';

class LinearProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final List<Color>? gradientColors;
  final double height;
  final bool showGlow;

  const LinearProgressBar({
    super.key,
    required this.value,
    this.gradientColors,
    this.height = 12.0,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Default gradient based on theme if not provided
    final colors = gradientColors ?? [
      colorScheme.primary,
      colorScheme.secondary,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            // Background track
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            // Progress bar with Gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: height,
              width: MediaQuery.of(context).size.width * (value.clamp(0.0, 1.0)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(height / 2),
                boxShadow: [
                  if (showGlow && value > 0)
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
