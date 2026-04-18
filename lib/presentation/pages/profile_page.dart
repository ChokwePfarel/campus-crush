import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/data/datasources/image_remote_data_source.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/data/repositories/image_repository_impl.dart';
import 'package:dating_app/domain/entities/image_entity.dart';
import 'package:dating_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:dating_app/presentation/bloc/auth/auth_event.dart';
import 'package:dating_app/presentation/bloc/image/image_bloc.dart';
import 'package:dating_app/presentation/bloc/image/image_event.dart';
import 'package:dating_app/presentation/bloc/image/image_sate.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/pages/full_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'profile_edit.dart';

class ProfilePage extends StatelessWidget {


  const ProfilePage({super.key,});

  void _confirmDeleteImage(BuildContext context, UserImageEntity image) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ImagesBloc>().add(
                DeleteImage(
                  imageId: image.id,
                  path:    image.path,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final color = Colors.purple;

    return BlocProvider(
      create: (_) => ImagesBloc(
        ImagesRepositoryImpl(
          ImagesRemoteDataSourceImpl(Supabase.instance.client),
        ),
      ),
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is UserError) {
            return Scaffold(body: Center(child: Text('Error: ${state.message}')));
          }

          if (state is UserLoaded) {
            // Cast UserEntity to UserModel to access all fields
            final user = state.user as UserModel;

            context.read<ImagesBloc>().add(LoadUserImages(user.id));


            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'My Profile',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.expand_more, color: Colors.black),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        SizeConfig.widthPercent(3),
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileEdit(user: user),
                          ),
                        );
                      } else if (value == 'logout') {
                        _showLogoutDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit Profile'),
                      ),
                      const PopupMenuItem(value: 'logout', child: Text('Logout')),
                    ],
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.widthPercent(5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.heightPercent(2)),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: SizeConfig.widthPercent(18),
                            backgroundColor: color.withOpacity(0.1),
                            backgroundImage: user.profileImageUrl.isNotEmpty
                                ? NetworkImage(user.profileImageUrl)
                                : null,
                            child: user.profileImageUrl.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: SizeConfig.widthPercent(18),
                                    color: color,
                                  )
                                : null,
                          ),
                          if (user.isVerified)
                            Positioned(
                              bottom: SizeConfig.heightPercent(0.5),
                              right: SizeConfig.widthPercent(1),
                              child: Container(
                                padding: EdgeInsets.all(
                                  SizeConfig.widthPercent(1),
                                ),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: SizeConfig.widthPercent(4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.heightPercent(2.5)),
                    Text(
                      "${user.name}, ${user.age}",
                      style: TextStyle(
                        fontSize: SizeConfig.widthPercent(6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.status,
                      style: TextStyle(
                        fontSize: SizeConfig.widthPercent(4.5),
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      user.university,
                      style: TextStyle(
                        fontSize: SizeConfig.widthPercent(3.5),
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: SizeConfig.heightPercent(2.5)),
                    _verificationRow(user),
                    SizedBox(height: SizeConfig.heightPercent(3)),
                    Text(
                      'About Me',
                      style: TextStyle(
                        fontSize: SizeConfig.widthPercent(5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: SizeConfig.heightPercent(1)),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(SizeConfig.widthPercent(4)),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(
                          SizeConfig.widthPercent(4),
                        ),
                      ),
                      child: Text(
                        user.bio.isNotEmpty ? user.bio : "No bio provided yet.",
                        style: TextStyle(
                          fontSize: SizeConfig.widthPercent(3.8),
                          height: 1.4,
                        ),
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
                    SizedBox(height: SizeConfig.heightPercent(1)),
                    Card(
                      elevation: 0,
                      color: color.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          SizeConfig.widthPercent(4),
                        ),
                        side: BorderSide(color: color.withOpacity(0.1)),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(SizeConfig.widthPercent(4)),
                        child: Wrap(
                          spacing: SizeConfig.widthPercent(2),
                          runSpacing: SizeConfig.widthPercent(2),
                          children: user.interests.map((interest) {
                            return Chip(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: color.withOpacity(0.2)),
                              label: Text(
                                interest,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: SizeConfig.widthPercent(3.2),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.heightPercent(3)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: SizeConfig.widthPercent(5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        TextButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );

                            if (picked == null || !context.mounted) return;

                            context.read<ImagesBloc>().add(
                              UploadGalleryImage(
                                userId: user.id,
                                image:  File(picked.path),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: Text(
                            'Photos',
                            style: TextStyle(
                              fontSize: SizeConfig.widthPercent(5),
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.heightPercent(1.5)),

                    BlocBuilder<ImagesBloc, ImagesState>(
                      builder: (context, imageState) {
                        // Still uploading — show loading indicator
                        if (imageState is ImagesUploading) {

                          return const Center(child: CircularProgressIndicator());
                        }

                        final images = imageState is ImagesLoaded
                            ? imageState.galleryImages
                            : [];

                        if (images.isEmpty) {
                          return Center(
                            child: Text(
                              'No photos yet. Tap + to add some.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: SizeConfig.widthPercent(3.5),
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: SizeConfig.widthPercent(2.5),
                            mainAxisSpacing: SizeConfig.widthPercent(2.5),
                          ),
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final image = images[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(
                                SizeConfig.widthPercent(3),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FullScreenPage(
                                        images: images.map((e) => e.url).toList(),
                                        initialIndex: index,
                                      ),
                                    ),
                                  );
                                },
                                onLongPress: () => _confirmDeleteImage(context, image),
                                child: Image.network(
                                  image.url,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    SizedBox(height: SizeConfig.heightPercent(5)),
                  ],
                ),
              ),
            );
          }
          return const Scaffold(body: Center(child: Text('No user data found.')));
        },
      ),
    );
  }

  Widget _verificationRow(UserModel user) {
    final color = user.isVerified ? Colors.blue : Colors.grey;
    return Container(
      padding: EdgeInsets.all(SizeConfig.widthPercent(3)),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3)),
      ),
      child: Row(
        children: [
          Icon(Icons.school, color: color, size: SizeConfig.widthPercent(6)),
          SizedBox(width: SizeConfig.widthPercent(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.isVerified ? 'Verified Student' : 'Identity Unverified',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: SizeConfig.widthPercent(3.8),
                  ),
                ),
                Text(
                  user.isVerified
                      ? 'Official student at ${user.university}'
                      : 'Connect with a university email to verify.',
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(3.2),
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          backgroundColor: Colors.white,
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),

            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: const Text(
                'YES',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
