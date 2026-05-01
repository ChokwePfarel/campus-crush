import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase/supabase.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/coins_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';

class OfflineCache {
  static const String postsBoxName = 'cached_posts';
  static const String profilesBoxName = 'cached_profiles';
  static const String discoveryBoxName = 'discovery_users';
  static const String coinsBoxName = 'cached_coins';
  static const String queuedMessagesBoxName = 'queued_messages';
  static const String conversationsBoxName = 'cached_conversations';
  static const String messageHistoryBoxName = 'cached_message_history';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(postsBoxName);
    await Hive.openBox(profilesBoxName);
    await Hive.openBox(discoveryBoxName);
    await Hive.openBox(coinsBoxName);
    await Hive.openBox(queuedMessagesBoxName);
    await Hive.openBox(conversationsBoxName);
    await Hive.openBox(messageHistoryBoxName);
  }

  // --- Conversations Cache ---
  static Future<void> cacheConversations(
    List<ConversationModel> conversations,
  ) async {
    final box = Hive.box(conversationsBoxName);
    final data = conversations.map((c) => c.toJson()).toList();
    await box.put('inbox', data);
  }

  static List<ConversationModel> getCachedConversations(String currentUserId) {
    final box = Hive.box(conversationsBoxName);
    final List<dynamic>? data = box.get('inbox');
    if (data == null) return [];
    return data
        .map(
          (json) => ConversationModel.fromJson(
            Map<String, dynamic>.from(json),
            currentUserId,
          ),
        )
        .toList();
  }

  // --- Message History Cache ---
  static Future<void> cacheMessageHistory(
    String conversationId,
    List<MessageModel> messages,
  ) async {
    final box = Hive.box(messageHistoryBoxName);
    // Only cache last 50 messages to save space
    final recent = messages.length > 50
        ? messages.sublist(messages.length - 50)
        : messages;
    final data = recent.map((m) => m.toJson()).toList();
    await box.put(conversationId, data);
  }

  static List<MessageModel> getCachedMessages(String conversationId) {
    final box = Hive.box(messageHistoryBoxName);
    final List<dynamic>? data = box.get(conversationId);
    if (data == null) return [];
    return data
        .map((json) => MessageModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // --- Message Queue ---
  static Future<void> enqueueMessage(MessageEntity message) async {
    final box = Hive.box(queuedMessagesBoxName);
    final data = {
      'id': message.id,
      'conversation_id': message.conversationId,
      'sender_id': message.senderId,
      'text': message.text,
      'created_at': message.createdAt.toIso8601String(),
    };
    await box.put(message.id, data);
  }

  static List<MessageEntity> getQueuedMessages(String conversationId) {
    final box = Hive.box(queuedMessagesBoxName);
    return box.values
        .map(
          (data) => MessageEntity(
            id: data['id'],

            text: data['text'],
            isRead: false,
            status: MessageStatus.pending,
            conversationId:  data['conversation_id'],
            senderId: '',
            createdAt:  DateTime.parse(data['created_at']),
          ),
        )
        .where((m) => m.conversationId == conversationId)
        .toList();
  }

  static Future<void> dequeueMessage(String messageId) async {
    final box = Hive.box(queuedMessagesBoxName);
    await box.delete(messageId);
  }

  static List<MessageEntity> getAllQueuedMessages() {
    final box = Hive.box(queuedMessagesBoxName);
    return box.values
        .map(
          (data) => MessageEntity(
            id: data['id'],
            text: data['text'],
            isRead: false,
            status: MessageStatus.pending,
            conversationId: data['conversation_id'],
            senderId: data['sender_id'],
            createdAt:  DateTime.parse(data['created_at']),
          ),
        )
        .toList();
  }

  // --- Coins Cache ---
  static Future<void> cacheCoins(CoinsEntity coins) async {
    final box = Hive.box(coinsBoxName);
    await box.put('user_coins', {
      'balance': coins.balance,
      'daily_ads_watched': coins.dailyAdsWatched,
      'last_ad_date': coins.lastAdDate?.toIso8601String(),
      'daily_direct_posts_count': coins.dailyDirectPostsCount,
      'last_direct_post_date': coins.lastDirectPostDate?.toIso8601String(),
    });
  }

  static CoinsEntity getCachedCoins() {
    final box = Hive.box(coinsBoxName);
    final data = box.get('user_coins');
    if (data == null) {
      return const CoinsEntity(
        balance: 0,
        dailyAdsWatched: 0,
        dailyDirectPostsCount: 0,
      );
    }
    return CoinsEntity(
      balance: data['balance'] ?? 0,
      dailyAdsWatched: data['daily_ads_watched'] ?? 0,
      lastAdDate: data['last_ad_date'] != null
          ? DateTime.parse(data['last_ad_date'])
          : null,
      dailyDirectPostsCount: data['daily_direct_posts_count'] ?? 0,
      lastDirectPostDate: data['last_direct_post_date'] != null
          ? DateTime.parse(data['last_direct_post_date'])
          : null,
    );
  }

  // --- Posts Cache ---
  static Future<void> cachePosts(List<PostModel> posts) async {
    final box = Hive.box(postsBoxName);
    final data = posts.map((p) => p.toJson()).toList();
    await box.put('recent_posts', data);
  }

  static List<PostModel> getCachedPosts() {
    final box = Hive.box(postsBoxName);
    final List<dynamic>? data = box.get('recent_posts');
    if (data == null) return [];
    return data
        .map((json) => PostModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // --- Discovery Users Cache ---
  static Future<void> cacheDiscoveryUsers(List<UserModel> users) async {
    final box = Hive.box(discoveryBoxName);
    final data = users.map((u) => u.toJson()).toList();
    await box.put('recent_discovery', data);
  }

  static List<UserModel> getCachedDiscoveryUsers() {
    final box = Hive.box(discoveryBoxName);
    final List<dynamic>? data = box.get('recent_discovery');
    if (data == null) return [];
    return data
        .map((json) => UserModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // --- Individual Profiles Cache ---
  static Future<void> cacheProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    final box = Hive.box(profilesBoxName);
    final textOnly = Map<String, dynamic>.from(profileData);
    textOnly.remove('profile_image_url');
    textOnly.remove('image_urls');
    await box.put(userId, textOnly);
  }

  static Map<String, dynamic>? getCachedProfile(String userId) {
    final box = Hive.box(profilesBoxName);
    final data = box.get(userId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }


}
