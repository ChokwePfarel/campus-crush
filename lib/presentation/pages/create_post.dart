import 'package:dating_app/core/constants/post_constants.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_event.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart' as user_st;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Main Screen ─────────────────────────────────────────────────────────────

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with TickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  PostType _postType = PostType.general;
  bool _isAnonymous = false;
  bool _isPosting = false;
  Color? _bgColor;
  String? _locationTag;

  final _contentCtrl = TextEditingController();
  final _focusNode = FocusNode();
  late final _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  bool get _canPost {
    final hasContent = _contentCtrl.text.trim().isNotEmpty;
    final needsLocation = _postType == PostType.spotted;
    return hasContent && (!needsLocation || _locationTag != null);
  }

  Color get _accentColor => _postType.color;

  bool get _darkBg => _bgColor != null && _bgColor!.computeLuminance() < 0.3;

  Color get _textColor => _darkBg ? Colors.white : const Color(0xFF1A1A2E);

  // ── actions ────────────────────────────────────────────────────────────────

  void _selectPostType(PostType type) {
    HapticFeedback.selectionClick();
    setState(() {
      _postType = type;
      if (type != PostType.spotted) _locationTag = null;
    });
  }

  void _toggleAnonymous() {
    HapticFeedback.lightImpact();
    setState(() => _isAnonymous = !_isAnonymous);
  }

  void _selectBgColor(Color? color) {
    HapticFeedback.selectionClick();
    setState(() => _bgColor = color);
  }

  Future<void> _handlePost() async {
    if (!_canPost || _isPosting) return;
    HapticFeedback.mediumImpact();

    final userState = context.read<UserBloc>().state;
    if (userState is! user_st.UserLoaded) return;

    setState(() => _isPosting = true);

    // Spotted posts usually expire after 24 hours
   ///Without .toUtc(), the stored time will be 2 hours ahead of local time (SAST),
    /// which is actually 4 hours ahead of UTC — so posts would expire 4 hours after
    /// creation instead of 2.
    final DateTime? expiresAt = _postType == PostType.spotted
        ? DateTime.now().toUtc().add(const Duration(hours: 2))
        : null;

    context.read<PostBloc>().add(CreatePostRequested(
          content: _contentCtrl.text.trim(),
          university: userState.user.university,
          backgroundColor: _bgColor ?? _postType.color,
          authorName: userState.user.name,
          isAnonymous: _isAnonymous,
          postType: _postType.name,
          locationTag: _locationTag,
          expiresAt: expiresAt,
          isNormalPost: true,
        ));

    // Assume success or handle state in listener
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.of(context).pop();
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationPickerSheet(
        selected: _locationTag,
        onSelected: (tag) {
          setState(() => _locationTag = tag);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showBgColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BgColorPickerSheet(
        selected: _bgColor,
        onSelected: (color) {
          _selectBgColor(color);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(SizeConfig.widthPercent(5), 0,
                    SizeConfig.widthPercent(5), SizeConfig.heightPercent(3)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: SizeConfig.heightPercent(2)),
                    _buildPostTypePicker(),
                    SizedBox(height: SizeConfig.heightPercent(2.5)),
                    _buildContentCard(),
                    SizedBox(height: SizeConfig.heightPercent(2)),
                    if (_postType == PostType.spotted) ...[
                      _buildLocationSelector(),
                      SizedBox(height: SizeConfig.heightPercent(2)),
                    ],
                    _buildOptionsRow(),
                    SizedBox(height: SizeConfig.heightPercent(3.5)),
                    _buildPostButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + SizeConfig.heightPercent(1),
        left: SizeConfig.widthPercent(2),
        right: SizeConfig.widthPercent(5),
        bottom: SizeConfig.heightPercent(1.5),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: const Color(0xFF1A1A2E),
          ),
          SizedBox(width: SizeConfig.widthPercent(1)),
          Text(
            'Create Post',
            style: TextStyle(
              fontSize: SizeConfig.widthPercent(5),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _canPost ? _accentColor : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(SizeConfig.widthPercent(5)),
            ),
            child: TextButton(
              onPressed: _canPost ? _handlePost : null,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.widthPercent(5),
                    vertical: SizeConfig.heightPercent(1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.widthPercent(5)),
                ),
              ),
              child: _isPosting
                  ? SizedBox(
                      width: SizeConfig.widthPercent(4),
                      height: SizeConfig.widthPercent(4),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Post',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.widthPercent(3.8),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Post Type Picker ───────────────────────────────────────────────────────

  Widget _buildPostTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post type',
          style: TextStyle(
            fontSize: SizeConfig.widthPercent(3.2),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8E8E9A),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: SizeConfig.heightPercent(1.2)),
        Row(
          children: PostType.values.map((type) {
            final selected = _postType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => _selectPostType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: SizeConfig.widthPercent(2)),
                  padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.heightPercent(1.2)),
                  decoration: BoxDecoration(
                    color: selected ? type.color : Colors.white,
                    borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3)),
                    border: Border.all(
                      color: selected ? type.color : const Color(0xFFE8E8F0),
                      width: 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: type.color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(type.emoji,
                          style:
                              TextStyle(fontSize: SizeConfig.widthPercent(4.5))),
                      SizedBox(height: SizeConfig.heightPercent(0.5)),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: SizeConfig.widthPercent(2.8),
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF8E8E9A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Content Card ───────────────────────────────────────────────────────────

  Widget _buildContentCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: _bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.widthPercent(5)),
        border: Border.all(
          color: _bgColor != null ? Colors.transparent : const Color(0xFFE8E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.widthPercent(4),
                SizeConfig.heightPercent(2), SizeConfig.widthPercent(4), 0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: SizeConfig.widthPercent(10),
                  height: SizeConfig.widthPercent(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAnonymous
                        ? const Color(0xFF8E8E9A)
                        : _accentColor.withOpacity(0.15),
                    border: Border.all(
                      color: _isAnonymous
                          ? Colors.white.withOpacity(0.15)
                          : _accentColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isAnonymous ? '🎭' : '👤',
                      style: TextStyle(fontSize: SizeConfig.widthPercent(4.5)),
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.widthPercent(2.5)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAnonymous ? 'Anonymous' : 'You',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: SizeConfig.widthPercent(3.8),
                        color: _textColor,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.widthPercent(2),
                              vertical: SizeConfig.heightPercent(0.3)),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_postType.emoji} ${_postType.label}',
                            style: TextStyle(
                              fontSize: SizeConfig.widthPercent(2.8),
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(SizeConfig.widthPercent(4),
                SizeConfig.heightPercent(1.5), SizeConfig.widthPercent(4), SizeConfig.heightPercent(2)),
            child: TextField(
              controller: _contentCtrl,
              focusNode: _focusNode,
              maxLines: 6,
              minLines: 4,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: SizeConfig.widthPercent(4),
                height: 1.5,
                color: _textColor,
              ),
              decoration: InputDecoration(
                hintText: _postType.hint,
                hintStyle: TextStyle(
                  color: _darkBg ? Colors.white54 : const Color(0xFFB0B0C0),
                  fontSize: SizeConfig.widthPercent(4),
                ),
                border: InputBorder.none,
                counterStyle: TextStyle(
                  color: _darkBg ? Colors.white54 : const Color(0xFFB0B0C0),
                  fontSize: SizeConfig.widthPercent(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Location Selector ──────────────────────────────────────────────────────

  Widget _buildLocationSelector() {
    return GestureDetector(
      onTap: _showLocationPicker,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.widthPercent(4),
            vertical: SizeConfig.heightPercent(1.8)),
        decoration: BoxDecoration(
          color: _locationTag != null
              ? const Color(0xFF2EC4B6).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(SizeConfig.widthPercent(4)),
          border: Border.all(
            color: _locationTag != null
                ? const Color(0xFF2EC4B6)
                : const Color(0xFFE8E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(SizeConfig.widthPercent(2)),
              decoration: BoxDecoration(
                color: const Color(0xFF2EC4B6).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('📍',
                  style: TextStyle(fontSize: SizeConfig.widthPercent(4.5))),
            ),
            SizedBox(width: SizeConfig.widthPercent(3)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Where are you right now?',
                    style: TextStyle(
                      fontSize: SizeConfig.widthPercent(3),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E8E9A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _locationTag ?? 'Select a location  (required)',
                    style: TextStyle(
                      fontSize: SizeConfig.widthPercent(3.8),
                      fontWeight: FontWeight.w600,
                      color: _locationTag != null
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFB0B0C0),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _locationTag != null
                  ? const Color(0xFF2EC4B6)
                  : const Color(0xFFB0B0C0),
            ),
          ],
        ),
      ),
    );
  }

  // ── Options Row ────────────────────────────────────────────────────────────

  Widget _buildOptionsRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _toggleAnonymous,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.widthPercent(3.5),
                  vertical: SizeConfig.heightPercent(1.5)),
              decoration: BoxDecoration(
                color: _isAnonymous ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius:
                    BorderRadius.circular(SizeConfig.widthPercent(3.5)),
                border: Border.all(
                  color: _isAnonymous
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFE8E8F0),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isAnonymous ? '🎭' : '👤',
                    style: TextStyle(fontSize: SizeConfig.widthPercent(4)),
                  ),
                  SizedBox(width: SizeConfig.widthPercent(2)),
                  Text(
                    _isAnonymous ? 'Anonymous' : 'Public',
                    style: TextStyle(
                      fontSize: SizeConfig.widthPercent(3.2),
                      fontWeight: FontWeight.w700,
                      color: _isAnonymous ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: SizeConfig.widthPercent(2.5)),
        GestureDetector(
          onTap: _showBgColorPicker,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.widthPercent(3.5),
                vertical: SizeConfig.heightPercent(1.5)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(SizeConfig.widthPercent(3.5)),
              border: Border.all(
                color: _bgColor != null ? _bgColor! : const Color(0xFFE8E8F0),
                width: _bgColor != null ? 2 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: SizeConfig.widthPercent(4.5),
                  height: SizeConfig.widthPercent(4.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _bgColor ?? const Color(0xFFE8E8F0),
                    border: Border.all(
                      color: Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.widthPercent(2)),
                Text(
                  'Background',
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(3.2),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Post Button ────────────────────────────────────────────────────────────

  Widget _buildPostButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: SizeConfig.heightPercent(7),
      decoration: BoxDecoration(
        gradient: _canPost
            ? LinearGradient(
                colors: [_accentColor, _accentColor.withOpacity(0.8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: _canPost ? null : const Color(0xFFE8E8F0),
        borderRadius: BorderRadius.circular(SizeConfig.widthPercent(4)),
        boxShadow: _canPost
            ? [
                BoxShadow(
                  color: _accentColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : [],
      ),
      child: TextButton(
        onPressed: _canPost ? _handlePost : null,
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SizeConfig.widthPercent(4)),
          ),
        ),
        child: _isPosting
            ? SizedBox(
                width: SizeConfig.widthPercent(5.5),
                height: SizeConfig.widthPercent(5.5),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _postType.emoji,
                    style: TextStyle(fontSize: SizeConfig.widthPercent(4.5)),
                  ),
                  SizedBox(width: SizeConfig.widthPercent(2.5)),
                  Text(
                    _canPost
                        ? 'Post ${_postType.label}'
                        : _postType == PostType.spotted && _locationTag == null
                            ? 'Select a location to post'
                            : 'Write something to post',
                    style: TextStyle(
                      fontSize: SizeConfig.widthPercent(4),
                      fontWeight: FontWeight.w700,
                      color: _canPost ? Colors.white : const Color(0xFFB0B0C0),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Location Picker Bottom Sheet ────────────────────────────────────────────

class _LocationPickerSheet extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _LocationPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = LocationTags.grouped;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(SizeConfig.widthPercent(6))),
      ),
      constraints: BoxConstraints(
        maxHeight: SizeConfig.heightPercent(75),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: EdgeInsets.only(
                  top: SizeConfig.heightPercent(1.5),
                  bottom: SizeConfig.heightPercent(1)),
              width: SizeConfig.widthPercent(9),
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDE8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                SizeConfig.widthPercent(5),
                SizeConfig.heightPercent(0.5),
                SizeConfig.widthPercent(5),
                SizeConfig.heightPercent(1.5)),
            child: Row(
              children: [
                Text('📍',
                    style: TextStyle(fontSize: SizeConfig.widthPercent(5.5))),
                SizedBox(width: SizeConfig.widthPercent(2.5)),
                Text(
                  'Where are you right now?',
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(4.5),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8E8F0)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(bottom: SizeConfig.heightPercent(3)),
              children: grouped.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          SizeConfig.widthPercent(5),
                          SizeConfig.heightPercent(2.5),
                          SizeConfig.widthPercent(5),
                          SizeConfig.heightPercent(1)),
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: SizeConfig.widthPercent(3),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8E8E9A),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    ...entry.value.map((tag) {
                      final isSelected = selected == tag['label'];
                      return GestureDetector(
                        onTap: () => onSelected(tag['label']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.symmetric(
                              horizontal: SizeConfig.widthPercent(4),
                              vertical: SizeConfig.heightPercent(0.4)),
                          padding: EdgeInsets.symmetric(
                              horizontal: SizeConfig.widthPercent(4),
                              vertical: SizeConfig.heightPercent(1.5)),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2EC4B6).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                                SizeConfig.widthPercent(3.5)),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2EC4B6)
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(tag['icon']!,
                                  style: TextStyle(
                                      fontSize: SizeConfig.widthPercent(5))),
                              SizedBox(width: SizeConfig.widthPercent(3)),
                              Text(
                                tag['label']!,
                                style: TextStyle(
                                  fontSize: SizeConfig.widthPercent(3.8),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF2EC4B6)
                                      : const Color(0xFF1A1A2E),
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: const Color(0xFF2EC4B6),
                                  size: SizeConfig.widthPercent(5),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Background Colour Picker Sheet ──────────────────────────────────────────

class _BgColorPickerSheet extends StatelessWidget {
  final Color? selected;
  final ValueChanged<Color?> onSelected;

  const _BgColorPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          SizeConfig.widthPercent(5),
          SizeConfig.heightPercent(2),
          SizeConfig.widthPercent(5),
          SizeConfig.heightPercent(4)),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: SizeConfig.widthPercent(9),
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDE8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Text(
            'Card Background',
            style: TextStyle(
              fontSize: SizeConfig.widthPercent(4.5),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          SizedBox(height: SizeConfig.heightPercent(2)),
          Wrap(
            spacing: SizeConfig.widthPercent(3),
            runSpacing: SizeConfig.widthPercent(3),
            children: postBgColors.map((color) {
              final isSelected = color == selected;
              final isNone = color == null;
              return GestureDetector(
                onTap: () => onSelected(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: SizeConfig.widthPercent(12),
                  height: SizeConfig.widthPercent(12),
                  decoration: BoxDecoration(
                    color: isNone ? Colors.white : color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFE8E8F0),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: isNone
                      ? Center(
                          child: Icon(
                            Icons.block_rounded,
                            size: SizeConfig.widthPercent(5),
                            color: const Color(0xFFB0B0C0),
                          ),
                        )
                      : isSelected
                          ? Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: SizeConfig.widthPercent(5),
                                color: Colors.black54,
                              ),
                            )
                          : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
