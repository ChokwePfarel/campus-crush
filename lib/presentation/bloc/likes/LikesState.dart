// lib/presentation/bloc/likes/likes_state.dart

abstract class LikesState {}

class LikesInitial extends LikesState {}

class LikesLoading extends LikesState {}

class LikesError extends LikesState {
  final String message;
  LikesError(this.message);
}

class LikesLoaded extends LikesState {
  final bool hasLiked;
  final int likeCount;

  LikesLoaded({required this.hasLiked, required this.likeCount});

  LikesLoaded copyWith({bool? hasLiked, int? likeCount}) => LikesLoaded(
    hasLiked: hasLiked ?? this.hasLiked,
    likeCount: likeCount ?? this.likeCount,
  );
}