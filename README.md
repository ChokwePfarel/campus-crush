# CampusCrush (UniDate)

CampusCrush is a modern social and dating application tailored specifically for university students. Built using Flutter and powered by Supabase, the application allows students to discover peers, post campus updates, share anonymous whispers or direct posts, chat in real time, and engage through a campus-centric ecosystem.

## Key Features

- Campus Verification and Discovery: Discover and connect with verified students from your university and nearby campuses.
- Dynamic Feed and Posts: Share public updates, filter feed content by campus or post type, and interact with posts via likes and comments.
- Anonymous Whispers and Direct Posts: Send targeted posts and secret crush messages with reveal options.
- Real-Time Messaging: Instant messaging and conversation management powered by Supabase Realtime listeners.
- In-App Coin and Reward System: Monetization and engagement framework powered by Google Mobile Ads rewarded video ads.
- Offline Caching and Sync: Seamless offline state management backed by Hive for instant page loads and network recovery handling.
- Safety and Moderation: Built-in user reporting system, warnings, account suspension state checks, and privacy controls.
- Notifications Center: Real-time badge tracking and alerts for likes, comments, and incoming messages.

## Technology Stack

- Framework: Flutter (Dart SDK)
- Backend as a Service: Supabase (Auth, PostgreSQL Database, Realtime, Storage)
- State Management: BLoC / Cubit (`flutter_bloc`)
- Architecture: Clean Architecture (Data, Domain, Presentation)
- Local Caching: Hive (`hive_flutter`), Shared Preferences
- Advertisements: Google Mobile Ads SDK (`google_mobile_ads`)
- Network & Connectivity: `connectivity_plus`, `cached_network_image`
- Deep Linking: `app_links`
- Environment Management: `flutter_dotenv`

## Project Architecture

The codebase follows Clean Architecture principles divided into three core layers:

```
lib/
├── core/                  # Utilities, shared widgets, services, and themes
│   ├── constants/         # Mock data and global constants
│   ├── features/          # Feature-specific reusable UI components
│   ├── services/          # Services (e.g., Google Ads service)
│   ├── utils/             # Caching, network status, date formatters, and helpers
│   └── widgets/           # Global widgets and custom navigation controls
├── data/                  # Data layer handling network API calls and local storage
│   ├── datasources/       # Supabase remote data sources and API implementations
│   ├── models/            # Data Transfer Objects (DTOs) with JSON serialization
│   └── repositories/      # Repository implementations bridging Domain and Data
├── domain/                # Business logic contracts and pure entities
│   ├── entities/          # Core business entities
│   └── repositories/      # Abstract repository interfaces
└── presentation/          # UI layer containing BLoCs, Pages, and Components
    ├── bloc/              # State management BLoCs and Events
    └── pages/             # App screens and flow navigation
```

## Getting Started

### Prerequisites

- Flutter SDK (version 3.9.0 or higher)
- Android Studio, VS Code, or Xcode
- Supabase project instance

### Environment Setup

1. Clone the repository to your local machine:
   ```bash
   git clone https://github.com/your-username/dating_app.git
   cd dating_app
   ```

2. Create a `.env` file in the root directory with your Supabase credentials:
   ```env
   SUPABASE_URL=https://your-supabase-project.supabase.co
   SUPABASE_ANON_KEY=your-supabase-anon-key
   ```

3. Ensure assets and fonts are declared correctly in `pubspec.yaml` (already included in repository).

### Installation and Running

1. Fetch application dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application on an emulator or physical device:
   ```bash
   flutter run
   ```

### Running Tests

Execute the automated unit and widget test suite:
```bash
flutter test
```

## License

This project is proprietary and confidential. All rights reserved.
