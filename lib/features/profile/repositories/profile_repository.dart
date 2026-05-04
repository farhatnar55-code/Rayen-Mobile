import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';

abstract class ProfileRepository {
  Future<UserModel> getProfile(String uid);
  Future<Map<String, int>> getStats(String uid);
}