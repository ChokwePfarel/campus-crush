import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/core/utils/match_calculator.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';

class UsersCard extends StatelessWidget {
  final UserModel user;
  final bool isOffline;

  const UsersCard({super.key, required this.user, this.isOffline = false});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherUserProfilePage(userId: user.id),
          ),
        );
      },
      child: Container(
        //margin: const EdgeInsets.fromLTRB(0, 5, 0, 5), // Padding between cards
        child: Container(
          height: SizeConfig.screenHeight * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // --- IMAGE ---
              Positioned.fill(
                child: user.profileImageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: user.profileImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator.adaptive()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 50, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
              ),

              // Match percentage
              Positioned(
                top: 15,
                left: 15,
                child: BlocBuilder<UserBloc, UserState>(
                  builder: (context, state) {
                    if (state is UserLoaded) {
                      final currentUser = state.user as UserModel;
                      final matchPercentage = MatchCalculator.calculateMatchPercentage(
                        currentUser,
                        user,
                      );

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite, color: Colors.pinkAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$matchPercentage% Match',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Content Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.name}, ${user.age}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.apartment, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            user.residence,
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      Text(user.bio, style: const TextStyle(color: Colors.white70, fontSize: 14))
                    ],
                  ),
                ),
              ),

              if (isOffline)
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.cloud_off, color: Colors.white70, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
