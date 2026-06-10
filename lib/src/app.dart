import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_router.dart';
import 'app/app_theme.dart';
import 'core/localization.dart';
import 'di/app_scope.dart';
import 'data/session_repository.dart';
import 'features/checkin/presentation/bloc/checkin.dart';
import 'features/dashboard/presentation/bloc/dashboard.dart';
import 'features/settings/presentation/bloc/locale_cubit.dart';
import 'features/settings/presentation/bloc/session_cubit.dart';

class ProgramCheckInApp extends StatefulWidget {
  const ProgramCheckInApp({super.key, required this.scope});

  final AppScope scope;

  @override
  State<ProgramCheckInApp> createState() => _ProgramCheckInAppState();
}

class _ProgramCheckInAppState extends State<ProgramCheckInApp> {
  late final DashboardBloc dashboardBloc;
  late final CheckInBloc checkInBloc;
  late final LocaleCubit localeCubit;
  late final SessionCubit sessionCubit;
  late final router = buildAppRouter();

  @override
  void initState() {
    super.initState();
    unawaited(widget.scope.sessionRepository.bootstrapFakeSession());
    dashboardBloc = DashboardBloc(
      programRepository: widget.scope.programRepository,
      sessionRepository: widget.scope.sessionRepository,
      observability: widget.scope.observability,
    )..add(const DashboardLoadRequested());
    checkInBloc = CheckInBloc(
      programRepository: widget.scope.programRepository,
      sessionRepository: widget.scope.sessionRepository,
      clock: widget.scope.clock,
      observability: widget.scope.observability,
    );
    localeCubit = LocaleCubit(
      sessionRepository: widget.scope.sessionRepository,
    );
    sessionCubit = SessionCubit(
      sessionRepository: widget.scope.sessionRepository,
    );
    unawaited(localeCubit.load());
  }

  @override
  void dispose() {
    router.dispose();
    dashboardBloc.close();
    checkInBloc.close();
    localeCubit.close();
    sessionCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SessionRepository>.value(
          value: widget.scope.sessionRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: dashboardBloc),
          BlocProvider.value(value: checkInBloc),
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: sessionCubit),
        ],
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp.router(
              title: AppStrings(locale.languageCode).appTitle,
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: const [Locale('en'), Locale('de')],
              localizationsDelegates: const [
                AppStringsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: buildAppTheme(),
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}
