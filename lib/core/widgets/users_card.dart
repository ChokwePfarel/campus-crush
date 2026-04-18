
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

  const UsersCard({super.key, required this.user});

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
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            children: [
              // iMAGE
              user.profileImageUrl.startsWith('http')
                  ? Image.network(
                      user.profileImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: SizeConfig.screenHeight * 0.5,
                    )
                  : Image.asset(
                      'assets/Solid_white.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: SizeConfig.screenHeight * 0.5,
                    ),

              // percentage
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
                          border: Border.all(color: Colors.white24),
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

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _textColumn(context),
                      const SizedBox(height: 8),
                      _interestsRow(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${user.name}, ${user.age}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          user.residence,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        if (user.status.isNotEmpty)
          Text(
            user.status,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500),
          ),
      ],
    );
  }

  Widget _interestsRow() {
    return SizedBox(
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: user.interests.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              user.interests[index],
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
