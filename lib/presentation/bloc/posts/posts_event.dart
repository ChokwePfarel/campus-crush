import 'package:flutter/material.dart';

abstract class PostEvent {}

class LoadPosts extends PostEvent {
  final String? university;
  final String? postType;
  final String? locationTag;
  final bool isInitial;

  LoadPosts({
    this.university,
    this.postType,
    this.locationTag,
    this.isInitial = false,
  });
}

class CreatePostRequested extends PostEvent {
  final String content;
  final String university;
  final Color backgroundColor;
  final bool isAnonymous;
  final String postType;
  final String authorName;
  final String? recipientId;
  final bool isNormalPost;
  final String? locationTag;
  final DateTime? expiresAt;

  CreatePostRequested({
    required this.content,
    required this.university,
    required this.backgroundColor,
    required this.postType,
    required this.isAnonymous,
    required this.authorName,
    this.recipientId,
    this.isNormalPost = true,
    this.locationTag,
    this.expiresAt,
  });
}

class DeletePostRequested extends PostEvent {
  final String postId;

  DeletePostRequested({required this.postId});
}