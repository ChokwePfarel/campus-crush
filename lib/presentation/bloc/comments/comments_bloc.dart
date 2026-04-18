// lib/presentation/bloc/comments_bloc/comments_bloc.dart

import 'package:dating_app/domain/entities/comment_entity.dart';
import 'package:dating_app/domain/repositories/comments_repository.dart';
import 'package:dating_app/presentation/bloc/comments/commenst_event.dart';
import 'package:dating_app/presentation/bloc/comments/comments_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final CommentsRepository _commentsRepository;

  CommentsBloc(this._commentsRepository) : super(InitialComments()) {
    on<LoadComments>(_onLoadComments);
    on<AddComment>(_onAddComment);
    on<DeleteComment>(_onDeleteComment);
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoadComments(
      LoadComments event,
      Emitter<CommentsState> emit,
      ) async {
    try {
      emit(LoadingComments());
      final comments =
      await _commentsRepository.getComments(event.postId);
      emit(CommentsLoaded(comments));
    } catch (e) {
      emit( ErrorComments(e.toString()));
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
        postId:          event.postId,
        userId:          event.userId,
        repliersName:    event.repliersName,
        text:            event.text,
        parentCommentId: event.parentCommentId,
      );

      List<CommentEntity> updated;

      if (event.parentCommentId == null) {
        // Top-level comment — add to the end of the list
        updated = [...current.comments, newComment];
      } else {
        // Reply — nest it under the parent comment
        updated = current.comments.map((c) {
          if (c.id == event.parentCommentId) {
            return _appendReply(c, newComment);
          }
          return c;
        }).toList();
      }

      emit(current.copyWith(comments: updated));
    } catch (e) {
      emit( ErrorComments(e.toString()));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDeleteComment(
      DeleteComment event,
      Emitter<CommentsState> emit,
      ) async {
    final current = state;
    if (current is! CommentsLoaded) return;

    // Optimistic update
    final optimistic = _removeComment(current.comments, event.commentId);
    emit(current.copyWith(comments: optimistic));

    try {
      await _commentsRepository.deleteComment(event.commentId);
    } catch (e) {
      // Revert on failure
      emit(current);
      emit( ErrorComments(e.toString()));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Appends a reply under a parent comment
  CommentEntity _appendReply(CommentEntity parent, CommentEntity reply) {
    return CommentEntity(
      id:              parent.id,
      postId:          parent.postId,
      userId:          parent.userId,
      repliersName:    parent.repliersName,
      text:            parent.text,
      createdAt:       parent.createdAt,
      parentCommentId: parent.parentCommentId,
      replies:         [...parent.replies, reply],
    );
  }

  /// Removes a comment or reply by id from the list
  List<CommentEntity> _removeComment(
      List<CommentEntity> comments,
      String commentId,
      ) {
    return comments
        .where((c) => c.id != commentId)
        .map((c) => CommentEntity(
      id:              c.id,
      postId:          c.postId,
      userId:          c.userId,
      repliersName:    c.repliersName,
      text:            c.text,
      createdAt:       c.createdAt,
      parentCommentId: c.parentCommentId,
      replies: c.replies
          .where((r) => r.id != commentId)
          .toList(),
    ))
        .toList();
  }
}