import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/features/course/domain/models/course_certificate_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_lesson_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_progress_model.dart';
import 'package:rayen_mobile/features/course/domain/models/enrollment_model.dart';
import 'package:rayen_mobile/features/course/domain/repositories/course_repository.dart';

enum CourseLoadStatus { initial, loading, loaded, error }

enum CourseDetailStatus { initial, loading, loaded, error }

enum CourseSortOption {
  dateNewest,
  dateOldest,
  priceLowToHigh,
  priceHighToLow,
  nameAZ,
  nameZA,
}

class CourseProvider extends ChangeNotifier {
  final CourseRepository _repository;

  CourseProvider(this._repository);

  CourseLoadStatus _status = CourseLoadStatus.initial;
  List<CourseModel> _courses = [];
  List<CourseModel> _searchResults = [];
  List<CourseLessonModel> _lessons = [];
  CourseProgressModel? _progress;
  CourseCertificateModel? _certificate;
  EnrollmentModel? _enrollment;
  String? _errorMessage;
  String? _detailErrorMessage;
  String? _selectedCategoryId;
  bool _isSearching = false;
  CourseDetailStatus _detailStatus = CourseDetailStatus.initial;
  CourseSortOption _sortOption = CourseSortOption.dateNewest;
  DocumentSnapshot<Map<String, dynamic>>? _lastCourseDocument;
  bool _hasMoreCourses = true;
  bool _isLoadingMoreCourses = false;
  static const int _pageSize = 20;

  CourseLoadStatus get status => _status;
  List<CourseModel> get courses => _courses;
  List<CourseModel> get searchResults => _searchResults;
  List<CourseLessonModel> get lessons => _lessons;
  CourseProgressModel? get progress => _progress;
  CourseCertificateModel? get certificate => _certificate;
  EnrollmentModel? get enrollment => _enrollment;
  bool get isEnrolled => _enrollment != null;
  String? get errorMessage => _errorMessage;
  String? get detailErrorMessage => _detailErrorMessage;
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isSearching => _isSearching;
  CourseDetailStatus get detailStatus => _detailStatus;
  CourseSortOption get sortOption => _sortOption;
  bool get hasMoreCourses => _hasMoreCourses;
  bool get isLoadingMoreCourses => _isLoadingMoreCourses;

  List<CourseModel> get displayedCourses {
    List<CourseModel> source = _isSearching ? _searchResults : _courses;
    return _sortCourses(source);
  }

  List<CourseModel> _sortCourses(List<CourseModel> courses) {
    final sorted = List<CourseModel>.from(courses);
    switch (_sortOption) {
      case CourseSortOption.dateNewest:
        sorted.sort((a, b) {
          final dateA = a.datePublished ?? DateTime(2000);
          final dateB = b.datePublished ?? DateTime(2000);
          return dateB.compareTo(dateA);
        });
        break;
      case CourseSortOption.dateOldest:
        sorted.sort((a, b) {
          final dateA = a.datePublished ?? DateTime(2000);
          final dateB = b.datePublished ?? DateTime(2000);
          return dateA.compareTo(dateB);
        });
        break;
      case CourseSortOption.priceLowToHigh:
        sorted.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CourseSortOption.priceHighToLow:
        sorted.sort((a, b) => b.price.compareTo(a.price));
        break;
      case CourseSortOption.nameAZ:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case CourseSortOption.nameZA:
        sorted.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
    }
    return sorted;
  }

  void setSortOption(CourseSortOption option) {
    if (_sortOption != option) {
      _sortOption = option;
      notifyListeners();
    }
  }

