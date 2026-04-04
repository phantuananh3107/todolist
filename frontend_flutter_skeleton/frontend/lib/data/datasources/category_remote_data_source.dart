import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/category_model.dart';

class CategoryRemoteDataSource {
  final Dio dio;

  CategoryRemoteDataSource({
    required this.dio,
  });

  Future<List<CategoryModel>> getCategories() async {
    final response = await dio.get(ApiConstants.categories);
    final data = response.data;

    if (data is List) {
      return data
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<void> createCategory(String name) async {
    await dio.post(
      ApiConstants.categories,
      data: {
        'name': name,
      },
    );
  }

  Future<void> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    await dio.put(
      ApiConstants.categoryDetail(categoryId),
      data: {
        'name': name,
      },
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    await dio.delete(ApiConstants.categoryDetail(categoryId));
  }
}