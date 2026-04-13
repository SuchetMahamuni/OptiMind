import 'dart:math' as math;
import 'package:flutter/material.dart';

class WaterFillingProgress extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final double size;

  const WaterFillingProgress({
    super.key,
    required this.progress,
    this.size = 250,
  });

  @override
  State<WaterFillingProgress> createState() => _WaterFillingProgressState();
}

class _WaterFillingProgressState extends State<WaterFillingProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: WaterFillingPainter(
            progress: widget.progress,
            waveValue: _waveController.value,
          ),
        );
      },
    );
  }
}

class WaterFillingPainter extends CustomPainter {
  final double progress;
  final double waveValue;

  WaterFillingPainter({
    required this.progress,
    required this.waveValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw the background circle (glassy look)
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius, borderPaint);

    // 2. Clip for the water
    canvas.save();
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.clipPath(clipPath);

    // 3. Draw Water
    final waterPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.lightBlueAccent.withValues(alpha: 0.8),
          Colors.lightBlue.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final waterHeight = size.height * (1 - progress);
    final waterPath = Path();
    
    waterPath.moveTo(0, waterHeight);
    
    // Wave animation
    for (double i = 0; i <= size.width; i++) {
      waterPath.lineTo(
        i,
        waterHeight + math.sin((i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi)) * 6,
      );
    }
    
    waterPath.lineTo(size.width, size.height);
    waterPath.lineTo(0, size.height);
    waterPath.close();

    canvas.drawPath(waterPath, waterPaint);

    // Subtle gloss on top of water
    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
      
    final waveLine = Path();
    waveLine.moveTo(0, waterHeight);
    for (double i = 0; i <= size.width; i++) {
        waveLine.lineTo(
          i,
          waterHeight + math.sin((i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi)) * 6,
        );
    }
    canvas.drawPath(waveLine, glossPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(WaterFillingPainter oldDelegate) => 
      oldDelegate.progress != progress || oldDelegate.waveValue != waveValue;
}
