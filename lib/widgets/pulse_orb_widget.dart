import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PulseOrbType { shield, voiceIdle, voiceListening }

class PulseOrbWidget extends StatefulWidget {
  final PulseOrbType type;
  final Widget child;
  final VoidCallback? onTap;

  const PulseOrbWidget({
    Key? key,
    required this.type,
    required this.child,
    this.onTap,
  }) : super(key: key);

  @override
  State<PulseOrbWidget> createState() => _PulseOrbWidgetState();
}

class _PulseOrbWidgetState extends State<PulseOrbWidget> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _rippleController;
  late Animation<double> _breatheAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Determine durations based on type
    int breatheDuration = 2000;
    int rippleDuration = 2500;

    if (widget.type == PulseOrbType.voiceListening) {
      breatheDuration = 600;
      rippleDuration = 1200;
    }

    _breatheController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: breatheDuration),
    );

    double beginScale = 0.95;
    double endScale = 1.05;
    if (widget.type == PulseOrbType.shield) {
      beginScale = 0.92;
      endScale = 1.08;
    } else if (widget.type == PulseOrbType.voiceListening) {
      beginScale = 1.0;
      endScale = 1.15;
    }

    _breatheAnimation = Tween<double>(begin: beginScale, end: endScale).animate(
      CurvedAnimation(
        parent: _breatheController,
        curve: Curves.easeInOut,
      ),
    );

    _breatheController.repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: rippleDuration),
    );

    double rippleEndScale = 1.3;
    if (widget.type == PulseOrbType.voiceListening) {
      rippleEndScale = 1.5;
    }

    _rippleAnimation = Tween<double>(begin: 1.0, end: rippleEndScale).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOut,
      ),
    );

    _rippleOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: Curves.easeOut,
      ),
    );

    _rippleController.repeat();
  }

  @override
  void didUpdateWidget(covariant PulseOrbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      _breatheController.dispose();
      _rippleController.dispose();
      _setupAnimations();
    }
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.type) {
      case PulseOrbType.shield:
        return AppTheme.primaryBlue;
      case PulseOrbType.voiceIdle:
        return AppTheme.primaryBlue;
      case PulseOrbType.voiceListening:
        return AppTheme.dangerRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breatheController, _rippleController]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple ring
              Transform.scale(
                scale: _rippleAnimation.value,
                child: Opacity(
                  opacity: _rippleOpacity.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color.withOpacity(0.4),
                        width: 4,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.type == PulseOrbType.voiceListening) ...[
                // Second ripple ring for listening staggered effect
                Transform.scale(
                  scale: ((_rippleAnimation.value - 1.0) * 0.7 + 1.0),
                  child: Opacity(
                    opacity: (1.0 - _rippleAnimation.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // Main breathing core orb
              Transform.scale(
                scale: _breatheAnimation.value,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _color.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(child: widget.child),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
