import '../datasources/admin_remote_data_source.dart';
import '../models/admin_statistics_model.dart';
import '../models/user_model.dart';

class AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepository({
    required this.remoteDataSource,
  });

  Future<List<UserModel>> getUsers() async {
    return remoteDataSource.getUsers();
  }

  Future<UserModel> getUserDetail(int userId) async {
    return remoteDataSource.getUserDetail(userId);
  }

  Future<void> toggleUserStatus(int userId) async {
    await remoteDataSource.toggleUserStatus(userId);
  }

  Future<AdminStatisticsModel> getStatistics() async {
    return remoteDataSource.getStatistics();
  }
}