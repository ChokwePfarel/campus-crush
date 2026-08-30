class UserWarning {
  final String post;
  final String reason;
  final DateTime createdAt;

  UserWarning({
    required this.reason,
    required this.post,
    required this.createdAt,
  });

  factory UserWarning.fromJson(Map<String, dynamic> json) {
    return UserWarning(
      post: json['post_content'] as String ?? '',
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_content': post,
      'reason': reason,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
