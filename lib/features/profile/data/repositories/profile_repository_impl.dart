import 'package:rayen_mobile/features/authentication/domain/models/user_model.dart';
import 'package:rayen_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:rayen_mobile/features/profile/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _dataSource;

  ProfileRepositoryImpl(this._dataSource);

  @override
  Future<UserModel> getProfile(String uid) =>
      _dataSource.getProfile(uid);

  @override
  Future<Map<String, int>> getStats(String uid) =>
      _dataSource.getStats(uid);
}
