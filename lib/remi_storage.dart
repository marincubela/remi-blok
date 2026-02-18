import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kartaski_blok/remi_repository.dart';

/// Lightweight metadata about a saved Remi game.
class GameInfo {
  const GameInfo({
    required this.id,
    required this.name,
    this.lastModified,
    this.playerCount = 0,
  });

  final String id;
  final String name;
  final DateTime? lastModified;
  final int playerCount;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'lastModified': lastModified?.toIso8601String(),
        'playerCount': playerCount,
      };

  factory GameInfo.fromJson(Map<String, dynamic> json) => GameInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        lastModified: json['lastModified'] != null
            ? DateTime.tryParse(json['lastModified'] as String)
            : null,
        playerCount: (json['playerCount'] as int?) ?? 0,
      );
}

class RemiStorage {
  static const String _defaultGameName = 'Game 1';
  static const String _indexKey = 'remi_games_index';
  static const String _legacySingleKey = 'remi_scores';
  static const String _legacyTxtKey = 'Remi_blok';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _gameKey(String gameId) => 'remi_game_$gameId';

  /// List all saved games. If no index exists but a legacy single-game storage is
  /// found, it will be migrated into a single entry in the games list.
  Future<List<GameInfo>> listGames() async {
    final prefs = await _prefs;

    try {
      final indexJsonString = prefs.getString(_indexKey);
      if (indexJsonString != null) {
        final Map<String, dynamic> json =
            jsonDecode(indexJsonString) as Map<String, dynamic>;
        final List<dynamic> gamesJson =
            (json['games'] as List<dynamic>?) ?? <dynamic>[];

        final games = gamesJson
            .map((dynamic e) => GameInfo.fromJson(e as Map<String, dynamic>))
            .toList();

        // Sort by last modified descending
        games.sort((a, b) => (b.lastModified ?? DateTime(0))
            .compareTo(a.lastModified ?? DateTime(0)));

        return games;
      }

      // No index yet – try migrating from legacy single-game storage.
      final legacyRepo = await _readLegacySingleGameOrNull();
      if (legacyRepo != null) {
        final String defaultId =
            DateTime.now().millisecondsSinceEpoch.toString();
        final GameInfo info = GameInfo(
          id: defaultId,
          name: _defaultGameName,
          lastModified: DateTime.now(),
          playerCount: legacyRepo.players.length,
        );

        await prefs.setString(
            _gameKey(defaultId), jsonEncode(legacyRepo.toJson()));

        final indexJson = <String, dynamic>{
          'version': 1,
          'games': <Map<String, dynamic>>[info.toJson()],
        };
        await prefs.setString(_indexKey, jsonEncode(indexJson));

        return <GameInfo>[info];
      }

      // Completely fresh install – no games yet.
      return <GameInfo>[];
    } catch (e, stackTrace) {
      debugPrint('Error while listing games: $e');
      debugPrintStack(stackTrace: stackTrace);
      return <GameInfo>[];
    }
  }

  /// Create a new game with the given [name] and an empty repository.
  Future<GameInfo> createGame(String name) async {
    final prefs = await _prefs;
    final List<GameInfo> current = await listGames();

    final String id = DateTime.now().millisecondsSinceEpoch.toString();
    final RemiRepository repository = RemiRepository(<String>['', '']);

    final GameInfo info = GameInfo(
      id: id,
      name: name.isNotEmpty ? name : 'Game ${current.length + 1}',
      lastModified: DateTime.now(),
      playerCount: repository.players.length,
    );

    await prefs.setString(_gameKey(id), jsonEncode(repository.toJson()));

    final List<Map<String, dynamic>> gamesJson =
        current.map((GameInfo g) => g.toJson()).toList()..add(info.toJson());

    final indexJson = <String, dynamic>{
      'version': 1,
      'games': gamesJson,
    };
    await prefs.setString(_indexKey, jsonEncode(indexJson));

    return info;
  }

