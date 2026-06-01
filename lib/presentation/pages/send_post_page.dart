import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/utils/snackbar.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/presentation/bloc/coins/coins_bloc.dart';
import 'package:dating_app/presentation/bloc/coins/coins_event.dart';
import 'package:dating_app/presentation/bloc/coins/coins_state.dart';
import 'package:dating_app/presentation/bloc/posts/posts_bloc.dart';
import 'package:dating_app/presentation/bloc/posts/posts_event.dart';
import 'package:dating_app/presentation/bloc/posts/posts_state.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart' as user_st;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Post type ────────────────────────────────────────────────────────────────

enum DirectPostType { crush, compliment, confession, question }

extension DirectPostTypeExt on DirectPostType {
  String get emoji {
    switch (this) {
      case DirectPostType.crush:       return '💘';
      case DirectPostType.compliment:  return '✨';
      case DirectPostType.confession:  return '🤫';
      case DirectPostType.question:    return '💭';
    }
  }

  String get label {
    switch (this) {
      case DirectPostType.crush:       return 'Crush';
      case DirectPostType.compliment:  return 'Compliment';
      case DirectPostType.confession:  return 'Confession';
      case DirectPostType.question:    return 'Question';
    }
  }

  String get hint {
    switch (this) {
      case DirectPostType.crush:       return 'Tell them how you feel... 💘';
      case DirectPostType.compliment:  return 'Say something kind ✨';
      case DirectPostType.confession:  return 'Get it off your chest 🤫';
      case DirectPostType.question:    return 'Ask them something 💭';
    }
  }

  Color get color {
    switch (this) {
      case DirectPostType.crush:       return const Color(0xFFB5193A);
      case DirectPostType.compliment:  return const Color(0xFF3730A3);
      case DirectPostType.confession:  return const Color(0xFFB45309);
      case DirectPostType.question:    return const Color(0xFF0F766E);
    }
  }

  List<String> get suggestions {
    switch (this) {
      case DirectPostType.crush:
        return [
          'I smile every time I see you 😊',
          'You\'ve been on my mind a lot lately',
          'I get nervous whenever you\'re around',
          'I wish I had the courage to talk to you',
        ];
      case DirectPostType.compliment:
        return [
          'Your energy in class is contagious ✨',
          'You always look amazing 🔥',
          'You seem like a genuinely good person',
          'Your laugh is everything 😄',
        ];
      case DirectPostType.confession:
        return [
          'I\'ve been watching your stories for months',
          'I almost spoke to you so many times',
          'You intimidate me in the best way',
          'I look for you whenever I\'m on campus',
        ];
      case DirectPostType.question:
        return [
          'Would you ever grab coffee with a stranger? ☕',
          'Do you come to the library often?',
          'What\'s your go-to study spot?',
          'Are you as interesting as you look?',
        ];
    }
  }
}

// ─── Main Page ────────────────────────────────────────────────────────────────

class SendPostPage extends StatefulWidget {
  final UserModel recipient;

  const SendPostPage({
    super.key,
    required this.recipient,
  });

  @override
  State<SendPostPage> createState() => _SendPostPageState();
}

