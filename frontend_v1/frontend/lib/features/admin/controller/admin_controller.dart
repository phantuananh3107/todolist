import 'package:flutter/material.dart';

import '../../../data/models/admin_statistics_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminController extends ChangeNotifier {
  final AdminRepository repository;

  AdminController({
    required this.repository,
  });

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<UserModel> _users = const [];
  UserModel? _selectedUser;
  AdminStatisticsModel _statistics = AdminStatisticsModel.empty();

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<UserModel> get users => _users;
  UserModel? get selectedUser => _selectedUser;
  AdminStatisticsModel get statistics => _statistics;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await repository.getUsers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStatistics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statistics = await repository.getStatistics();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserDetail(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedUser = await repository.getUserDetail(userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserStatus(int userId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = _selectedUser?.id == userId
          ? _selectedUser
          : _users.cast<UserModel?>().firstWhere(
                (user) => user?.id == userId,
                orElse: () => null,
              );

      await repository.toggleUserStatus(
        userId: userId,
        isActive: currentUser?.isActive ?? true,
      );
      await fetchUsers();
      if (_selectedUser?.id == userId) {
        await fetchUserDetail(userId);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
