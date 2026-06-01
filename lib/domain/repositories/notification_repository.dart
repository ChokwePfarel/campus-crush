import 'package:dating_app/domain/entities/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications(String userId);
  Future<void> markAllAsRead(String userId);
  Stream<List<NotificationEntity>> watchNotifications(String userId);
}
