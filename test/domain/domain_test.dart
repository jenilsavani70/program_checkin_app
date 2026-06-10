import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:program_checkin_app/src/core/formatting.dart';
import 'package:program_checkin_app/src/core/result.dart';
import 'package:program_checkin_app/src/domain/checkin.dart';

void main() {
  test(
    'mixed progress parsing handles numeric, comma decimal, and invalid values',
    () {
      expect(parseProgressValue(80), 80);
      expect(parseProgressValue(80.4), 80.4);
      expect(parseProgressValue('80,4'), 80.4);
      expect(parseProgressValue('not a number'), isNull);
    },
  );

  test('check-in validation requires progress, adherence, and wellbeing', () {
    final failures = const CheckInDraft().validate();
    expect(
      failures.map((failure) => failure.safeCode),
      containsAll([
        'progress_required',
        'adherence_required',
        'wellbeing_required',
      ]),
    );
  });

  test('draft maps to typed submission without widget logic', () {
    final result = const CheckInDraft(
      progressValue: 81.5,
      adherence: Adherence.completed,
      wellbeing: Wellbeing.good,
      note: ' keep this private ',
    ).toSubmission(submittedAt: DateTime.utc(2026, 6, 8));

    expect(result, isA<Success<CheckInSubmission>>());
    final submission = (result as Success<CheckInSubmission>).value;
    expect(submission.idempotencyKey, 'checkin-2026-06-08');
    expect(submission.note, 'keep this private');
  });

  test('German formatting uses locale-aware decimal separator', () {
    expect(formatProgressValue(80.4, 'de'), contains(','));
  });

  test('German date formatting uses locale-aware month labels', () async {
    await initializeDateFormatting('de');
    final formatted = formatShortDate(DateTime.utc(2026, 6, 8), 'de');
    expect(formatted, isNot(contains('2026-06-08')));
    expect(formatted, contains('2026'));
  });
}
