class ChartStats {
  const ChartStats({
    required this.range,
    required this.basis,
    required this.from,
    required this.to,
    required this.total,
    required this.todo,
    required this.doing,
    required this.done,
    required this.overdue,
    required this.incomplete,
    required this.completionRate,
  });

  final String range;
  final String basis;
  final DateTime from;
  final DateTime to;
  final int total;
  final int todo;
  final int doing;
  final int done;
  final int overdue;
  final int incomplete;
  final double completionRate;

  factory ChartStats.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '0') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '0') ?? 0;
    }

    return ChartStats(
      range: (json['range'] ?? 'WEEK').toString(),
      basis: (json['basis'] ?? 'DUE_DATE').toString(),
      from: parseDate(json['from']),
      to: parseDate(json['to']),
      total: parseInt(json['total']),
      todo: parseInt(json['todo']),
      doing: parseInt(json['doing']),
      done: parseInt(json['done']),
      overdue: parseInt(json['overdue']),
      incomplete: parseInt(json['incomplete']),
      completionRate: parseDouble(json['completionRate']),
    );
  }
}
