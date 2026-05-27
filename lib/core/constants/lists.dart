
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



  String get hint {
    switch (this) {
      case PostType.general:
        return "What's on your mind?";
      case PostType.crush:
        return "Tell us about your crush...";
      case PostType.confession:
        return "Confess something... we won't judge ";
      case PostType.spotted:
        return "Describe what you're wearing today...";
    }
  }


}

class DropDownOptions {
  static final List<String> sexOptions = ['Male', 'Female', 'LGBTQ'];

  static final List<String> universities = [
    'University of the Western Cape (UWC)'
  ];

  static final List<String> availableInterests = [
    'Coding',
    'Music',
    'Sports',
    'Traveling',
    'Foodie',
    'Photography',
    'Gaming',
    'Reading',
    'Dancing',
    'Art',
    'Movies',
    'Volunteering',
    'Fitness',
    'Hiking',
    'Cooking',
    'Netflix',
    'Anime',
    'Gym',
    'Coffee',
  ];

  static final List<String> statuses = [
    'Single',
    'In a relationship',
    'Engaged',
    'Married',
    'Divorced',
    'Widowed',
  ];
}
