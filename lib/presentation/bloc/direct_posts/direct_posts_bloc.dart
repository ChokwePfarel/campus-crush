// lib/presentation/bloc/direct_posts_bloc/direct_posts_bloc.dart

import 'dart:async';

import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/posts_repository.dart';
import 'package:dating_app/presentation/bloc/direct_posts/direct_posts_event.dart';
import 'package:dating_app/presentation/bloc/direct_posts/direct_posts_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DirectPostsBloc extends Bloc<DirectPostsEvent, DirectPostsState> {
  final PostRepository _postRepository;
  StreamSubscription<List<PostModel>>? _realtimeSubscription;

  static const int _pageSize = 15;

  DirectPostsBloc(this._postRepository) : super(DirectPostsInitial()) {
    on<LoadDirectPosts>(_onLoad);
    on<LoadMoreDirectPosts>(_onLoadMore);
    on<NewDirectPostReceived>(_onNewPostReceived);
    on<RefreshDirectPosts>(_onRefresh);
  }

  // ── Initial load ────────────────────────────────────────────────────────

  Future<void> _onLoad(
      LoadDirectPosts event,
      Emitter<DirectPostsState> emit,
      ) async {
    emit(DirectPostsLoading());

    try {
      final posts = await _postRepository.getDirectPostsPaginated(
        recipientId: event.recipientId,
        limit:  _pageSize,
      );

      emit(DirectPostsLoaded(
        posts:   posts,
        hasMore: posts.length == _pageSize,
      ));

      // Start real-time subscription for new incoming posts
      _startRealtime(event.recipientId);
    } catch (e) {
      emit(DirectPostsError(e.toString()));
    }
  }

  // ── Load more (pagination) ────────────────────────────────────────────────

  Future<void> _onLoadMore(
      LoadMoreDirectPosts event,
      Emitter<DirectPostsState> emit,
      ) async {
    final current = state;
    if (current is! DirectPostsLoaded) return;
    if (!current.hasMore || current.isLoadingMore) return;

    emit(current.copyWith(isLoadingMore: true));

    try {
      final more = await _postRepository.getDirectPostsPaginated(
        recipientId: event.recipientId,
        before:      current.cursor,   // cursor-based pagination
        limit:       _pageSize,
      );

      emit(current.copyWith(
        posts:         [...current.posts, ...more],
        hasMore:       more.length == _pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      // On error keep existing posts, just stop loading more
      emit(current.copyWith(isLoadingMore: false));
      emit(DirectPostsError(
        e.toString(),
        previousPosts: current.posts,
      ));
    }
  }

  // ── New real-time post received ────────────────────────────────────────────

  void _onNewPostReceived(
      NewDirectPostReceived event,
      Emitter<DirectPostsState> emit,
      ) {
    final current = state;
    if (current is! DirectPostsLoaded) return;

    // Avoid duplicates
    final alreadyExists =
    current.posts.any((p) => p.id == event.post.id);
    if (alreadyExists) return;

    // Prepend new post to the top
    emit(current.copyWith(
      posts:      [event.post, ...current.posts],
      hasNewPost: true,
    ));

    // Reset hasNewPost flag after a short delay
    // so UI can animate the badge and clear it
    Future.delayed(const Duration(seconds: 3), () {
      if (state is DirectPostsLoaded) {
        emit((state as DirectPostsLoaded).copyWith(hasNewPost: false));
      }
    });
  }

  // ── Refresh ────────────────────────────────────────────────────────────────

  Future<void> _onRefresh(
      RefreshDirectPosts event,
      Emitter<DirectPostsState> emit,
      ) async {
    // Cancel existing real-time sub before restarting
    await _realtimeSubscription?.cancel();
    _realtimeSubscription = null;

    // Re-use load logic
    add(LoadDirectPosts(event.recipientId));
  }

  // ── Real-time subscription ─────────────────────────────────────────────────

  void _startRealtime(String recipientId) {
    _realtimeSubscription?.cancel();

    _realtimeSubscription = _postRepository
        .watchNewDirectPosts(recipientId)
        .listen((posts) {
      if (posts.isNotEmpty) {
        add(NewDirectPostReceived(posts.first));
      }
    });
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }
}