import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final int badgeCount;

  const BadgeIcon({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(isActive ? activeIcon : icon),
        if (badgeCount > 0)
          Positioned(
            top:   -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color:  Color(0xFFFF4D6D),
                shape:  BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth:  16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color:     Colors.white,
                  fontSize:  9,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}