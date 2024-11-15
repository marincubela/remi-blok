import 'package:flutter/material.dart';
import 'package:remi_blok/keyboard.dart';
import 'package:remi_blok/remi_repository.dart';
import 'package:remi_blok/remi_storage.dart';

class RemiPage extends StatefulWidget {
  const RemiPage({super.key, required this.title, required this.storage});

  final String title;
  final RemiStorage storage;

  @override
  State<RemiPage> createState() => _RemiPageState();
}

class _RemiPageState extends State<RemiPage> {
  RemiRepository repository = RemiRepository([]);
  final FocusNode _focus = FocusNode(); // 1) init _focus
  TextEditingController textController = TextEditingController();
  static const insideBorder = BorderSide(color: Colors.black, width: 0.1);

  void _resetGame() {
    setState(() {
      repository = RemiRepository(['', '']);
    });

    widget.storage.writeRemi(repository);
  }

  void _addPlayer() {
    setState(() {
      repository.addPlayer('');
    });

    widget.storage.writeRemi(repository);
  }

  void _removePlayer() {
    setState(() {
      repository.removeLastPlayer();
    });

    widget.storage.writeRemi(repository);
  }

  void _addRound() {
    setState(() {
      repository.addRound();
    });

    widget.storage.writeRemi(repository);
  }

  void _removeRound() {
    setState(() {
      repository.removeLastRound();
    });

    widget.storage.writeRemi(repository);
  }

  void _updatePlayerName(int index, String newName) {
    setState(() {
      repository.updatePlayerName(index, newName);
    });

    widget.storage.writeRemi(repository);
  }

  @override
  void initState() {
    super.initState();
    widget.storage.readRemi().then((value) {
      setState(() {
        repository = value;
      });
    });
    _focus.addListener(_onFocusChange); // 2) add listener to our focus
  }

  @override
  void dispose() {
    super.dispose();
    textController.dispose();
    _focus
      ..removeListener(_onFocusChange)
      ..dispose(); // 3) removeListener and dispose
  }

// 4)
  void _onFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remi blok'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addPlayer,
            tooltip: 'Add Player',
            color: Theme.of(context).colorScheme.primary,
          ),
          IconButton(
            icon: const Icon(Icons.person_remove),
            onPressed: _removePlayer,
            tooltip: 'Remove Player',
            color: Theme.of(context).colorScheme.primary,
          ),
          IconButton(
            icon: const Icon(Icons.playlist_remove 
            ),
            onPressed: _resetGame,
            tooltip: 'Reset game',
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Table(
              columnWidths: repository.players
                  .map((e) => const FlexColumnWidth())
                  .toList()
                  .asMap(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(verticalInside: insideBorder),
              children: _buildTable(),
            ),
            // 6) if hasFocus show keyboard, else show empty container
            _focus.hasFocus
                ? NumericKeypad(
                    controller: textController,
                    focusNode: _focus,
                  )
                : Container(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.primary,
            width: 4)
            )
          ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OverflowBar(
            alignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(                
                backgroundColor: Theme.of(context).colorScheme.surface,
                onPressed: _addRound,
                tooltip: 'Add Round',
                child: Icon(Icons.add,
                   color: Theme.of(context).colorScheme.primary),
              ),
              FloatingActionButton(
                backgroundColor: Theme.of(context).colorScheme.surface,
                onPressed: _removeRound,
                tooltip: 'Remove Round',
                child: Icon(Icons.remove,
                   color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TableRow> _buildTable() {
    List<TableRow> tableRows = [];
    var primary = Theme.of(context).colorScheme.primary;

    if (repository.players.isEmpty) {
      return tableRows;
    }

    // Header row with player names
    tableRows.add(TableRow(
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: primary))),
      children: [
        ...repository.players.asMap().entries.map((entry) {
          var index = entry.key;
          var player = entry.value;
          return TableCell(
            child: TextFormField(
              initialValue: repository.players[index].toString(),
              textAlign: TextAlign.center,
                decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Igrač ${index + 1}',
              ),
              // onChanged: (newValue) => _updatePlayerName(repository.players.indexOf(player), newValue),
              onChanged : (newValue) {
                setState(() {
                    _updatePlayerName(repository.players.indexOf(player), newValue);

                    widget.storage.writeRemi(repository);
                  });
              },
              onFieldSubmitted: (newValue) => _updatePlayerName(
                  repository.players.indexOf(player), newValue),
            ),
          );
        }),
      ],
    ));

    // Data rows for each round
    for (int roundIndex = 0;
        roundIndex < repository.points.length;
        roundIndex++) {
      var round = repository.points[roundIndex];
      tableRows.add(TableRow(
        decoration: roundIndex % repository.numberOfPlayers() == 0
            ? BoxDecoration(
                border: Border(top: BorderSide(color: primary, width: 1)))
            : const BoxDecoration(border: Border(top: insideBorder)),
        children: [
          ...round.asMap().entries.map((entry) {
            var index = entry.key;
            var score = entry.value;
            return TableCell(
              child: TextFormField(
                initialValue: repository.points[roundIndex][index] != 0
                  ? repository.points[roundIndex][index].toString()
                  : '',
                onChanged: (newValue) {
                  setState(() {
                    repository.points[roundIndex][index] =
                        int.tryParse(newValue) ?? score;

                    widget.storage.writeRemi(repository);
                  });
                },
                textAlign: TextAlign.center,
                // controller: textController,
                // focusNode: _focus, // 5) pass our focusNode to our textfield
                // keyboardType: TextInputType.none,
                keyboardType: TextInputType.numberWithOptions(signed: true),
                onFieldSubmitted: (newValue) {
                  setState(() {
                    repository.points[roundIndex][index] =
                        int.tryParse(newValue) ?? score;

                    widget.storage.writeRemi(repository);
                  });
                },
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            );
          }),
        ],
      ));
    }

    // Total row
    tableRows.add(TableRow(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(width: 2, color: primary))),
      children: [
        ...repository.calculateTotals().map((total) => TableCell(
              child: Container(
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Text(
                    total.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  )),
            )),
      ],
    ));

    return tableRows;
  }
}
