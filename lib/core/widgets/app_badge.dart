import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final bool outlined;

  const AppBadge({
    super.key,
    required this.text,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bgColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: outlined ? bgColor : bgColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: outlined ? bgColor : bgColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
