import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.background, required this.textColor});

  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

Color priorityBg(String value) {
  switch (value) {
    case 'HIGH':
      return const Color(0xFFFDE2E2);
    case 'LOW':
      return const Color(0xFFDBEAFE);
    default:
      return const Color(0xFFFFEDD5);
  }
}

Color priorityText(String value) {
  switch (value) {
    case 'HIGH':
      return AppColors.danger;
    case 'LOW':
      return AppColors.info;
    default:
      return const Color(0xFFD97706);
  }
}

Color statusBg(String value) {
  switch (value) {
    case 'DONE':
      return const Color(0xFFDCFCE7);
    case 'DOING':
      return const Color(0xFFFFEDD5);
    default:
      return const Color(0xFFF1F5F9);
  }
}

Color statusText(String value) {
  switch (value) {
    case 'DONE':
      return const Color(0xFF15803D);
    case 'DOING':
      return const Color(0xFFD97706);
    default:
      return const Color(0xFF475569);
  }
}
