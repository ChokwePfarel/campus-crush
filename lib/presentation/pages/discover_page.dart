import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/utils/users_skeleton.dart';
import 'package:dating_app/core/utils/warning_bar.dart';
import 'package:dating_app/domain/repositories/users_repository.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/bloc/users/users_bloc.dart';
import 'package:dating_app/presentation/bloc/users/users_event.dart';
import 'package:dating_app/presentation/bloc/users/users_state.dart'
    as users_st;
import 'package:dating_app/presentation/pages/account_suspended.dart';
import 'package:dating_app/presentation/pages/profile_page.dart';
import 'package:dating_app/presentation/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/widgets/users_card.dart';

class DiscoverPage extends StatefulWidget {
  final Function(double)? onScroll;
  final String currentUserId;

  const DiscoverPage({super.key, this.onScroll, required this.currentUserId});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _connectivitySubscription;
  bool _isOffline = false;

  Timer? _debounce;
  String? _currentUniversity;
  String? _currentSex;
  String? _currentSearch;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_scrollListener);

    // Initial check
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        setState(() => _isOffline = results.first == ConnectivityResult.none);
      }
    });

    // Listen for changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final bool offline = results.first == ConnectivityResult.none;
      if (_isOffline && !offline) _triggerLoad(context, isInitial: true);
      if (mounted) setState(() => _isOffline = offline);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userState = context.read<UserBloc>().state;
      if (userState is UserLoaded) {
        _currentUniversity = userState.user.university;
        _currentSex = userState.user.sex;
        _triggerLoad(context, isInitial: true);
      } else {

        context.read<UserBloc>().add(LoadUserSubscription());
      }
    });
  }

  void _scrollListener() {
    if (!mounted) return;

    if (_scrollController.hasClients) {
      widget.onScroll?.call(_scrollController.offset);
    }

    if (!_isOffline &&
        _scrollController.position.pixels >=
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

    ctx.read<UsersBloc>().add(
      LoadUsers(
        university: _currentUniversity!,
        sex: _currentSex!,
        residence: _currentSearch,
        isInitial: isInitial,
      ),
    );
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
        final String profileStatus = userState is UserLoaded
            ? userState.user.profileStatus
            : '';

        final bool isSuspended = profileStatus.contains('suspended');

        if (isSuspended) {
          return const SuspendedPage();
        } else {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Column(
              children: [
                if (_isOffline) _buildOfflineBanner(),
                Expanded(
                  child: BlocListener<UserBloc, UserState>(
                    listenWhen: (previous, current) =>
                        previous is! UserLoaded && current is UserLoaded,
                    listener: (listenerCtx, state) {
                      if (state is UserLoaded && mounted) {
                        _currentUniversity = state.user.university;
                        _currentSex = state.user.sex;
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
                              preferredSize: Size.fromHeight(
                                SizeConfig.heightPercent(8),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: SizeConfig.widthPercent(4),
                                  vertical: SizeConfig.heightPercent(1),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _showWarningBar(profileStatus),
                                    const SizedBox(width: 10),
                                    _profileButton(profileImg),
                                    const SizedBox(width: 10),
                                    _searchField(),
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
                            return _buildErrorState();
                          }

                          if (state is users_st.UsersLoaded) {
                            return _buildUserList(
                              state.users,
                              state.hasReachedMax,
                            );
                          }

                          return const UserListSkeleton();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Text(
        'Connection lost',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildUserList(List<dynamic> users, bool hasReachedMax) {
    if (users.isEmpty) return const Center(child: Text('Data not available.'));
    return RefreshIndicator(
      onRefresh: () async {
        if (_isOffline) return;
        _triggerLoad(context, isInitial: true);
      },
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: hasReachedMax || _isOffline
            ? users.length
            : users.length + 1,
        itemBuilder: (listCtx, index) {
          if (index >= users.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator.adaptive(),
              ),
            );
          }
          return UsersCard(user: users[index], isOffline: _isOffline);
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Connection Error',
            style: TextStyle(fontSize: 14, color: Colors.purple),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () => _triggerLoad(context, isInitial: true),
            child: const Text(
              'Try again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => UsersBloc(context.read<UsersRepository>()),
              child: const SearchPage(),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Icon(
            Icons.search,
            size: SizeConfig.widthPercent(9),
            color: Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _profileButton(String image) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );


      },
      child: CircleAvatar(
        radius: SizeConfig.widthPercent(6),
        backgroundColor: Colors.grey[200],
        backgroundImage:
            !_isOffline && image.isNotEmpty && image.startsWith('http')
            ? NetworkImage(image)
            : const AssetImage('assets/profile_picture.png') as ImageProvider,
        child: _isOffline || image.isEmpty
            ? const Icon(Icons.person, color: Colors.grey)
            : null,
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

  Widget _showWarningBar(String profileStatus) {
    if (profileStatus == 'warned') {
      return const WarningBar();
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

}
