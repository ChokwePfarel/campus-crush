import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/domain/repositories/users_repository.dart';
import 'package:dating_app/presentation/bloc/users/users_event.dart';
import 'package:dating_app/presentation/bloc/users/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _usersRepository;
  static const int _limit = 20;

  UsersBloc(this._usersRepository) : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<SearchUsers>(_onSearchUsers);
    on<ClearSearch>((event, emit) => emit(UsersInitial()));
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UsersState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is UsersLoaded && currentState.hasReachedMax && !event.isInitial) {
      return;
    }

    try {
      if (event.isInitial || currentState is! UsersLoaded) {
        // --- 1. INSTANT CACHE RENDER ---
        final cached = OfflineCache.getCachedDiscoveryUsers();
        if (cached.isNotEmpty && event.isInitial) {
          emit(UsersLoaded(users: cached, hasReachedMax: false));
        } else if (currentState is! UsersLoaded) {
          emit(UsersLoading());
        }
        
        // --- 2. FETCH FROM SERVER ---
        final users = await _usersRepository.getUsers(
          university: event.university,
          sex: event.sex,
          residence: event.residence,
          offset: 0,
          limit: _limit,
        );
        
        // --- 3. PERSIST TO CACHE (Only Page 1) ---
        if (users.isNotEmpty && (event.residence == null || event.residence!.isEmpty)) {
          await OfflineCache.cacheDiscoveryUsers(users);
        }

        emit(UsersLoaded(
          users: users,
          hasReachedMax: users.length < _limit,
        ));
      } else {
        // Pagination for non-initial loads
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
      // If we already have cache data in state, keep it and stay silent
      if (state is! UsersLoaded) {
        emit(UsersError(e.toString()));
      }
    }
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<UsersState> emit,
  ) async {
    final currentState = state;

    if (currentState is UsersLoaded && currentState.hasReachedMax && !event.isInitial) {
      return;
    }

    try {
      if (event.isInitial) {
        emit(UsersLoading());
        final users = await _usersRepository.searchUsers(
          university: event.university,
          query: event.query,
          offset: 0,
          limit: _limit,
        );
        emit(UsersLoaded(users: users, hasReachedMax: users.length < _limit));
      } else if (currentState is UsersLoaded) {
        final users = await _usersRepository.searchUsers(
          university: event.university,
          query: event.query,
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
