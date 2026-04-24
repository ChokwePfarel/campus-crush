import 'dart:async';

import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/utils/users_skeleton.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/bloc/users/users_bloc.dart';
import 'package:dating_app/presentation/bloc/users/users_event.dart';
import 'package:dating_app/presentation/bloc/users/users_state.dart' as users_st;
import 'package:dating_app/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/users_card.dart';

class DiscoverPage extends StatefulWidget {
  final Function(bool)? onScrollDirectionChanged;

  const DiscoverPage({super.key, this.onScrollDirectionChanged});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final ScrollController _scrollController = ScrollController();

  Timer? _debounce;

  String? _currentUniversity;
  String? _currentSex;
  String? _currentSearch;
  String? _currenUserId;


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    
    // Initial fetch after first frame to avoid build-phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userState = context.read<UserBloc>().state;
      if (userState is UserLoaded) {
        _currentUniversity = userState.user.university;
        _currentSex = userState.user.sex;
        _currenUserId = userState.user.id;
        _triggerLoad(context, isInitial: true);
      }
    });
  }

  void _scrollListener() {
    if (!mounted) return;
    
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      widget.onScrollDirectionChanged?.call(false);
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      widget.onScrollDirectionChanged?.call(true);
    }

    // Pagination trigger
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final state = context.read<UsersBloc>().state;
      if (state is users_st.UsersLoaded && !state.hasReachedMax) {
        _triggerLoad(context);
      }
    }
  }

  void _triggerLoad(BuildContext ctx, {bool isInitial = false}) {
    if (!mounted) return;
    if (_currentUniversity == null || _currentSex == null) return;

    // Use the passed context to ensure we are using a valid element in the tree
    ctx.read<UsersBloc>().add(
      LoadUsers(
        university: _currentUniversity!,
        sex: _currentSex!,
        residence: _currentSearch,
        isInitial: isInitial,
      ),
    );
  }

  void _onSearchChanged(String value) {
    _currentSearch = value;

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _triggerLoad(context, isInitial: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return BlocBuilder<UserBloc, UserState>(
      builder: (builderCtx, userState) {
        String profileImg = '';
        if (userState is UserLoaded) {
          profileImg = userState.user.profileImageUrl;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: BlocListener<UserBloc, UserState>(
            listenWhen: (previous, current) =>
                previous is! UserLoaded && current is UserLoaded,
            listener: (listenerCtx, state) {
              if (state is UserLoaded && mounted) {
                _currentUniversity = state.user.university;
                _currentSex = state.user.sex;
                // Use listenerCtx which is guaranteed to be active during this callback
                _triggerLoad(listenerCtx, isInitial: true);
              }
            },
            child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (headerCtx, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    centerTitle: true,
                    title: _appName(),
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(SizeConfig.heightPercent(8)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.widthPercent(4),
                          vertical: SizeConfig.heightPercent(1),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _searchField()),
                            const SizedBox(width: 12),
                            _profileButton(profileImg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: BlocBuilder<UsersBloc, users_st.UsersState>(
                builder: (usersBuilderCtx, state) {
                  if (state is users_st.UsersLoading) {
                    return const UserListSkeleton();
                  }

                  if (state is users_st.UsersError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }

                  if (state is users_st.UsersLoaded) {
                    final users = state.users;

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'No users found matching your university',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        if (!mounted) return;
                        _triggerLoad(context, isInitial: true);
                      },
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: state.hasReachedMax
                            ? users.length
                            : users.length + 1,
                        itemBuilder: (listCtx, index) {
                          if (index >= users.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          return UsersCard(user: users[index]);
                        },
                      ),
                    );
                  }

                  return const UserListSkeleton();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _searchField() {
    return Container(
      height: SizeConfig.heightPercent(5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(SizeConfig.widthPercent(10)),
      ),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search by Residence',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: SizeConfig.widthPercent(3.5),
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: SizeConfig.heightPercent(1.5),
          ),
        ),
        textAlignVertical: TextAlignVertical.center, // ensures vertical centering
      ),
    );
  }

  Widget _profileButton(String image,) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfilePage(
          )),
        );
      },
      child: CircleAvatar(
        radius: SizeConfig.widthPercent(5),
        backgroundColor: Colors.grey[200],
        backgroundImage: image.startsWith('http')
            ? NetworkImage(image)
            : const AssetImage('assets/profile_picture.png') as ImageProvider,
      ),
    );
  }

  Widget _appName() {
    return Text(
      'CampusCrush',
      style: GoogleFonts.dancingScript(
        textStyle: TextStyle(
          fontSize: SizeConfig.widthPercent(9),
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
