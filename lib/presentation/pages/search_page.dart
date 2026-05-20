import 'dart:async';

import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/utils/search_skeleton.dart';
import 'package:dating_app/core/widgets/common/users_list_tile.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/bloc/users/users_bloc.dart';
import 'package:dating_app/presentation/bloc/users/users_event.dart';
import 'package:dating_app/presentation/bloc/users/users_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final userState = context.read<UserBloc>().state;
      final usersState = context.read<UsersBloc>().state;
      
      if (userState is UserLoaded && usersState is UsersLoaded && !usersState.hasReachedMax) {
        final query = _searchController.text.trim();
        if (query.isNotEmpty) {
          context.read<UsersBloc>().add(SearchUsers(
                university: userState.user.university,
                query: query.toLowerCase(),
                isInitial: false,
              ));
        }
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final normalizedQuery = query.trim().toLowerCase();
      final userState = context.read<UserBloc>().state;
      if (userState is UserLoaded) {
        if (normalizedQuery.isEmpty) {
          // If query is empty, maybe we want to load default users or show empty state
          // For now, let's just clear or trigger LoadUsers if needed.
          // But according to requirements, we trigger search.
          context.read<UsersBloc>().add(LoadUsers(
            university: userState.user.university,
            sex: userState.user.sex,
            isInitial: true,
          ));
        } else {
          context.read<UsersBloc>().add(SearchUsers(
                university: userState.user.university,
                query: normalizedQuery,
                isInitial: true,
              ));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF1A1A2E)),
        ),

        title: _searchField(),
      ),
      body: BlocBuilder<UsersBloc, UsersState>(
        builder: (context, state) {
          if (state is UsersInitial) {
            return const Center(child: Text('Start searching for friends!'));
          }

          if (state is UsersLoading) {
            return ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) => const UserSkeletonItem(),
            );
          }

          if (state is UsersError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is UsersLoaded) {
            if (state.users.isEmpty) {
              return const Center(child: Text('No users found.'));
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: state.hasReachedMax ? state.users.length : state.users.length + 1,
              itemBuilder: (context, index) {
                if (index >= state.users.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return UsersListTile(user: state.users[index]);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
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
        controller: _searchController,
        onChanged: _onSearchChanged,


        decoration: InputDecoration(
          hintText: 'Search by Name or Residence',
          hintStyle: TextStyle(
            color: Colors.grey,
            fontSize: SizeConfig.widthPercent(3.5),
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: SizeConfig.heightPercent(1.5),
          ),
        ),
      ),
    );
  }
}
