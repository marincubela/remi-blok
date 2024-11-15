

class RemiRepository {
  RemiRepository(List<String> players) {
    for (String player in players) {
      addPlayer(player);
    }
  }

  List<String> players = [];
  List<List<int>> points = [];

  int numberOfPlayers() {
    return players.length;
  }

  bool addPlayer(String name) {
    if (numberOfPlayers() > 6) {
      return false;
    }

    players.add(name);

    for (var round in points) {
      round.add(0);
    }

    return true;
  }

  bool removeLastPlayer() {
    if (players.length <= 2) {
      return false;
    }

    players.removeLast();

    for (var round in points) {
      round.removeLast();
    }

    return true;
  }

  void addRound() {
    points.add(List.filled(players.length, 0, growable: true));
  }

  bool removeLastRound() {
    if (points.length < 2) {
      return false;
    }

    points.removeLast();
    return true;
  }

  List<int> calculateTotals() {
    List<int> totals = List.filled(players.length, 0);
    for (var round in points) {
      for (int i = 0; i < round.length; i++) {
        totals[i] += round[i];
      }
    }
    return totals;
  }

  void updatePlayerName(int index, String newName) {
    if (newName.isNotEmpty) {
      players[index] = newName;
    }
  }

  Map<String, dynamic> toJson() =>  { 
    'players': players,
    'points': points 
  };

  static List<List<int>> parsePoints(dynamic json) {
    List<dynamic> firstList = json as List;

    var secondList = firstList.map((e) {
      var innerList = e as List;

      return innerList.map((e) => e as int).toList();
    }).toList();

    return secondList;
  }

  RemiRepository.fromJson(Map<String, dynamic> json)
    : players = List<String>.from(json['players'] as List),
      points = parsePoints(json['points']);
}
