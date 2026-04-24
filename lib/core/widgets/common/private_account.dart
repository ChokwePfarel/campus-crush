import 'package:flutter/material.dart';

class PrivateProfilePage extends StatefulWidget {
  final String username;
  final String? avatarUrl;
  final VoidCallback? onMessagePressed;

  const PrivateProfilePage({
    super.key,
    required this.username,
    this.avatarUrl,
    this.onMessagePressed,
  });

  @override
  State<PrivateProfilePage> createState() => _PrivateProfilePageState();
}

class _PrivateProfilePageState extends State<PrivateProfilePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _lockController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _lockScaleAnimation;
  late Animation<double> _lockBounceAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _lockScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _lockController, curve: Curves.elasticOut),
    );

    _lockBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lockController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _fadeController.forward();
    _lockController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _lockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isDark),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [

                  const SizedBox(height: 24),
                  _buildAvatar(isDark),

                  const SizedBox(height: 16),
                  _buildUsername(isDark),

                  const SizedBox(height: 6),

                  _buildPrivateBadge(isDark),


                  const SizedBox(height: 24),


                  const SizedBox(height: 40),
                  _buildDivider(isDark),

                  const SizedBox(height: 40),
                  _buildLockSection(isDark),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      backgroundColor:
      isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      elevation: 0,
      pinned: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),

    );
  }

  Widget _buildAvatar(bool isDark) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
                  : [const Color(0xFFE0E0E0), const Color(0xFFCCCCCC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              width: 1.5,
            ),
          ),
          child:


          widget.avatarUrl != null


              ? ClipOval(
            child: Image.network(
              widget.avatarUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(isDark),
            ),
          )
              : _buildAvatarPlaceholder(isDark),
        ),
        // Lock overlay on avatar
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.lock_rounded,
            size: 14,
            color: isDark ? Colors.white60 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(bool isDark) {
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: 48,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }

  Widget _buildUsername(bool isDark) {
    return Text(
      widget.username,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildPrivateBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_rounded,
            size: 12,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          const SizedBox(width: 5),
          Text(
            'Private account',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? Colors.white10 : Colors.black,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockSection(bool isDark) {
    return Column(
      children: [
        ScaleTransition(
          scale: _lockScaleAnimation,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.04),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 32,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'This account is private',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),

      ],
    );
  }

}


