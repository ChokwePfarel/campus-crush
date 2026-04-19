import 'package:dating_app/core/utils/screen_size.dart';
import 'package:flutter/cupertino.dart';

class EmptyState extends StatelessWidget {
  const EmptyState();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('📓', style: TextStyle(fontSize: SizeConfig.widthPercent(12))),
        SizedBox(height: SizeConfig.heightPercent(2)),
        const Text(
          'No posts yet',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}