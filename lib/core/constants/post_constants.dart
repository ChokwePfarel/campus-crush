import 'package:dating_app/data/models/coins_model.dart';
import 'package:flutter/material.dart';

enum PostType { general, crush, confession, spotted }

extension PostTypeExt on PostType {
  String get label {
    switch (this) {
      case PostType.general:
        return 'General';
      case PostType.crush:
        return 'Crush';
      case PostType.confession:
        return 'Confession';
      case PostType.spotted:
        return 'Spotted';
    }
  }

  String get emoji {
    switch (this) {
      case PostType.general:
        return '💬';
      case PostType.crush:
        return '💘';
      case PostType.confession:
        return '🤫';
      case PostType.spotted:
        return '📡';
    }
  }

  String get hint {
    switch (this) {
      case PostType.general:
        return "What's on your mind?";
      case PostType.crush:
        return "Tell us about your crush... 💘";
      case PostType.confession:
        return "Confess something... we won't judge 🤫";
      case PostType.spotted:
        return "Describe what you're wearing today...";
    }
  }

  Color get color {
    switch (this) {
      case PostType.general:
        return const Color(0xFF6C63FF);
      case PostType.crush:
        return const Color(0xFFFF4D6D);
      case PostType.confession:
        return const Color(0xFFFF9F1C);
      case PostType.spotted:
        return const Color(0xFF2EC4B6);
    }
  }
}

class LocationTags {
  static const List<Map<String, String>> all = [
    {'label': 'Main Library', 'icon': '📚', 'category': 'Libraries & Study'},
    {
      'label': 'Library Ground Floor',
      'icon': '📖',
      'category': 'Libraries & Study',
    },
    {
      'label': 'Library Computer Lab',
      'icon': '💻',
      'category': 'Libraries & Study',
    },
    {'label': 'A Block', 'icon': '📚', 'category': 'Libraries & Study'},
    {'label': 'B Block', 'icon': '📚', 'category': 'Libraries & Study'},
    {'label': '24hr Study Room', 'icon': '🌙', 'category': 'Libraries & Study'},
    {'label': 'Main Cafeteria', 'icon': '🍽️', 'category': 'Food & Hangout'},
    {'label': 'Halaal Cafeteria', 'icon': '🥗', 'category': 'Food & Hangout'},
    {'label': 'Student Centre Café', 'icon': '☕', 'category': 'Food & Hangout'},
    {'label': 'Student Centre', 'icon': '🏛️', 'category': 'Social Spaces'},
    {'label': 'The Barn', 'icon': '🎭', 'category': 'Social Spaces'},
    {
      'label': 'Sports Centre / Gym',
      'icon': '💪',
      'category': 'Sports & Wellness',
    },
    {'label': 'Swimming Pool', 'icon': '🏊', 'category': 'Sports & Wellness'},
    {'label': 'Football Fields', 'icon': '⚽', 'category': 'Sports & Wellness'},
  ];

  static Map<String, List<Map<String, String>>> get grouped {
    final map = <String, List<Map<String, String>>>{};
    for (final tag in all) {
      map.putIfAbsent(tag['category']!, () => []).add(tag);
    }
    return map;
  }
}

const List<Color?> postBgColors = [
  null, // no background (default)
  Color(0xFFFFE0E6),
  Color(0xFFFFEDD5),
  Color(0xFFFFF9C4),
  Color(0xFFDCF8E0),
  Color(0xFFD6EAFF),
  Color(0xFFEDE0FF),
  Color(0xFFFFD6F5),
  Color(0xFFD0F4F4),
  Color(0xFF1A1A2E),
  Color(0xFF2D1B1B),
  Color(0xFF1B2D1B),
];

class MockCoins {
  static final mockCoins = [
    CoinsModel(
      balance: 100,
      dailyAdsWatched: 5,
      dailyDirectPostsCount: 2,

    ),
  ];
}
