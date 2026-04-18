
import 'package:supabase/supabase.dart';

abstract class AuthRepository {

  Future<AuthResponse> login(String email, String password);

  Future<AuthResponse> signUp(String email, String password, String name);
  Future<void> logout();

  User? get currentUser;
}
