import 'package:dating_app/core/utils/date_utils.dart';
import 'package:dating_app/core/utils/feed_skeleton.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/posts_repository.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_event.dart';
import 'package:dating_app/presentation/bloc/posts/posts_state.dart';
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SpottedPage extends StatefulWidget {
  final String location;
  final String university;

  const SpottedPage({
    super.key,
    required this.location,
    required this.university,
  });

  @override
  State<SpottedPage> createState() => _SpottedPageState();
}

class _SpottedPageState extends State<SpottedPage> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent * 0.9) {
      final state = context.read<PostBloc>().state;
      if (state is PostsLoaded && !state.hasReachedMax) {
        context.read<PostBloc>().add(LoadPosts(
              university: widget.university,
              postType: 'spotted',
              locationTag: widget.location,
              isInitial: false,
            ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return BlocProvider(
      create: (context) => PostBloc(context.read<PostRepository>())
        ..add(LoadPosts(
          university: widget.university,
          postType: 'spotted',
          locationTag: widget.location,
          isInitial: true,
        )),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spotted at ${widget.location}',
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.university,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        body: BlocBuilder<PostBloc, PostState>(
          builder: (context, state) {
            if (state is LoadingPosts) {
              return const FeedSkeleton();
            }

            if (state is PostsLoaded) {
              final posts = state.post;
              if (posts.isEmpty) {
                return const Center(child: Text('No one else spotted here yet.'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<PostBloc>().add(LoadPosts(
                        university: widget.university,
                        postType: 'spotted',
                        locationTag: widget.location,
                        isInitial: true,
                      ));
                },
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.hasReachedMax ? posts.length : posts.length + 1,
                  itemBuilder: (context, i) {
                    if (i >= posts.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _SpottedListTile(post: posts[i]);
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _SpottedListTile extends StatelessWidget {
  final PostModel post;
  const _SpottedListTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF2EC4B6).withOpacity(0.1),
                backgroundImage: (post.profileImageUrl != null &&
                    post.profileImageUrl!.startsWith('http') && !post.isAnonymous)
                    ? NetworkImage(post.profileImageUrl!)
                    : const AssetImage('assets/profile_picture.png'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.isAnonymous ? 'Someone hidden' : post.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateUtilsHelper.timeAgo(post.createdAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              post.isAnonymous ? const SizedBox() :
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OtherUserProfilePage(userId: post.userId)));
                },
                child: const Text('View', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post.content, style: const TextStyle(fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}
