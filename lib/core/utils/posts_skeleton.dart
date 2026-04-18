import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class PostListSkeleton extends StatelessWidget {
  const PostListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Expanded(
          child: ListView.builder(
            itemCount: 6, // number of skeleton cards
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  interval: const Duration(milliseconds: 500),
                  color: Colors.grey.shade300,
                  colorOpacity: 0.3,
                  enabled: true,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
