import 'package:nightingale/core/activitypub/models/ap_activity.dart';

sealed class ValidationResult {}

class ValidationOk extends ValidationResult {
  ValidationOk(this.activity);
  final ApActivity activity;
}

class ValidationDropped extends ValidationResult {
  ValidationDropped(this.reason);
  final String reason;
}

class ActivityValidator {
  const ActivityValidator();

  ValidationResult validate(Map<String, dynamic> json) {
    try {
      final activity = ApActivity.fromJson(json);
      return ValidationOk(activity);
    } on UnrecognizedActivityTypeException catch (e) {
      return ValidationDropped('unrecognized type: ${e.type}');
    } catch (e) {
      return ValidationDropped('parse error: $e');
    }
  }
}
