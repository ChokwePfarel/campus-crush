import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class UserSkeletonItem extends StatelessWidget {
  const UserSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListTile(
        leading:  CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade200 , // shimmer will animate over this
        ),
        title: Container(
          decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade200,
          ),
          height: 14,
          width:30,
          margin: const EdgeInsets.only(bottom: 6),
        ),
        subtitle: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade200,
          ),
          height: 14,
          width: 25,
        ),
      ),
    );
  }
}
