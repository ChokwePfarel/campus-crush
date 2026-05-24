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

    //-----------chacking if data is fresh

    final bool isFresh = event.isInitial || currentState is! PostsLoaded;

    if(isFresh){
      //SHOW CACHED RIGHT AWAY
      final cached = OfflineCache.getCachedPosts();
      if(cached.isNotEmpty){
        // Filter cached posts by type and location if provided
        final filteredCached = cached.where((p) {
          final typeMatch = event.postType == null || p.postType == event.postType;
          final locationMatch = event.locationTag == null || p.locationTag == event.locationTag;
          return typeMatch && locationMatch;
        }).toList();
        
        emit(PostsLoaded(post: filteredCached, hasReachedMax: false));
      } else {
        emit(LoadingPosts());
      }

      //FETCH PAGE 1 FROM SERVER
      try{

        final posts = await _postRepository.getPosts(
          university: event.university,
          postType: event.postType,
          locationTag: event.locationTag,
          offset: 0,
          limit: _limit,
        );

        //Only caching page 1

        final models = posts.whereType<PostModel>().toList();
        if(models.isNotEmpty){
          await OfflineCache.cachePosts(models);
        }

        emit(PostsLoaded(
            post: models,
            hasReachedMax: posts.length < _limit
        ));

      } catch (e){
        //SERVER FAILED
        final alreadyShowingCache =
            state is PostsLoaded && (state as PostsLoaded).post.isNotEmpty;
        //If not,show the error
        if(!alreadyShowingCache){
          emit(PostError(e.toString()));
        }
      }

    } else {

      final loaded = currentState;
      try{

        final posts = await _postRepository.getPosts(
          university: event.university,
          postType: event.postType,
          locationTag: event.locationTag,
          offset: currentState.post.length,
          limit: _limit,
        );

        emit(posts.isEmpty
            ? loaded.copyWith(hasReachedMax: true)
            : PostsLoaded(
          post: loaded.post + posts,
          hasReachedMax: posts.length < _limit,
        ));

      } catch (e) {
        //emit(PostError(e.toString()));
        // Pagination failure — keep the existing list, don't wipe it.
        // The scroll listener will retry on the next scroll event.
        emit(loaded.copyWith(hasReachedMax: false));

      }
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
        final updatedPosts =
        currentPosts.where((p) => p.id != event.postId).toList();
        emit((state as PostsLoaded).copyWith(post: updatedPosts));
      }
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }
}
