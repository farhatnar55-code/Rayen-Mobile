import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/core/algorithms/cosine_similarity.dart';
import 'package:rayen_mobile/features/recommendation/data/models/course_vector_model.dart';
import 'package:rayen_mobile/features/recommendation/data/models/recommendation_item_model.dart';
import 'package:rayen_mobile/features/recommendation/domain/entities/recommendation_item.dart';
import 'package:rayen_mobile/features/recommendation/domain/repositories/recommendation_repository.dart';

class RecommendationRepositoryImpl implements RecommendationRepository {
  final FirebaseFirestore _db;

  // ignore: unused_field
  static const double _contentWeight = 0.50;
  // ignore: unused_field
  static const double _popularityWeight = 0.20;
  // ignore: unused_field
  static const double _recencyWeight = 0.15;
  // ignore: unused_field
  static const double _diversityWeight = 0.15;
  static const int _maxPerCategory = 2;

  RecommendationRepositoryImpl(this._db);

  @override
  Future<List<RecommendationItem>> getRecommendations({
    required String userId,
    required String fieldOfStudies,
    int topN = 10,
  }) async {
    final enrolledSessionIds = await _fetchEnrolledSessionIds(userId);
    final enrolledData = await _fetchEnrolledDataWithTimeDecay(userId);

    List<double> centroid;
    if (enrolledData.isNotEmpty) {
      centroid = _computeWeightedCentroid(enrolledData);
    } else {
      centroid = await _coldStartVector(fieldOfStudies);
    }

    if (centroid.isEmpty) {
      return _coldStartRecommendations(fieldOfStudies, topN);
    }

    final candidates = await _getAllCandidates(enrolledSessionIds);

    final scoredCourses = _scoreAndFilterItems(
      items: candidates['courses']!,
      centroid: centroid,
      type: RecommendationItemType.course,
    );

    final scoredSessions = _scoreAndFilterItems(
      items: candidates['sessions']!,
      centroid: centroid,
      type: RecommendationItemType.session,
    );

    final diverseCourses = _applyDiversityFilter(scoredCourses);
    final diverseSessions = _applyDiversityFilter(scoredSessions);

    final combined = [
      ...diverseCourses.take(topN ~/ 2),
      ...diverseSessions.take(topN ~/ 2),
    ];

    combined.sort(
      (a, b) => (b as RecommendationItemModel).hybridScore.compareTo(
        (a as RecommendationItemModel).hybridScore,
      ),
    );

    return combined.take(topN).toList();
  }

  Future<Set<String>> _fetchEnrolledSessionIds(String userId) async {
    final snap = await _db
        .collection('session_enrollments')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .get();
    return snap.docs.map((d) => d.data()['sessionId'] as String).toSet();
  }

  Future<List<EnrolledItemData>> _fetchEnrolledDataWithTimeDecay(
    String userId,
  ) async {
    final snap = await _db
        .collection('session_enrollments')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'approved')
        .get();

    final items = <EnrolledItemData>[];
    final now = DateTime.now();

    for (final doc in snap.docs) {
      final data = doc.data();
      final sessionId = data['sessionId'] as String;
      final enrolledAt =
          (data['enrolledAt'] ?? data['enrolled_at']) as Timestamp?;

      double weight = 1.0;
      if (enrolledAt != null) {
        final daysSinceEnrollment = now.difference(enrolledAt.toDate()).inDays;
        weight = _calculateTimeDecay(daysSinceEnrollment);
      }

      final vectorSnap = await _db
          .collection('course_vectors')
          .doc(sessionId)
          .get();

      if (vectorSnap.exists) {
        final vectorData = vectorSnap.data();
        if (vectorData != null) {
          final model = CourseVectorModel.fromMap(vectorData, sessionId);
          items.add(
            EnrolledItemData(
              vector: model.vector,
              weight: weight,
              metadata: model.metadata,
            ),
          );
        }
      }
    }

