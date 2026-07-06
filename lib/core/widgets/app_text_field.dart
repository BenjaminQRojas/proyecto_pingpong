import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String value;
  final ValueChanged<String>? onChanged;
  final bool monospace;

  const AppTextField({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.onChanged,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: monospace ? 'monospace' : null,
          ),
          decoration: InputDecoration(hintText: hint, isDense: true),
        ),
      ],
    );
  }
}
