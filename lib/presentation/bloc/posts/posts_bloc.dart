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

    if (currentState is PostsLoaded && currentState.hasReachedMax && !event.isInitial) {
      return;
    }

    try {
      if (event.isInitial || currentState is! PostsLoaded) {
        emit(LoadingPosts());

        final posts = await _postRepository.getPosts(
          university: event.university,
          offset: 0,
          limit: _limit,
        );

        emit(PostsLoaded(
          post: posts,
          hasReachedMax: posts.length < _limit,
        ));
      } else {
        final posts = await _postRepository.getPosts(
          university: event.university,
          offset: currentState.post.length,
          limit: _limit,
        );

        emit(posts.isEmpty
            ? currentState.copyWith(hasReachedMax: true)
            : PostsLoaded(
                post: currentState.post + posts,
                hasReachedMax: posts.length < _limit,
              ));
      }
    } catch (e) {
      emit(PostError(e.toString()));
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
      );
      // Refresh posts after creation
      add(LoadPosts(university: event.university, isInitial: true));
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
      // If we are in loaded state, we could also remove it optimistically
      if (state is PostsLoaded) {
        final currentPosts = (state as PostsLoaded).post;
        final updatedPosts = currentPosts.where((p) => p.id != event.postId).toList();
        emit((state as PostsLoaded).copyWith(post: updatedPosts));
      }
    } catch (e) {
      emit(PostError(e.toString()));
    }
  }
}
