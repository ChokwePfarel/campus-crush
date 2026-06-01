
import 'dart:io';

abstract class ImagesEvent {}

class LoadUserImages extends ImagesEvent {
  final String userId;
  LoadUserImages(this.userId);
}

class UploadProfileImage extends ImagesEvent {
  final String userId;
  final File image;
  UploadProfileImage({required this.userId, required this.image});
}

class UploadGalleryImage extends ImagesEvent {
  final String userId;
  final File image;
  UploadGalleryImage({required this.userId, required this.image});
}

class DeleteImage extends ImagesEvent {
  final String imageId;
  final String path;
  DeleteImage({required this.imageId, required this.path});
}
