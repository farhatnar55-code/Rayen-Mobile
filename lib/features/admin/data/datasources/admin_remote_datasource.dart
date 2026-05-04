import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_role.dart';
import 'package:rayen_mobile/features/category/domain/models/category_model.dart';
import 'package:rayen_mobile/features/category/domain/models/subcategory_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';

class AdminRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUser({
    required String uid,
    required String fullName,
    required UserRole role,
    required bool isActive,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'fullName': fullName,
      'role': role.value,
      'isActive': isActive,
    });
  }

  Future<List<UserModel>> getUsers({UserRole? role}) async {
    Query query = _firestore.collection('users');
    if (role != null) {
      query = query.where('role', isEqualTo: role.value);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    await _firestore.collection('users').doc(uid).update({'role': role.value});
  }

  Future<void> toggleUserActive(String uid, bool isActive) async {
    await _firestore.collection('users').doc(uid).update({
      'isActive': isActive,
    });
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isDeleted': true,
      'isActive': false,
    });
  }

  Future<UserModel> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final result = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: result.user!.uid,
        email: email,
        fullName: fullName,
        role: role,
        isActive: true,
        profileCompleted: true,
        createdAt: DateTime.now(),
        fieldOfStudiesId: null,
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      return user;
    } finally {
      await secondaryApp?.delete();
    }
  }

  Future<List<CourseModel>> getAllCourses() async {
    final snapshot = await _firestore.collection('courses').get();
    return snapshot.docs
        .map((doc) => CourseModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<UserModel>> getTrainers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'trainer')
        .get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<void> toggleCoursePublished(String courseId, bool isPublished) async {
    await _firestore.collection('courses').doc(courseId).update({
      'isPublished': isPublished,
    });
  }

  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection('courses').doc(courseId).delete();
  }

  Future<List<CategoryModel>> getCategories() async {
    final snapshot = await _firestore
        .collection('categories')
        .orderBy('order')
        .get();
    return snapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<SubcategoryModel>> getSubcategories() async {
    final snapshot = await _firestore.collection('subcategories').get();
    return snapshot.docs
        .map((doc) => SubcategoryModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<TrainingSessionModel>> getAllSessions() async {
    final snapshot = await _firestore.collection('training_sessions').get();
    return snapshot.docs
        .map((doc) => TrainingSessionModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Map<String, int>> getStats() async {
    final results = await Future.wait([
      _firestore.collection('users').count().get(),
      _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .count()
          .get(),
      _firestore
          .collection('users')
          .where('role', isEqualTo: 'instructor')
          .count()
          .get(),
      _firestore.collection('courses').count().get(),
      _firestore
          .collection('courses')
          .where('is_free', isEqualTo: true)
          .count()
          .get(),
      _firestore.collection('enrollments').count().get(),
    ]);

    return {
      'totalUsers': results[0].count ?? 0,
      'totalStudents': results[1].count ?? 0,
      'totalInstructors': results[2].count ?? 0,
      'totalCourses': results[3].count ?? 0,
      'freeCourses': results[4].count ?? 0,
      'totalEnrollments': results[5].count ?? 0,
    };
  }
}
