import 'package:dating_app/domain/repositories/current_user_post_repository.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_event.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class CurrentUserPostBloc extends Bloc<UserPostEvent, UserPostState> {
  final CurrentUserPostRepository _currentUserPostRepository;

  CurrentUserPostBloc(this._currentUserPostRepository) : super(InitialUserPostState()) {
    on<LoadUserPosts>(_onLoadUserPosts);
    on<RemovePostLocally>(_onRemovePostLocally);
  }

  Future<void> _onLoadUserPosts(
    LoadUserPosts event,
    Emitter<UserPostState> emit,
  ) async {
    emit(UserPostLoading());
    try {
      final posts = await _currentUserPostRepository.getCurrentUserPost();
      emit(UserPostLoaded(posts: posts));
    } catch (e) {
      emit(UserPostError(message: e.toString()));
    }
  }

  void _onRemovePostLocally(
    RemovePostLocally event,
    Emitter<UserPostState> emit,
  ) {
    if (state is UserPostLoaded) {
      final currentPosts = (state as UserPostLoaded).posts;
      final updatedPosts =
          currentPosts.where((p) => p.id != event.postId).toList();
      emit(UserPostLoaded(posts: updatedPosts));
    }
  }
}
