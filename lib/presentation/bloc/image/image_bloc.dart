
import 'package:dating_app/domain/entities/image_entity.dart';
import 'package:dating_app/domain/repositories/image_repository.dart';
import 'package:dating_app/presentation/bloc/image/image_event.dart';
import 'package:dating_app/presentation/bloc/image/image_sate.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

class ImagesBloc extends Bloc<ImagesEvent, ImagesState> {
  final ImagesRepository _imagesRepository;

  ImagesBloc(this._imagesRepository) : super(ImagesInitial()) {
    on<LoadUserImages>(_onLoadUserImages);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<UploadGalleryImage>(_onUploadGalleryImage);
    on<DeleteImage>(_onDeleteImage);
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoadUserImages(
      LoadUserImages event,
      Emitter<ImagesState> emit,
      ) async {
    try {

      emit(ImagesLoading());

      final images = await _imagesRepository.getUserImages(event.userId);

      emit(ImagesLoaded(images));
    } catch (e) {
      emit(ImagesError(e.toString()));
    }
  }

  // ── Upload Profile ────────────────────────────────────────────────────────

  Future<void> _onUploadProfileImage(
      UploadProfileImage event,
      Emitter<ImagesState> emit,
      ) async {
    final current = state;
    final List<UserImageEntity> currentImages =
    current is ImagesLoaded ? current.images : [];

    emit(ImagesUploading(currentImages));

    try {
      final newImage = await _imagesRepository.uploadProfileImage(
        userId: event.userId,
        image:  event.image,
      );

      // Replace old profile image with the new one
      final updated = [
        ...currentImages.where((i) => i.isGallery),
        newImage,
      ];

      emit(ImagesLoaded(updated));
    } catch (e) {
      emit(ImagesError(e.toString(),
          previousImages: currentImages));
    }
  }

  // ── Upload Gallery ────────────────────────────────────────────────────────

  Future<void> _onUploadGalleryImage(
      UploadGalleryImage event,
      Emitter<ImagesState> emit,
      ) async {
    final current = state;
    final List<UserImageEntity> currentImages =
    current is ImagesLoaded ? current.images : [];

    emit(ImagesUploading(currentImages));

    try {
      final newImage = await _imagesRepository.uploadGalleryImage(
        userId: event.userId,
        image:  event.image,
      );

      emit(ImagesLoaded([newImage, ...currentImages]));
    } catch (e) {
      emit(ImagesError(e.toString(),
          previousImages: currentImages));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _onDeleteImage(
      DeleteImage event,
      Emitter<ImagesState> emit,
      ) async {
    final current = state;
    if (current is! ImagesLoaded) return;

    // Optimistic update
    final optimistic =
    current.images.where((i) => i.id != event.imageId).toList();
    emit(current.copyWith(images: optimistic));

    try {
      await _imagesRepository.deleteImage(
        imageId: event.imageId,
        path:    event.path,
      );
    } catch (e) {
      // Revert on failure
      emit(current);
      emit(ImagesError(e.toString()));
    }
  }
}
