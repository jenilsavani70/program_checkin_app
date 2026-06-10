enum CheckInReturnTo { dashboard, history }

class CheckInRouteArgs {
  const CheckInRouteArgs({this.returnTo = CheckInReturnTo.history});

  final CheckInReturnTo returnTo;

  static CheckInRouteArgs? decode(Object? extra) {
    if (extra == null) return const CheckInRouteArgs();
    if (extra is CheckInRouteArgs) return extra;
    return null;
  }
}

class HistoryRouteArgs {
  const HistoryRouteArgs();

  static HistoryRouteArgs? decode(Object? extra) {
    if (extra == null) return const HistoryRouteArgs();
    if (extra is HistoryRouteArgs) return extra;
    return null;
  }
}
