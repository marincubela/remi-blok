import 'package:flutter_test/flutter_test.dart';
import 'package:kartaski_blok/remi_repository.dart';

void main() {
  group('RemiRepository', () {
    test('adds and removes players within limits', () {
      final repo = RemiRepository([]);

      expect(repo.numberOfPlayers(), 0);

      // Add up to the maximum number of players.
      for (int i = 0; i < RemiRepository.maxPlayers; i++) {
        final added = repo.addPlayer('Player $i');
        expect(added, isTrue);
      }
      expect(repo.numberOfPlayers(), RemiRepository.maxPlayers);

      // Adding beyond the maximum should fail.
      final extraAdded = repo.addPlayer('Extra');
      expect(extraAdded, isFalse);

      // Removing down to the minimum is allowed.
      while (repo.numberOfPlayers() > RemiRepository.minPlayers) {
        final removed = repo.removeLastPlayer();
        expect(removed, isTrue);
      }
      expect(repo.numberOfPlayers(), RemiRepository.minPlayers);

      // Removing below the minimum should fail.
      final removedBelowMin = repo.removeLastPlayer();
      expect(removedBelowMin, isFalse);
    });

    test('adds and removes rounds respecting minimum', () {
      final repo = RemiRepository(['A', 'B']);

      expect(repo.points.length, 0);

      repo.addRound();
      expect(repo.points.length, 1);

      final cannotRemoveLast = repo.removeLastRound();
      expect(cannotRemoveLast, isFalse);
      expect(repo.points.length, 1);

      repo.addRound();
      expect(repo.points.length, 2);

      final removed = repo.removeLastRound();
      expect(removed, isTrue);
      expect(repo.points.length, 1);
    });

    test('setScore updates scores safely', () {
      final repo = RemiRepository(['A', 'B']);
      repo.addRound();

      repo.setScore(0, 0, 10);
      repo.setScore(0, 1, -5);

      expect(repo.points[0][0], 10);
      expect(repo.points[0][1], -5);

      // Out-of-range indices are ignored.
      repo.setScore(5, 0, 100);
      repo.setScore(0, 5, 100);
      expect(repo.points[0][0], 10);
      expect(repo.points[0][1], -5);
    });

    test('calculateTotals and calculateCumulativeTotals work correctly', () {
      final repo = RemiRepository(['A', 'B']);
      repo.addRound();
      repo.addRound();

      repo.setScore(0, 0, 10);
      repo.setScore(0, 1, 20);
      repo.setScore(1, 0, -5);
      repo.setScore(1, 1, 15);

      expect(repo.calculateTotals(), [5, 35]);

      expect(repo.calculateCumulativeTotals(0), [10, 20]);
      expect(repo.calculateCumulativeTotals(1), [5, 35]);
    });
  });
}
