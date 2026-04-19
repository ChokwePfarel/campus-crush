// lib/presentation/bloc/likes/likes_bloc.dart

import 'package:dating_app/domain/repositories/likes_repository.dart';
import 'package:dating_app/presentation/bloc/likes/LikesEvent.dart';
import 'package:dating_app/presentation/bloc/likes/LikesState.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class LikesBloc extends Bloc<LikesEvent, LikesState> {
  final LikesRepository _likesRepository;

  LikesBloc(this._likesRepository) : super(LikesInitial()) {
    on<InitializeLikes>(_onInitialize);
    on<LikePost>(_onLikePost);
    on<UnlikePost>(_onUnlikePost);
    on<LoadLikes>(_onLoadLikes);

  }

  Future<void> _onInitialize(
      InitializeLikes event,
      Emitter<LikesState> emit,
      ) async {
    // Show the PostModel count immediately — no loading flicker
    emit(LikesLoaded(hasLiked: false, likeCount: event.initialCount));

    try {
      final hasLiked = await _likesRepository.hasLiked(
        postId: event.postId,
        userId: event.userId,
      );
      final current = state as LikesLoaded;
      emit(current.copyWith(hasLiked: hasLiked));
    } catch (_) {
      // Non-fatal — count is still shown, heart just defaults to unliked
    }
  }

  Future<void> _onLikePost(
      LikePost event,
      Emitter<LikesState> emit,
      ) async {
    final current = state;
    if (current is! LikesLoaded) return;

    // Optimistic update
    emit(current.copyWith(hasLiked: true, likeCount: current.likeCount + 1));

    try {
      await _likesRepository.likePost(
        postId: event.postId,
        userId: event.userId,
        likedByName: event.likedByName,
      );
      // Supabase trigger handles like_count on the DB — no extra call needed
    } catch (e) {
      // Revert
      emit(current.copyWith(hasLiked: false, likeCount: current.likeCount));
    }
  }

  Future<void> _onUnlikePost(
      UnlikePost event,
      Emitter<LikesState> emit,
      ) async {
    final current = state;
    if (current is! LikesLoaded) return;

    // Optimistic update
    emit(current.copyWith(
      hasLiked: false,
      likeCount: (current.likeCount - 1).clamp(0, double.maxFinite.toInt()),
    ));

    try {
      await _likesRepository.unlikePost(
        postId: event.postId,
        userId: event.userId,
      );
    } catch (e) {
      // Revert
      emit(current.copyWith(hasLiked: true, likeCount: current.likeCount));
    }
  }

  Future<void> _onLoadLikes(
      LoadLikes event,
      Emitter<LikesState> emit,
      ) async {
    emit(LikesLoading());
    try {
      final likes = await _likesRepository.getLikes(event.postId);
      emit(LikesListLoaded(likes));
    } catch (e) {
      emit(LikesError(e.toString()));
    }
  }
}