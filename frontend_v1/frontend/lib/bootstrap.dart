import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/admin_remote_data_source.dart';
import 'data/datasources/auth_remote_data_source.dart';
import 'data/datasources/category_remote_data_source.dart';
import 'data/datasources/profile_remote_data_source.dart';
import 'data/datasources/reminder_remote_data_source.dart';
import 'data/datasources/statistics_remote_data_source.dart';
import 'data/datasources/task_remote_data_source.dart';
import 'data/local/app_preferences.dart';
import 'data/local/token_storage.dart';
import 'data/local/user_storage.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/repositories/statistics_repository.dart';
import 'data/repositories/task_repository.dart';
import 'features/admin/controller/admin_controller.dart';
import 'features/auth/controller/auth_controller.dart';
import 'features/calendar/controller/calendar_controller.dart';
import 'features/calendar/controller/reminder_controller.dart';
import 'features/home/controller/bottom_nav_controller.dart';
import 'features/profile/controller/profile_controller.dart';
import 'features/profile/controller/settings_controller.dart';
import 'features/task/controller/category_controller.dart';
import 'features/task/controller/statistics_controller.dart';
import 'features/task/controller/task_controller.dart';
import 'features/task/controller/task_form_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  final sharedPreferences = await SharedPreferences.getInstance();

  final appPreferences = AppPreferences(sharedPreferences);
  final userStorage = UserStorage(sharedPreferences);
  final tokenStorage = TokenStorage(sharedPreferences);
  final dio = DioClient.create(tokenStorage: tokenStorage);

  final authRemoteDataSource = AuthRemoteDataSource(dio: dio);
  final taskRemoteDataSource = TaskRemoteDataSource(dio: dio);
  final categoryRemoteDataSource = CategoryRemoteDataSource(dio: dio);
  final profileRemoteDataSource = ProfileRemoteDataSource(dio: dio);
  final reminderRemoteDataSource = ReminderRemoteDataSource(dio: dio);
  final statisticsRemoteDataSource = StatisticsRemoteDataSource(dio: dio);
  final adminRemoteDataSource = AdminRemoteDataSource(dio: dio);

  final authRepository = AuthRepository(
    remoteDataSource: authRemoteDataSource,
    tokenStorage: tokenStorage,
    userStorage: userStorage,
  );

  final taskRepository = TaskRepository(
    remoteDataSource: taskRemoteDataSource,
  );

  final categoryRepository = CategoryRepository(
    remoteDataSource: categoryRemoteDataSource,
  );

  final profileRepository = ProfileRepository(
    remoteDataSource: profileRemoteDataSource,
    userStorage: userStorage,
    tokenStorage: tokenStorage,
  );

  final reminderRepository = ReminderRepository(
    remoteDataSource: reminderRemoteDataSource,
  );

  final statisticsRepository = StatisticsRepository(
    remoteDataSource: statisticsRemoteDataSource,
  );

  final adminRepository = AdminRepository(
    remoteDataSource: adminRemoteDataSource,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: sharedPreferences),
        Provider<AppPreferences>.value(value: appPreferences),
        Provider<UserStorage>.value(value: userStorage),
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<Dio>.value(value: dio),
        Provider<AuthRemoteDataSource>.value(value: authRemoteDataSource),
        Provider<TaskRemoteDataSource>.value(value: taskRemoteDataSource),
        Provider<CategoryRemoteDataSource>.value(value: categoryRemoteDataSource),
        Provider<ProfileRemoteDataSource>.value(value: profileRemoteDataSource),
        Provider<ReminderRemoteDataSource>.value(value: reminderRemoteDataSource),
        Provider<StatisticsRemoteDataSource>.value(
          value: statisticsRemoteDataSource,
        ),
        Provider<AdminRemoteDataSource>.value(value: adminRemoteDataSource),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<TaskRepository>.value(value: taskRepository),
        Provider<CategoryRepository>.value(value: categoryRepository),
        Provider<ProfileRepository>.value(value: profileRepository),
        Provider<ReminderRepository>.value(value: reminderRepository),
        Provider<StatisticsRepository>.value(value: statisticsRepository),
        Provider<AdminRepository>.value(value: adminRepository),
        ChangeNotifierProvider(create: (_) => BottomNavController()),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            repository: authRepository,
            tokenStorage: tokenStorage,
            userStorage: userStorage,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskController(repository: taskRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskFormController(repository: taskRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryController(repository: categoryRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => StatisticsController(repository: statisticsRepository),
        ),
        ChangeNotifierProvider(create: (_) => CalendarController()),
        ChangeNotifierProvider(
          create: (_) => ReminderController(repository: reminderRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileController(repository: profileRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsController(appPreferences: appPreferences),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminController(repository: adminRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
