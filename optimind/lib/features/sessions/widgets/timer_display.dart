import 'package:flutter/material.dart';

class TimerDisplay extends StatefulWidget {
  final int seconds;
  final bool isActive;
  final bool isTask;
  final int? estimatedTime;


  const TimerDisplay({
    super.key,
    required this.seconds,
    required this.isActive,
    required this.isTask,
    this.estimatedTime,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay> with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    // Start task from time where it was left off
    // widget.seconds;


    if (widget.isActive) {
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_breathingController.isAnimating) {
      _breathingController.repeat(reverse: true);
    } else if (!widget.isActive && _breathingController.isAnimating) {
      _breathingController.stop();
    }
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: ScaleTransition(
        scale: _breatheAnimation,
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface.withAlpha(130),
            // backgroundBlendMode: BlendMode.darken,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: 20,
              ),
            ],
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.seconds >= 3600 ? "HOURS" : "MINUTES",
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              if (widget.isTask) ...[
                  Text(
                    _formatTime(widget.seconds),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w200,
                      fontSize: 60,
                      letterSpacing: -1,
                      fontFamily: 'monospace', // Ensure consistent spacing for digits
                    ),
                  ),


                  Divider(
                    thickness: 2.0,
                    color: Colors.grey,
                    indent: 20.0,
                    endIndent: 20.0,
                  ),
                  Text(
                    _formatTime(widget.estimatedTime ?? 3600),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w200,
                      fontSize: 60,
                      letterSpacing: -1,
                      fontFamily: 'monospace', // Ensure consistent spacing for digits
                    ),
                  ),
              ] else ...[
                Text(
                  _formatTime(widget.seconds),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w200,
                    fontSize: 64,
                    letterSpacing: -1,
                    fontFamily: 'monospace', // Ensure consistent spacing for digits
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Text(
                widget.isActive ? "FOCUS PERIOD" : "PAUSED",
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
