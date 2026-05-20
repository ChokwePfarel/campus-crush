
import 'package:dating_app/data/models/post_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PostsCard extends StatelessWidget {
  final PostModel post;

  const PostsCard({super.key, required this.post});

  String timeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds}s ago";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hrs ago";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return "${createdAt.day}/${createdAt.month}/${createdAt.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: post.backgroundColor ?? Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 150),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timeAgo(post.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (post.isAnonymous)
                  const Icon(Icons.security, color: Colors.white70, size: 16),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                post.content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            Column(
              children: [
                if (post.isAnonymous)
                  const Text(
                    '~ Anonymous',
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(color: Colors.white24),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(CupertinoIcons.chat_bubble),
                      color: Colors.white,
                      iconSize: 20,
                    ),
                    const Text(
                      'Reply',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
