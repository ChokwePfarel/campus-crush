abstract class ReportsState {}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsSuccess extends ReportsState {}

class PostAlreadyReported extends ReportsState {}

class ReportsFailure extends ReportsState {
  final String message;
  ReportsFailure(this.message);
}


abstract class BlockUserState {}

class BlockUserInitial extends BlockUserState {}

class BlockUserLoading extends BlockUserState {}

class BlockUserSuccess extends BlockUserState {}


class BlockUserFailure extends BlockUserState {
  final String message;
  BlockUserFailure(this.message);
}