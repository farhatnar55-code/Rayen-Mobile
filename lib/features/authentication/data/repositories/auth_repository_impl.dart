import '../../domain/models/user_model.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<UserModel> signInWithEmail(String email, String password) {
    return _dataSource.signInWithEmail(email, password);
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) {
    return _dataSource.registerWithEmail(
      email:    email,
      password: password,
      fullName: fullName,
      role:     role,
    );
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<UserModel?> getCurrentUser() => _dataSource.getCurrentUser();

  @override
  Stream<UserModel?> get authStateChanges => _dataSource.authStateChanges;
}
