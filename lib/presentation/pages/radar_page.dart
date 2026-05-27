import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dating_app/core/constants/post_constants.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/utils/snackbar.dart';
import 'package:dating_app/data/models/post_model.dart';
import 'package:dating_app/domain/repositories/posts_repository.dart';
import 'package:dating_app/presentation/bloc/conectivity/conectivityBloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_event.dart';
import 'package:dating_app/presentation/bloc/posts/posts_state.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart' as user_st;
import 'package:dating_app/presentation/pages/other_user_profile.dart';
import 'package:dating_app/presentation/pages/spotted_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Bubble position model ────────────────────────────────────────────────────

class _BubbleData {
  final PostModel post;
  final Offset position;
  final double size;
  final Color color;
  final Duration animDelay;

  const _BubbleData({
    required this.post,
    required this.position,
    required this.size,
    required this.color,
    required this.animDelay,
  });
}

const _bubbleColors = [
  Color(0xFF2EC4B6),
  Color(0xFFFF4D6D),
  Color(0xFF6C63FF),
  Color(0xFFFF9F1C),
  Color(0xFF43C59E),
  Color(0xFFE040FB),
];

class RadarPage extends StatefulWidget {
  final void Function(String userId)? onProfileTap;
  final VoidCallback? onCreateSpotted;

  const RadarPage({super.key, this.onProfileTap, this.onCreateSpotted});

  @override
  State<RadarPage> createState() => _RadarPageState();
}

class _RadarPageState extends State<RadarPage> with TickerProviderStateMixin {
  String? _selectedLocation;

  late final _radarCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  late final _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  bool _isOffline = false;
  StreamSubscription? _connectivitySub;

  late final PostBloc _postBloc; // Stable bloc instance

  @override
  void initState() {
    super.initState();
    //Initialting bloc once
    _postBloc = PostBloc(context.read<PostRepository>());

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.first == ConnectivityResult.none;
        });
      }
    });
  }

  @override
  void dispose() {
    _postBloc.close(); // Clean up bloc
    _radarCtrl.dispose();
    _pulseCtrl.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _fetchSpottedPosts() {
    final userState = context.read<UserBloc>().state;
    if (userState is user_st.UserLoaded) {
      _postBloc.add(
        LoadPosts(
          university: userState.user.university,
          postType: 'spotted',
          locationTag: _selectedLocation,
          isInitial: true,
        ),
      );
    }
  }

  void _selectLocation(String location) {
    HapticFeedback.mediumImpact();
    if (_isOffline) {
      AppSnackBar.show(
        context,
        'No internet connection',
        type: SnackBarType.warning,
      );
      return;
    }

    setState(() {
      _selectedLocation = location;
    });
    _fetchSpottedPosts();
  }

  void _navigateToSpottedPage(BuildContext context) {
    final userState = context.read<UserBloc>().state;
    if (userState is user_st.UserLoaded && _selectedLocation != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpottedPage(
            location: _selectedLocation!,
            university: userState.user.university,
          ),
        ),
      );
    }
  }

  List<_BubbleData> _buildBubbles(List<PostModel> posts) {
    if (_selectedLocation == null) return [];
    final rng = Random(_selectedLocation.hashCode);

    // Only show top 5 for radar view
    final displayPosts = posts.take(3).toList();

    final positions = <Offset>[];
    final bubbles = <_BubbleData>[];

    for (var i = 0; i < displayPosts.length; i++) {
      Offset pos;
      int attempts = 0;

      // More generous margins to prevent clipping
      const double leftMargin = 0.15; // 15% from left edge
      const double rightMargin = 0.85; // 85% from left edge (15% from right)
      const double topMargin = 0.18; // 18% from top edge
      const double bottomMargin = 0.82; // 82% from top edge (18% from bottom)

      do {
        final x = leftMargin + rng.nextDouble() * (rightMargin - leftMargin);
        final y = topMargin + rng.nextDouble() * (bottomMargin - topMargin);
        pos = Offset(x, y);
        attempts++;
      } while (attempts < 30 &&
          positions.any((p) => (p - pos).distance < 0.18));

      positions.add(pos);
      bubbles.add(
        _BubbleData(
          post: displayPosts[i],
          position: pos,
          size: 88 + rng.nextDouble() * 28,
          color: _bubbleColors[i % _bubbleColors.length],
          animDelay: Duration(milliseconds: i * 180),
        ),
      );
    }
    return bubbles;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return BlocProvider.value(
      value: _postBloc,
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(child: _RadarBackground(ctrl: _radarCtrl)),

                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: _selectedLocation == null
                            ? _buildLocationPicker(context)
                            : _buildRadarContent(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadarContent(BuildContext context) {
    return BlocBuilder<PostBloc, PostState>(
      builder: (context, state) {
        // Handle loading and initial states
        if (state is LoadingPosts || state is PostInitial) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2EC4B6)),
          );
        }

        // Handle error states
        if (state is PostError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: _fetchSpottedPosts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state is PostsLoaded) {
          final bubbles = _buildBubbles(state.post);

          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Rings always in the background once per select
                  _RadarRings(ctrl: _radarCtrl, pulse: _pulseCtrl),

                  if (bubbles.isEmpty)
                    _buildEmptyRadarMessage()
                  else ...[
                    ...bubbles.map(
                      (b) => _SpottedBubble(
                        data: b,
                        canvasSize: Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showBubbleDetail(b.post);
                        },
                      ),
                    ),
                    _buildCountBadge(context, state.post.length),
                  ],
                ],
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildCountBadge(BuildContext context, int totalCount) {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => _navigateToSpottedPage(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2EC4B6).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF2EC4B6).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$totalCount ${totalCount == 1 ? 'person' : 'people'} spotted',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2EC4B6),
                  ),
                ),
                if (totalCount > 5) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '|  See more >',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2EC4B6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          if (_selectedLocation != null)
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _selectedLocation = null);
              },
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Radar',
                style: TextStyle(
                  fontSize: SizeConfig.widthPercent(6),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                _selectedLocation ?? 'Who\'s around you right now?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildLiveIndicator(),
        ],
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF2EC4B6).withOpacity(0.15),
            const Color(0xFF2EC4B6).withOpacity(0.3),
            _pulseCtrl.value,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2EC4B6).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  const Color(0xFF2EC4B6),
                  Colors.white,
                  _pulseCtrl.value * 0.4,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Text(
              'LIVE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2EC4B6),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPicker(BuildContext context) {
    final grouped = LocationTags.grouped;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.35),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: entry.value.map((tag) {
                return GestureDetector(
                  onTap: () => _selectLocation(tag['label']!),

                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tag['icon']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            tag['label']!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildEmptyRadarMessage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Text(
          'No one spotted here yet',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Be the first to post your outfit!',
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.4)),
        ),
      ],
    );
  }

  void _showBubbleDetail(PostModel post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white10,
                  child: Text(
                    post.isAnonymous ? '🎭' : '👤',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.isAnonymous
                            ? 'Anonymous Student'
                            : post.authorName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'at $_selectedLocation',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              post.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            post.isAnonymous
                ? const SizedBox()
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OtherUserProfilePage(userId: post.userId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2EC4B6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Say Hi',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Animation Components (Painters) ──────────────────────────────────────────

class _RadarBackground extends StatelessWidget {
  final Animation<double> ctrl;

  const _RadarBackground({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, child) =>
          CustomPaint(painter: _RadarBackgroundPainter(progress: ctrl.value)),
    );
  }
}

class _RadarBackgroundPainter extends CustomPainter {
  final double progress;

  _RadarBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RadarRings extends StatelessWidget {
  final Animation<double> ctrl;
  final Animation<double> pulse;

  const _RadarRings({required this.ctrl, required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ctrl, pulse]),
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          // Use the full available space
          final size = constraints.biggest;
          return CustomPaint(
            painter: _RadarRingsPainter(
              progress: ctrl.value,
              pulse: pulse.value,
              canvasSize: size,
            ),
            size: size,
          );
        },
      ),
    );
  }
}

