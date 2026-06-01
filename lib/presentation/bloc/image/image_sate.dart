
import 'package:dating_app/domain/entities/image_entity.dart';

abstract class ImagesState {}

class ImagesInitial extends ImagesState {}

class ImagesLoading extends ImagesState {}

class ImagesUploading extends ImagesState {
  final List<UserImageEntity> currentImages; // keep showing existing while uploading
  ImagesUploading(this.currentImages);
}

class ImagesLoaded extends ImagesState {
  final List<UserImageEntity> images;

  ImagesLoaded(this.images);

  UserImageEntity? get profileImage =>
      images.where((i) => i.isProfile).firstOrNull;

  List<UserImageEntity> get galleryImages =>
      images.where((i) => i.isGallery).toList();

  ImagesLoaded copyWith({List<UserImageEntity>? images}) =>
      ImagesLoaded(images ?? this.images);
}

class ImagesError extends ImagesState {
  final String message;
  final List<UserImageEntity>? previousImages; // revert to these on failure
  ImagesError(this.message, {this.previousImages});
}
