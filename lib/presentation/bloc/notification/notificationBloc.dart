import 'dart:async';
import 'package:dating_app/domain/entities/notification_entity.dart';
import 'package:dating_app/domain/repositories/notification_repository.dart';
import 'package:dating_app/presentation/bloc/notification/notification_event.dart';
import 'package:dating_app/presentation/bloc/notification/notification_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;

  NotificationBloc(this._repository) : super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoad);
    on<WatchNotifications>(_onWatch);
    on<MarkNotificationsRead>(_onMarkRead);
  }

  Future<void> _onLoad(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    final currentDot = state.showRedDot;
    try {
      emit(NotificationLoading(showRedDot: currentDot));
      final notifications = await _repository.getNotifications(event.userId);

      // Filter duplicates by id and commentId
      final seenIds = <String>{};
      final seenCommentIds = <String>{};
      final uniqueNotifications = notifications.where((n) {
        final isNewId = seenIds.add(n.id);
        // If commentId is not empty, ensure it's unique. Otherwise just rely on ID.
        final isNewComment = n.commentId.isEmpty || seenCommentIds.add(n.commentId);
        return isNewId && isNewComment;
      }).toList();

      final hasUnread = uniqueNotifications.any((n) => !n.isRead);

      emit(NotificationLoaded(uniqueNotifications, showRedDot: hasUnread));
    } catch (e) {

      emit(NotificationError(e.toString(), showRedDot: currentDot));
    }
  }

  Future<void> _onWatch(
    WatchNotifications event,
    Emitter<NotificationState> emit,
  ) async {


    return emit.forEach<List<NotificationEntity>>(
      _repository.watchNotifications(event.userId),
      onData: (notifications) {


        final seenIds = <String>{};
        final seenCommentIds = <String>{};
        final uniqueNotifications = notifications.where((n) {
          final isNewId = seenIds.add(n.id);
          final isNewComment = n.commentId.isEmpty || seenCommentIds.add(n.commentId);
          return isNewId && isNewComment;
        }).toList();

        final hasUnread = uniqueNotifications.any((n) => !n.isRead);

        final current = state;
        if (current is NotificationLoaded) {
          return current.copyWith(
            notifications: uniqueNotifications,
            showRedDot: hasUnread,
          );
        }
        return NotificationLoaded(uniqueNotifications, showRedDot: hasUnread);
      },
      onError: (error, stackTrace) {


        return NotificationError(
          error.toString(),
          showRedDot: state.showRedDot,
        );
      },
    );
  }

  Future<void> _onMarkRead(
    MarkNotificationsRead event,
    Emitter<NotificationState> emit,
  ) async {

    final current = state;
    if (current is NotificationLoaded) {

      // Optimistically clear the red dot and update local items


      final updated = current.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(current.copyWith(notifications: updated, showRedDot: false));
    }

    try {
      await _repository.markAllAsRead(event.userId);
    } catch (e) {
      emit(NotificationError(e.toString(), showRedDot: state.showRedDot));
    }
  }
}
