import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartaski_blok/remi.dart';
import 'package:kartaski_blok/remi_repository.dart';
import 'package:kartaski_blok/remi_storage.dart';

class FakeRemiStorage extends RemiStorage {
  RemiRepository _repository = RemiRepository(['Alice', 'Bob']);

  @override
  Future<RemiRepository> readGame(String gameId) async {
    // Ensure we have at least one round
    if (_repository.points.isEmpty) {
      _repository.addRound();
    }
    return _repository;
  }

  @override
  Future<void> writeGame(String gameId, RemiRepository repository) async {
    _repository = repository;
  }
}

void main() {
  testWidgets('ScoreCell allows inline editing and updates repository',
      (WidgetTester tester) async {
    final storage = FakeRemiStorage();

    await tester.pumpWidget(
      MaterialApp(
        home: RemiPage(
          title: 'Inline Test',
          storage: storage,
          gameId: 'test-inline',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial state: Scores are 0. displayed as empty string in roundScore mode?
    // In roundScore mode: "mainText = score != 0 ? score.toString() : '';" -> so empty string.
    // ScoreCell when not editing shows a Text widget inside a Column.
    // The text content should be empty string or 0 depending on logic.
    // Let's find the ScoreCell.
    final scoreCellFinder = find.byType(ScoreCell);
    expect(scoreCellFinder,
        findsWidgets); // Should find at least 2 cells (2 players)

    // Tap the first cell (Round 1, Player 1)
    await tester.tap(scoreCellFinder.first);
    await tester.pumpAndSettle(); // Rebuild to show TextField

    // Verify TextField appears inside the ScoreCell
    final textFieldFinder = find.descendant(
      of: scoreCellFinder.first,
      matching: find.byType(TextField),
    );
    expect(textFieldFinder, findsOneWidget);

    // Enter a score
    await tester.enterText(textFieldFinder, '50');
    await tester.testTextInput
        .receiveAction(TextInputAction.next); // Simulate "Next" or submit
    await tester.pumpAndSettle(); // Allow writeGame to complete (async)
    // Wait for the writeGame future? writeGame is awaited inside setState but it's fire-and-forget in the callback:
    // "widget.storage.writeGame(widget.gameId, repository);"
    // It is NOT awaited in the callback properly (setState is sync).
    // But verify the UI updates.

    // After submission, the cell should return to display mode (unless focus moves to next cell??)
    // Actually, onFieldSubmitted calls FocusScope.of(context).nextFocus();
    // In test environment, next focus might be the next cell?
    // Let's verify that the repository was updated.

    // We can check by re-reading from storage or checking UI.
    // UI should show '50' now (Round score, Cumulative score, and Total footer)
    expect(find.text('50'), findsAtLeastNWidgets(1));

    // Verify persistence
    final repo = await storage.readGame('test-inline');
    expect(repo.points[0][0], 50);
  });
}
