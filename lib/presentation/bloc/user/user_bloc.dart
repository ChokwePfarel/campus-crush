import 'dart:async';

import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/domain/repositories/user_repository.dart';
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;
  StreamSubscription? _userSubscription;

  UserBloc(this._userRepository) : super(UserInitial()) {
    on<LoadUserSubscription>(_onLoadUserSubscription);
    on<UserUpdated>(_onUserUpdated);
    on<UpdateUserRequested>(_onUpdateUserRequested);
  }

  Future<void> _onLoadUserSubscription(
      LoadUserSubscription event,
      Emitter<UserState> emit,
      ) async {
    // ── Step 1: Emit cached user instantly ────────────────────────────────
    // This unblocks DiscoverPage and FeedScreen immediately — they need
    // university + sex from UserLoaded to trigger their own data loads.
    // Without this, both pages show a skeleton until the Supabase stream
    // completes its first round trip.
    final cached = OfflineCache.getCachedCurrentUser();
    if (cached != null) {
      emit(UserLoaded(cached));
    } else {
      emit(UserLoading());
    }

    // ── Step 2: Subscribe to live stream ──────────────────────────────────
    // The stream fires immediately with the current DB value, then again
    // on any profile change. Each emission updates the state and refreshes
    // the cache so the next cold start is even faster.
    await _userSubscription?.cancel();
    _userSubscription = _userRepository.watchCurrentUser().listen(
          (user) => add(UserUpdated(user)),
      onError: (error) {
        // Only surface the error if we have no cached user to fall back on.
        // If we already emitted UserLoaded from cache, stay there silently.
        if (state is! UserLoaded) {
          emit(UserError(error.toString()));
        }
      },
    );
  }

  Future<void> _onUserUpdated(
      UserUpdated event,
      Emitter<UserState> emit,
      ) async {
    if (event.user != null) {
      final user = event.user! as UserModel;
      // Write fresh data to cache every time the stream fires
      await OfflineCache.cacheCurrentUser(user);
      emit(UserLoaded(user));
    } else {
      emit(UserError('User data not found'));
    }
  }

  Future<void> _onUpdateUserRequested(
      UpdateUserRequested event,
      Emitter<UserState> emit,
      ) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      // Optimistic update — reflect changes in UI immediately
      final optimistic = (currentState.user as UserModel).copyWith(
        name:             event.name,
        bio:              event.bio,
        status:           event.status,
        residence:        event.residence,
        interests:        event.interests,
        age:              event.age,
        privacySettings:  event.privacySettings,
      );

      emit(UserLoaded(optimistic));
      // Also update cache so the optimistic value survives a restart
      await OfflineCache.cacheCurrentUser(optimistic);
    }

    try {
      // Background sync to Supabase — the stream will fire with the
      // confirmed server value and call _onUserUpdated, which overwrites
      // the optimistic cache with the real one.
      await _userRepository.updateUserData(
        name:             event.name,
        sex:              event.sex,
        bio:              event.bio,
        status:           event.status,
        residence:        event.residence,
        university:       event.university,
        interests:        event.interests,
        age:              event.age,
        privacySettings:  event.privacySettings,
        isVerified:       event.isVerified,
      );
    } catch (e) {
      // Revert — the stream will eventually correct it once reconnected
      emit(UserError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}