
import 'package:dating_app/domain/entities/notification_entity.dart';

abstract class NotificationEvent {}

class LoadNotifications extends NotificationEvent {
  final String userId;
  LoadNotifications(this.userId);
}

class WatchNotifications extends NotificationEvent {
  final String userId;
  WatchNotifications(this.userId);
}

class NewNotificationArrived extends NotificationEvent {
  final NotificationEntity notification;
  NewNotificationArrived(this.notification);
}

class MarkNotificationsRead extends NotificationEvent {
  final String userId;
  MarkNotificationsRead(this.userId);
}
