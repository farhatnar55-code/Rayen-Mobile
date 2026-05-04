import 'package:rayen_mobile/features/course/data/datasources/course_remote_datasource.dart';
import 'package:rayen_mobile/features/course/domain/models/course_certificate_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_lesson_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_model.dart';
import 'package:rayen_mobile/features/course/domain/models/course_progress_model.dart';
import 'package:rayen_mobile/features/course/domain/models/enrollment_model.dart';
import 'package:rayen_mobile/features/course/domain/repositories/course_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/models/paginated_result.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource _dataSource;

  CourseRepositoryImpl(this._dataSource);

  @override
  Future<List<CourseModel>> getCourses({
    String? categoryId,
    String? subcategoryId,
    bool? isFree,
    int limit = 20,
  }) {
    return _dataSource.getCourses(
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      isFree: isFree,
      limit: limit,
    );
  }

  @override
  Future<PaginatedResult<CourseModel>> getCoursesPage({
    String? categoryId,
    String? subcategoryId,
    bool? isFree,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    return _dataSource.getCoursesPage(
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      isFree: isFree,
      limit: limit,
      startAfter: startAfter,
    );
  }

  @override
  Future<List<CourseModel>> searchCourses(String query) {
    return _dataSource.searchCourses(query);
  }

  @override
  Future<CourseModel?> getCourseById(String id) {
    return _dataSource.getCourseById(id);
  }

  @override
  Future<List<CourseLessonModel>> getLessons(String courseId) {
    return _dataSource.getLessons(courseId);
  }

  @override
  Future<CourseProgressModel?> getProgress(String userId, String courseId) {
    return _dataSource.getProgress(userId, courseId);
  }

  @override
  Future<CourseProgressModel> markLessonCompleted({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required int totalLessons,
  }) {
    return _dataSource.markLessonCompleted(
      userId: userId,
      userFullName: userFullName,
      courseId: courseId,
      courseTitle: courseTitle,
      lessonId: lessonId,
      totalLessons: totalLessons,
    );
  }

  @override
  Future<CourseCertificateModel?> getCertificate(
    String userId,
    String courseId,
  ) {
    return _dataSource.getCertificate(userId, courseId);
  }

  @override
  Future<CourseModel> createCourse(CourseModel course) {
    return _dataSource.createCourse(course);
  }

  @override
  Future<CourseModel> updateCourse(CourseModel course) {
    return _dataSource.updateCourse(course);
  }

  @override
  Future<void> deleteCourse(String courseId) {
    return _dataSource.deleteCourse(courseId);
  }

  @override
  Future<CourseLessonModel> addLesson(CourseLessonModel lesson) {
    return _dataSource.addLesson(lesson);
  }

  @override
  Future<void> updateLesson(CourseLessonModel lesson) {
    return _dataSource.updateLesson(lesson);
  }

  @override
  Future<void> deleteLesson(String courseId, String lessonId) {
    return _dataSource.deleteLesson(courseId, lessonId);
  }

  @override
  Future<EnrollmentModel?> getEnrollment(String userId, String courseId) {
    return _dataSource.getEnrollment(userId, courseId);
  }

  @override
  Future<EnrollmentModel> enrollFreeCourse({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
  }) {
    return _dataSource.enrollFreeCourse(
      userId: userId,
      userFullName: userFullName,
      courseId: courseId,
      courseTitle: courseTitle,
    );
  }

  @override
  Future<void> recordPaidEnrollment({
    required String userId,
    required String userFullName,
    required String courseId,
    required String courseTitle,
    required String transactionId,
  }) {
    return _dataSource.recordPaidEnrollment(
      userId: userId,
      userFullName: userFullName,
      courseId: courseId,
      courseTitle: courseTitle,
      transactionId: transactionId,
    );
  }
}
