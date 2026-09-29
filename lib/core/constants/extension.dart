import 'dart:ui';

import '../../presentation/pages/send_post_page.dart';



///TO-DO : I should look at this code again...

extension DirectPostTypeExt on DirectPostType {
  String get emoji {
    switch (this) {
      case DirectPostType.crush:
        return '💘';
      case DirectPostType.compliment:
        return '✨';
      case DirectPostType.confession:
        return '🤫';
      case DirectPostType.question:
        return '💭';
    }
  }

  String get label {
    switch (this) {
      case DirectPostType.crush:
        return 'Crush';
      case DirectPostType.compliment:
        return 'Compliment';
      case DirectPostType.confession:
        return 'Confession';
      case DirectPostType.question:
        return 'Question';
    }
  }

  String get hint {
    switch (this) {
      case DirectPostType.crush:
        return 'Tell them how you feel... 💘';
      case DirectPostType.compliment:
        return 'Say something kind ✨';
      case DirectPostType.confession:
        return 'Get it off your chest 🤫';
      case DirectPostType.question:
        return 'Ask them something 💭';
    }
  }

  Color get color {
    switch (this) {
      case DirectPostType.crush:
        return const Color(0xFFB5193A);
      case DirectPostType.compliment:
        return const Color(0xFF3730A3);
      case DirectPostType.confession:
        return const Color(0xFFB45309);
      case DirectPostType.question:
        return const Color(0xFF0F766E);
    }
  }

  List<String> get suggestions {
    switch (this) {
      case DirectPostType.crush:
        return [
          'I smile every time I see you 😊',
          'You\'ve been on my mind a lot lately',
          'I get nervous whenever you\'re around',
          'I wish I had the courage to talk to you',
        ];
      case DirectPostType.compliment:
        return [
          'Your energy in class is contagious ✨',
          'You always look amazing 🔥',
          'You seem like a genuinely good person',
          'Your laugh is everything 😄',
        ];
      case DirectPostType.confession:
        return [
          'I\'ve been watching your stories for months',
          'I almost spoke to you so many times',
          'You intimidate me in the best way',
          'I look for you whenever I\'m on campus',
        ];
      case DirectPostType.question:
        return [
          'Would you ever grab coffee with a stranger? ☕',
          'Do you come to the library often?',
          'What\'s your go-to study spot?',
          'Are you as interesting as you look?',
        ];
    }
  }
}