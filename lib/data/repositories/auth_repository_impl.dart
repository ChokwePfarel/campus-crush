import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuthResponse> login(String email, String password) async {
    return await remoteDataSource.signInWithEmailPassword(email, password);
  }

  @override
  Future<AuthResponse> signUp(
    String email,
    String password,
    String name,
  ) async {
    return await remoteDataSource.signUpWithEmailPassword(
      email,
      password,
      name,
    );
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.signOut();
  }

  @override
  User? get currentUser => remoteDataSource.currentSession?.user;
}
