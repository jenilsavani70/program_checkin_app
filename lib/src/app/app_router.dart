import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../core/localization.dart';
import '../features/checkin/presentation/pages/checkin_screen.dart';
import '../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../features/history/presentation/pages/history_screen.dart';
import '../features/main/presentation/pages/recoverable_route_error.dart';
import 'route_args.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/dashboard'),
      GoRoute(
        name: 'dashboard',
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        name: 'check-in',
        path: '/check-in',
        builder: (context, state) {
          final args = CheckInRouteArgs.decode(state.extra);
          if (args == null) {
            return RecoverableRouteError(
              message: AppStrings.of(context).invalidRoute,
            );
          }
          return CheckInScreen(returnTo: args.returnTo);
        },
      ),
      GoRoute(
        name: 'history',
        path: '/history',
        builder: (context, state) {
          final args = HistoryRouteArgs.decode(state.extra);
          if (args == null) {
            return RecoverableRouteError(
              message: AppStrings.of(context).invalidRoute,
            );
          }
          return const HistoryScreen();
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return RecoverableRouteError(
        message: AppStrings.of(context).invalidRoute,
      );
    },
  );
}
