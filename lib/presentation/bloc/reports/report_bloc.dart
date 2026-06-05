import 'package:dating_app/domain/repositories/reports_repository.dart';
import 'package:dating_app/presentation/bloc/reports/report_event.dart';
import 'package:dating_app/presentation/bloc/reports/report_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        reportedUserId: event.postId,
        reporterId: event.reporterId,
        postId: event.postId,
        reason: event.reason,
      );
      emit(ReportsSuccess());
    } catch (e) {
      emit(ReportsFailure(e.toString()));
    }
  }
}

class BlockUserBloc extends Bloc<BlockUserEvent, BlockUserState> {
  final ReportsRepository repository;

  BlockUserBloc(this.repository) : super(BlockUserInitial()) {
    on<BlockUser>(_onBlockUser);
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
      emit(BlockUserSuccess());
    } catch (e) {
      emit(BlockUserFailure(e.toString()));
    }
  }
}
