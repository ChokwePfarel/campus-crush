import 'package:dating_app/data/datasources/notification_remote_data_source.dart';
import 'package:dating_app/domain/entities/notification_entity.dart';
import 'package:dating_app/domain/repositories/notification_repository.dart';

class NotificationRepositoryImp implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImp(this._remoteDataSource);

  @override
  Future<List<NotificationEntity>> getNotifications(String userId) {
    return _remoteDataSource.getNotifications(userId);
  }

  @override
  Future<void> markAllAsRead(String userId) {
    return _remoteDataSource.markAllAsRead(userId);
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(String userId) {
    return _remoteDataSource.subscribeToNotifications(userId);
  }
}
