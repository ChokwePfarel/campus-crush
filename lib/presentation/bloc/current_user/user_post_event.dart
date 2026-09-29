

abstract class UserPostEvent{}

class LoadUserPosts extends UserPostEvent {}

class RemovePostLocally extends UserPostEvent {
  final String postId;
  RemovePostLocally(this.postId);
}
