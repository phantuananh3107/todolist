import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/chart_stats.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_refresh_bus.dart';
import '../../utils/auth_navigation.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/section_card.dart';
import '../notifications/notifications_screen.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  bool _loading = true;
  String _range = 'WEEK';
  ChartStats? _stats;

  @override
  void initState() {
    super.initState();
    AppRefreshBus.tasks.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppRefreshBus.tasks.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await ApiService.fetchTaskStats(range: _range, basis: 'DUE_DATE');
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (ApiService.isUnauthorized(e)) {
        if (!mounted) return;
        setState(() => _loading = false);
        await handleUnauthorized(context);
        return;
      }
      if (!mounted) return;
      setState(() {
        _stats = null;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được thống kê.')),
      );
    }
  }

  int get _total => _stats?.total ?? 0;
  int get _done => _stats?.done ?? 0;
  int get _doing => _stats?.doing ?? 0;
  int get _todo => _stats?.todo ?? 0;
  int get _overdue => _stats?.overdue ?? 0;
  double get _completionRate => _stats == null ? 0 : (_stats!.completionRate / 100).clamp(0, 1);

  List<_LegendData> get _segments => [
        _LegendData('To-do', _todo, const Color(0xFF98A2B3)),
        _LegendData('Doing', _doing, const Color(0xFFF59E0B)),
        _LegendData('Done', _done, AppColors.success),
        _LegendData('Overdue', _overdue, AppColors.danger),
      ];

  String get _rangeLabel {
    switch (_range) {
      case 'DAY':
        return 'hôm nay';
      case 'MONTH':
        return 'tháng này';
      default:
        return 'tuần này';
    }
  }

  Future<void> _changeRange(String range) async {
    if (_range == range) return;
    setState(() => _range = range);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            ScreenHeader(
              subtitle: 'Theo dõi hiệu suất theo ngày, tuần, tháng',
              title: 'Biểu đồ công việc',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconCircleButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                  const SizedBox(width: 10),
                  _IconCircleButton(icon: Icons.refresh_rounded, onTap: _load),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionCard(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFBFA), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phân bố trạng thái', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Thống kê theo hạn công việc trong $_rangeLabel.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: _DonutChart(
                            segments: _segments,
                            total: _total,
                            centerTop: _total.toString(),
                            centerBottom: _total == 1 ? 'task' : 'tasks',
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ..._segments.map(
                              (segment) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _LegendTile(data: segment, total: _total),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _total == 0
                                  ? 'Chưa có task trong khoảng thời gian này.'
                                  : 'Hoàn thành ${(_stats?.completionRate ?? 0).toStringAsFixed(0)}% công việc trong giai đoạn được chọn.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _RangeChip(label: 'Today', selected: _range == 'DAY', onTap: () => _changeRange('DAY')),
                  const SizedBox(width: 8),
                  _RangeChip(label: 'Weekly', selected: _range == 'WEEK', onTap: () => _changeRange('WEEK')),
                  const SizedBox(width: 8),
                  _RangeChip(label: 'Monthly', selected: _range == 'MONTH', onTap: () => _changeRange('MONTH')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_stats == null || _total == 0)
              const EmptyStateCard(
                icon: Icons.pie_chart_rounded,
                title: 'Chưa có dữ liệu biểu đồ',
                message: 'Khi có task, màn hình này sẽ hiển thị biểu đồ tròn và số lượng công việc theo từng trạng thái.',
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _SummaryMetricCard(
                      label: 'Tỷ lệ hoàn thành',
                      value: '${(_completionRate * 100).toStringAsFixed(0)}%',
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryMetricCard(
                      label: 'Task mở',
                      value: '${_todo + _doing + _overdue}',
                      icon: Icons.timelapse_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chi tiết trạng thái', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Mỗi trạng thái đều hiển thị số lượng và tỷ trọng trong giai đoạn đang chọn.', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 18),
                    ..._segments.map(
                      (segment) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DetailRow(data: segment, total: _total),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFFFF7F5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          boxShadow: selected ? AppColors.softShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.text,
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({
    required this.segments,
    required this.total,
    required this.centerTop,
    required this.centerBottom,
  });

  final List<_LegendData> segments;
  final int total;
  final String centerTop;
  final String centerBottom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(190),
            painter: _DonutPainter(
              segments: segments,
              total: total,
            ),
          ),
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerTop, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(centerBottom, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments, required this.total});

  final List<_LegendData> segments;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 24.0;
    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final backgroundPaint = Paint()
      ..color = AppColors.primarySoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    if (total <= 0) return;

    final gap = 0.045;
    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweep = ((segment.value / total) * math.pi * 2) - gap;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, math.max(sweep, 0.04), false, paint);
      startAngle += (segment.value / total) * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.segments != segments;
  }
}

class _LegendTile extends StatelessWidget {
  const _LegendTile({required this.data, required this.total});

  final _LegendData data;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (data.value / total * 100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.label, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text('${percent.toStringAsFixed(0)}% tổng số task', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text('${data.value}', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  const _SummaryMetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.data, required this.total});

  final _LegendData data;
  final int total;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : (data.value / total);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: data.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(data.label, style: Theme.of(context).textTheme.titleMedium)),
              Text('${data.value}', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.primarySoft,
              valueColor: AlwaysStoppedAnimation<Color>(data.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendData {
  const _LegendData(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.text),
        ),
      ),
    );
  }
}
