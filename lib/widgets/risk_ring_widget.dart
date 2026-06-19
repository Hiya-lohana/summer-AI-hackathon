import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/scan_result.dart';
import '../theme/app_theme.dart';

class RiskRingWidget extends StatefulWidget {
  final RiskLevel riskLevel;
  final double score;

  const RiskRingWidget({
    super.key,
    required this.riskLevel,
    required this.score,
  });

  @override
  State<RiskRingWidget> createState() => _RiskRingWidgetState();
}

class _RiskRingWidgetState extends State<RiskRingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scoreAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnimation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    )..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.riskLevel) {
      case RiskLevel.safe:
        return AppTheme.safeGreen;
      case RiskLevel.suspicious:
        return AppTheme.warningOrange;
      case RiskLevel.dangerous:
        return AppTheme.dangerRed;
    }
  }

  String get _label {
    switch (widget.riskLevel) {
      case RiskLevel.safe:
        return 'SAFE';
      case RiskLevel.suspicious:
        return 'SUSPICIOUS';
      case RiskLevel.dangerous:
        return 'DANGEROUS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final animatedScore = _scoreAnimation.value;
    return Center(
      child: CircularPercentIndicator(
        radius: 80.0, // 160dp diameter
        lineWidth: 12.0,
        animation: true,
        animationDuration: 1200,
        percent: widget.score / 100.0,
        animateFromLastPercent: true,
        curve: Curves.easeOutBack,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${animatedScore.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _color,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        circularStrokeCap: CircularStrokeCap.butt,
        progressColor: _color,
        backgroundColor: Colors.white.withOpacity(0.1),
      ),
    );
  }
}
