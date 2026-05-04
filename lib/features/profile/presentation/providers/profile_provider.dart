import 'package:flutter/material.dart';
import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/profile/repositories/profile_repository.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileProvider(this._repository);

  ProfileStatus    _status      = ProfileStatus.initial;
  UserModel?       _profile;
  Map<String, int> _stats       = {};
  String?          _errorMessage;

  ProfileStatus    get status       => _status;
  UserModel?       get profile      => _profile;
  Map<String, int> get stats        => _stats;
  String?          get errorMessage => _errorMessage;

  Future<void> loadProfile(String uid) async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _profile = await _repository.getProfile(uid);
      _stats   = await _repository.getStats(uid);
      _status  = ProfileStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  void clear() {
    _profile      = null;
    _stats        = {};
    _status       = ProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}
