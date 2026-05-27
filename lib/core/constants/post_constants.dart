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
        return const Color(0xFF000000);
      case PostType.crush:
        return const Color(0xFF000000);
      case PostType.confession:
        return const Color(0xFF000000);
      case PostType.spotted:
        return const Color(0xFF000000);
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
    {'label': 'level 8', 'icon': '📚', 'category': 'Libraries & Study'},
    {'label': 'level 9', 'icon': '📚', 'category': 'Libraries & Study'},
    {'label': 'level 10', 'icon': '📚', 'category': 'Libraries & Study'},
    {'label': 'level 11', 'icon': '📚', 'category': 'Libraries & Study'},
    {'label': 'level 12', 'icon': '📚', 'category': 'Libraries & Study'},
    {'label': '24hr Study Room', 'icon': '🌙', 'category': 'Libraries & Study'},
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

  Color(0xFF1A1A2E),
  Color(0xFF2D1B1B), // dark maroon
  Color(0xFF1B2D1B), // dark forest green
  Color(0xFF0D1B2A), // midnight blue
  Color(0xFF2C2C54), // indigo
  Color(0xFF263238), // charcoal grey
  Color(0xFF000000), // teal green
  Color(0xFF00695C), // teal green
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
