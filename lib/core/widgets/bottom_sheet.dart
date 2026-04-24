import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/domain/entities/comment_entity.dart';
import 'package:dating_app/presentation/bloc/comments/commenst_event.dart';
import 'package:dating_app/presentation/bloc/comments/comments_bloc.dart';
import 'package:dating_app/presentation/bloc/comments/comments_state.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart' as user_st;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Show helper ─────────────────────────────────────────────────────────────

void showCommentsSheet({
  required BuildContext context,
  required String postId,
  required int commentCount,
}) {
  // Trigger initial load
  context.read<CommentsBloc>().add(LoadComments(postId));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<CommentsBloc>(),
      child: CommentsSheet(
        postId: postId,
        commentCount: commentCount,
      ),
    ),
  );
}

// ─── CommentsSheet ────────────────────────────────────────────────────────────

class CommentsSheet extends StatefulWidget {
  final String postId;
  final int commentCount;

  const CommentsSheet({
    super.key,
    required this.postId,
    required this.commentCount,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();
  CommentEntity? _replyingTo;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final userState = context.read<UserBloc>().state;
    if (userState is user_st.UserLoaded) {
      context.read<CommentsBloc>().add(AddComment(
            postId: widget.postId,
            userId: userState.user.id,
            repliersName: userState.user.name,
            text: text,
            parentCommentId: _replyingTo?.id,
          ));

      _inputCtrl.clear();
      setState(() => _replyingTo = null);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          const Divider(height: 1, color: Color(0xFFF0F0F5)),
          Expanded(child: _buildBody()),
          if (_replyingTo != null) _buildReplyBanner(),
          _buildInputBar(bottomInset),
        ],
      ),
    );
  }

  Widget _buildHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDDDDE8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: [
          const Text('Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text('${widget.commentCount}',
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<CommentsBloc, CommentsState>(
      builder: (context, state) {
        if (state is LoadingComments) {

          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (state is ErrorComments) {
          return Center(child: Text(state.message));
        }
        if (state is CommentsLoaded) {
          if (state.comments.isEmpty) return const Center(child: Text("No comments yet."));

          final topLevel =
              state.comments.where((c) => c.parentCommentId == null).toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: topLevel.length,
            itemBuilder: (_, i) => _CommentTile(
              comment: topLevel[i],
              onReply: (c) => setState(() => _replyingTo = c),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildReplyBanner() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(CupertinoIcons.reply, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
              child: Text('Replying to ${_replyingTo!.repliersName}',
                  style: const TextStyle(fontSize: 12))),
          IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => setState(() => _replyingTo = null))
        ],
      ),
    );
  }

  Widget _buildInputBar(double bottom) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom, left: 16, right: 16, top: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          IconButton(
            icon:  Icon(CupertinoIcons.arrow_up_circle_fill,
                color: AppStylee.primaryColor, size: 32),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final CommentEntity comment;
  final void Function(CommentEntity) onReply;

  const _CommentTile({
    required this.comment,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final isAnonymous = comment.repliersName == 'Anonymous';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          onLongPress: () {
            showCupertinoModalPopup(
              context: context,
              builder: (ctx) => CupertinoActionSheet(
                actions: [
                  CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    onPressed: () {
                      context
                          .read<CommentsBloc>()
                          .add(DeleteComment(commentId: comment.id));
                      Navigator.pop(ctx);
                    },
                    child: const Text('Delete Comment'),
                  ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            );
          },
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: isAnonymous ? Colors.grey[200] : Colors.purple[50],
            child: Text(isAnonymous ? '🎭' : comment.repliersName[0]),
          ),
          title: Text(comment.repliersName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(comment.text, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(DateUtilsHelper.timeAgo(comment.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => onReply(comment),
                    child: const Text('Reply',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6C63FF))),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (comment.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: comment.replies
                  .map((r) => _CommentTile(comment: r, onReply: onReply))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
