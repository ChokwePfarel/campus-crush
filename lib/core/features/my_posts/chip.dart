import 'package:dating_app/core/utils/screen_size.dart';
import 'package:flutter/cupertino.dart';

class StatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const StatChip({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.heightPercent(1.5)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3.5)),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: SizeConfig.widthPercent(5))),
            SizedBox(height: SizeConfig.heightPercent(0.5)),
            Text(
              value,
              style: TextStyle(
                fontSize: SizeConfig.widthPercent(4.5),
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: SizeConfig.widthPercent(2.8),
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
