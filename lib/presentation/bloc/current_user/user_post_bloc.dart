import 'package:dating_app/domain/repositories/current_user_post_repository.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_event.dart';
import 'package:dating_app/presentation/bloc/current_user/user_post_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class CurrentUserPostBloc extends Bloc<UserPostEvent, UserPostState> {
  final CurrentUserPostRepository _currentUserPostRepository;

  CurrentUserPostBloc(this._currentUserPostRepository) : super(InitialUserPostState()) {
    on<LoadUserPosts>(_onLoadUserPosts);
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
}
