import 'package:flutter/material.dart';

class PostEntity {
  final String id;
  final String userId;
  final String recipientId;
  final bool isNormalPost;
  final String content;
  final String university;
  final DateTime createdAt;
  final String? imageUrl;
  final String? videoUrl;
  final Color? backgroundColor;
  final bool isAnonymous;
  final String postType;
  final String? locationTag;
  final DateTime? expiresAt;
  final int likeCount;
  final int commentCount;
  final String authorName;
  final String? profileImageUrl;
  final bool isVerified;


  PostEntity({
    required this.id,
    required this.userId,
    required this.recipientId,
    required this.isNormalPost,
    required this.content,
    required this.university,
    required this.createdAt,
    this.imageUrl,
    this.videoUrl,
    this.backgroundColor,
    this.isAnonymous = false,
    required this.postType,
    this.locationTag,
    this.expiresAt,
    this.likeCount = 0,
    this.commentCount = 0,
    required this.authorName,

    this.profileImageUrl,
    this.isVerified = false,
  });
}
