import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFF45B48);
  static const Color secondary = Color(0xFFFF8A65);
  static const Color accent = Color(0xFFFFC4B8);

  static const Color background = Color(0xFFF8F8F8);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFF0E3DE);
  static const Color divider = Color(0xFFF2ECE8);

  static const Color textPrimary = Color(0xFF241B18);
  static const Color textSecondary = Color(0xFF8B7E7A);

  static const Color success = Color(0xFF61C454);
  static const Color warning = Color(0xFFFFB020);
  static const Color danger = Color(0xFFFF5D5D);
  static const Color info = Color(0xFF4F7CFF);

  static const Color todo = Color(0xFF9AA5B1);
  static const Color doing = Color(0xFFFFB020);
  static const Color done = Color(0xFF61C454);
  static const Color overdue = Color(0xFFFF5D5D);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF45B48), Color(0xFFFF7A59)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
