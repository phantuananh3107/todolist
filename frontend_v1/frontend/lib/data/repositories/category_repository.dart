import '../datasources/category_remote_data_source.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;

  CategoryRepository({
    required this.remoteDataSource,
  });

  Future<List<CategoryModel>> getCategories() async {
    return remoteDataSource.getCategories();
  }

  Future<void> createCategory(String name) async {
    await remoteDataSource.createCategory(name);
  }

  Future<void> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    await remoteDataSource.updateCategory(
      categoryId: categoryId,
      name: name,
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    await remoteDataSource.deleteCategory(categoryId);
  }
}