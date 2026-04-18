import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signInWithEmailPassword(String email, String password);

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  );

  Future<void> signOut();

  Session? get currentSession;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      return await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
    } catch (e) {
      // Print before throwing, or just throw as the Bloc will handle the error message
      print('Error signing up: $e');
      throw Exception('Error signing up: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  @override
  Session? get currentSession => client.auth.currentSession;
}
