import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/task_card.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = demoTasks;
    return Scaffold(
      appBar: AppBar(title: const Text('Calender')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('October 2026', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                GridView.builder(
                  itemCount: 30,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemBuilder: (_, index) {
                    final day = index + 1;
                    final active = day == DateTime.now().day;
                    return Container(
                      decoration: BoxDecoration(
                        color: active ? Theme.of(context).colorScheme.primary : const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(color: active ? Colors.white : Colors.black87, fontWeight: FontWeight.w700),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Tasks in selected day', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...tasks.take(2).map((task) => Padding(padding: const EdgeInsets.only(bottom: 16), child: TaskCard(task: task))),
        ],
      ),
    );
  }
}
