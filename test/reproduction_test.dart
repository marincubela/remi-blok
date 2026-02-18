import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartaski_blok/remi.dart';
import 'package:kartaski_blok/remi_repository.dart';
import 'package:kartaski_blok/remi_storage.dart';

class FakeRemiStorage extends RemiStorage {
  RemiRepository _repository = RemiRepository(['A', 'B']);

  @override
  Future<RemiRepository> readGame(String gameId) async {
    return _repository;
  }

  @override
  Future<void> writeGame(String gameId, RemiRepository repository) async {
    _repository = repository;
  }
}

void main() {
  testWidgets('RemiPage layout reproduction', (WidgetTester tester) async {
    // Set a surface size to ensure layout constraints are active
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;

    final storage = FakeRemiStorage();

    await tester.pumpWidget(
      MaterialApp(
        home: RemiPage(
          title: 'Test Remi',
          storage: storage,
          gameId: 'test-game',
        ),
      ),
    );

    // Let the initial readRemi future complete.
    await tester.pumpAndSettle();

    // Verify Tables exist (Header, Body, Footer)
    final tableFinder = find.byType(Table);
    expect(tableFinder, findsNWidgets(3));

    // We can check the body table (index 1)
    final bodyTableFinder = tableFinder.at(1);
    final Size tableSize = tester.getSize(bodyTableFinder);
    print('Body Table size: $tableSize');

    // If width is 0, it explains why it's invisible to the user
    // However, in a test environment with unconstrained parent width,
    // Table might just take 0 width without failing if not asserted.
    // Or it might be the cause of "broken" look.

    // In actual app, SingleChildScrollView (horizontal) gives infinite width constraint.
    // Table with FlexColumnWidth needs definite width.
    // This usually throws: "RenderTable ... has non-zero flex column widths but the table has unbounded width."

    // Let's assert width > 0 to see if it's rendering at all.
    expect(tableSize.width, greaterThan(0));

    // Check if exception was thrown
    expect(tester.takeException(), isNull);
  });
}
