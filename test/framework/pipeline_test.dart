import 'package:alba/src/framework/pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

class AddPipe extends PipelineHandler<int> {
  bool wasCalled = false;

  @override
  void handle(int subject, next) {
    wasCalled = true;
    next(subject + 1);
  }
}

class AbortPipe extends PipelineHandler<int> {
  @override
  void handle(int subject, next) {
    // This pipe doesn't call next.
  }
}

void main() {
  group('Pipeline', () {
    test('runs through pipes', () {
      var subject = 1;
      var pipe1 = AddPipe();
      var pipe2 = AddPipe();
      var thenWasCalled = false;
      int? result;

      pipeline<int>(
        subject,
        [pipe1, pipe2],
        (subject) {
          thenWasCalled = true;
          result = subject;
        },
      );

      expect(pipe1.wasCalled, true);
      expect(pipe2.wasCalled, true);
      expect(thenWasCalled, true);
      expect(result, 3);
    });

    test('is aborted', () {
      var subject = 1;
      var pipe1 = AddPipe();
      var pipe2 = AbortPipe();
      var pipe3 = AddPipe();
      var thenWasCalled = false;
      int? result;

      pipeline<int>(
        subject,
        [pipe1, pipe2],
        (subject) {
          thenWasCalled = true;
          result = subject;
        },
      );

      expect(pipe1.wasCalled, true);
      expect(pipe3.wasCalled, false);
      expect(thenWasCalled, false);
      expect(result, null);
    });
  });
}
