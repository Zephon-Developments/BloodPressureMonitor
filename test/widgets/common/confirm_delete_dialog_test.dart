import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/widgets/common/confirm_delete_dialog.dart';

void main() {
  testWidgets('resolves to true when delete is confirmed',
      (WidgetTester tester) async {
    final completer = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await ConfirmDeleteDialog.show(
                context,
                title: 'Delete?',
                message: 'Really delete this item?',
              );
              completer.complete(result);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();

    expect(await completer.future, isTrue);
  });

  testWidgets('resolves to false when dialog is cancelled',
      (WidgetTester tester) async {
    final completer = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              final result = await ConfirmDeleteDialog.show(
                context,
                title: 'Delete?',
                message: 'Really delete this item?',
              );
              completer.complete(result);
            },
            child: const Text('Open Dialog'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await completer.future, isFalse);
  });
}
