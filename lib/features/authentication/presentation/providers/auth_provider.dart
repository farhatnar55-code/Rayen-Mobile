import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthProvider(this._repository) {
    _repository.authStateChanges.listen((user) {
      _user = user;
      _status = user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserRole? get role => _user?.role;

  Future<void> signIn(String email, String password) async {
    _setLoading();
    try {
      await _repository.signInWithEmail(email, password);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    _setLoading();
    try {
      await _repository.registerWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    try {
      final uid = _user?.uid;
      if (uid == null) return;
      final updated = await _repository.getCurrentUser();
      _user = updated;
      _status = updated != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();
    } catch (_) {}
  }
}
