import 'dart:io';

import 'package:dating_app/domain/entities/image_entity.dart';

abstract class ImagesRepository {
  Future<List<UserImageEntity>> getUserImages(String userId);
  Future<UserImageEntity> uploadProfileImage({
    required String userId,
    required File image,
  });
  Future<UserImageEntity> uploadGalleryImage({
    required String userId,
    required File image,
  });
  Future<void> deleteImage({
    required String imageId,
    required String path,
  });
}