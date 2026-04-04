import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_empty_state.dart';
import '../controller/task_controller.dart';
import 'widgets/task_card.dart';

class SearchTaskScreen extends StatefulWidget {
  const SearchTaskScreen({super.key});

  @override
  State<SearchTaskScreen> createState() => _SearchTaskScreenState();
}

class _SearchTaskScreenState extends State<SearchTaskScreen> {
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskController = context.watch<TaskController>();
    final tasks = taskController.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Task'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: searchController,
              onChanged: taskController.updateSearchKeyword,
              decoration: InputDecoration(
                hintText: 'Search by title or description',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          taskController.clearSearch();
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Expanded(
            child: tasks.isEmpty
                ? const AppEmptyState(
                    icon: Icons.search_off,
                    title: 'Không tìm thấy công việc phù hợp',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => TaskCard(task: tasks[index]),
                  ),
          ),
        ],
      ),
    );
  }
}