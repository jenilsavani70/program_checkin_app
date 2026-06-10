import 'package:equatable/equatable.dart';

import '../../../../core/result.dart';
import '../../../../domain/checkin.dart';

enum CheckInStatus {
  editing,
  validating,
  supportNeeded,
  submitting,
  submitted,
  retryableFailure,
  unauthorized,
  invalid,
}

class CheckInState extends Equatable {
  const CheckInState({
    required this.draft,
    required this.step,
    required this.status,
    this.failure,
    this.submittedEntry,
    this.correlationId,
  });

  const CheckInState.initial()
    : this(draft: const CheckInDraft(), step: 0, status: CheckInStatus.editing);

  final CheckInDraft draft;
  final int step;
  final CheckInStatus status;
  final AppFailure? failure;
  final CheckInEntry? submittedEntry;
  final String? correlationId;

  CheckInState copyWith({
    CheckInDraft? draft,
    int? step,
    CheckInStatus? status,
    AppFailure? failure,
    CheckInEntry? submittedEntry,
    String? correlationId,
  }) {
    return CheckInState(
      draft: draft ?? this.draft,
      step: step ?? this.step,
      status: status ?? this.status,
      failure: failure,
      submittedEntry: submittedEntry ?? this.submittedEntry,
      correlationId: correlationId ?? this.correlationId,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    step,
    status,
    failure,
    submittedEntry,
    correlationId,
  ];
}
