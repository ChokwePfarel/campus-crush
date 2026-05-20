import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UsersListTile extends StatelessWidget {

  final UserModel user;

  const UsersListTile({required this.user,super.key});

  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherUserProfilePage(userId: user.id),
          ),
        );
      },

      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: user.profileImageUrl.startsWith('http')
                ? NetworkImage(user.profileImageUrl)
                : const AssetImage('assets/profile_picture.png') as ImageProvider,
          ),

          title: Text(user.name,style: TextStyle(fontWeight: FontWeight.bold),),
          subtitle: Text(user.residence),
        ),
      ),
    );
  }
}
