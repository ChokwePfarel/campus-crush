import 'package:dating_app/core/utils/screen_size.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({super.key, 
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SizeConfig.widthPercent(2)),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.widthPercent(3),
            vertical: SizeConfig.heightPercent(1)
        ),
        child: Row(
          children: [
            Icon(icon, size: SizeConfig.widthPercent(5), color: color),
            SizedBox(width: SizeConfig.widthPercent(1.5)),
            Text(
              label,
              style: TextStyle(
                fontSize: SizeConfig.widthPercent(3.2),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
