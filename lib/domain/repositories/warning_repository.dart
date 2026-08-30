import 'package:dating_app/data/models/warning_model.dart';

abstract class WarningRepository {
  Future<UserWarning> getUserWarning();
}