class _SendPostPageState extends State<SendPostPage>
    with TickerProviderStateMixin {
  DirectPostType _postType  = DirectPostType.crush;
  bool           _isAnonymous = true;
  bool           _isSending   = false;

  final _contentCtrl = TextEditingController();
  final _focusNode   = FocusNode();

  late final _entranceCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 500),
  )..forward();
  late final _entranceFade =
  CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
  late final _entranceSlide = Tween<Offset>(
    begin: const Offset(0, 0.05), end: Offset.zero,
  ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));

  late final _pulseCtrl = AnimationController(
    vsync: this, duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _contentCtrl.dispose();
    _focusNode.dispose();
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _canSend => _contentCtrl.text.trim().isNotEmpty && !_isSending;
  Color get _accent  => _postType.color;

  void _pickType(DirectPostType type) {
    HapticFeedback.selectionClick();
    setState(() => _postType = type);
  }

  void _toggleAnonymous() {
    HapticFeedback.lightImpact();
    setState(() => _isAnonymous = !_isAnonymous);
  }

  void _useSuggestion(String text) {
    HapticFeedback.selectionClick();
    _contentCtrl.text = text;
    _contentCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    setState(() {});
  }

  void _handleSend() {
    if (!_canSend || _isSending) return;

    final userState = context.read<UserBloc>().state;
    if (userState is! user_st.UserLoaded) return;

    final coinsState = context.read<CoinsBloc>().state;
    
    // Default to free if state is still loading to avoid blocking the user
    bool canPostFree = true;
    bool hasEnough = true;

    if (coinsState is CoinsLoaded) {
      canPostFree = coinsState.coins.canSendFreeDirectPost;
      hasEnough = coinsState.coins.hasEnoughForDirectPost;
    }

    if (canPostFree) {
      _initiateCoinDeduction(userState.user.id, isFree: true);
    } else if (hasEnough) {
      _initiateCoinDeduction(userState.user.id, isFree: false);
    } else {
      _showNotEnoughCoinsDialog();
    }
  }

  void _initiateCoinDeduction(String userId, {required bool isFree}) {
    HapticFeedback.mediumImpact();
    setState(() => _isSending = true);

    if (isFree) {
      context.read<CoinsBloc>().add(TrackFreeDirectPost(userId));
    } else {
      context.read<CoinsBloc>().add(SpendCoinsOnDirectPost(userId));
    }
  }

  void _executePostCreation(String userName) {
    context.read<PostBloc>().add(
      CreatePostRequested(
        content: _contentCtrl.text.trim(),
        university: widget.recipient.university,
        backgroundColor: _postType.color,
        isAnonymous: _isAnonymous,
        postType: _postType.name,
        authorName: userName,
        recipientId: widget.recipient.id,
        isNormalPost: false,
      ),
    );
  }

  void _showNotEnoughCoinsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Not Enough Coins'),
        content: const Text('Sending a direct post costs 5 coins. Watch an ad to earn 10 coins instantly!'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              _watchAd();
            },
            child: const Text('Watch Ad (+10 🪙)'),
          ),
        ],
      ),
    );
  }

  void _watchAd() {
    final userState = context.read<UserBloc>().state;
    if (userState is user_st.UserLoaded) {
      // We set _isSending to true so that when CoinsEarned is received,
      // it automatically proceeds with _handleSend().
      setState(() => _isSending = true);
      context.read<CoinsBloc>().add(WatchAdRequested(userState.user.id));
    }
  }

  void _showSuccessAndPop() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        postType: _postType,
        isAnonymous: _isAnonymous,
        recipientName: widget.recipient.name.split(' ').first,
        onDone: () {
          Navigator.of(context).pop(); // close dialog
          Navigator.of(context).pop(); // close page
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<PostBloc, PostState>(
          listener: (context, state) {
            if (state is PostsLoaded && _isSending) {
              setState(() => _isSending = false);
              _showSuccessAndPop();
            }
            if (state is PostError && _isSending) {
              setState(() => _isSending = false);
              AppSnackBar.show(context, 'Something went wrong', type: SnackBarType.error);
            }
          },
        ),
        BlocListener<CoinsBloc, CoinsState>(
          listener: (context, state) {
            if (state is CoinsError && _isSending) {
              setState(() => _isSending = false);
              AppSnackBar.show(context, state.message, type: SnackBarType.error);
            }
            
            if (state is CoinsSpent && _isSending) {
              final userState = context.read<UserBloc>().state;
              if (userState is user_st.UserLoaded) {
                _executePostCreation(userState.user.name);
              } else {
                setState(() => _isSending = false);
              }
            }

            if (state is CoinsEarned) {
              setState(() => _isSending = false);  // ← ADD THIS LINE
              if (_isSending) _handleSend();
            }

            if (state is AdNotReady && _isSending) {
               setState(() => _isSending = false);
               AppSnackBar.show(context, 'Ad not ready, try again in a moment', type: SnackBarType.warning);
            }
            if (state is AdLimitReached && _isSending) {
               setState(() => _isSending = false);
               AppSnackBar.show(context, 'Daily ad limit reached', type: SnackBarType.info);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: FadeTransition(
          opacity: _entranceFade,
          child: SlideTransition(
            position: _entranceSlide,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.widthPercent(5)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: SizeConfig.heightPercent(2)),
                        _buildRecipientCard(),
                        SizedBox(height: SizeConfig.heightPercent(3)),
                        _buildTypePicker(),
                        SizedBox(height: SizeConfig.heightPercent(2.5)),
                        _buildComposerCard(),
                        SizedBox(height: SizeConfig.heightPercent(2)),
                        _buildSuggestions(),
                        SizedBox(height: SizeConfig.heightPercent(2.5)),
                        _buildAnonymousToggle(),
                        SizedBox(height: SizeConfig.heightPercent(4)),
                        _buildSendButton(),
                        SizedBox(height: SizeConfig.heightPercent(4)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 20,
        bottom: 12,
      ),
      child: Row(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              width: SizeConfig.widthPercent(10),
              height: SizeConfig.widthPercent(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3)),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                CupertinoIcons.chevron_left,
                color: Colors.white,
                size: SizeConfig.widthPercent(5),
              ),
            ),
          ),
          SizedBox(width: SizeConfig.widthPercent(3)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a Post',
                style: TextStyle(
                  fontSize: SizeConfig.widthPercent(5),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Only they will see this',
                style: TextStyle(
                  fontSize: SizeConfig.widthPercent(3),
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildCoinsBadge(),
        ],
      ),
    );
  }

  Widget _buildCoinsBadge() {
    return BlocBuilder<CoinsBloc, CoinsState>(
      builder: (context, state) {
        final balance = state is CoinsLoaded ? state.coins.balance : 0;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.widthPercent(3), 
            vertical: SizeConfig.heightPercent(0.8)
          ),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3)),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text('🪙', style: TextStyle(fontSize: SizeConfig.widthPercent(3.5))),
              SizedBox(width: SizeConfig.widthPercent(1)),
              Text(
                '$balance', 
                style: TextStyle(
                  color: Colors.orange, 
                  fontWeight: FontWeight.bold, 
                  fontSize: SizeConfig.widthPercent(3.5)
                )
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Recipient Card ──────────────────────────────────────────────────────────

  Widget _buildRecipientCard() {
    final bool hasValidImage = widget.recipient.profileImageUrl.isNotEmpty && 
                                widget.recipient.profileImageUrl.startsWith('http');

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _accent.withOpacity(0.2 + _pulseCtrl.value * 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.06 + _pulseCtrl.value * 0.04),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: SizeConfig.widthPercent(14),
                height: SizeConfig.widthPercent(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withOpacity(0.15),
                  border: Border.all(
                    color: _accent.withOpacity(0.35),
                    width: 2,
                  ),
                  image: hasValidImage
                      ? DecorationImage(
                          image: NetworkImage(widget.recipient.profileImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: !hasValidImage
                    ? const Center(child: Text('👤', style: TextStyle(fontSize: 22)))
                    : null,
              ),
              if (widget.recipient.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: SizeConfig.widthPercent(4.5),
                    height: SizeConfig.widthPercent(4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2EC4B6),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0D0D1A), width: 2),
                    ),
                    child: Icon(CupertinoIcons.checkmark_alt,
                        size: SizeConfig.widthPercent(2.5), color: Colors.white),
                  ),
                ),
            ],
          ),
          SizedBox(width: SizeConfig.widthPercent(3.5)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sending to',
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(2.8),
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.recipient.name,
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(4.2),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.recipient.major,
                  style: TextStyle(
                    fontSize: SizeConfig.widthPercent(3.2),
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: SizeConfig.widthPercent(11),
            height: SizeConfig.widthPercent(11),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3)),
            ),
            child: Center(
              child: Text(
                _postType.emoji,
                style: TextStyle(fontSize: SizeConfig.widthPercent(5.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Type Picker ─────────────────────────────────────────────────────────────

  Widget _buildTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE',
          style: TextStyle(
            fontSize: SizeConfig.widthPercent(2.8),
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: SizeConfig.heightPercent(1.2)),
        Row(
          children: DirectPostType.values.map((type) {
            final selected = _postType == type;
            return Expanded(
              child: GestureDetector(
                onTap: () => _pickType(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.only(right: SizeConfig.widthPercent(2)),
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.heightPercent(1.5)),
                  decoration: BoxDecoration(
                    color: selected
                        ? type.color.withOpacity(0.18)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3.5)),
                    border: Border.all(
                      color: selected
                          ? type.color.withOpacity(0.6)
                          : Colors.white.withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(type.emoji,
                          style: TextStyle(fontSize: SizeConfig.widthPercent(5))),
                      SizedBox(height: SizeConfig.heightPercent(0.5)),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontSize: SizeConfig.widthPercent(2.5),
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? type.color
                              : Colors.white.withOpacity(0.35),
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

  // ── Composer Card ───────────────────────────────────────────────────────────

  Widget _buildComposerCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _canSend
              ? _accent.withOpacity(0.4)
              : Colors.white.withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.widthPercent(4), 
              SizeConfig.heightPercent(1.8), 
              SizeConfig.widthPercent(4), 
              0
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: SizeConfig.widthPercent(9),
                  height: SizeConfig.widthPercent(9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isAnonymous
                        ? Colors.white.withOpacity(0.1)
                        : _accent.withOpacity(0.15),
                    border: Border.all(
                      color: _isAnonymous
                          ? Colors.white.withOpacity(0.15)
                          : _accent.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _isAnonymous ? '🎭' : '👤',
                      style: TextStyle(fontSize: SizeConfig.widthPercent(4)),
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
                        fontSize: SizeConfig.widthPercent(3.5),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isAnonymous
                          ? 'They won\'t know it\'s you'
                          : 'They\'ll see your name',
                      style: TextStyle(
                        fontSize: SizeConfig.widthPercent(2.8),
                        color: _isAnonymous
                            ? Colors.white.withOpacity(0.4)
                            : _accent.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.widthPercent(2.5), 
                      vertical: SizeConfig.heightPercent(0.5)
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(SizeConfig.widthPercent(2)),
                  ),
                  child: Text(
                    '${_postType.emoji} ${_postType.label}',
                    style: TextStyle(
                      fontSize: SizeConfig.widthPercent(2.8),
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              SizeConfig.widthPercent(4), 
              SizeConfig.heightPercent(1.2), 
              SizeConfig.widthPercent(4), 
              SizeConfig.heightPercent(2)
            ),
            child: TextField(
              controller: _contentCtrl,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 4,
              maxLength: 300,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: SizeConfig.widthPercent(4),
                height: 1.55,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: _postType.hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: SizeConfig.widthPercent(4),
                ),
                border: InputBorder.none,
                counterStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: SizeConfig.widthPercent(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Suggestions ─────────────────────────────────────────────────────────────

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SUGGESTIONS',
          style: TextStyle(
            fontSize: SizeConfig.widthPercent(2.8),
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: SizeConfig.heightPercent(1.2)),
        ...(_postType.suggestions.map((s) => GestureDetector(
          onTap: () => _useSuggestion(s),
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: SizeConfig.heightPercent(1)),
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.widthPercent(4), 
                vertical: SizeConfig.heightPercent(1.5)
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3.5)),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: SizeConfig.widthPercent(3.5),
                      color: Colors.white.withOpacity(0.6),
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(width: SizeConfig.widthPercent(2.5)),
                Icon(
                  CupertinoIcons.arrow_up_left,
                  size: SizeConfig.widthPercent(3.5),
                  color: Colors.white.withOpacity(0.25),
                ),
              ],
            ),
          ),
        ))),
      ],
    );
  }

  // ── Anonymous Toggle ─────────────────────────────────────────────────────────

  Widget _buildAnonymousToggle() {
    return GestureDetector(
      onTap: _toggleAnonymous,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isAnonymous
              ? Colors.white.withOpacity(0.06)
              : _accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isAnonymous
                ? Colors.white.withOpacity(0.1)
                : _accent.withOpacity(0.35),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: SizeConfig.widthPercent(11),
              height: SizeConfig.widthPercent(11),
              decoration: BoxDecoration(
                color: _isAnonymous
                    ? Colors.white.withOpacity(0.08)
                    : _accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(SizeConfig.widthPercent(3.5)),
              ),
              child: Center(
                child: Text(
                  _isAnonymous ? '🎭' : '👤',
                  style: TextStyle(fontSize: SizeConfig.widthPercent(5.5)),
                ),
              ),
            ),
            SizedBox(width: SizeConfig.widthPercent(3.5)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAnonymous ? 'Sending anonymously' : 'Sending as yourself',
                    style: TextStyle(
                      fontSize: SizeConfig.widthPercent(3.8),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _isAnonymous
                        ? '${widget.recipient.name.split(' ').first} won\'t know who sent this'
                        : '${widget.recipient.name.split(' ').first} will see your name and photo',
                    style: TextStyle(
                      fontSize: SizeConfig.widthPercent(3),
                      color: Colors.white.withOpacity(0.45),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.widthPercent(2.5)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: SizeConfig.widthPercent(12),
              height: SizeConfig.heightPercent(3.5),
              decoration: BoxDecoration(
                color: _isAnonymous ? Colors.white.withOpacity(0.15) : _accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment:
                    _isAnonymous ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: SizeConfig.widthPercent(5.5),
                  height: SizeConfig.widthPercent(5.5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Send Button ─────────────────────────────────────────────────────────────

  Widget _buildSendButton() {
    return BlocBuilder<CoinsBloc, CoinsState>(builder: (context, state) {
      bool canPostFree = true;
      String label = 'Send for Free';

      if (state is CoinsLoaded) {
        canPostFree = state.coins.canSendFreeDirectPost;
        label = canPostFree ? 'Send for Free' : 'Send (5 🪙)';
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: SizeConfig.heightPercent(7),
        decoration: BoxDecoration(
          gradient: _canSend
              ? LinearGradient(
                  colors: [_accent, _accent.withOpacity(0.7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: _canSend ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(SizeConfig.widthPercent(4.5)),
          boxShadow: _canSend
              ? [
                  BoxShadow(
                    color: _accent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _canSend ? _handleSend : null,
          child: _isSending
              ? const CircularProgressIndicator.adaptive()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _postType.emoji,
                      style: TextStyle(fontSize: SizeConfig.widthPercent(5)),
                    ),
                    SizedBox(width: SizeConfig.widthPercent(2.5)),
                    Text(
                      _canSend
                          ? label
                          : 'Write something first...',
                      style: TextStyle(
                        fontSize: SizeConfig.widthPercent(4),
                        fontWeight: FontWeight.w700,
                        color: _canSend
                            ? Colors.white
                            : Colors.white.withOpacity(0.25),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}

// ─── Success Dialog ───────────────────────────────────────────────────────────

class _SuccessDialog extends StatefulWidget {
  final DirectPostType postType;
  final bool isAnonymous;
  final String recipientName;
  final VoidCallback onDone;

  const _SuccessDialog({
    required this.postType,
    required this.isAnonymous,
    required this.recipientName,
    required this.onDone,
  });

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  @override
  void initState() {
    super.initState();
    // Auto-close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDone();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated checkmark (optional)
          Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _getTitle(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDone();
          },
          child: const Text(
            'GOT IT',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _getTitle() {
    if (widget.isAnonymous) {
      return '✨ Anonymous Post Sent!';
    }
    return '✨ Post Sent!';
  }

  String _getMessage() {
    final postTypeText = widget.postType.name.toLowerCase();
    final recipientDisplay = widget.isAnonymous
        ? widget.recipientName
        : '${widget.recipientName} (they can see it\'s you)';

    if (widget.isAnonymous) {
      return 'Your $postTypeText post has been sent anonymously to $recipientDisplay';
    }
    return 'Your $postTypeText post has been sent to $recipientDisplay';
  }
}
