import 'dart:ui';
import 'package:dating_app/domain/entities/post_entity.dart';

class PostModel extends PostEntity {
  PostModel({
    required super.id,
    required super.userId,
    required super.recipientId,
    required super.isNormalPost,
    required super.content,
    required super.university,
    required super.createdAt,
    super.imageUrl,
    super.videoUrl,
    super.backgroundColor,
    super.isAnonymous,
    required super.postType,
    super.locationTag,
    super.expiresAt,
    super.likeCount = 0,
    super.commentCount = 0,
    required super.authorName,
    super.profileImageUrl,
    super.isVerified,  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      recipientId: json['recipient_id'] ?? '',
      isNormalPost: json['is_normal_post'] ?? true,
      content: json['content'] ?? '',
      university: json['university'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      backgroundColor: json['background_color'] != null
          ? Color(json['background_color'] as int)
          : null,
      isAnonymous: json['is_anonymous'] ?? false,
      postType: json['post_type'] ?? 'general',
      locationTag: json['location_tag'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      authorName: json['profiles'] != null 
          ? json['profiles']['name'] ?? '' 
          : (json['author_name'] ?? ''),

      profileImageUrl: json['profiles'] != null
          ? json['profiles']['profile_image_url']
          : null,
      isVerified: json['profiles'] != null
          ? json['profiles']['is_verified'] ?? false
          : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'recipient_id': recipientId,
      'is_normal_post': isNormalPost,
      'content': content,
      'university': university,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
      'video_url': videoUrl,
      'background_color': backgroundColor?.value,
      'is_anonymous': isAnonymous,
      'post_type': postType,
      'location_tag': locationTag,
      'expires_at': expiresAt?.toIso8601String(),
      'like_count': likeCount,
      'comment_count': commentCount,
      'author_name': authorName,

      'profile_image_url': profileImageUrl,
      'is_verified': isVerified,
    };
  }
}
