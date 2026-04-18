import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OtherProfileSkeleton extends StatelessWidget {
  const OtherProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top half: image placeholder
        Expanded(
          flex: 1,
          child: Container(
            width: double.infinity,
            color: Colors.grey.shade300,
            child: const Center(
              child: Icon(Icons.person, size: 100, color: Colors.grey),
            ),
          ),
        ),

        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  4,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    height: 16,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
