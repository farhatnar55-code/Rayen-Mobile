import 'package:rayen_mobile/features/training/domain/models/session_enrollment_model.dart';
import 'package:rayen_mobile/features/training/domain/models/training_session_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/models/paginated_result.dart';

abstract class TrainingRepository {
  Future<List<TrainingSessionModel>> getPublishedSessions();
  Future<PaginatedResult<TrainingSessionModel>> getPublishedSessionsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  });
  Future<List<TrainingSessionModel>> getSessionsByOrganizer(String organizerId);
  Future<List<TrainingSessionModel>> getSessionsByTrainer(String trainerId);
  Future<TrainingSessionModel> createSession(TrainingSessionModel session);
  Future<void> updateSession(TrainingSessionModel session);
  Future<void> deleteSession(String sessionId);
  Future<void> updateSessionStatus(String sessionId, SessionStatus status);
  Future<SessionEnrollmentModel> requestEnrollment(SessionEnrollmentModel enrollment);
  Future<void> respondToEnrollment(String enrollmentId, EnrollmentRequestStatus status);
  Future<List<SessionEnrollmentModel>> getEnrollmentsBySession(String sessionId);
  Future<List<SessionEnrollmentModel>> getEnrollmentsByUser(String userId);
  Future<void> issueCertificate(String enrollmentId);
}
