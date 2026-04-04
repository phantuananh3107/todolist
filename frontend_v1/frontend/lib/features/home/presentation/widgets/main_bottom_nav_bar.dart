import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.checklist_rounded, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.checklist_rounded, color: AppColors.primary),
          label: 'Task',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_rounded, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_rounded, color: AppColors.textSecondary),
          selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
          label: 'Profile',
        ),
      ],
    );
  }
}
