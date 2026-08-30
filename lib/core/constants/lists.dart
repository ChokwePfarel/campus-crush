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
    "University of Cape Town",
    "Stellenbosch University",
    "University of Pretoria",
    "University of the Witwatersrand",
    "University of KwaZulu-Natal",
    "University of the Western Cape",
    "Rhodes University",
    "University of South Africa",
    "Nelson Mandela University",
    "North-West University",
    "Sefako Makgatho Health Sciences University",
    "Sol Plaatje University",
    "University of Fort Hare",
    "University of Johannesburg",
    "University of Limpopo",
    "University of Mpumalanga",
    "University of the Free State",
    "University of Venda",
    "Tshwane University of Technology",
    "Durban University of Technology",
    "Central University of Technology",
    "Cape Peninsula University of Technology",
    "Mangosuthu University of Technology",
    "Nelson Mandela University"
        'Walter Sisulu University',
    "University of Mpumalanga"
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

static final List<String> southAfricanUniversities = [
  "University of Cape Town",
  "Stellenbosch University",
  "University of Pretoria",
  "University of the Witwatersrand",
  "University of KwaZulu-Natal",
  "University of the Western Cape",
  "Rhodes University",
  "University of South Africa",
  "Nelson Mandela University",
  "North-West University",
  "Sefako Makgatho Health Sciences University",
  "Sol Plaatje University",
  "University of Fort Hare",
  "University of Johannesburg",
  "University of Limpopo",
  "University of Mpumalanga",
  "University of the Free State",
  "University of Venda",
  "Tshwane University of Technology",
  "Durban University of Technology",
  "Central University of Technology",
  "Cape Peninsula University of Technology",
  "Mangosuthu University of Technology",
  "Nelson Mandela University"
      'Walter Sisulu University',
  "University of Mpumalanga"
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

class Reason {
  static final reasons = [
    "Spam",
    "Harassment",
    "Hate Speech",
    "Inappropriate Content",
    "Misinformation",
    "Illegal Activity",
    "Self-harm",
    "Other",
  ];
}
