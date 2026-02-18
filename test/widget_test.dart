import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartaski_blok/remi.dart';
import 'package:kartaski_blok/remi_repository.dart';
import 'package:kartaski_blok/remi_storage.dart';

class FakeRemiStorage extends RemiStorage {
  RemiRepository _repository = RemiRepository(['', '']);

  @override
  Future<RemiRepository> readGame(String gameId) async {
    return _repository;
  }

  @override
  Future<void> writeGame(String gameId, RemiRepository repository) async {
    _repository = repository;
    // Return a dummy file reference; the path is not used in tests.
  }
}

void main() {
  testWidgets('RemiPage toggles display mode icon', (WidgetTester tester) async {
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

    // Starts in roundScore mode (looks_one icon).
    expect(find.byIcon(Icons.looks_one), findsOneWidget);

    // Tap to switch to cumulativeScore (trending_up icon).
    await tester.tap(find.byIcon(Icons.looks_one));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.trending_up), findsOneWidget);
  });
}