class _RadarRingsPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final Size canvasSize;

  _RadarRingsPainter({
    required this.progress,
    required this.pulse,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = min(canvasSize.width, canvasSize.height) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw rings
    for (int i = 1; i <= 3; i++) {
      paint.color = const Color(
        0xFF2EC4B6,
      ).withOpacity(0.15 - (i * 0.03) + (pulse * 0.08));
      canvas.drawCircle(center, radius * (i / 3), paint);
    }

    // Draw sweep gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF2EC4B6).withOpacity(0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * 2 * pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is _RadarRingsPainter) {
      return progress != oldDelegate.progress ||
          pulse != oldDelegate.pulse ||
          canvasSize != oldDelegate.canvasSize;
    }
    return true;
  }
}

class _SpottedBubble extends StatefulWidget {
  final _BubbleData data;
  final Size canvasSize;
  final VoidCallback onTap;

  const _SpottedBubble({
    required this.data,
    required this.canvasSize,
    required this.onTap,
  });

  @override
  State<_SpottedBubble> createState() => _SpottedBubbleState();
}

class _SpottedBubbleState extends State<_SpottedBubble>
    with SingleTickerProviderStateMixin {
  late final _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final _scaleAnim = CurvedAnimation(
    parent: _animCtrl,
    curve: Curves.elasticOut,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.data.animDelay, () {
      if (mounted) _animCtrl.forward();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final x = widget.data.position.dx * widget.canvasSize.width;
    final y = widget.data.position.dy * widget.canvasSize.height;
    return Positioned(
      left: x - widget.data.size / 2,
      top: y - widget.data.size / 2,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.data.size,
            height: widget.data.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.data.color.withOpacity(0.2),
              border: Border.all(
                color: widget.data.color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.data.color.withOpacity(0.2),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              CircleAvatar(
              radius: widget.data.size * 0.25,
                backgroundColor: Colors.white10,
                backgroundImage: (widget.data.post.profileImageUrl != null &&
                    widget.data.post.profileImageUrl!.startsWith('http') && !widget.data.post.isAnonymous)
                    ? NetworkImage(widget.data.post.profileImageUrl!)
                    : const AssetImage('assets/profile_picture.png'),
              ),
                  const SizedBox(height: 4),
                  Text(
                    widget.data.post.isAnonymous
                        ? 'Anonymous'
                        : (widget.data.post.authorName.split(' ').first),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.data.size * 0.12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
