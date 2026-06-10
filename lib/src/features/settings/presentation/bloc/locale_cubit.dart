import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/session_repository.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({required this.sessionRepository}) : super(const Locale('en'));

  final SessionRepository sessionRepository;

  Future<void> load() async {
    final saved = await sessionRepository.loadLocale();
    if (saved == 'de' || saved == 'en') emit(Locale(saved!));
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'en' && locale.languageCode != 'de') return;
    await sessionRepository.saveLocale(locale.languageCode);
    emit(locale);
  }
}
