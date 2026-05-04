import 'package:rayen_mobile/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:rayen_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_role.dart';
import 'package:rayen_mobile/features/category/domain/models/category_model.dart';
import 'package:rayen_mobile/features/category/domain/models/subcategory_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource _dataSource;

  AdminRepositoryImpl(this._dataSource);

  @override
  Future<List<UserModel>> getUsers({UserRole? role}) =>
      _dataSource.getUsers(role: role);

    @override
    Future<void> updateUser({
        required String uid,
        required String fullName,
        required UserRole role,
        required bool isActive,
    }) => _dataSource.updateUser(
        uid: uid,
        fullName: fullName,
        role: role,
        isActive: isActive,
    );

  @override
  Future<void> updateUserRole(String uid, UserRole role) =>
      _dataSource.updateUserRole(uid, role);

  @override
  Future<void> toggleUserActive(String uid, bool isActive) =>
      _dataSource.toggleUserActive(uid, isActive);

  @override
  Future<void> deleteUser(String uid) => _dataSource.deleteUser(uid);

  @override
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) => _dataSource.createUser(
    email: email,
    password: password,
    fullName: fullName,
    role: role,
  );

  @override
  Future<List<CourseModel>> getAllCourses() => _dataSource.getAllCourses();

  @override
  Future<void> toggleCoursePublished(String courseId, bool isPublished) =>
      _dataSource.toggleCoursePublished(courseId, isPublished);

  @override
  Future<void> deleteCourse(String courseId) =>
      _dataSource.deleteCourse(courseId);

  @override
  Future<List<CategoryModel>> getCategories() => _dataSource.getCategories();

  @override
  Future<List<SubcategoryModel>> getSubcategories() =>
      _dataSource.getSubcategories();

  @override
  Future<Map<String, int>> getStats() => _dataSource.getStats();

  @override
  Future<List<UserModel>> getTrainers() => _dataSource.getTrainers();

  @override
  Future<List<TrainingSessionModel>> getAllSessions() =>
      _dataSource.getAllSessions();
}
