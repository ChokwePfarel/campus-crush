// lib/presentation/bloc/direct_posts_bloc/direct_posts_event.dart

import 'package:dating_app/data/models/post_model.dart';

abstract class DirectPostsEvent {}

/// Initial load — fetches first page
class LoadDirectPosts extends DirectPostsEvent {
  final String recipientId;
  LoadDirectPosts(this.recipientId);
}

/// Load more — fetches next page using cursor
class LoadMoreDirectPosts extends DirectPostsEvent {
  final String recipientId;
  LoadMoreDirectPosts(this.recipientId);
}

/// Fired internally when real-time stream delivers a new post
class NewDirectPostReceived extends DirectPostsEvent {
  final PostModel post;
  NewDirectPostReceived(this.post);
}

/// Refresh — full reload from scratch
class RefreshDirectPosts extends DirectPostsEvent {
  final String recipientId;
  RefreshDirectPosts(this.recipientId);
}
