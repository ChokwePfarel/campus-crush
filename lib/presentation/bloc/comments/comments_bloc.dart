import 'dart:async';
import 'package:dating_app/domain/entities/comment_entity.dart';
import 'package:dating_app/domain/repositories/comments_repository.dart';
import 'package:dating_app/presentation/bloc/comments/commenst_event.dart';
import 'package:dating_app/presentation/bloc/comments/comments_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final CommentsRepository _commentsRepository;
  StreamSubscription? _notificationSub;
  List<CommentEntity> _notifications = [];

  CommentsBloc(this._commentsRepository) : super(const InitialComments()) {
    on<LoadComments>(_onLoadComments);
    on<AddComment>(_onAddComment);
    on<DeleteComment>(_onDeleteComment);
   /* on<WatchUserNotifications>(_onWatchUserNotifications);
    on<NewNotificationReceived>(_onNewNotificationReceived);
    on<MarkNotificationsAsRead>(_onMarkNotificationsAsRead);*/
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<CommentsState> emit,
  ) async {
    final currentRedDot = state.showRedDot;
    try {
      emit(LoadingComments(
        showRedDot: currentRedDot,
        notifications: _notifications,
      ));
      final comments = await _commentsRepository.getComments(event.postId);
      emit(CommentsLoaded(
        comments,
        showRedDot: currentRedDot,
        notifications: _notifications,
      ));
    } catch (e) {
      emit(ErrorComments(
        e.toString(),
        showRedDot: currentRedDot,
        notifications: _notifications,
      ));
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> _onAddComment(
    AddComment event,
    Emitter<CommentsState> emit,
  ) async {
    final current = state;
    if (current is! CommentsLoaded) return;

    try {
      final newComment = await _commentsRepository.addComment(
        postId: event.postId,
        userId: event.userId,
        repliersName: event.repliersName,
        text: event.text,
        parentCommentId: event.parentCommentId,
      );

      List<CommentEntity> updated;

      if (event.parentCommentId == null) {
        updated = [...current.comments, newComment];
      } else {
        updated = current.comments.map((c) {
          if (c.id == event.parentCommentId) {
            return _appendReply(c, newComment);
          }
          return c;
        }).toList();
      }

      emit(current.copyWith(comments: updated));
    } catch (e) {
      emit(ErrorComments(
        e.toString(),
        showRedDot: state.showRedDot,
        notifications: _notifications,
      ));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDeleteComment(
    DeleteComment event,
    Emitter<CommentsState> emit,
  ) async {
    final current = state;
    if (current is! CommentsLoaded) return;

    final optimistic = _removeComment(current.comments, event.commentId);
    emit(current.copyWith(comments: optimistic));

    try {
      await _commentsRepository.deleteComment(event.commentId);
    } catch (e) {
      emit(current);
      emit(ErrorComments(
        e.toString(),
        showRedDot: state.showRedDot,
        notifications: _notifications,
      ));
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────
/*
  Future<void> _onWatchUserNotifications(
    WatchUserNotifications event,
    Emitter<CommentsState> emit,
  ) async {
// print('DEBUG: 👀 Watching notifications for: ${event.userId}');
    await _notificationSub?.cancel();
    _notificationSub = _commentsRepository
        .watchUserNotifications(event.userId)
        .listen((comment) {
// print('DEBUG: 🔔 Notification stream received comment: ${comment.text}');
      add(NewNotificationReceived(comment));
    }, onError: (err) {
// print('DEBUG: ❌ Notification stream error: $err');
    });
  }

  void _onNewNotificationReceived(
    NewNotificationReceived event,
    Emitter<CommentsState> emit,
  ) {
// print('DEBUG: 📬 Bloc handling NewNotificationReceived: ${event.comment.text}');
    _notifications = [event.comment, ..._notifications];

    final current = state;
    if (current is CommentsLoaded) {
      emit(current.copyWith(
        showRedDot: true,
        notifications: _notifications,
      ));
    } else {
      emit(InitialComments(
        showRedDot: true,
        notifications: _notifications,
      ));
    }
  }

  void _onMarkNotificationsAsRead(
    MarkNotificationsAsRead event,
    Emitter<CommentsState> emit,
  ) {
// print('DEBUG: ✅ Marking notifications as read');
    final current = state;
    if (current is CommentsLoaded) {
      emit(current.copyWith(showRedDot: false));
    } else {
      emit(InitialComments(
        showRedDot: false,
        notifications: _notifications,
      ));
    }
  }*/

  // ── Helpers ───────────────────────────────────────────────────────────────

  CommentEntity _appendReply(CommentEntity parent, CommentEntity reply) {
    return CommentEntity(
      id: parent.id,
      postId: parent.postId,
      userId: parent.userId,
      repliersName: parent.repliersName,
      text: parent.text,
      createdAt: parent.createdAt,
      parentCommentId: parent.parentCommentId,
      replies: [...parent.replies, reply],
    );
  }

  List<CommentEntity> _removeComment(
    List<CommentEntity> comments,
    String commentId,
  ) {
    return comments
        .where((c) => c.id != commentId)
        .map((c) => CommentEntity(
              id: c.id,
              postId: c.postId,
              userId: c.userId,
              repliersName: c.repliersName,
              text: c.text,
              createdAt: c.createdAt,
              parentCommentId: c.parentCommentId,
              replies: c.replies.where((r) => r.id != commentId).toList(),
            ))
        .toList();
  }

  @override
  Future<void> close() {
    _notificationSub?.cancel();
    return super.close();
  }
}
