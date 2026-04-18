
import 'package:dating_app/data/models/post_model.dart';

abstract class PostState {

}

class PostInitial extends PostState {}

class LoadingPosts extends PostState {}

class PostsLoaded extends PostState {
  //Require list of post instance and a boolean to trac
  final List<PostModel> post;
  final bool hasReachedMax;

  PostsLoaded({
    required this.post,
    required this.hasReachedMax,
  });

  PostsLoaded copyWith({List<PostModel>? post, bool? hasReachedMax}) {

    return PostsLoaded(
      post: post ?? this.post,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,

    );
  }}

class PostError extends PostState {
  final String message;

PostError(this.message);

}