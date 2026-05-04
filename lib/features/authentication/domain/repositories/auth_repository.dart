import '../models/user_model.dart';
import '../models/user_role.dart';

abstract class AuthRepository {
  Future<UserModel> signInWithEmail(String email, String password);
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
}
