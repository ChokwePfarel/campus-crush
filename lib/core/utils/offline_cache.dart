import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/coins_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

class OfflineCache {
  /// Hive deserialises nested maps as Map<dynamic, dynamic>.
  /// This recursively casts any map/list structure to Map<String, dynamic>
  /// so every fromJson factory receives the type it expects.
  static Map<String, dynamic> _deepCast(dynamic raw) {
    final map = Map<String, dynamic>.from(raw as Map);
    return map.map((key, value) {
      if (value is Map) return MapEntry(key, _deepCast(value));
      if (value is List) return MapEntry(key, _deepCastList(value));
      return MapEntry(key, value);
    });
  }

  static List<dynamic> _deepCastList(List raw) {
    return raw.map((item) {
      if (item is Map) return _deepCast(item);
      if (item is List) return _deepCastList(item);
      return item;
    }).toList();
  }

  static const String postsBoxName           = 'cached_posts';
  static const String profilesBoxName        = 'cached_profiles';
  static const String discoveryBoxName       = 'discovery_users';
  static const String coinsBoxName           = 'cached_coins';
  static const String queuedMessagesBoxName  = 'queued_messages';
  static const String conversationsBoxName   = 'cached_conversations';
  static const String messageHistoryBoxName  = 'cached_message_history';
  static const String currentUserBoxName     = 'current_user';

