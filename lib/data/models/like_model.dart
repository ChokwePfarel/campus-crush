// lib/data/models/like_model.dart

import 'package:dating_app/domain/entities/like_entity.dart';

class LikeModel extends LikeEntity {
  const LikeModel({
    required super.id,
    required super.postId,
    required super.userId,
    required super.likedByName,
    required super.createdAt,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id:          json['id'] ?? '',
      postId:      json['post_id'] ?? '',
      userId:      json['user_id'] ?? '',
      likedByName: json['liked_by_name'] ?? 'Anonymous',
      createdAt:   DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':            id,
      'post_id':       postId,
      'user_id':       userId,
      'liked_by_name': likedByName,
      'created_at':    createdAt.toIso8601String(),
    };
  }
}