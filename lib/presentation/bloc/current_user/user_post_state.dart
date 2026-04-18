import 'package:dating_app/data/models/post_model.dart';

abstract class UserPostState{}


class InitialUserPostState extends UserPostState{}

class UserPostLoading extends UserPostState{}



class UserPostLoaded extends UserPostState{
  final List<PostModel> posts;
  UserPostLoaded({required this.posts});
}



class UserPostError extends UserPostState{
  final String message;
  UserPostError({required this.message});
}