  Future<void> loadCourses({String? categoryId}) async {
    _status = CourseLoadStatus.loading;
    _selectedCategoryId = categoryId;
    _isSearching = false;
    _courses = [];
    _lastCourseDocument = null;
    _hasMoreCourses = true;
    notifyListeners();

    try {
      await _fetchNextCoursesPage(reset: true);
      _status = CourseLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = CourseLoadStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMoreCourses() async {
    if (_isSearching || !_hasMoreCourses || _isLoadingMoreCourses) return;
    await _fetchNextCoursesPage();
    notifyListeners();
  }

  Future<void> _fetchNextCoursesPage({bool reset = false}) async {
    if (_isLoadingMoreCourses) return;
    _isLoadingMoreCourses = true;
    try {
      final result = await _repository.getCoursesPage(
        categoryId: _selectedCategoryId,
        limit: _pageSize,
        startAfter: reset ? null : _lastCourseDocument,
      );
      if (reset) {
        _courses = result.items;
      } else {
        _courses = [..._courses, ...result.items];
      }
      _lastCourseDocument = result.lastDocument;
      _hasMoreCourses = result.items.length == _pageSize;
    } finally {
      _isLoadingMoreCourses = false;
    }
  }

  Future<void> loadCourseDetails({
    required String userId,
    required String courseId,
  }) async {
    _detailStatus = CourseDetailStatus.loading;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      _lessons = await _repository.getLessons(courseId);
      _progress = await _repository.getProgress(userId, courseId);
      _certificate = await _repository.getCertificate(userId, courseId);
      _enrollment = await _repository.getEnrollment(userId, courseId);
      _detailStatus = CourseDetailStatus.loaded;
      notifyListeners();
    } catch (e) {
      _detailErrorMessage = e.toString();
      _detailStatus = CourseDetailStatus.error;
      notifyListeners();
    }
  }

  Future<void> completeLesson({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required int totalLessons,
  }) async {
    final updated = await _repository.markLessonCompleted(
      userId: userId,
      userFullName: userFullName,
      courseId: courseId,
      courseTitle: courseTitle,
      lessonId: lessonId,
      totalLessons: totalLessons,
    );
    _progress = updated;
    _certificate = await _repository.getCertificate(userId, courseId);
    notifyListeners();
  }

  Future<CourseModel?> createCourse(CourseModel course) async {
    try {
      final created = await _repository.createCourse(course);
      _courses = [created, ..._courses];
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<CourseModel?> updateCourse(CourseModel course) async {
    try {
      final updated = await _repository.updateCourse(course);
      final index = _courses.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _courses[index] = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    await _repository.deleteCourse(courseId);
    _courses.removeWhere((c) => c.id == courseId);
    notifyListeners();
  }

  Future<CourseLessonModel?> addLesson(CourseLessonModel lesson) async {
    try {
      final created = await _repository.addLesson(lesson);
      if (_lessons.isEmpty) {
        _lessons = [created];
      } else {
        _lessons = [..._lessons, created]
          ..sort((a, b) => a.order.compareTo(b.order));
      }
      notifyListeners();
      return created;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> updateLesson(CourseLessonModel lesson) async {
    try {
      await _repository.updateLesson(lesson);
      final index = _lessons.indexWhere((l) => l.id == lesson.id);
      if (index != -1) {
        _lessons[index] = lesson;
        _lessons = [..._lessons]..sort((a, b) => a.order.compareTo(b.order));
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteLesson(String courseId, String lessonId) async {
    try {
      await _repository.deleteLesson(courseId, lessonId);
      _lessons.removeWhere((l) => l.id == lessonId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadLessons(String courseId) async {
    try {
      _lessons = await _repository.getLessons(courseId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _status = CourseLoadStatus.loading;
    notifyListeners();

    try {
      _searchResults = await _repository.searchCourses(query);
      _status = CourseLoadStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = CourseLoadStatus.error;
    }
    notifyListeners();
  }

  void clearSearch() {
    _isSearching = false;
    _searchResults = [];
    notifyListeners();
  }

  void selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    loadCourses(categoryId: categoryId);
  }

  Future<bool> enrollInFreeCourse({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
  }) async {
    try {
      _enrollment = await _repository.enrollFreeCourse(
        userId: userId,
        userFullName: userFullName,
        courseId: courseId,
        courseTitle: courseTitle,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> recordPaidEnrollment({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
    required String transactionId,
  }) async {
    try {
      await _repository.recordPaidEnrollment(
        userId: userId,
        userFullName: userFullName,
        courseId: courseId,
        courseTitle: courseTitle,
        transactionId: transactionId,
      );
      _enrollment = await _repository.getEnrollment(userId, courseId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
