import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  String filter = 'Weekly';

  @override
  Widget build(BuildContext context) {
    final done = demoTasks.where((e) => e.status == 'DONE').length;
    final pending = demoTasks.length - done;

    return Scaffold(
      appBar: AppBar(title: const Text('Chart')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _StatBox(title: 'Completed', value: '$done')),
              const SizedBox(width: 16),
              Expanded(child: _StatBox(title: 'Pending', value: '$pending')),
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
                          Text(e, style: TextStyle(fontWeight: filter == e ? FontWeight.w700 : FontWeight.w500)),
                          const SizedBox(height: 8),
                          Container(width: 52, height: 2, color: filter == e ? AppColors.primary : Colors.transparent),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: CustomPaint(
                    painter: PiePainter(),
                    child: const Center(child: Text('Performance', style: TextStyle(fontWeight: FontWeight.w700))),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Legend(color: Color(0xFFF04E3E), label: 'Done'),
                    _Legend(color: Color(0xFFF59E0B), label: 'Doing'),
                    _Legend(color: Color(0xFF3B82F6), label: 'To-do'),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
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
        Container(width: 18, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }
}

class PiePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width * 0.32);
    final paint1 = Paint()..color = const Color(0xFFF04E3E);
    final paint2 = Paint()..color = const Color(0xFFF59E0B);
    final paint3 = Paint()..color = const Color(0xFF3B82F6);
    canvas.drawArc(rect, -1.57, 2.4, true, paint1);
    canvas.drawArc(rect, 0.83, 1.5, true, paint2);
    canvas.drawArc(rect, 2.33, 2.38, true, paint3);
    canvas.drawCircle(size.center(Offset.zero), size.width * 0.16, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
