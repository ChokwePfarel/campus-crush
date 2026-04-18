
import 'package:flutter/material.dart';

class DateUtilsHelper {
  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

extension PostTypeTheme on String {
  String get emoji {
    switch (this) {
      case 'crush':       return '💘';
      case 'confession':  return '🤫';
      case 'spotted':     return '📡';
      default:            return '💬';
    }
  }

  String get label {
    switch (this) {
      case 'crush':       return 'Crush';
      case 'confession':  return 'Confession';
      case 'spotted':     return 'Spotted';
      default:            return 'General';
    }
  }

  Color get accentColor {
    switch (this) {
      case 'crush':       return const Color(0xFFFF4D6D);
      case 'confession':  return const Color(0xFFFF9F1C);
      case 'spotted':     return const Color(0xFF2EC4B6);
      default:            return const Color(0xFF6C63FF);
    }
  }
}
