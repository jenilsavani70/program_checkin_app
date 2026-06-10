import 'package:equatable/equatable.dart';

import '../core/result.dart';

enum Adherence { completed, partial, missed }

enum Wellbeing { good, okay, needsSupport }

class CheckInDraft extends Equatable {
  const CheckInDraft({
    this.progressValue,
    this.adherence,
    this.wellbeing,
    this.note = '',
  });

  final double? progressValue;
  final Adherence? adherence;
  final Wellbeing? wellbeing;
  final String note;

  CheckInDraft copyWith({
    double? progressValue,
    bool clearProgress = false,
    Adherence? adherence,
    Wellbeing? wellbeing,
    String? note,
  }) {
    return CheckInDraft(
      progressValue: clearProgress ? null : progressValue ?? this.progressValue,
      adherence: adherence ?? this.adherence,
      wellbeing: wellbeing ?? this.wellbeing,
      note: note ?? this.note,
    );
  }

  List<AppFailure> validate() {
    final failures = <AppFailure>[];
    if (progressValue == null || progressValue! < 0 || progressValue! > 999) {
      failures.add(
        const AppFailure(
          kind: FailureKind.validation,
          safeCode: 'progress_required',
          retryable: false,
        ),
      );
    }
    if (adherence == null) {
      failures.add(
        const AppFailure(
          kind: FailureKind.validation,
          safeCode: 'adherence_required',
          retryable: false,
        ),
      );
    }
    if (wellbeing == null) {
      failures.add(
        const AppFailure(
          kind: FailureKind.validation,
          safeCode: 'wellbeing_required',
          retryable: false,
        ),
      );
    }
    return failures;
  }

  Result<CheckInSubmission> toSubmission({required DateTime submittedAt}) {
    final failures = validate();
    if (failures.isNotEmpty) return Failure(failures.first);
    return Success(
      CheckInSubmission(
        idempotencyKey:
            'checkin-${submittedAt.toIso8601String().substring(0, 10)}',
        submittedAt: submittedAt,
        progressValue: progressValue!,
        adherence: adherence!,
        wellbeing: wellbeing!,
        note: note.trim().isEmpty ? null : note.trim(),
      ),
    );
  }

  @override
  List<Object?> get props => [progressValue, adherence, wellbeing, note];
}

class CheckInSubmission extends Equatable {
  const CheckInSubmission({
    required this.idempotencyKey,
    required this.submittedAt,
    required this.progressValue,
    required this.adherence,
    required this.wellbeing,
    this.note,
  });

  final String idempotencyKey;
  final DateTime submittedAt;
  final double progressValue;
  final Adherence adherence;
  final Wellbeing wellbeing;
  final String? note;

  @override
  List<Object?> get props => [
    idempotencyKey,
    submittedAt,
    progressValue,
    adherence,
    wellbeing,
    note,
  ];
}

class CheckInEntry extends Equatable {
  const CheckInEntry({
    required this.id,
    required this.date,
    required this.progressValue,
    required this.adherence,
    required this.wellbeing,
  });

  final String id;
  final DateTime date;
  final double? progressValue;
  final Adherence adherence;
  final Wellbeing wellbeing;

  @override
  List<Object?> get props => [id, date, progressValue, adherence, wellbeing];
}
