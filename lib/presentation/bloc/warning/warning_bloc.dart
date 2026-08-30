import 'package:dating_app/domain/repositories/warning_repository.dart';
import 'package:dating_app/presentation/bloc/warning/warning_event.dart';
import 'package:dating_app/presentation/bloc/warning/warning_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WarningBloc extends Bloc<WarningEvent, WarningState> {

  final WarningRepository warningRepository;

  WarningBloc(this.warningRepository) : super(WarningInitial()) {
    on<FetchUserWarning>(_fetchUserWarning);
  }

  Future<void> _fetchUserWarning(FetchUserWarning event,
      Emitter<WarningState> emit) async {
    emit(WarningLoading());
    try {
      final warning = await warningRepository.getUserWarning();
      emit(WarningLoaded(warning));
    } on Exception catch (e) {
      emit(WarningError(e.toString()));
    }
  }

}