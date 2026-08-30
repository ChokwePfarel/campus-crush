import 'package:dating_app/data/datasources/user_remote_data_source.dart';
import 'package:dating_app/data/models/warning_model.dart';
import 'package:dating_app/domain/repositories/warning_repository.dart';

class WarningRepositoryImpl extends WarningRepository {

  final UserRemoteDataSource remoteDataSource;

  WarningRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserWarning> getUserWarning() async {
    try {
      final warning = await remoteDataSource.getUserWarning();
      return warning;
    } catch (e) {
      rethrow;
    }
  }
  }

