class RemiRepository {
  /// Minimum number of players required for a valid game.
  static const int minPlayers = 2;

  /// Maximum number of players supported.
  static const int maxPlayers = 7;

  /// Minimum number of rounds to keep when removing.
  static const int minRounds = 1;

  RemiRepository(List<String> players) {
    for (final player in players) {
      addPlayer(player);
    }
  }

  List<String> players = [];
  List<List<int>> points = [];

  int numberOfPlayers() {
    return players.length;
  }

  bool addPlayer(String name) {
    if (numberOfPlayers() >= maxPlayers) {
      return false;
    }

    players.add(name);

    for (final round in points) {
      round.add(0);
    }

    return true;
  }

  bool removeLastPlayer() {
    if (players.length <= minPlayers) {
      return false;
    }

    players.removeLast();

    for (final round in points) {
      if (round.isNotEmpty) {
        round.removeLast();
      }
    }

    return true;
  }

  void addRound() {
    if (players.isEmpty) {
      return;
    }
    points.add(List<int>.filled(players.length, 0, growable: true));
  }

  bool removeLastRound() {
    if (points.length <= minRounds) {
      return false;
    }

    points.removeLast();
    return true;
  }

  /// Safely set the score for a given [roundIndex] and [playerIndex].
  /// Out-of-range indices are ignored.
  void setScore(int roundIndex, int playerIndex, int score) {
    if (roundIndex < 0 ||
        roundIndex >= points.length ||
        playerIndex < 0 ||
        (points.isNotEmpty && playerIndex >= points[roundIndex].length)) {
      return;
    }
    points[roundIndex][playerIndex] = score;
  }

  List<int> calculateTotals() {
    final totals = List<int>.filled(players.length, 0);
    for (final round in points) {
      for (int i = 0; i < round.length; i++) {
        totals[i] += round[i];
      }
    }
    return totals;
  }

  List<int> calculateCumulativeTotals(int upToRound) {
    final totals = List<int>.filled(players.length, 0);
    for (int roundIndex = 0;
        roundIndex <= upToRound && roundIndex < points.length;
        roundIndex++) {
      final round = points[roundIndex];
      for (int i = 0; i < round.length; i++) {
        totals[i] += round[i];
      }
    }
    return totals;
  }

  void updatePlayerName(int index, String newName) {
    if (newName.isNotEmpty && index >= 0 && index < players.length) {
      players[index] = newName;
    }
  }

  Map<String, dynamic> toJson() => {
        'version': 1,
        'players': players,
        'points': points,
      };

  static List<List<int>> parsePoints(dynamic json) {
    final firstList = json as List<dynamic>;

    final secondList = firstList.map((e) {
      final innerList = e as List<dynamic>;
      return innerList.map((value) => value as int).toList();
    }).toList();

    return secondList;
  }

  RemiRepository.fromJson(Map<String, dynamic> json)
      : players = List<String>.from(json['players'] as List),
        points = parsePoints(json['points']);
}
