import 'dart:async';
import 'package:dating_app/data/models/notification_model.dart';
import 'package:dating_app/domain/entities/notification_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markAllAsRead(String userId);
  Stream<List<NotificationModel>> subscribeToNotifications(String userId);
  Stream<NotificationEntity> watchNotifications(String userId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final SupabaseClient client;

  NotificationRemoteDataSourceImpl(this.client);

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    final response = await client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
    }
  }

  @override
  Stream<List<NotificationModel>> subscribeToNotifications(String userId) {
    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((data) {
          return data.map((json) => NotificationModel.fromJson(json)).toList();
        });
  }

  @override
  Stream<NotificationEntity> watchNotifications(String userId) {
    final controller = StreamController<NotificationEntity>();

    final channel = client
        .channel('notifications-$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        controller.add(NotificationModel.fromJson(payload.newRecord));
      },
    )
        .subscribe();

    controller.onCancel = () {
      client.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
