import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/di/app_scope.dart';

void main() {
  runApp(ProgramCheckInApp(scope: AppScope.demo()));
}
