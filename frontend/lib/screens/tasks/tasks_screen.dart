import 'package:flutter/material.dart';

import '../../models/category_item.dart';
import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/task_card.dart';
import 'task_form_screen.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<TaskItem> tasks = [];
  List<CategoryItem> categories = [];
  String selectedCategory = 'All';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fetchedTasks = await ApiService.fetchTasks();
    final fetchedCategories = await ApiService.fetchCategories();
    if (!mounted) return;
    setState(() {
      tasks = fetchedTasks;
      categories = fetchedCategories;
      loading = false;
    });
  }

  List<TaskItem> get filteredTasks {
    if (selectedCategory == 'All') return tasks;
    return tasks.where((e) => e.category.toLowerCase() == selectedCategory.toLowerCase()).toList();
  }

  List<TaskItem> get upcomingTasks => filteredTasks.where((e) => !e.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  children: [
                    Text('Today', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: Text('Task Manager', style: Theme.of(context).textTheme.headlineMedium)),
                        const CircleAvatar(radius: 24, backgroundColor: Color(0xFFFAD7C3), child: Icon(Icons.person_outline)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search your tasks...',
                        suffixIcon: IconButton(onPressed: () {}, icon: const Icon(Icons.tune_rounded)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (_, i) {
                          final label = i == 0 ? 'All' : categories[i].name;
                          final selected = selectedCategory == label;
                          return GestureDetector(
                            onTap: () => setState(() => selectedCategory = label),
                            child: Column(
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                    color: selected ? AppColors.primary : AppColors.subText,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: selected ? 22 : 0,
                                  height: 2,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 24),
                        itemCount: categories.length,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: const [
                        _FilterPill(label: 'Date'),
                        _FilterPill(label: 'Priority'),
                        _FilterPill(label: 'Status'),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Text('All', style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECE8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${filteredTasks.length} Tasks', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ...filteredTasks.take(2).map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TaskCard(
                          task: task,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: task))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Upcoming', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 18),
                    ...upcomingTasks.skip(2).map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TaskCard(
                          task: task,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskFormScreen(existingTask: task))),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskFormScreen())),
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Task'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(label), const SizedBox(width: 6), const Icon(Icons.keyboard_arrow_down_rounded, size: 18)],
      ),
    );
  }
}
