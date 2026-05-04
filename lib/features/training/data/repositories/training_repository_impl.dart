import 'package:rayen_mobile/features/training/data/datasources/training_remote_datasource.dart';
import 'package:rayen_mobile/features/training/domain/models/session_enrollment_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';
import 'package:rayen_mobile/features/training/domain/repositories/training_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/models/paginated_result.dart';

class TrainingRepositoryImpl implements TrainingRepository {
  final TrainingRemoteDataSource _dataSource;

  TrainingRepositoryImpl(this._dataSource);

  @override
  Future<List<TrainingSessionModel>> getPublishedSessions() =>
      _dataSource.getPublishedSessions();

  @override
  Future<PaginatedResult<TrainingSessionModel>> getPublishedSessionsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) => _dataSource.getPublishedSessionsPage(limit: limit, startAfter: startAfter);

  @override
  Future<List<TrainingSessionModel>> getSessionsByOrganizer(String id) =>
      _dataSource.getSessionsByOrganizer(id);

  @override
  Future<List<TrainingSessionModel>> getSessionsByTrainer(String id) =>
      _dataSource.getSessionsByTrainer(id);

  @override
  Future<TrainingSessionModel> createSession(TrainingSessionModel session) =>
      _dataSource.createSession(session);

  @override
  Future<void> updateSession(TrainingSessionModel session) =>
      _dataSource.updateSession(session);

  @override
  Future<void> deleteSession(String sessionId) =>
      _dataSource.deleteSession(sessionId);

  @override
  Future<void> updateSessionStatus(String sessionId, SessionStatus status) =>
      _dataSource.updateSessionStatus(sessionId, status);

  @override
  Future<SessionEnrollmentModel> requestEnrollment(
          SessionEnrollmentModel enrollment) =>
      _dataSource.requestEnrollment(enrollment);

  @override
  Future<void> respondToEnrollment(
          String enrollmentId, EnrollmentRequestStatus status) =>
      _dataSource.respondToEnrollment(enrollmentId, status);

  @override
  Future<List<SessionEnrollmentModel>> getEnrollmentsBySession(
          String sessionId) =>
      _dataSource.getEnrollmentsBySession(sessionId);

  @override
  Future<List<SessionEnrollmentModel>> getEnrollmentsByUser(String userId) =>
      _dataSource.getEnrollmentsByUser(userId);

  @override
  Future<void> issueCertificate(String enrollmentId) =>
      _dataSource.issueCertificate(enrollmentId);
}
