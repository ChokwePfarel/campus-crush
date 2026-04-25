import 'package:dating_app/core/utils/other_user_profile_skeleton.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/core/widgets/common/private_account.dart';
import 'package:dating_app/data/datasources/image_remote_data_source.dart';
import 'package:dating_app/data/repositories/image_repository_impl.dart';
import 'package:dating_app/domain/repositories/users_repository.dart';
import 'package:dating_app/presentation/bloc/image/image_bloc.dart';
import 'package:dating_app/presentation/bloc/image/image_event.dart';
import 'package:dating_app/presentation/bloc/image/image_sate.dart';
import 'package:dating_app/presentation/bloc/otheruser/otheruser_bloc.dart';
import 'package:dating_app/presentation/bloc/otheruser/otheruser_event.dart';
import 'package:dating_app/presentation/bloc/otheruser/otheruser_state.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_event.dart';
import 'package:dating_app/presentation/bloc/conversation/conversation_state.dart';
import 'package:dating_app/presentation/pages/chat_page.dart';
import 'package:dating_app/presentation/pages/full_screen.dart';
import 'package:dating_app/presentation/pages/send_post_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtherUserProfilePage extends StatelessWidget {
  final String userId;

  const OtherUserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final color = AppStylee.collor;
    final currentUserId = Supabase.instance.client.auth.currentUser!.id;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => OtherUserBloc(context.read<UsersRepository>())
            ..add(FetchOtherUserRequested(userId)),
        ),
        BlocProvider(
          create: (context) => ImagesBloc(
            ImagesRepositoryImpl(
              ImagesRemoteDataSourceImpl(Supabase.instance.client),
            ),
          ),
        ),
      ],
      child: BlocListener<ConversationsBloc, ConversationsState>(
        listener: (context, state) {
          if (state is ConversationReady) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  conversation: state.conversation,
                  currentUserId: currentUserId,
                ),
              ),
            );
          } else if (state is ConversationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: BlocBuilder<OtherUserBloc, OtherUserState>(
            builder: (context, state) {
              if (state is OtherUserLoading) {
                return const Center(child: CircularProgressIndicator.adaptive());
              }

              if (state is OtherUserError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<OtherUserBloc>().add(
                                FetchOtherUserRequested(userId),
                              );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is OtherUserLoaded) {
                final user = state.user;

                // --- CHECK PRIVACY SETTINGS ---
                if (user.privacySettings.isProfilePrivate) {
                  return PrivateProfilePage(
                    username: user.name,
                    avatarUrl: user.profileImageUrl,
                    onMessagePressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => SendPostPage(recipient: user),
                        ),
                      );
                    },
                  );
                }

                context.read<ImagesBloc>().add(LoadUserImages(user.id));

                return Stack(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── Header Image ───
                          Stack(
                            children: [
                              Container(
                                height: SizeConfig.heightPercent(50),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: user.profileImageUrl.isNotEmpty
                                        ? NetworkImage(user.profileImageUrl)
                                        : const AssetImage(
                                            'assets/Solid_white.png',
                                          ) as ImageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: SizeConfig.heightPercent(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.widthPercent(5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${user.name}, ${user.age}",
                                      style: TextStyle(
                                        fontSize: SizeConfig.widthPercent(7),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (user.isVerified) ...[
                                      SizedBox(
                                        width: SizeConfig.widthPercent(2),
                                      ),
                                      Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: SizeConfig.widthPercent(6),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  user.major,
                                  style: TextStyle(
                                    fontSize: SizeConfig.widthPercent(4.5),
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (user.privacySettings.showUniversity)
                                  Text(
                                    user.university,
                                    style: TextStyle(
                                      fontSize: SizeConfig.widthPercent(3.5),
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                SizedBox(height: SizeConfig.heightPercent(2)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: SizeConfig.widthPercent(3),
                                    vertical: SizeConfig.heightPercent(0.5),
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      SizeConfig.widthPercent(2),
                                    ),
                                  ),
                                  child: Text(
                                    user.status,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: SizeConfig.widthPercent(3),
                                    ),
                                  ),
                                ),
                                SizedBox(height: SizeConfig.heightPercent(3)),
                                Text(
                                  'About Me',
                                  style: TextStyle(
                                    fontSize: SizeConfig.widthPercent(5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: SizeConfig.heightPercent(1)),
                                Text(
                                  user.bio.isNotEmpty
                                      ? user.bio
                                      : "This user hasn't added a bio yet.",
                                  style: TextStyle(
                                    fontSize: SizeConfig.widthPercent(4),
                                    height: 1.4,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: SizeConfig.heightPercent(3)),
                                Text(
                                  'Interests',
                                  style: TextStyle(
                                    fontSize: SizeConfig.widthPercent(5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: SizeConfig.heightPercent(1.5)),
                                Wrap(
                                  spacing: SizeConfig.widthPercent(2),
                                  runSpacing: SizeConfig.widthPercent(2),
                                  children: user.interests.map((interest) {
                                    return Chip(
                                      backgroundColor: Colors.grey[100],
                                      side: BorderSide.none,
                                      label: Text(
                                        interest,
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: SizeConfig.widthPercent(
                                            3.2,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                SizedBox(height: SizeConfig.heightPercent(3)),

                                BlocBuilder<ImagesBloc, ImagesState>(
                                  builder: (context, imageState) {
                                    if (imageState is ImagesLoading ||
                                        imageState is ImagesInitial) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    final images = imageState is ImagesLoaded
                                        ? imageState.galleryImages
                                        : [];

                                    if (images.isEmpty) {
                                      return const SizedBox.shrink();
                                    }

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Gallery',
                                          style: TextStyle(
                                            fontSize: SizeConfig.widthPercent(
                                              5,
                                            ),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(
                                          height: SizeConfig.heightPercent(1.5),
                                        ),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 2,
                                                crossAxisSpacing:
                                                    SizeConfig.widthPercent(3),
                                                mainAxisSpacing:
                                                    SizeConfig.widthPercent(3),
                                                childAspectRatio: 0.8,
                                              ),
                                          itemCount: images.length,
                                          itemBuilder: (context, index) {
                                            return ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    SizeConfig.widthPercent(4),
                                                  ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          FullScreenPage(
                                                            images: images.map((e) => e.url).toList(),
                                                            initialIndex: index,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                child: Image.network(
                                                  images[index].url,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                SizedBox(height: SizeConfig.heightPercent(15)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: SizeConfig.widthPercent(5),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.3),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: SizeConfig.heightPercent(3),
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _circularActionButton(
                            icon: CupertinoIcons.xmark,
                            color: Colors.redAccent,
                            onTap: () => Navigator.pop(context),
                          ),
                          SizedBox(width: SizeConfig.widthPercent(8)),
                          _circularActionButton(
                            icon: CupertinoIcons.heart_fill,
                            color: Colors.pinkAccent,
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => SendPostPage(recipient: user),
                                ),
                              );
                            },
                            isLarge: true,
                          ),
                          SizedBox(width: SizeConfig.widthPercent(8)),
                          _circularActionButton(
                            icon: CupertinoIcons.chat_bubble_fill,
                            color: Colors.blueAccent,
                            onTap: () {
                              context.read<ConversationsBloc>().add(
                                    OpenOrCreateConversation(
                                      currentUserId: currentUserId,
                                      otherUserId: user.id,
                                    ),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: Text('Loading profile...'));
            },
          ),
        ),
      ),
    );
  }

  Widget _circularActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    final double size =
        isLarge ? SizeConfig.widthPercent(18) : SizeConfig.widthPercent(14);
    final double iconSize =
        isLarge ? SizeConfig.widthPercent(8) : SizeConfig.widthPercent(6);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
