import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onTriggered;

  const SosButton({
    Key? key,
    required this.onTriggered,
  }) : super(key: key);

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  late AnimationController _breatheController;
  late AnimationController _countdownController;
  late Animation<double> _breatheAnimation;

  bool _isCountingDown = false;
  bool _isSuccess = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breatheAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _breatheController.repeat(reverse: true);

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _countdownController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSuccess();
      }
    });
  }

  void _triggerSuccess() {
    setState(() {
      _isCountingDown = false;
      _isSuccess = true;
    });
    HapticFeedback.heavyImpact();
    widget.onTriggered();

    _successTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _countdownController.reset();
        });
      }
    });
  }

  void _onTapDown() {
    if (_isSuccess) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _isCountingDown = true;
    });
    _countdownController.forward();
  }

  void _onTapCancel() {
    if (!_isCountingDown) return;
    setState(() {
      _isCountingDown = false;
    });
    _countdownController.reset();
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _countdownController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _onTapDown(),
          onTapUp: (_) => _onTapCancel(),
          onTapCancel: () => _onTapCancel(),
          child: AnimatedBuilder(
            animation: Listenable.merge([_breatheController, _countdownController]),
            builder: (context, child) {
              double scale = _breatheAnimation.value;
              if (_isCountingDown) {
                scale = 0.96; // Shrink slightly on press
              }

              Color buttonColor = AppTheme.dangerRed;
              if (_isSuccess) {
                buttonColor = AppTheme.safeGreen;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  // Countdown ring container
                  if (_isCountingDown)
                    SizedBox(
                      width: 230,
                      height: 230,
                      child: CircularProgressIndicator(
                        value: 1.0 - _countdownController.value, // Drains down to 0
                        strokeWidth: 6,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.dangerRed),
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                  // SOS Orb Body
                  Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: buttonColor.withOpacity(isDark ? 0.08 : 0.06),
                        border: Border.all(
                          color: buttonColor,
                          width: 4.0,
                        ),
                      ),
                      child: Center(
                        child: AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: _isSuccess
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  color: buttonColor,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'HOLD FOR 3S',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          secondChild: Icon(
                            Icons.check_circle_outline,
                            color: buttonColor,
                            size: 80,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        AnimatedOpacity(
          opacity: _isCountingDown ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: const Text(
            'Keep holding...',
            style: TextStyle(
              color: AppTheme.dangerRed,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
