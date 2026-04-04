class AdminStatisticsModel {
  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int totalTasks;

  const AdminStatisticsModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.totalTasks,
  });

  factory AdminStatisticsModel.fromJson(Map<String, dynamic> json) {
    return AdminStatisticsModel(
      totalUsers: json['totalUsers'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      inactiveUsers: json['inactiveUsers'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
    );
  }

  factory AdminStatisticsModel.empty() {
    return const AdminStatisticsModel(
      totalUsers: 0,
      activeUsers: 0,
      inactiveUsers: 0,
      totalTasks: 0,
    );
  }
}