import 'package:dating_app/data/datasources/report_remote_data_source.dart';
import 'package:dating_app/domain/repositories/reports_repository.dart';
import 'package:dating_app/presentation/bloc/reports/report_event.dart';
import 'package:dating_app/presentation/bloc/reports/report_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/offline_cache.dart';

class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  final ReportsRepository repository;

  ReportsBloc(this.repository) : super(ReportsInitial()) {
    on<ReportPost>(_onReportPost);
  }

  Future<void> _onReportPost(
      ReportPost event,
      Emitter<ReportsState> emit,
      ) async {
    emit(ReportsLoading());

    try {
      await repository.reportPost(
        reportedUserId: event.reportedUserId,
        reporterId: event.reporterId,
        postId: event.postId,
        reason: event.reason,
      );

      emit(ReportsSuccess());
    } on PostAlreadyReportedException {
      emit(PostAlreadyReported());
    } catch (e) {

      //Fixing
      // Fallback: Check if the error message contains 'duplicate key' 
      // in case the exception mapping in the data source was bypassed.

      if (e.toString().contains('duplicate key')) {
        emit(PostAlreadyReported());
      } else {
        emit(ReportsFailure(e.toString()));
      }
    }
  }}




class BlockUserBloc extends Bloc<BlockUserEvent, BlockUserState> {
  final ReportsRepository repository;

  BlockUserBloc(this.repository) : super(BlockUserInitial()) {
    on<BlockUser>(_onBlockUser);
    on<UnblockUser>(_onUnblockUser);
  }

  Future<void> _onBlockUser(
    BlockUser event,
    Emitter<BlockUserState> emit,
  ) async {
    emit(BlockUserLoading());
    try {
      await repository.blockUser(
        blockerId: event.blockerId,
        blockedId: event.blockedId,
      );
      await OfflineCache.clearPostsCache();
      emit(BlockUserSuccess());
    } catch (e) {
      emit(BlockUserFailure(e.toString()));
    }
  }

  Future<void> _onUnblockUser(
    UnblockUser event,
    Emitter<BlockUserState> emit,
  ) async {
    emit(BlockUserLoading());
    try {
      await repository.unblockUser(
        blockerId: event.blockerId,
        blockedId: event.blockedId,
      );
      // Clear offline cache to allow unblocked user's posts to reappear
      await OfflineCache.clearPostsCache();
      emit(BlockUserSuccess());
    } catch (e) {
      emit(BlockUserFailure(e.toString()));
    }
  }
}
