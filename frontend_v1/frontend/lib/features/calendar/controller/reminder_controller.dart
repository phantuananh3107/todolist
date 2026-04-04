import 'package:flutter/material.dart';

import '../../../data/models/reminder_model.dart';
import '../../../data/repositories/reminder_repository.dart';

class ReminderController extends ChangeNotifier {
  final ReminderRepository repository;

  ReminderController({
    required this.repository,
  });

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<ReminderModel> _reminders = const [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<ReminderModel> get reminders => _reminders;

  Future<void> fetchRemindersByTask(int taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reminders = await repository.getRemindersByTask(taskId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReminder({
    required int taskId,
    required DateTime remindTime,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.createReminder(
        taskId: taskId,
        remindTime: remindTime.toIso8601String(),
      );
      await fetchRemindersByTask(taskId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReminder({
    required int reminderId,
    required int taskId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.deleteReminder(reminderId);
      await fetchRemindersByTask(taskId);
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