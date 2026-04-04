class StatisticsModel {
  final int totalTasks;
  final int completedTasks;
  final int doingTasks;
  final int todoTasks;
  final int overdueTasks;
  final String filterType;

  const StatisticsModel({
    required this.totalTasks,
    required this.completedTasks,
    required this.doingTasks,
    required this.todoTasks,
    required this.overdueTasks,
    required this.filterType,
  });

  int get incompleteTasks => totalTasks - completedTasks;

  double get completedPercent {
    if (totalTasks == 0) return 0;
    return (completedTasks / totalTasks) * 100;
  }

  factory StatisticsModel.empty({String filterType = 'day'}) {
    return StatisticsModel(
      totalTasks: 0,
      completedTasks: 0,
      doingTasks: 0,
      todoTasks: 0,
      overdueTasks: 0,
      filterType: filterType,
    );
  }

  factory StatisticsModel.fromTasks({
    required int totalTasks,
    required int completedTasks,
    required int doingTasks,
    required int todoTasks,
    required int overdueTasks,
    required String filterType,
  }) {
    return StatisticsModel(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      doingTasks: doingTasks,
      todoTasks: todoTasks,
      overdueTasks: overdueTasks,
      filterType: filterType,
    );
  }
}