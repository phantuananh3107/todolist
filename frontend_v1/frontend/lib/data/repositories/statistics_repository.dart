import '../datasources/statistics_remote_data_source.dart';
import '../models/statistics_model.dart';

class StatisticsRepository {
  final StatisticsRemoteDataSource remoteDataSource;

  StatisticsRepository({
    required this.remoteDataSource,
  });

  Future<StatisticsModel> getStatistics({
    required String filterType,
  }) async {
    return remoteDataSource.getStatistics(filterType: filterType);
  }
}