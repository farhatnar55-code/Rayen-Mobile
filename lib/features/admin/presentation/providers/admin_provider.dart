import 'package:flutter/material.dart';
import 'package:rayen_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_role.dart';
import 'package:rayen_mobile/features/category/domain/models/category_model.dart';
import 'package:rayen_mobile/features/category/domain/models/subcategory_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';

enum AdminLoadStatus { initial, loading, loaded, error }

enum AdminUserSortOption { newest, oldest, roleAsc, roleDesc, nameAsc, nameDesc }

class AdminProvider extends ChangeNotifier {
  final AdminRepository _repository;

  AdminProvider(this._repository);

  AdminLoadStatus _usersStatus = AdminLoadStatus.initial;
  AdminLoadStatus _coursesStatus = AdminLoadStatus.initial;
  AdminLoadStatus _categoriesStatus = AdminLoadStatus.initial;
  AdminLoadStatus _sessionsStatus = AdminLoadStatus.initial;
  AdminLoadStatus _statsStatus = AdminLoadStatus.initial;

  List<UserModel> _users = [];
  String _userSearchQuery = '';
  List<CourseModel> _courses = [];
  List<CategoryModel> _categories = [];
  List<SubcategoryModel> _subcategories = [];
  List<TrainingSessionModel> _sessions = [];
  Map<String, int> _stats = {};
  String? _errorMessage;
  UserRole? _selectedRoleFilter;
  AdminUserSortOption _userSortOption = AdminUserSortOption.newest;

  AdminLoadStatus get usersStatus => _usersStatus;
  AdminLoadStatus get coursesStatus => _coursesStatus;
  AdminLoadStatus get categoriesStatus => _categoriesStatus;
  AdminLoadStatus get sessionsStatus => _sessionsStatus;
  AdminLoadStatus get statsStatus => _statsStatus;
  List<UserModel> get users => _users;
  List<CourseModel> get courses => _courses;
  List<CategoryModel> get categories => _categories;
  List<SubcategoryModel> get subcategories => _subcategories;
  List<TrainingSessionModel> get sessions => _sessions;
  Map<String, int> get stats => _stats;
  String? get errorMessage => _errorMessage;
  UserRole? get selectedRoleFilter => _selectedRoleFilter;
  String get userSearchQuery => _userSearchQuery;
  AdminUserSortOption get userSortOption => _userSortOption;