  /// Delete the game with [gameId] and its stored data.
  Future<void> deleteGame(String gameId) async {
    final prefs = await _prefs;
    final List<GameInfo> current = await listGames();

    final List<GameInfo> updated =
        current.where((GameInfo g) => g.id != gameId).toList();

    final indexJson = <String, dynamic>{
      'version': 1,
      'games': updated.map((GameInfo g) => g.toJson()).toList(),
    };
    await prefs.setString(_indexKey, jsonEncode(indexJson));

    try {
      await prefs.remove(_gameKey(gameId));
    } catch (e, stackTrace) {
      debugPrint('Error deleting game data for $gameId: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Rename an existing game.
  Future<void> renameGame(String gameId, String newName) async {
    final prefs = await _prefs;
    final List<GameInfo> current = await listGames();

    final List<GameInfo> updated = current
        .map(
          (GameInfo g) => g.id == gameId
              ? GameInfo(
                  id: g.id,
                  name: newName.isNotEmpty ? newName : g.name,
                  lastModified:
                      DateTime.now(), // Update timestamp on rename too
                  playerCount: g.playerCount,
                )
              : g,
        )
        .toList();

    final indexJson = <String, dynamic>{
      'version': 1,
      'games': updated.map((GameInfo g) => g.toJson()).toList(),
    };
    await prefs.setString(_indexKey, jsonEncode(indexJson));
  }

  /// Load the repository for a specific game. If the data is missing or
  /// malformed, a new default repository is returned.
  Future<RemiRepository> readGame(String gameId) async {
    final prefs = await _prefs;

    try {
      final gameJsonString = prefs.getString(_gameKey(gameId));
      if (gameJsonString == null) {
        return RemiRepository(<String>['', '']);
      }

      final Map<String, dynamic> json =
          jsonDecode(gameJsonString) as Map<String, dynamic>;
      return RemiRepository.fromJson(json);
    } on FormatException catch (e, stackTrace) {
      debugPrint('Failed to parse game $gameId: $e');
      debugPrintStack(stackTrace: stackTrace);
      return RemiRepository(<String>['', '']);
    } catch (e, stackTrace) {
      debugPrint('Unexpected error while reading game $gameId: $e');
      debugPrintStack(stackTrace: stackTrace);
      return RemiRepository(<String>['', '']);
    }
  }

  /// Persist the repository for a specific game.
  Future<void> writeGame(String gameId, RemiRepository repository) async {
    final prefs = await _prefs;
    await prefs.setString(_gameKey(gameId), jsonEncode(repository.toJson()));

    // Also update the index to reflect changes (e.g. player count or just last accessed)
    final List<GameInfo> current = await listGames();
    final int index = current.indexWhere((g) => g.id == gameId);

    if (index != -1) {
      final oldInfo = current[index];
      final newInfo = GameInfo(
        id: oldInfo.id,
        name: oldInfo.name,
        lastModified: DateTime.now(),
        playerCount: repository.players.length,
      );

      current[index] = newInfo;

      final indexJson = <String, dynamic>{
        'version': 1,
        'games': current.map((GameInfo g) => g.toJson()).toList(),
      };
      await prefs.setString(_indexKey, jsonEncode(indexJson));
    }
  }

  /// Backwards-compatible API for the previous single-game design.
  /// Uses the first game in the list, creating one if needed.
  Future<RemiRepository> readRemi() async {
    final List<GameInfo> games = await listGames();
    if (games.isEmpty) {
      final GameInfo created = await createGame(_defaultGameName);
      return readGame(created.id);
    }
    return readGame(games.first.id);
  }

  /// Backwards-compatible API for the previous single-game design.
  /// Persists to the first game in the list, creating one if needed.
  Future<void> writeRemi(RemiRepository repository) async {
    final List<GameInfo> games = await listGames();
    if (games.isEmpty) {
      final GameInfo created = await createGame(_defaultGameName);
      await writeGame(created.id, repository);
      return;
    }
    await writeGame(games.first.id, repository);
  }

  /// Try to read a legacy single-game repository from previous versions.
  /// Checks for old SharedPreferences keys that may have been used before.
  Future<RemiRepository?> _readLegacySingleGameOrNull() async {
    try {
      final prefs = await _prefs;

      // Check for legacy SharedPreferences keys
      final legacySingleJson = prefs.getString(_legacySingleKey);
      if (legacySingleJson != null) {
        final Map<String, dynamic> json =
            jsonDecode(legacySingleJson) as Map<String, dynamic>;
        return RemiRepository.fromJson(json);
      }

      final legacyTxtJson = prefs.getString(_legacyTxtKey);
      if (legacyTxtJson != null) {
        final Map<String, dynamic> json =
            jsonDecode(legacyTxtJson) as Map<String, dynamic>;
        return RemiRepository.fromJson(json);
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to read legacy single-game storage: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
    return null;
  }
}
