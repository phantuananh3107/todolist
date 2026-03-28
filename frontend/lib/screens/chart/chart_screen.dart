import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/task_item.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  String filter = 'Weekly';
  List<TaskItem> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final fetched = await ApiService.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasks = fetched;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tasks = demoTasks;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không kết nối được backend — đang dùng dữ liệu demo'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // lọc task theo khoảng thời gian đang chọn
  List<TaskItem> get _filteredByPeriod {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case 'Daily':
        return _tasks.where((t) {
          final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          return d.isAtSameMomentAs(today);
        }).toList();

      case 'Weekly':
        // thứ 2 đầu tuần đến chủ nhật cuối tuần
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return _tasks.where((t) {
          final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
          return !d.isBefore(monday) && !d.isAfter(sunday);
        }).toList();

      case 'Monthly':
        return _tasks.where((t) =>
            t.dueDate.year == now.year && t.dueDate.month == now.month,
        ).toList();

      default:
        return _tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredByPeriod;
    final done = filtered.where((e) => e.status == 'DONE').length;
    final doing = filtered.where((e) => e.status == 'DOING').length;
    final todo = filtered.where((e) => e.status == 'TODO').length;
    final pending = doing + todo;

    return Scaffold(
      appBar: AppBar(title: const Text('Chart')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: _StatBox(
                              title: 'Completed', value: '$done')),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _StatBox(
                              title: 'Pending', value: '$pending')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['Daily', 'Weekly', 'Monthly']
                        .map((e) => InkWell(
                              onTap: () => setState(() => filter = e),
                              child: Column(
                                children: [
                                  Text(e,
                                      style: TextStyle(
                                          fontWeight: filter == e
                                              ? FontWeight.w700
                                              : FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 52,
                                    height: 2,
                                    color: filter == e
                                        ? AppColors.primary
                                        : Colors.transparent,
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: filtered.isEmpty
                              ? Center(
                                  child: Text(
                                    'Không có task trong khoảng $filter',
                                    style:
                                        const TextStyle(color: Colors.grey),
                                  ),
                                )
                              : CustomPaint(
                                  painter: PiePainter(
                                      done: done,
                                      doing: doing,
                                      todo: todo),
                                  child: const Center(
                                    child: Text('Performance',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _Legend(
                                color: const Color(0xFFF04E3E),
                                label: 'Done ($done)'),
                            _Legend(
                                color: const Color(0xFFF59E0B),
                                label: 'Doing ($doing)'),
                            _Legend(
                                color: const Color(0xFF3B82F6),
                                label: 'To-do ($todo)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 44, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(6))),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

// donut chart tính từ data thật
class PiePainter extends CustomPainter {
  PiePainter({required this.done, required this.doing, required this.todo});

  final int done;
  final int doing;
  final int todo;

  @override
  void paint(Canvas canvas, Size size) {
    final total = done + doing + todo;
    if (total == 0) return;

    final rect = Rect.fromCircle(
        center: size.center(Offset.zero), radius: size.width * 0.32);
    final twoPi = 2 * pi;

    final doneAngle = (done / total) * twoPi;
    final doingAngle = (doing / total) * twoPi;
    final todoAngle = (todo / total) * twoPi;

    double start = -pi / 2;

    canvas.drawArc(rect, start, doneAngle, true,
        Paint()..color = const Color(0xFFF04E3E));
    start += doneAngle;

    canvas.drawArc(rect, start, doingAngle, true,
        Paint()..color = const Color(0xFFF59E0B));
    start += doingAngle;

    canvas.drawArc(rect, start, todoAngle, true,
        Paint()..color = const Color(0xFF3B82F6));

    canvas.drawCircle(size.center(Offset.zero), size.width * 0.16,
        Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant PiePainter old) =>
      old.done != done || old.doing != doing || old.todo != todo;
}
