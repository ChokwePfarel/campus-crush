import 'package:dating_app/domain/entities/like_entity.dart';

abstract class LikesState {}

class LikesInitial extends LikesState {}

class LikesLoading extends LikesState {}

class LikesError extends LikesState {
  final String message;
  LikesError(this.message);
}

/// Used by each post card — tracks count and whether current user liked it
class LikesLoaded extends LikesState {
  final bool hasLiked;
  final int likeCount;

  LikesLoaded({required this.hasLiked, required this.likeCount});

  LikesLoaded copyWith({bool? hasLiked, int? likeCount}) => LikesLoaded(
    hasLiked: hasLiked ?? this.hasLiked,
    likeCount: likeCount ?? this.likeCount,
  );
}

/// Used only by the "Liked by" bottom sheet
class LikesListLoaded extends LikesState {
  final List<LikeEntity> likes;
  LikesListLoaded(this.likes);
}
