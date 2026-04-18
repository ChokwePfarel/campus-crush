

import 'dart:ui';


enum PostType { general, crush, confession, spotted }

extension PostTypeExt on PostType {
  String get label {
    switch (this) {
      case PostType.general:    return 'General';
      case PostType.crush:      return 'Crush';
      case PostType.confession: return 'Confession';
      case PostType.spotted:    return 'Spotted';
    }
  }

  String get emoji {
    switch (this) {
      case PostType.general:    return '💬';
      case PostType.crush:      return '💘';
      case PostType.confession: return '🤫';
      case PostType.spotted:    return '📡';
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
      case PostType.general:    return const Color(0xFF6C63FF);
      case PostType.crush:      return const Color(0xFFFF4D6D);
      case PostType.confession: return const Color(0xFFFF9F1C);
      case PostType.spotted:    return const Color(0xFF2EC4B6);
    }
  }

}

class DropDownOptions{
  static  final List<String> sexOptions = [
    'Male',
    'Female',
  ];

  static final List<String> availableInterests = [
  'Coding', 'Music', 'Sports', 'Traveling', 'Foodie', 'Photography',
  'Gaming', 'Reading', 'Dancing', 'Art', 'Movies', 'Volunteering',
  'Fitness', 'Hiking', 'Cooking', 'Netflix', 'Anime', 'Gym', 'Coffee'
  ];

  static final List<String> statuses = [
    'Single',
    'In a relationship',
    'Engaged',
    'Married',
    'Divorced',
    'Widowed'
  ];
}



