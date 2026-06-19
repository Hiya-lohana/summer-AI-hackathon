import 'package:flutter/material.dart';

class Tip {
  final String category;
  final String title;
  final String description;
  final IconData icon;
  final Color themeColor;
  final String fullAdvice;

  Tip({
    required this.category,
    required this.title,
    required this.description,
    required this.icon,
    required this.themeColor,
    required this.fullAdvice,
  });
}
