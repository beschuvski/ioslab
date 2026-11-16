import 'package:flutter_test/flutter_test.dart';
import 'package:ioslab_app/lab_model.dart';

void main() {
  group('LabModel', () {
    test('starts with two of three checks passing', () {
      final LabModel model = LabModel();
      expect(model.total, 3);
      expect(model.passed, 2);
      expect(model.summary, '2/3 checks passing');
      expect(model.isComplete, isFalse);
    });

    test('runNextCheck promotes the first pending check', () {
      final LabModel model = LabModel();
      expect(model.runNextCheck(), isTrue);
      expect(model.passed, 3);
      expect(model.isComplete, isTrue);
      expect(model.checks.last.status, CheckStatus.pass);
    });

    test('runNextCheck returns false when everything passed', () {
      final LabModel model = LabModel();
      model.runNextCheck();
      expect(model.runNextCheck(), isFalse);
      expect(model.passed, 3);
    });

    test('checks list is unmodifiable', () {
      final LabModel model = LabModel();
      expect(
        () => model.checks.add(model.checks.first),
        throwsUnsupportedError,
      );
    });
  });
}
