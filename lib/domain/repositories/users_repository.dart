import '../../data/models/user_model.dart';

abstract class UsersRepository {
  Future<List<UserModel>> getUsers({
    required String university,
    required String sex,
    String? residence,
    required int offset,
    required int limit,
  });

  Future<UserModel> getUserById(String userId);
}
