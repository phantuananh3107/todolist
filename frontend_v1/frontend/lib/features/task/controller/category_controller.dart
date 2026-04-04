import 'package:flutter/material.dart';

import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

class CategoryController extends ChangeNotifier {
  final CategoryRepository repository;

  CategoryController({
    required this.repository,
  });

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<CategoryModel> _categories = const [];

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<CategoryModel> get categories => _categories;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await repository.getCategories();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(String name) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.createCategory(name);
      await fetchCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.updateCategory(
        categoryId: categoryId,
        name: name,
      );
      await fetchCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(int categoryId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.deleteCategory(categoryId);
      await fetchCategories();
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