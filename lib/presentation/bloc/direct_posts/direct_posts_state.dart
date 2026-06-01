// lib/presentation/bloc/direct_posts_bloc/direct_posts_state.dart

import 'package:dating_app/data/models/post_model.dart';

abstract class DirectPostsState {}

class DirectPostsInitial extends DirectPostsState {}

class DirectPostsLoading extends DirectPostsState {}

class DirectPostsLoaded extends DirectPostsState {
  final List<PostModel> posts;
  final bool hasMore;        // false when we've reached the end
  final bool isLoadingMore;  // true while fetching next page
  final bool hasNewPost;     // true briefly when a real-time post arrives

  DirectPostsLoaded({
    required this.posts,
    required this.hasMore,
    this.isLoadingMore = false,
    this.hasNewPost    = false,
  });

  /// Cursor for pagination — oldest post's createdAt
  DateTime? get cursor => posts.isNotEmpty ? posts.last.createdAt : null;

  DirectPostsLoaded copyWith({
    List<PostModel>? posts,
    bool? hasMore,
    bool? isLoadingMore,
    bool? hasNewPost,
  }) =>
      DirectPostsLoaded(
        posts:         posts         ?? this.posts,
        hasMore:       hasMore       ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasNewPost:    hasNewPost    ?? this.hasNewPost,
      );
}

class DirectPostsError extends DirectPostsState {
  final String message;

  /// Keep previous posts visible on error so the UI doesn't go blank
  final List<PostModel> previousPosts;

  DirectPostsError(this.message, {this.previousPosts = const []});
}
