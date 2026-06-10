import 'dart:ui';

class AppColors {
  const AppColors._();

  static const light = AppColorScheme(ink: Color(0xff143d36));
}

class AppColorScheme {
  const AppColorScheme({required this.ink});

  final Color ink;
}
