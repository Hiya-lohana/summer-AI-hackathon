import 'package:flutter/material.dart';
import '../models/tip.dart';
import '../theme/app_theme.dart';

class ScamTipCard extends StatefulWidget {
  final Tip tip;

  const ScamTipCard({
    Key? key,
    required this.tip,
  }) : super(key: key);

  @override
  State<ScamTipCard> createState() => _ScamTipCardState();
}

class _ScamTipCardState extends State<ScamTipCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border(
          left: BorderSide(color: widget.tip.themeColor, width: 5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(widget.tip.icon, color: widget.tip.themeColor, size: 24),
            title: Text(
              widget.tip.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15.0,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              widget.tip.category,
              style: TextStyle(
                color: widget.tip.themeColor.withOpacity(0.8),
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.textSecondary,
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
            child: Text(
              widget.tip.description,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13.0,
                height: 1.4,
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: AppTheme.dividerColor),
                  const SizedBox(height: 8),
                  Text(
                    'AI Safety Advice:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.tip.fullAdvice,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
