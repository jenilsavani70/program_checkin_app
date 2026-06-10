import 'package:flutter/widgets.dart';

import '../domain/checkin.dart';

class AppStrings {
  const AppStrings(this.localeCode);

  final String localeCode;

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  bool get isGerman => localeCode == 'de';
  String get appTitle => isGerman ? 'Programm Check-in' : 'Program Check-in';
  String get dashboard => isGerman ? 'Dashboard' : 'Dashboard';
  String get history => isGerman ? 'Verlauf' : 'History';
  String get retry => isGerman ? 'Erneut versuchen' : 'Retry';
  String get startCheckIn => isGerman ? 'Check-in starten' : 'Start check-in';
  String get pendingTask =>
      isGerman ? 'Ausstehender Check-in' : 'Pending check-in';
  String get noPendingTask =>
      isGerman ? 'Kein Check-in offen' : 'No check-in pending';
  String get activeProgram => isGerman ? 'Aktives Programm' : 'Active program';
  String get currentWeek => isGerman ? 'Aktuelle Woche' : 'Current week';
  String get due => isGerman ? 'Faellig' : 'Due';
  String get region => isGerman ? 'Region' : 'Region';
  String get progress => isGerman ? 'Fortschritt' : 'Progress';
  String get adherence => isGerman ? 'Umsetzung' : 'Adherence';
  String get wellbeing => isGerman ? 'Wohlbefinden' : 'Wellbeing';
  String get note => isGerman ? 'Notiz' : 'Note';
  String get optional => isGerman ? 'Optional' : 'Optional';
  String get next => isGerman ? 'Weiter' : 'Next';
  String get back => isGerman ? 'Zurueck' : 'Back';
  String get submit => isGerman ? 'Senden' : 'Submit';
  String get summary => isGerman ? 'Zusammenfassung' : 'Summary';
  String get supportTitle => isGerman ? 'Unterstuetzung' : 'Support';
  String get supportCopy => isGerman
      ? 'Deine Auswahl wurde gespeichert. Pruefe die Zusammenfassung, wenn du bereit bist.'
      : 'Your selection was saved. Review the summary when you are ready.';
  String get requiredField => isGerman ? 'Pflichtfeld' : 'Required';
  String get locale => isGerman ? 'Sprache' : 'Language';
  String get english => 'English';
  String get german => 'Deutsch';
  String get signedOut => isGerman ? 'Sitzung beendet' : 'Signed out';
  String get refreshSession =>
      isGerman ? 'Sitzung erneuern' : 'Refresh session';
  String get submitFailed =>
      isGerman ? 'Senden fehlgeschlagen' : 'Submit failed';
  String get tryAgain => isGerman ? 'Nochmals versuchen' : 'Try again';
  String get emptyDashboard =>
      isGerman ? 'Keine Programmdaten' : 'No program data';
  String get invalidRoute => isGerman ? 'Ungueltige Route' : 'Invalid route';

  String greeting(String firstName) => '$appTitle, $firstName';

  String currentWeekValue(int week) => '$currentWeek $week';

  String programWeekSummary(String programName, int week) {
    return '$programName - ${currentWeekValue(week)}';
  }

  String dueDate(String date) => '$due: $date';

  String errorWithCode(String code) => '$submitFailed: $code';

  String noteOptionalLabel() => '$note ($optional)';

  String historyAdherence(String value) => '$adherence: $value';

  String summaryProgress(String value) => '$progress: $value';

  String summaryAdherence(String value) => '$adherence: $value';

  String summaryWellbeing(String value) => '$wellbeing: $value';

  String adherenceOption(Adherence value) {
    return switch (value) {
      Adherence.completed =>
        isGerman ? 'Wie geplant abgeschlossen' : 'Completed as planned',
      Adherence.partial =>
        isGerman ? 'Teilweise abgeschlossen' : 'Partially completed',
      Adherence.missed => isGerman ? 'Verpasst' : 'Missed',
    };
  }

  String wellbeingOption(Wellbeing value) {
    return switch (value) {
      Wellbeing.good => isGerman ? 'Gut' : 'Good',
      Wellbeing.okay => isGerman ? 'Okay' : 'Okay',
      Wellbeing.needsSupport =>
        isGerman ? 'Braucht Unterstuetzung' : 'Needs support',
    };
  }
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async =>
      AppStrings(locale.languageCode);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
