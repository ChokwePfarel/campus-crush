import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/post_model.dart';
import '../../data/models/user_model.dart';

class OfflineCache {
  static const String postsBoxName = 'cached_posts';
  static const String profilesBoxName = 'cached_profiles';
  static const String discoveryBoxName = 'discovery_users';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(postsBoxName);
    await Hive.openBox(profilesBoxName);
    await Hive.openBox(discoveryBoxName);
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
    return data.map((json) => PostModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  // --- Discovery Users Cache ---
  static Future<void> cacheDiscoveryUsers(List<UserModel> users) async {
    final box = Hive.box(discoveryBoxName);
    // Keep all fields (including image URLs) so CachedNetworkImage can find them offline
    final data = users.map((u) => u.toJson()).toList();
    await box.put('recent_discovery', data);
  }

  static List<UserModel> getCachedDiscoveryUsers() {
    final box = Hive.box(discoveryBoxName);
    final List<dynamic>? data = box.get('recent_discovery');
    if (data == null) return [];
    print('Returning cached discovery users');
    return data.map((json) => UserModel.fromJson(Map<String, dynamic>.from(json))).toList();
  }

  // --- Individual Profiles Cache ---
  static Future<void> cacheProfile(String userId, Map<String, dynamic> profileData) async {
    final box = Hive.box(profilesBoxName);
    final textOnly = Map<String, dynamic>.from(profileData);
    // We strip images only for deep profile storage to save space, 
    // but keep them in discovery for the main feed UX.
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
