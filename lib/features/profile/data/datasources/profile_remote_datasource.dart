import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';

class ProfileRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('Profil introuvable.');
    return UserModel.fromMap(doc.data()!);
  }

  Future<Map<String, int>> getStats(String uid) async {
    final results = await Future.wait([
      _firestore
          .collection('enrollments')
          .where('studentId', isEqualTo: uid)
          .count()
          .get(),
      _firestore
          .collection('session_enrollments')
          .where('userId', isEqualTo: uid)
          .where('status', isEqualTo: 'approved')
          .count()
          .get(),
    ]);

    return {
      'enrolledCourses':  results[0].count ?? 0,
      'approvedSessions': results[1].count ?? 0,
    };
  }
}