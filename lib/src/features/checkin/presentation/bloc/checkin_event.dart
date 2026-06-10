import 'package:equatable/equatable.dart';

import '../../../../domain/checkin.dart';

sealed class CheckInEvent extends Equatable {
  const CheckInEvent();

  @override
  List<Object?> get props => [];
}

class CheckInProgressChanged extends CheckInEvent {
  const CheckInProgressChanged(this.value);

  final double? value;

  @override
  List<Object?> get props => [value];
}

class CheckInAdherenceChanged extends CheckInEvent {
  const CheckInAdherenceChanged(this.value);

  final Adherence value;

  @override
  List<Object?> get props => [value];
}

class CheckInWellbeingChanged extends CheckInEvent {
  const CheckInWellbeingChanged(this.value);

  final Wellbeing value;

  @override
  List<Object?> get props => [value];
}

class CheckInNoteChanged extends CheckInEvent {
  const CheckInNoteChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class CheckInNextPressed extends CheckInEvent {
  const CheckInNextPressed();
}

class CheckInBackPressed extends CheckInEvent {
  const CheckInBackPressed();
}

class CheckInFlowStarted extends CheckInEvent {
  const CheckInFlowStarted(this.correlationId);

  final String correlationId;

  @override
  List<Object?> get props => [correlationId];
}

class CheckInSubmitPressed extends CheckInEvent {
  const CheckInSubmitPressed();
}
