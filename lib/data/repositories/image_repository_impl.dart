
import 'dart:io';

import 'package:dating_app/data/datasources/image_remote_data_source.dart';
import 'package:dating_app/domain/entities/image_entity.dart';
import 'package:dating_app/domain/repositories/image_repository.dart';

class ImagesRepositoryImpl implements ImagesRepository {
  final ImagesRemoteDataSource dataSource;

  ImagesRepositoryImpl(this.dataSource);

  @override
  Future<List<UserImageEntity>> getUserImages(String userId) =>
      dataSource.getUserImages(userId);



  @override
  Future<UserImageEntity> uploadProfileImage({
    required String userId,
    required File image,
  }) =>
      dataSource.uploadProfileImage(userId: userId, image: image);

  @override
  Future<UserImageEntity> uploadGalleryImage({
    required String userId,
    required File image,
  }) =>
      dataSource.uploadGalleryImage(userId: userId, image: image);

  @override
  Future<void> deleteImage({
    required String imageId,
    required String path,
  }) =>
      dataSource.deleteImage(imageId: imageId, path: path);
}