import 'dart:async';

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
    emit(UserLoading());
    await _userSubscription?.cancel();

    _userSubscription = _userRepository.watchCurrentUser().listen(
      (user) {
        add(UserUpdated(user));
      },
      onError: (error) {
        emit(UserError(error.toString()));
      },
    );
  }

  void _onUserUpdated(UserUpdated event, Emitter<UserState> emit) {
    if (event.user != null) {
      emit(UserLoaded(event.user!));
    } else {
      emit(UserError("User data not found"));
    }
  }

  Future<void> _onUpdateUserRequested(    UpdateUserRequested event,
      Emitter<UserState> emit,
      ) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      // 1. OPTIMISTIC UPDATE: Update memory immediately
      final updatedUser = (currentState.user as UserModel).copyWith(
        name: event.name,
        bio: event.bio,
        status: event.status,
        residence: event.residence,
        interests: event.interests,
        age: event.age,
        privacySettings: event.privacySettings,
      );
      emit(UserLoaded(updatedUser));
    }

    try {
      // 2. BACKGROUND SYNC: Update Supabase
      await _userRepository.updateUserData(
        name: event.name,
        sex: event.sex,
        bio: event.bio,
        status: event.status,
        residence: event.residence,
        university: event.university,
        interests: event.interests,
        age: event.age,
        privacySettings: event.privacySettings,
        isVerified: event.isVerified,
      );
    } catch (e) {
      // 3. REVERT ON ERROR: If server fails, show error and let stream fix it
      emit(UserError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
