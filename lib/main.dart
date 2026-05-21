import 'package:dating_app/core/services/ad_service.dart';
import 'package:dating_app/core/utils/offline_cache.dart';
import 'package:dating_app/data/datasources/auth_remote_data_source.dart';
import 'package:dating_app/data/datasources/chat_remote_data_source.dart';
import 'package:dating_app/data/datasources/coins_remote_data_source.dart';
import 'package:dating_app/data/datasources/comment_remote_data_source.dart';
import 'package:dating_app/data/datasources/image_remote_data_source.dart';
import 'package:dating_app/data/datasources/likes_remote_data_source.dart';
import 'package:dating_app/data/datasources/post_remote_data_source.dart';
import 'package:dating_app/data/datasources/user_remote_data_source.dart';
import 'package:dating_app/data/datasources/users_remote_data_source.dart';
import 'package:dating_app/data/repositories/auth_repository_impl.dart';
import 'package:dating_app/data/repositories/chat_repository_impl.dart';
import 'package:dating_app/data/repositories/coins_repository_impl.dart';
import 'package:dating_app/data/repositories/image_repository_impl.dart';
import 'package:dating_app/data/repositories/posts_repository_impl.dart';
import 'package:dating_app/data/repositories/user_repository_impl.dart';
import 'package:dating_app/data/repositories/users_repository_impl.dart';
import 'package:dating_app/domain/repositories/chat_repository.dart';
import 'package:dating_app/domain/repositories/image_repository.dart';
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
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
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
import 'package:dating_app/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await MobileAds.instance.initialize();
  AdService.instance.loadRewardedAd();

  await HiveInit.init();

  // Load the .env file
  await dotenv.load(fileName: ".env");


  try {

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_SERVICE_ROLE_KEY']!,
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

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserRepository>(create: (_) => userRepository),
        RepositoryProvider<UsersRepository>(create: (_) => usersRepository),
        RepositoryProvider<PostRepository>(create: (_) => postRepository),
        RepositoryProvider<CurrentUserPostRepository>(
          create: (_) => currentUserPostRepository,
        ),
        RepositoryProvider<CommentsRepository>(create: (_) => commentsRepository,
        ),
        RepositoryProvider<LikesRepository>(create: (_) => likesRepository),
        RepositoryProvider<ChatRepository>(create: (_) => chatRepository),
        RepositoryProvider<CoinsRepository>(create: (_) => coinsRepository),
        RepositoryProvider<ImagesRepository>(create: (_) => imageRepository),
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

          BlocProvider(
            create: (_) => ConnectivityBloc(),
            child: MyApp(),
          ),

        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
