import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:program_checkin_app/src/app.dart';
import 'package:program_checkin_app/src/domain/checkin.dart';
import 'package:program_checkin_app/src/features/checkin/presentation/widgets/checkin_widgets.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('dashboard renders at a small viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProgramCheckInApp(scope: testScope()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Maya'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Pending check-in'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pending check-in'), findsOneWidget);
    expect(find.text('Active program'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('History'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsWidgets);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Pending check-in'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Pending check-in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small viewport with large text avoids layout overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => tester.platformDispatcher.textScaleFactorTestValue = 1.0);
    await tester.pumpWidget(ProgramCheckInApp(scope: testScope()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Maya'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Maya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('check-in progress step renders from dashboard', (tester) async {
    await tester.pumpWidget(ProgramCheckInApp(scope: testScope()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Pending check-in'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Pending check-in'));
    await tester.pumpAndSettle();

    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets(
    'custom selection control exposes semantics label, selected state, and tap action',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionGroup<Adherence>(
              title: 'Adherence',
              values: Adherence.values,
              value: Adherence.completed,
              labelFor: (value) => value.name,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'completed',
      );
      expect(
        tester.getSemantics(semanticsFinder),
        matchesSemantics(
          label: 'completed',
          isSelected: true,
          isButton: true,
          hasSelectedState: true,
          hasTapAction: true,
        ),
      );
    },
  );

  testWidgets('locale switch updates English and German labels', (
    tester,
  ) async {
    await tester.pumpWidget(ProgramCheckInApp(scope: testScope()));
    await tester.pumpAndSettle();

    expect(find.text('History'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    expect(find.text('Verlauf'), findsOneWidget);
  });
}