    return items;
  }

  double _calculateTimeDecay(int days) {
    if (days <= 7) return 1.0;
    if (days <= 30) return 0.9;
    if (days <= 90) return 0.7;
    if (days <= 180) return 0.5;
    if (days <= 365) return 0.3;
    return 0.1;
  }

  List<double> _computeWeightedCentroid(List<EnrolledItemData> enrolledData) {
    if (enrolledData.isEmpty) return [];

    final dims = enrolledData.first.vector.length;
    final weightedSum = List<double>.filled(dims, 0.0);
    double totalWeight = 0.0;

    for (final item in enrolledData) {
      for (var i = 0; i < dims; i++) {
        weightedSum[i] += item.vector[i] * item.weight;
      }
      totalWeight += item.weight;
    }

    if (totalWeight == 0) return [];

    final centroid = weightedSum.map((v) => v / totalWeight).toList();
    final magnitude = _vectorMagnitude(centroid);
    if (magnitude > 0) {
      return centroid.map((v) => v / magnitude).toList();
    }

    return centroid;
  }

  double _vectorMagnitude(List<double> vec) {
    double sum = 0;
    for (final v in vec) {
      sum += v * v;
    }
    return sum > 0 ? _sqrt(sum) : 0;
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  Future<List<double>> _coldStartVector(String fieldOfStudies) async {
    try {
      final snap = await _db.collection('course_vectors').limit(20).get();

      if (snap.docs.isEmpty) return [];

      final vectors = snap.docs
          .map((d) => CourseVectorModel.fromMap(d.data(), d.id).vector)
          .toList();

      final avgVector = List<double>.filled(vectors.first.length, 0.0);
      for (final v in vectors) {
        for (var i = 0; i < avgVector.length; i++) {
          avgVector[i] += v[i];
        }
      }
      for (var i = 0; i < avgVector.length; i++) {
        avgVector[i] /= vectors.length;
      }

      return avgVector;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, List<_CandidateItem>>> _getAllCandidates(
    Set<String> excludeIds,
  ) async {
    final courseVectors = await _db.collection('course_vectors').get();
    final courses = await _db.collection('courses').get();
    final sessionVectors = await _db.collection('session_vectors').get();
    final sessions = await _db
        .collection('training_sessions')
        .where('status', isEqualTo: 'published')
        .get();

    final courseMap = {for (final d in courses.docs) d.id: d.data()};
    final sessionMap = {for (final d in sessions.docs) d.id: d.data()};

    final courseCandidates = <_CandidateItem>[];
    for (final vDoc in courseVectors.docs) {
      if (excludeIds.contains(vDoc.id)) continue;
      final courseData = courseMap[vDoc.id];
      if (courseData == null) continue;

      final model = CourseVectorModel.fromMap(vDoc.data(), vDoc.id);
      courseCandidates.add(
        _CandidateItem(
          id: vDoc.id,
          data: courseData,
          vector: model.vector,
          metadata: model.metadata,
        ),
      );
    }

    final sessionCandidates = <_CandidateItem>[];
    for (final vDoc in sessionVectors.docs) {
      if (excludeIds.contains(vDoc.id)) continue;
      final sessionData = sessionMap[vDoc.id];
      if (sessionData == null) continue;

      final enrolledCount = sessionData['enrolledCount'] as int? ?? 0;
      final maxParticipants = sessionData['maxParticipants'] as int? ?? 0;
      if (maxParticipants > 0 && enrolledCount >= maxParticipants) continue;

      final model = CourseVectorModel.fromMap(vDoc.data(), vDoc.id);
      sessionCandidates.add(
        _CandidateItem(
          id: vDoc.id,
          data: sessionData,
          vector: model.vector,
          metadata: model.metadata,
        ),
      );
    }

    return {'courses': courseCandidates, 'sessions': sessionCandidates};
  }

  List<RecommendationItemModel> _scoreAndFilterItems({
    required List<_CandidateItem> items,
    required List<double> centroid,
    required RecommendationItemType type,
  }) {
    final scored = <RecommendationItemModel>[];

    for (final item in items) {
      final contentScore = CosineSimilarity.compute(centroid, item.vector);

      final recommendation = type == RecommendationItemType.course
          ? RecommendationItemModel.fromCourse(
              item.data,
              item.id,
              contentScore,
              metadata: item.metadata,
            )
          : RecommendationItemModel.fromSession(
              item.data,
              item.id,
              contentScore,
              metadata: item.metadata,
            );

      scored.add(recommendation);
    }

    scored.sort((a, b) => b.hybridScore.compareTo(a.hybridScore));

    return scored;
  }

  List<RecommendationItem> _applyDiversityFilter(
    List<RecommendationItemModel> items,
  ) {
    final categoryCounts = <String, int>{};
    final filtered = <RecommendationItem>[];

    for (final item in items) {
      final category = item.category.isNotEmpty ? item.category : 'general';
      final count = categoryCounts[category] ?? 0;

      if (count < _maxPerCategory) {
        filtered.add(item);
        categoryCounts[category] = count + 1;
      }

      if (filtered.length >= 10) break;
    }

    return filtered;
  }

  Future<List<RecommendationItem>> _coldStartRecommendations(
    String fieldOfStudies,
    int topN,
  ) async {
    final popularCourses = await _db
        .collection('courses')
        .orderBy('studentsCount', descending: true)
        .limit(topN)
        .get();

    final trendingSessions = await _db
        .collection('training_sessions')
        .where('status', isEqualTo: 'published')
        .orderBy('enrolledCount', descending: true)
        .limit(topN ~/ 2)
        .get();

    final items = <RecommendationItem>[];

    for (final doc in popularCourses.docs) {
      final data = doc.data();
      items.add(RecommendationItemModel.fromCourse(data, doc.id, 0.8));
    }

    for (final doc in trendingSessions.docs) {
      final data = doc.data();
      items.add(RecommendationItemModel.fromSession(data, doc.id, 0.7));
    }

    return items.take(topN).toList();
  }
}

class EnrolledItemData {
  final List<double> vector;
  final double weight;
  final VectorMetadata? metadata;

  EnrolledItemData({required this.vector, required this.weight, this.metadata});
}

class _CandidateItem {
  final String id;
  final Map<String, dynamic> data;
  final List<double> vector;
  final VectorMetadata? metadata;

  _CandidateItem({
    required this.id,
    required this.data,
    required this.vector,
    this.metadata,
  });
}
