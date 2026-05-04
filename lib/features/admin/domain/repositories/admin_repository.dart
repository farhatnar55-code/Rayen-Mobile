import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_role.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/category/domain/models/category_model.dart';
import 'package:rayen_mobile/features/category/domain/models/subcategory_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';

abstract class AdminRepository {
  Future<List<UserModel>> getUsers({UserRole? role});
  Future<void> updateUser({
    required String uid,
    required String fullName,
    required UserRole role,
    required bool isActive,
  });
  Future<void> updateUserRole(String uid, UserRole role);
  Future<void> toggleUserActive(String uid, bool isActive);
  Future<void> deleteUser(String uid);
  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });
  Future<void> toggleCoursePublished(String courseId, bool isPublished);
  Future<void> deleteCourse(String courseId);
  Future<List<CourseModel>> getAllCourses();
  Future<List<CategoryModel>> getCategories();
  Future<List<SubcategoryModel>> getSubcategories();
  Future<Map<String, int>> getStats();
  Future<List<UserModel>> getTrainers();
  Future<List<TrainingSessionModel>> getAllSessions();
}
