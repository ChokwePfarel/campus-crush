import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/posts_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'posts_event.dart';
import 'posts_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository _postRepository;
  static const int _limit = 10;

  PostBloc(this._postRepository) : super(PostInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<CreatePostRequested>(_onCreatePost);
    on<DeletePostRequested>(_onDeletePost);
    on<GetOnePostById>(_onGetOnePostById);
  }

  Future<void> _onLoadPosts(
    LoadPosts event,
    Emitter<PostState> emit,
  ) async {
    final currentState = state;

    if (currentState is PostsLoaded &&
        currentState.hasReachedMax &&
        !event.isInitial) {
      return;
    }

    final bool isFresh = event.isInitial || currentState is! PostsLoaded;

    if (isFresh) {
      final cached = OfflineCache.getCachedPosts();
      if (cached.isNotEmpty) {
        final filteredCached = cached.where((p) {
          final typeMatch = event.postType == null || p.postType == event.postType;
          final locationMatch = event.locationTag == null || p.locationTag == event.locationTag;
          return typeMatch && locationMatch;
        }).toList();

        emit(PostsLoaded(post: filteredCached, hasReachedMax: false));
      } else {
        emit(LoadingPosts());
      }

      try {
        final posts = await _postRepository.getPosts(
          university: event.university,
          postType: event.postType,
          locationTag: event.locationTag,
          offset: 0,
          limit: _limit,
        );

        final models = posts.whereType<PostModel>().toList();
        if (models.isNotEmpty) {
          await OfflineCache.cachePosts(models);
        }

        emit(PostsLoaded(post: models, hasReachedMax: posts.length < _limit));
      } catch (e) {
        final alreadyShowingCache =
            state is PostsLoaded && (state as PostsLoaded).post.isNotEmpty;
        if (!alreadyShowingCache) {
          emit(PostError(e.toString()));
        }
      }
    } else    try {
      final posts = await _postRepository.getPosts(
        university: event.university,
        postType: event.postType,
        locationTag: event.locationTag,
        offset: currentState.post.length,
        limit: _limit,
      );

      emit(posts.isEmpty
          ? currentState.copyWith(hasReachedMax: true)
          : PostsLoaded(
              post: currentState.post + posts,
              hasReachedMax: posts.length < _limit,
            ));
    } catch (e) {
      emit(currentState.copyWith(hasReachedMax: false));
    }

  }

  Future<void> _onCreatePost(
      CreatePostRequested event,
      Emitter<PostState> emit,
      ) async {
    try {
      await _postRepository.createPost(
        content: event.content,
        university: event.university,
        backgroundColor: event.backgroundColor,
        isAnonymous: event.isAnonymous,
        postType: event.postType,
        authorName: event.authorName,
        recipientId: event.recipientId,
        isNormalPost: event.isNormalPost,
        locationTag: event.locationTag,
        expiresAt: event.expiresAt,
      );
      add(LoadPosts(
        university: event.university,
        postType: event.postType,
        locationTag: event.locationTag,
        isInitial: true,
      ));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  Future<void> _onDeletePost(
    DeletePostRequested event,
    Emitter<PostState> emit,
  ) async {
    try {
      await _postRepository.deletePost(event.postId);
      if (state is PostsLoaded) {
        final currentPosts = (state as PostsLoaded).post;
        final updatedPosts = currentPosts.where((p) => p.id != event.postId).toList();
        emit((state as PostsLoaded).copyWith(post: updatedPosts));
      }
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }

  Future<void> _onGetOnePostById(
    GetOnePostById event,
    Emitter<PostState> emit,
  ) async {
    try {
      final post = await _postRepository.getOnePostById(event.postId);
      emit(OnePostLoaded(post));
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }


}
