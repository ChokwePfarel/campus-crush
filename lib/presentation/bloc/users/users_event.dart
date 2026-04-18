abstract class UsersEvent {}

class LoadUsers extends UsersEvent {
  final String university;
  final String sex;
  final String? residence;
  final bool isInitial;

  LoadUsers({ required this.university, required this.sex, this.residence, this.isInitial = false});
}



