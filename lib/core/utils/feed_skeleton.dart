import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        // Vertical list of card skeletons
        Expanded(
          child: ListView.builder(
            itemCount: 6, // number of skeleton cards
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  interval: const Duration(milliseconds: 500),
                  color: Colors.grey.shade300,
                  colorOpacity: 0.3,
                  enabled: true,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
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
