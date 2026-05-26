import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.background,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color background;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

Color priorityBg(String value) {
  switch (value) {
    case 'HIGH':
      return const Color(0xFFFFE5E1);
    case 'LOW':
      return const Color(0xFFE7F0FF);
    default:
      return const Color(0xFFFFF1DA);
  }
}

Color priorityText(String value) {
  switch (value) {
    case 'HIGH':
      return AppColors.danger;
    case 'LOW':
      return AppColors.info;
    default:
      return AppColors.warning;
  }
}

IconData priorityIcon(String value) {
  switch (value) {
    case 'HIGH':
      return Icons.keyboard_double_arrow_up_rounded;
    case 'LOW':
      return Icons.keyboard_double_arrow_down_rounded;
    default:
      return Icons.remove_rounded;
  }
}

Color statusBg(String value) {
  switch (value) {
    case 'DONE':
      return const Color(0xFFE7F8EF);
    case 'DOING':
      return const Color(0xFFFFF1DA);
    case 'OVERDUE':
      return const Color(0xFFFFE8E8);
    default:
      return const Color(0xFFF1F2F5);
  }
}

Color statusText(String value) {
  switch (value) {
    case 'DONE':
      return AppColors.success;
    case 'DOING':
      return AppColors.warning;
    case 'OVERDUE':
      return AppColors.danger;
    default:
      return const Color(0xFF637083);
  }
}

IconData statusIcon(String value) {
  switch (value) {
    case 'DONE':
      return Icons.check_circle_rounded;
    case 'DOING':
      return Icons.timelapse_rounded;
    case 'OVERDUE':
      return Icons.warning_amber_rounded;
    default:
      return Icons.radio_button_unchecked_rounded;
  }
}
