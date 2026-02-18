import 'package:flutter/material.dart';
import 'package:kartaski_blok/remi.dart';
import 'package:kartaski_blok/remi_storage.dart';

class GamesListPage extends StatefulWidget {
  const GamesListPage({super.key, required this.storage});

  final RemiStorage storage;

  @override
  State<GamesListPage> createState() => _GamesListPageState();
}

class _GamesListPageState extends State<GamesListPage> {
  late Future<List<GameInfo>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    _gamesFuture = widget.storage.listGames();
  }

  Future<void> _refreshGames() async {
    setState(() {
      _gamesFuture = widget.storage.listGames();
    });
  }

  Future<void> _createGame() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New game'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Game name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final newGame = await widget.storage.createGame(result);
    // Refresh list first
    await _refreshGames();

    if (!mounted) return;

    // Auto-open new game
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RemiPage(
          title: newGame.name,
          storage: widget.storage,
          gameId: newGame.id,
        ),
      ),
    );
  }

  Future<void> _renameGame(GameInfo game) async {
    final controller = TextEditingController(text: game.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename game'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Game name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null || result.trim().isEmpty) return;

    await widget.storage.renameGame(game.id, result.trim());
    await _refreshGames();
  }

  Future<void> _deleteGame(GameInfo game) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete game'),
          content: Text('Delete "${game.name}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await widget.storage.deleteGame(game.id);
    await _refreshGames();
  }

  void _openGame(GameInfo game) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => RemiPage(
              title: game.name,
              storage: widget.storage,
              gameId: game.id,
            ),
          ),
        )
        .then((_) => _refreshGames());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kartaški blok'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: FutureBuilder<List<GameInfo>>(
        future: _gamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final games = snapshot.data ?? [];
          if (games.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No games yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _createGame,
                    icon: const Icon(Icons.add),
                    label: const Text('Create first game'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshGames,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: games.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final game = games[index];

                String subtitle = '';
                if (game.lastModified != null) {
                  final date = game.lastModified!;
                  final dateStr =
                      '${date.day}.${date.month}.${date.year}. ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  subtitle = 'Last played: $dateStr';
                }

                if (game.playerCount > 0) {
                  subtitle +=
                      '${subtitle.isEmpty ? '' : ' • '}${game.playerCount} players';
                }

                return ListTile(
                  title: Text(game.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      game.name.isNotEmpty ? game.name[0].toUpperCase() : '?',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Rename',
                        onPressed: () => _renameGame(game),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () => _deleteGame(game),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () => _openGame(game),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGame,
        icon: const Icon(Icons.add),
        label: const Text('New game'),
      ),
    );
  }
}
