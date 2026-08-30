import 'package:app_links/app_links.dart';
import 'package:dating_app/core/services/ad_service.dart';
import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/datasources/auth_remote_data_source.dart';
import 'package:dating_app/data/datasources/chat_remote_data_source.dart';
import 'package:dating_app/data/datasources/coins_remote_data_source.dart';
import 'package:dating_app/data/datasources/comment_remote_data_source.dart';
import 'package:dating_app/data/datasources/image_remote_data_source.dart';
import 'package:dating_app/data/datasources/likes_remote_data_source.dart';
import 'package:dating_app/data/datasources/notification_remote_data_source.dart';
import 'package:dating_app/data/datasources/post_remote_data_source.dart';
import 'package:dating_app/data/datasources/report_remote_data_source.dart';
import 'package:dating_app/data/datasources/user_remote_data_source.dart';
import 'package:dating_app/data/datasources/users_remote_data_source.dart';
import 'package:dating_app/data/repositories/auth_repository_impl.dart';
import 'package:dating_app/data/repositories/chat_repository_impl.dart';
import 'package:dating_app/data/repositories/coins_repository_impl.dart';
import 'package:dating_app/data/repositories/image_repository_impl.dart';
import 'package:dating_app/data/repositories/notification_repository_imp.dart';
import 'package:dating_app/data/repositories/posts_repository_impl.dart';
import 'package:dating_app/data/repositories/reports_repository_impl.dart';
import 'package:dating_app/data/repositories/user_repository_impl.dart';
import 'package:dating_app/data/repositories/users_repository_impl.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/domain/repositories/image_repository.dart';
import 'package:dating_app/domain/repositories/notification_repository.dart';
import 'package:dating_app/domain/repositories/posts_repository.dart';
import 'package:dating_app/domain/repositories/user_repository.dart';
import 'package:dating_app/domain/repositories/users_repository.dart';
import 'package:dating_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:dating_app/presentation/bloc/auth/auth_event.dart';
import 'package:dating_app/presentation/bloc/coins/coins_bloc.dart';
import 'package:dating_app/presentation/bloc/comments/comments_bloc.dart';
import 'package:dating_app/presentation/bloc/conectivity/conectivityBloc.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:dating_app/presentation/bloc/direct_posts/direct_posts_bloc.dart';
import 'package:dating_app/presentation/bloc/image/image_bloc.dart';
import 'package:dating_app/presentation/bloc/likes/likes_bloc.dart';
import 'package:dating_app/presentation/bloc/notification/notificationBloc.dart';
import 'package:dating_app/presentation/bloc/notification/notification_event.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/reports/report_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/bloc/users/users_bloc.dart';
import 'package:dating_app/domain/repositories/likes_repository.dart';
import 'package:dating_app/data/repositories/likes_repository_impl.dart';
import 'package:dating_app/domain/repositories/comments_repository.dart';
import 'package:dating_app/data/repositories/comments_repository_impl.dart';
import 'package:dating_app/domain/repositories/current_user_post_repository.dart';
import 'package:dating_app/data/repositories/current_user_post_repository_impl.dart';
import 'package:dating_app/domain/repositories/coins_repository.dart';
import 'package:dating_app/presentation/pages/create_account_page.dart';
import 'package:dating_app/presentation/pages/home_page.dart';
import 'package:dating_app/presentation/pages/login_page.dart';
import 'package:dating_app/presentation/pages/splash_screen.dart';
import 'package:dating_app/presentation/pages/reset_password_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // overrides the global 'print' function
  void print(dynamic object) {
    if (kDebugMode) {
      debugPrint(object.toString());
    }
  }

  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();

  AdService.instance.loadRewardedAd();

  await HiveInit.init();

  // Load the .env file
  await dotenv.load(fileName: ".env");

  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }

  final supabaseClient = Supabase.instance.client;

  final userRepository = UserRepositoryImpl(
    remoteDataSource: UserRemoteDataSourceImpl(client: supabaseClient),
  );

  final usersRepository = UsersRepositoryImpl(
    remoteDataSource: UsersRemoteDataSourceImpl(client: supabaseClient),
  );

  final postRepository = PostRepositoryImp(
    remoteDataSource: PostRemoteDataSourceImpl(client: supabaseClient),
  );

  final currentUserPostRepository = CurrentUserPostImp(
    remoteDataSource: PostRemoteDataSourceImpl(client: supabaseClient),
  );

  final commentsRepository = CommentsRepositoryImpl(
    CommentsRemoteDataSourceImpl(supabaseClient),
  );

  final likesRepository = LikeRepositoryImpl(
    remoteDataSource: LikeRemoteDataSourceImpl(supabaseClient),
  );

  final chatRepository = ChatRepositoryImpl(
    ChatRemoteDataSourceImpl(supabaseClient),
  );

  final coinsRepository = CoinsRepositoryImpl(
    CoinsRemoteDataSourceImpl(supabaseClient),
  );

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(client: supabaseClient),
  );

  final imageRepository = ImagesRepositoryImpl(
    ImagesRemoteDataSourceImpl(supabaseClient),
  );

  final notificationsRepository = NotificationRepositoryImp(
    NotificationRemoteDataSourceImpl(supabaseClient),
  );

  final reportsRepository = ReportsRepositoryImpl(
    remoteDataSource: ReportsRemoteDataSourceImp(supabaseClient),
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>(create: (_) => userRepository),
        RepositoryProvider<UsersRepository>(create: (_) => usersRepository),
        RepositoryProvider<PostRepository>(create: (_) => postRepository),
        RepositoryProvider<CurrentUserPostRepository>(
          create: (_) => currentUserPostRepository,
        ),
        RepositoryProvider<CommentsRepository>(
          create: (_) => commentsRepository,
        ),
        RepositoryProvider<LikesRepository>(create: (_) => likesRepository),
        RepositoryProvider<ChatRepository>(create: (_) => chatRepository),
        RepositoryProvider<CoinsRepository>(create: (_) => coinsRepository),
        RepositoryProvider<ImagesRepository>(create: (_) => imageRepository),
        RepositoryProvider<NotificationRepository>(
          create: (_) => notificationsRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository)..add(AuthCheckRequested()),
          ),
          BlocProvider<UserBloc>(
            create: (context) =>
                UserBloc(userRepository)..add(LoadUserSubscription()),
          ),
          BlocProvider<UsersBloc>(
            create: (context) => UsersBloc(usersRepository),
          ),
          BlocProvider<CommentsBloc>(
            create: (context) => CommentsBloc(commentsRepository),
          ),
          BlocProvider<LikesBloc>(
            create: (context) => LikesBloc(likesRepository),
          ),
          BlocProvider<ConversationsBloc>(
            create: (context) =>
                ConversationsBloc(context.read<ChatRepository>()),
          ),
          BlocProvider<DirectPostsBloc>(
            create: (context) =>
                DirectPostsBloc(context.read<PostRepository>()),
          ),
          BlocProvider<CoinsBloc>(
            create: (context) => CoinsBloc(context.read<CoinsRepository>()),
          ),
          BlocProvider<ImagesBloc>(
            create: (context) => ImagesBloc(context.read<ImagesRepository>()),
          ),
          BlocProvider<PostBloc>(
            create: (context) => PostBloc(context.read<PostRepository>()),
          ),
          BlocProvider<ConnectivityBloc>(create: (_) => ConnectivityBloc()),

          //Listen FOR NOTIFICATION
          BlocProvider<NotificationBloc>(
            create: (context) {
              final bloc = NotificationBloc(notificationsRepository);
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                bloc.add(WatchNotifications(user.id));
              }
              return bloc;
            },
          ),
          BlocProvider<BlockUserBloc>(
            create: (context) => BlockUserBloc(reportsRepository),
          ),
          BlocProvider<ReportsBloc>(
            create: (context) => ReportsBloc(reportsRepository),
          )
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _setupAuthStateListener();
  }

  /// One-time utility to promote a specific user to admin using the 'roles' table.


  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Handle link when the app is already running in the background
    _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });

    // 2. Handle link when the app is launched from a terminated state
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleIncomingLink(initialUri);
    }
  }

  void _handleIncomingLink(Uri uri) {
    // Supabase sends the reset token as a hash fragment (e.g., #access_token=...)
    if (uri.fragment.contains('access_token')) {
      print("Detected Auth token in fragment: ${uri.fragment}");
    }
  }

  void _setupAuthStateListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      final _UserRepository = context.read<UserRepository>();

      // 1. Existing Password Reset Logic
      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
        );
      }
      // 2. New Verification/Sign-in Logic
      else if (event == AuthChangeEvent.signedIn && session != null) {
        print("User signed in: ${session.user}");
        final isCompleted = await _UserRepository.checkIsProfileCompleted(session.user.id);
        print("Is profile completed: $isCompleted");

        if (!isCompleted) {
          print("Pushing to CreateAccountProfilePage");
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CreateAccountProfilePage()),
                (route) => false,
          );
        } else {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MyHomePage()),
                (route) => false,
          );
        }
      }
      // 3. Optional: Add SignOut logic here if needed
      else if (event == AuthChangeEvent.signedOut) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class HiveInit {
  HiveInit._();

  static Future<void> init() async {
    await OfflineCache.init();
  }
}
