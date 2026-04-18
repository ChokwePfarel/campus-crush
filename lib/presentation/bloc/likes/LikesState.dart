// lib/presentation/bloc/likes_bloc/likes_state.dart

import 'package:dating_app/domain/entities/like_entity.dart';

abstract class LikesState {}

class LikesInitial extends LikesState {}

class LikesLoading extends LikesState {}

class LikesLoaded extends LikesState {
  final List<LikeEntity> likes;
  final bool hasLiked;      // whether the current user liked this post

  LikesLoaded({
    required this.likes,
    required this.hasLiked,
  });

  int get likeCount => likes.length;

  LikesLoaded copyWith({
    List<LikeEntity>? likes,
    bool? hasLiked,
  }) {
    return LikesLoaded(
      likes:    likes    ?? this.likes,
      hasLiked: hasLiked ?? this.hasLiked,
    );
  }
}

class LikesError extends LikesState {
  final String message;
  LikesError(this.message);
}