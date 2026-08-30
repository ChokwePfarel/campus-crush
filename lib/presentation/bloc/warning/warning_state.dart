import 'package:dating_app/data/models/warning_model.dart';

abstract class WarningState {}

class WarningInitial extends WarningState {}

class WarningLoading extends WarningState {}

class WarningLoaded extends WarningState {
  final UserWarning warning;
  WarningLoaded(this.warning);
}

class WarningEmpty extends WarningState {} // no active warning

class WarningError extends WarningState {
  final String message;
  WarningError(this.message);
}
