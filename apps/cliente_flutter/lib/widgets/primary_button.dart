import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      backgroundColor: isSecondary ? Colors.white : AppTheme.ink,
      foregroundColor: isSecondary ? AppTheme.ink : Colors.white,
      elevation: 0,
      side: BorderSide(color: isSecondary ? AppTheme.ink : AppTheme.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isSecondary ? AppTheme.ink : Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(label),
              ],
            ),
    );
  }
}
