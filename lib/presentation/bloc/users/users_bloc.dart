/*


import 'package:dating_app/domain/repositories/users_repository.dart';
import 'package:dating_app/presentation/bloc/users/users_event.dart';
import 'package:dating_app/presentation/bloc/users/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _usersRepository;
  static const int _limit = 10;

  UsersBloc(this._usersRepository) : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UsersState> emit,
  ) async {
    final currentState = state;
    
    // Check if we're already loading or have reached max, unless it's a fresh search/load
    if (currentState is UsersLoaded && currentState.hasReachedMax && !event.isInitial) {
      return;
    }

    try {
      if (event.isInitial || currentState is! UsersLoaded) {
        emit(UsersLoading());
        
        final users = await _usersRepository.getUsers(
          university: event.university,
          sex: event.sex,
          residence: event.residence,
          offset: 0,
          limit: _limit,
        );
        
        emit(UsersLoaded(
          users: users,
          hasReachedMax: users.length < _limit,
        ));
      } else {
        // Fetch next page
        final users = await _usersRepository.getUsers(
          university: event.university,
          sex: event.sex,
          residence: event.residence,
          offset: currentState.users.length,
          limit: _limit,
        );
        
        emit(users.isEmpty
            ? currentState.copyWith(hasReachedMax: true)
            : UsersLoaded(
                users: currentState.users + users,
                hasReachedMax: users.length < _limit,
              ));
      }
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}
*/

import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/domain/repositories/users_repository.dart';
import 'package:dating_app/presentation/bloc/users/users_event.dart';
import 'package:dating_app/presentation/bloc/users/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _usersRepository;
  static const int _limit = 10;

  UsersBloc(this._usersRepository) : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
  }

  Future<void> _onLoadUsers(
      LoadUsers event,
      Emitter<UsersState> emit,
      ) async {
    final currentState = state;

    // Already at the end of pages and this isn't a fresh load — do nothing.
    if (currentState is UsersLoaded &&
        currentState.hasReachedMax &&
        !event.isInitial) {
      return;
    }

    final bool isFresh = event.isInitial || currentState is! UsersLoaded;

    if (isFresh) {
      // ── Step 1: Show cache instantly on initial load ───────────────────
      final cached = OfflineCache.getCachedDiscoveryUsers();
      if (cached.isNotEmpty) {
        emit(UsersLoaded(users: cached, hasReachedMax: false));
      } else {
        emit(UsersLoading());
      }

      // ── Step 2: Fetch page 1 from server ──────────────────────────────
      try {
        final users = await _usersRepository.getUsers(
          university: event.university,
          sex: event.sex,
          residence: event.residence,
          offset: 0,
          limit: _limit,
        );

        // Persist first page for offline use.
        // Only cache page 1 — we don't want a partial page 3 to be shown
        // as the full offline list.
        final models = users.whereType<UserModel>().toList();
        if (models.isNotEmpty) {
          await OfflineCache.cacheDiscoveryUsers(models);
        }

        emit(UsersLoaded(
          users: users,
          hasReachedMax: users.length < _limit,
        ));
      } catch (e) {
        // Server failed — if we already emitted cache, stay there silently.
        // If cache was empty we showed the skeleton — surface the error.
        final alreadyShowingCache =
            state is UsersLoaded && (state as UsersLoaded).users.isNotEmpty;
        if (!alreadyShowingCache) {
          emit(UsersError(e.toString()));
        }
      }
    } else {
      // ── Pagination: append next page (online only) ────────────────────
      // We never paginate from cache — offline users see page 1 only.
      final loaded = currentState;
      try {
        final users = await _usersRepository.getUsers(
          university: event.university,
          sex: event.sex,
          residence: event.residence,
          offset: loaded.users.length,
          limit: _limit,
        );

        emit(users.isEmpty
            ? loaded.copyWith(hasReachedMax: true)
            : UsersLoaded(
          users: loaded.users + users,
          hasReachedMax: users.length < _limit,
        ));
      } catch (e) {
        // Pagination failure — keep the existing list, don't wipe it.
        // The scroll listener will retry on the next scroll event.
        emit(loaded.copyWith(hasReachedMax: false));
      }
    }
  }
}