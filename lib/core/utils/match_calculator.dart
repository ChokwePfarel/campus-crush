
import '../../data/models/user_model.dart';

class MatchCalculator {
  static int calculateMatchPercentage(UserModel currentUser, UserModel otherUser) {
    int percentage = 0;

    // 1. Interests Match (Highest weight: 70%)
    if (currentUser.interests.isNotEmpty && otherUser.interests.isNotEmpty) {
      final sharedInterests = currentUser.interests
          .where((interest) => otherUser.interests.contains(interest))
          .length;
      
      final maxInterests = currentUser.interests.length > otherUser.interests.length 
          ? currentUser.interests.length 
          : otherUser.interests.length;

      percentage += ((sharedInterests / maxInterests) * 70).round();
    }

    // 2. Residence Match (15%)
    if (currentUser.residence == otherUser.residence) {
      percentage += 15;
    }

    // 3. Age proximity (15%)
    final ageDiff = (currentUser.age - otherUser.age).abs();
    if (ageDiff <= 2) {
      percentage += 15;
    } else if (ageDiff <= 5) {
      percentage += 10;
    } else if (ageDiff <= 10) {
      percentage += 5;
    }

    return percentage > 100 ? 100 : (percentage < 10 ? 10 : percentage);
  }
}
