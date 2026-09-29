abstract class UsersEvent {}

class LoadUsers extends UsersEvent {
  final String university;
  final String sex;
  final String? residence;
  final bool isInitial;

  LoadUsers({ required this.university, required this.sex, this.residence, this.isInitial = false});
}

class SearchUsers extends UsersEvent {
  final String university;
  final String query;
  final bool isInitial;

  SearchUsers({
    required this.university,
    required this.query,
    this.isInitial = true,
  });
}

class ClearSearch extends UsersEvent {}
