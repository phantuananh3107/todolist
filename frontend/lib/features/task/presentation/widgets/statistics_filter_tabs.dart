import 'package:flutter/material.dart';

class StatisticsFilterTabs extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const StatisticsFilterTabs({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = const ['day', 'week', 'month'];

    return Row(
      children: items.map((item) {
        final isSelected = item == value;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                item[0].toUpperCase() + item.substring(1),
              ),
              selected: isSelected,
              onSelected: (_) => onChanged(item),
            ),
          ),
        );
      }).toList(),
    );
  }
}