  // ─── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(postsBoxName);
    await Hive.openBox(profilesBoxName);
    await Hive.openBox(discoveryBoxName);
    await Hive.openBox(coinsBoxName);
    await Hive.openBox(queuedMessagesBoxName);
    await Hive.openBox(conversationsBoxName);
    await Hive.openBox(messageHistoryBoxName);
    await Hive.openBox(currentUserBoxName);
  }

  // ─── Conversations Cache ───────────────────────────────────────────────────

  /// Cache conversations keyed by [currentUserId] so multiple accounts
  /// on the same device don't bleed into each other.
  static Future<void> cacheConversations(
      String currentUserId,
      List<ConversationModel> conversations,
      ) async {
    final box  = Hive.box(conversationsBoxName);
    final data = conversations.map((c) => _conversationToJson(c)).toList();
    await box.put('inbox_$currentUserId', data);
  }

  static List<ConversationModel> getCachedConversations(String currentUserId) {
    final box              = Hive.box(conversationsBoxName);
    final List<dynamic>? data = box.get('inbox_$currentUserId');
    if (data == null) return [];
    return data
        .map(
          (json) => ConversationModel.fromJson(
        _deepCast(json),
        currentUserId,
      ),
    )
        .toList();
  }

  /// Serialise a [ConversationModel] to a plain map.
  /// ConversationModel doesn't define toJson(), so we build it here
  /// using the fields available on ConversationEntity.
  static Map<String, dynamic> _conversationToJson(ConversationModel c) => {
    'id':               c.id,
    'user_one_id':      c.userOneId,
    'user_two_id':      c.userTwoId,
    'last_message':     c.lastMessage,
    'last_message_at':  c.lastMessageAt?.toIso8601String(),
    'created_at':       c.createdAt.toIso8601String(),
    'unread_count':     c.unreadCount,
    // Flatten the "other user" fields so fromJson can reconstruct them.
    // fromJson reads json['user_one'] or json['user_two'] depending on
    // which side the current user is on — we store both sides identically
    // so the factory works without modification.
    'user_one': {
      'name':              c.otherUserName,
      'profile_image_url': c.otherUserImageUrl,
      'is_verified':       c.otherUserIsVerified,
    },
    'user_two': {
      'name':              c.otherUserName,
      'profile_image_url': c.otherUserImageUrl,
      'is_verified':       c.otherUserIsVerified,
    },
  };

  // ─── Message History Cache ─────────────────────────────────────────────────

  static Future<void> cacheMessageHistory(
      String conversationId,
      List<MessageModel> messages,
      ) async {
    final box    = Hive.box(messageHistoryBoxName);
    // Only store the last 50 messages to keep storage bounded
    final recent = messages.length > 50
        ? messages.sublist(messages.length - 50)
        : messages;
    final data   = recent.map((m) => m.toJson()).toList();
    await box.put(conversationId, data);
  }

  static List<MessageModel> getCachedMessages(String conversationId) {
    final box              = Hive.box(messageHistoryBoxName);
    final List<dynamic>? data = box.get(conversationId);
    if (data == null) return [];
    return data
        .map((json) => MessageModel.fromJson(_deepCast(json)))
        .toList();
  }

  // ─── Outbox Queue ──────────────────────────────────────────────────────────

  static Future<void> enqueueMessage(MessageEntity message) async {
    final box  = Hive.box(queuedMessagesBoxName);
    final data = {
      'id':              message.id,
      'conversation_id': message.conversationId,
      'sender_id':       message.senderId,
      'text':            message.text,
      'created_at':      message.createdAt.toIso8601String(),
    };
    await box.put(message.id, data);
  }

  static List<MessageEntity> getQueuedMessages(String conversationId) {
    final box = Hive.box(queuedMessagesBoxName);
    return box.values
        .map((raw) => _queuedToEntity(_deepCast(raw)))
        .where((m) => m.conversationId == conversationId)
        .toList();
  }

  static List<MessageEntity> getAllQueuedMessages() {
    final box = Hive.box(queuedMessagesBoxName);
    return box.values
        .map((raw) => _queuedToEntity(_deepCast(raw)))
        .toList();
  }

  static Future<void> dequeueMessage(String messageId) async {
    await Hive.box(queuedMessagesBoxName).delete(messageId);
  }

  static MessageEntity _queuedToEntity(Map<String, dynamic> data) =>
      MessageEntity(
        id:             data['id'],
        conversationId: data['conversation_id'],
        senderId:       data['sender_id'],
        text:           data['text'],
        isRead:         false,
        createdAt:      DateTime.parse(data['created_at']),
        status:         MessageStatus.pending,
      );

  // ─── Coins Cache ───────────────────────────────────────────────────────────

  static Future<void> cacheCoins(CoinsEntity coins) async {
    final box = Hive.box(coinsBoxName);
    await box.put('user_coins', {
      'balance':                coins.balance,
      'daily_ads_watched':      coins.dailyAdsWatched,
      'last_ad_date':           coins.lastAdDate?.toIso8601String(),
      'daily_direct_posts_count': coins.dailyDirectPostsCount,
      'last_direct_post_date':  coins.lastDirectPostDate?.toIso8601String(),
    });
  }

  static CoinsEntity getCachedCoins() {
    final box  = Hive.box(coinsBoxName);
    final data = box.get('user_coins');
    if (data == null) {
      return const CoinsEntity(
        balance: 0,
        dailyAdsWatched: 0,
        dailyDirectPostsCount: 0,
      );
    }
    return CoinsEntity(
      balance:               data['balance']               ?? 0,
      dailyAdsWatched:       data['daily_ads_watched']     ?? 0,
      lastAdDate:            data['last_ad_date'] != null
          ? DateTime.parse(data['last_ad_date'])
          : null,
      dailyDirectPostsCount: data['daily_direct_posts_count'] ?? 0,
      lastDirectPostDate:    data['last_direct_post_date'] != null
          ? DateTime.parse(data['last_direct_post_date'])
          : null,
    );
  }

  // ─── Posts Cache ───────────────────────────────────────────────────────────

  static Future<void> cachePosts(List<PostModel> posts) async {
    final box  = Hive.box(postsBoxName);
    final data = posts.map((p) => p.toJson()).toList();
    await box.put('recent_posts', data);
  }

  static List<PostModel> getCachedPosts() {
    final box              = Hive.box(postsBoxName);
    final List<dynamic>? data = box.get('recent_posts');
    if (data == null) return [];
    return data
        .map((json) => PostModel.fromJson(_deepCast(json)))
        .toList();
  }

  // ─── Discovery Users Cache ─────────────────────────────────────────────────

  static Future<void> cacheDiscoveryUsers(List<UserModel> users) async {
    final box  = Hive.box(discoveryBoxName);
    final data = users.map((u) => u.toJson()).toList();
    await box.put('recent_discovery', data);
  }

  static List<UserModel> getCachedDiscoveryUsers() {
    final box              = Hive.box(discoveryBoxName);
    final List<dynamic>? data = box.get('recent_discovery');
    if (data == null) return [];
    return data
        .map((json) => UserModel.fromJson(_deepCast(json)))
        .toList();
  }

  // ─── Current User Cache ────────────────────────────────────────────────────

  /// Cache the signed-in user so UserBloc can emit UserLoaded instantly
  /// on the next cold start before the Supabase stream fires.
  static Future<void> cacheCurrentUser(UserModel user) async {
    final box = Hive.box(currentUserBoxName);
    await box.put('me', user.toJson());
  }

  static UserModel? getCachedCurrentUser() {
    final box  = Hive.box(currentUserBoxName);
    final data = box.get('me');
    if (data == null) return null;
    try {
      return UserModel.fromJson(_deepCast(data));
    } catch (_) {
      // Corrupted cache — ignore and let the stream fetch fresh data
      return null;
    }
  }

  static Future<void> clearCurrentUser() async {
    await Hive.box(currentUserBoxName).delete('me');
  }

  // ─── Individual Profiles Cache ─────────────────────────────────────────────

  static Future<void> cacheProfile(
      String userId,
      Map<String, dynamic> profileData,
      ) async {
    final box      = Hive.box(profilesBoxName);
    final textOnly = Map<String, dynamic>.from(profileData)
      ..remove('profile_image_url')
      ..remove('image_urls');
    await box.put(userId, textOnly);
  }

  static Map<String, dynamic>? getCachedProfile(String userId) {
    final box  = Hive.box(profilesBoxName);
    final data = box.get(userId);
    return data != null ? _deepCast(data) : null;
  }
}
