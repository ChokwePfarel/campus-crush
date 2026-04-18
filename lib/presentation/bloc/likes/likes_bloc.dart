// lib/presentation/bloc/likes_bloc/likes_bloc.dart
import 'package:dating_app/domain/repositories/likes_repository.dart';
import 'package:dating_app/presentation/bloc/likes/LikesEvent.dart';
import 'package:dating_app/presentation/bloc/likes/LikesState.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class LikesBloc extends Bloc<LikesEvent, LikesState> {
  final LikesRepository _likesRepository;

  LikesBloc(this._likesRepository) : super(LikesInitial()) {
    on<LoadLikes>(_onLoadLikes);
    on<LikePost>(_onLikePost);
    on<UnlikePost>(_onUnlikePost);
    on<CheckHasLiked>(_onCheckHasLiked);
  }

  Future<void> _onLoadLikes(
      LoadLikes event,
      Emitter<LikesState> emit,
      ) async {
    try {
      emit(LikesLoading());
      final likes = await _likesRepository.getLikes(event.postId);
      emit(LikesLoaded(likes: likes, hasLiked: false));
    } catch (e) {
      emit(LikesError(e.toString()));
    }
  }

  Future<void> _onLikePost(
      LikePost event,
      Emitter<LikesState> emit,
      ) async {
    final current = state;
    if (current is! LikesLoaded) return;

    // Optimistic update — feels instant to the user
    emit(current.copyWith(hasLiked: true));

    try {
      final newLike = await _likesRepository.likePost(
        postId:      event.postId,
        userId:      event.userId,
        likedByName: event.likedByName,
      );
      emit(current.copyWith(
        likes:    [newLike, ...current.likes],
        hasLiked: true,
      ));
    } catch (e) {
      // Revert on failure
      emit(current.copyWith(hasLiked: false));
      emit(LikesError(e.toString()));
    }
  }

  Future<void> _onUnlikePost(
      UnlikePost event,
      Emitter<LikesState> emit,
      ) async {
    final current = state;
    if (current is! LikesLoaded) return;

    // Optimistic update
    final optimisticLikes = current.likes
        .where((l) => l.userId != event.userId)
        .toList();
    emit(current.copyWith(likes: optimisticLikes, hasLiked: false));

    try {
      await _likesRepository.unlikePost(
        postId: event.postId,
        userId: event.userId,
      );
    } catch (e) {
      // Revert on failure
      emit(current.copyWith(hasLiked: true));
      emit(LikesError(e.toString()));
    }
  }

  Future<void> _onCheckHasLiked(
      CheckHasLiked event,
      Emitter<LikesState> emit,
      ) async {
    final current = state;
    if (current is! LikesLoaded) return;

    try {
      final hasLiked = await _likesRepository.hasLiked(
        postId: event.postId,
        userId: event.userId,
      );
      emit(current.copyWith(hasLiked: hasLiked));
    } catch (e) {
      emit(LikesError(e.toString()));
    }
  }
}