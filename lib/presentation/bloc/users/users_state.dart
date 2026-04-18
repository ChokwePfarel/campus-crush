
import '../../../data/models/user_model.dart';

abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<UserModel> users;
  final bool hasReachedMax;

  UsersLoaded({
    required this.users,
    required this.hasReachedMax,
  });

  UsersLoaded copyWith({
    List<UserModel>? users,
    bool? hasReachedMax,
  }) {
    return UsersLoaded(
      // if users was passed in, use it
      // if users was null (not passed) ,keep this.users
      //only users might change hence fall back for the one that didnt
      users: users ?? this.users,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class UsersError extends UsersState {
  final String message;
  UsersError(this.message);
}


//-----------------Explainig copy with

///copy with allow for creation of new state instance while changing only specific filds
///For example, when last page is detected,only hasRichedMax can be changed, not the list.
///Copy with allows for the pagination to add more users on the existing list of users
/// it prevents wiping out the list of the users already loaded.
/// it basically "append and update"

