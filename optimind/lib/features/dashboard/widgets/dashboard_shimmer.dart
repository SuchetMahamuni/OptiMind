import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(height: 16, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(height: 28, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 40),
            _buildShimmerBox(height: 160),
            const SizedBox(height: 24),
            _buildShimmerBox(height: 120),
            const SizedBox(height: 24),
            _buildShimmerBox(height: 100),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildShimmerBox(height: 80)),
                const SizedBox(width: 16),
                Expanded(child: _buildShimmerBox(height: 80)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}
