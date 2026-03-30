import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VerticalSlider extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final Color color;
  final ValueChanged<int> onChanged;

  const VerticalSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: 3,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: color,
          inactiveTrackColor: AppTheme.border,
          thumbColor: color,
          overlayColor: color.withOpacity(0.2),
          trackHeight: 8,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        ),
        child: Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          onChanged: (v) => onChanged(v.round()),
        ),
      ),
    );
  }
}
