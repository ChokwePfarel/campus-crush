
import 'package:dating_app/domain/entities/notification_entity.dart';

abstract class NotificationState {
  final bool showRedDot;
  const NotificationState({this.showRedDot = false});
}

class NotificationInitial extends NotificationState {
  const NotificationInitial({super.showRedDot});
}

class NotificationLoading extends NotificationState {
  const NotificationLoading({super.showRedDot});
}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;

  const NotificationLoaded(this.notifications, {super.showRedDot});

  NotificationLoaded copyWith({
    List<NotificationEntity>? notifications,
    bool? showRedDot,
  }) {
    return NotificationLoaded(
      notifications ?? this.notifications,
      showRedDot: showRedDot ?? this.showRedDot,
    );
  }
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message, {super.showRedDot});
}