  List<UserModel> get filteredUsers {
    final filtered = _users.where((u) {
      if (_selectedRoleFilter != null && u.role != _selectedRoleFilter) {
        return false;
      }
      if (_userSearchQuery.isNotEmpty) {
        final q = _userSearchQuery.toLowerCase();
        return u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.role.value.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    int roleOrder(UserRole role) {
      switch (role) {
        case UserRole.admin:
          return 0;
        case UserRole.organizer:
          return 1;
        case UserRole.instructor:
          return 2;
        case UserRole.trainer:
          return 3;
        case UserRole.student:
          return 4;
      }
    }

    switch (_userSortOption) {
      case AdminUserSortOption.newest:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case AdminUserSortOption.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case AdminUserSortOption.roleAsc:
        filtered.sort((a, b) {
          final byRole = roleOrder(a.role).compareTo(roleOrder(b.role));
          if (byRole != 0) return byRole;
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        });
        break;
      case AdminUserSortOption.roleDesc:
        filtered.sort((a, b) {
          final byRole = roleOrder(b.role).compareTo(roleOrder(a.role));
          if (byRole != 0) return byRole;
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        });
        break;
      case AdminUserSortOption.nameAsc:
        filtered.sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
        break;
      case AdminUserSortOption.nameDesc:
        filtered.sort(
          (a, b) => b.fullName.toLowerCase().compareTo(a.fullName.toLowerCase()),
        );
        break;
    }

    return filtered;
  }

  int get totalStudents =>
      _users.where((u) => u.role == UserRole.student).length;
  int get totalInstructors =>
      _users.where((u) => u.role == UserRole.instructor).length;
  int get totalOrganizers =>
      _users.where((u) => u.role == UserRole.organizer).length;
  int get totalTrainers =>
      _users.where((u) => u.role == UserRole.trainer).length;
  int get totalAdmins => _users.where((u) => u.role == UserRole.admin).length;
  int get activeUsers => _users.where((u) => u.isActive).length;
  int get subscribedUsers => _users.where((u) => u.isSubscribed).length;

  int get publishedCourses => _courses.where((c) => c.isPublished).length;
  int get freeCourses => _courses.where((c) => c.isFree).length;
  int get paidCourses => _courses.where((c) => !c.isFree).length;

  double get averageRating {
    if (_courses.isEmpty) return 0;
    final ratings = _courses.map((c) => c.rating).where((r) => r > 0);
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  int get totalStudentsEnrolled =>
      _courses.fold(0, (sum, c) => sum + c.studentsCount);

  Map<UserRole, int> get usersByRole => {
    UserRole.student: totalStudents,
    UserRole.instructor: totalInstructors,
    UserRole.organizer: totalOrganizers,
    UserRole.trainer: totalTrainers,
    UserRole.admin: totalAdmins,
  };

  Map<String, int> get coursesByCategory {
    final map = <String, int>{};
    for (final course in _courses) {
      final cat = course.categoryName ?? 'Autre';
      map[cat] = (map[cat] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> get publishedSessionsByDomain {
    final map = <String, int>{};
    for (final session in _sessions.where(
      (s) => s.status == SessionStatus.published,
    )) {
      map[session.domain] = (map[session.domain] ?? 0) + 1;
    }
    return map;
  }

  int get totalPublishedSessions =>
      _sessions.where((s) => s.status == SessionStatus.published).length;
  int get totalDraftSessions =>
      _sessions.where((s) => s.status == SessionStatus.draft).length;
  int get totalCompletedSessions =>
      _sessions.where((s) => s.status == SessionStatus.completed).length;
  int get totalCancelledSessions =>
      _sessions.where((s) => s.status == SessionStatus.cancelled).length;

  int get totalEnrolledParticipants =>
      _sessions.fold(0, (sum, s) => sum + s.enrolledCount);

  Future<void> loadUsers({UserRole? role}) async {
    _usersStatus = AdminLoadStatus.loading;
    notifyListeners();
    try {
      _users = await _repository.getUsers(role: role ?? _selectedRoleFilter);
      _usersStatus = AdminLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _usersStatus = AdminLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadCourses() async {
    _coursesStatus = AdminLoadStatus.loading;
    notifyListeners();
    try {
      _courses = await _repository.getAllCourses();
      _coursesStatus = AdminLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _coursesStatus = AdminLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categoriesStatus = AdminLoadStatus.loading;
    notifyListeners();
    try {
      _categories = await _repository.getCategories();
      _subcategories = await _repository.getSubcategories();
      _categoriesStatus = AdminLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _categoriesStatus = AdminLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadSessions() async {
    _sessionsStatus = AdminLoadStatus.loading;
    notifyListeners();
    try {
      _sessions = await _repository.getAllSessions();
      _sessionsStatus = AdminLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _sessionsStatus = AdminLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadStats() async {
    _statsStatus = AdminLoadStatus.loading;
    notifyListeners();
    try {
      _stats = await _repository.getStats();
      _statsStatus = AdminLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _statsStatus = AdminLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadAllData() async {
    await Future.wait([
      loadStats(),
      loadUsers(),
      loadCourses(),
      loadSessions(),
    ]);
  }

  Future<bool> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final user = await _repository.createUser(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
      _users.insert(0, user);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser({
    required String uid,
    required String fullName,
    required UserRole role,
    required bool isActive,
  }) async {
    try {
      await _repository.updateUser(
        uid: uid,
        fullName: fullName,
        role: role,
        isActive: isActive,
      );
      final index = _users.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        _users[index] = _users[index].copyWith(
          fullName: fullName,
          role: role,
          isActive: isActive,
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    await _repository.updateUserRole(uid, role);
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(role: role);
      notifyListeners();
    }
  }

  Future<void> toggleUserActive(String uid, bool isActive) async {
    await _repository.toggleUserActive(uid, isActive);
    final index = _users.indexWhere((u) => u.uid == uid);
    if (index != -1) {
      _users[index] = _users[index].copyWith(isActive: isActive);
      notifyListeners();
    }
  }

  Future<void> deleteUser(String uid) async {
    await _repository.deleteUser(uid);
    _users.removeWhere((u) => u.uid == uid);
    notifyListeners();
  }

  void setUserSearchQuery(String query) {
    _userSearchQuery = query;
    notifyListeners();
  }

  List<UserModel> _trainers = [];
  List<UserModel> get trainers => _trainers;

  Future<void> loadTrainers() async {
    try {
      _trainers = await _repository.getTrainers();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleCoursePublished(String courseId, bool isPublished) async {
    await _repository.toggleCoursePublished(courseId, isPublished);
    final index = _courses.indexWhere((c) => c.id == courseId);
    if (index != -1) {
      _courses[index] = _courses[index].copyWith(isPublished: isPublished);
      notifyListeners();
    }
  }

  Future<void> deleteCourse(String courseId) async {
    await _repository.deleteCourse(courseId);
    _courses.removeWhere((c) => c.id == courseId);
    notifyListeners();
  }

  void setRoleFilter(UserRole? role) {
    _selectedRoleFilter = role;
    notifyListeners();
  }

  void setUserSortOption(AdminUserSortOption option) {
    _userSortOption = option;
    notifyListeners();
  }
}
