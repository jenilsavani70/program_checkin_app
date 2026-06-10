import 'package:equatable/equatable.dart';

class ProgramDashboard extends Equatable {
  const ProgramDashboard({
    required this.firstName,
    required this.region,
    required this.programName,
    required this.currentWeek,
    required this.nextCheckInDue,
    required this.hasPendingTask,
  });

  final String firstName;
  final String region;
  final String programName;
  final int currentWeek;
  final DateTime nextCheckInDue;
  final bool hasPendingTask;

  ProgramDashboard copyWith({bool? hasPendingTask}) {
    return ProgramDashboard(
      firstName: firstName,
      region: region,
      programName: programName,
      currentWeek: currentWeek,
      nextCheckInDue: nextCheckInDue,
      hasPendingTask: hasPendingTask ?? this.hasPendingTask,
    );
  }

  @override
  List<Object?> get props => [
    firstName,
    region,
    programName,
    currentWeek,
    nextCheckInDue,
    hasPendingTask,
  ];
}
