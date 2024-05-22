import 'package:flutter/material.dart';
import 'package:remi_blok/keyboard.dart';
import 'package:remi_blok/remi_repository.dart';

class RemiPage extends StatefulWidget {
  const RemiPage({super.key, required this.title});

  final String title;

  @override
  State<RemiPage> createState() => _RemiPageState();
}

class _RemiPageState extends State<RemiPage> {
  RemiRepository repository = RemiRepository(['', '']);
  final FocusNode _focus = FocusNode(); // 1) init _focus
  TextEditingController textController = TextEditingController();
  static const insideBorder = BorderSide(color: Colors.black, width: 0.1);

  void _addPlayer() {
    setState(() {
      repository.addPlayer('');
    });
  }

  void _removePlayer() {
    setState(() {
      repository.removeLastPlayer();
    });
  }

  void _addRound() {
    setState(() {
      repository.addRound();
    });
  }

  void _removeRound() {
    setState(() {
      repository.removeLastRound();
    });
  }

  void _updatePlayerName(int index, String newName) {
    setState(() {
      repository.updatePlayerName(index, newName);
    });
  }

  @override
  void initState() {
    super.initState();
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
        backgroundColor: Theme.of(context).colorScheme.background,
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
      bottomNavigationBar: ButtonBar(
        buttonPadding: const EdgeInsets.all(25),
        alignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _addRound,
            tooltip: 'Add Round',
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            onPressed: _removeRound,
            tooltip: 'Remove Round',
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }

  List<TableRow> _buildTable() {
    List<TableRow> tableRows = [];
    var primary = Theme.of(context).colorScheme.primary;

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
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Igrač ${index + 1}',
              ),
              onChanged: (newValue) => _updatePlayerName(
                  repository.players.indexOf(player), newValue),
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
                onChanged: (newValue) {
                  setState(() {
                    repository.points[roundIndex][index] =
                        int.tryParse(newValue) ?? score;
                  });
                },
                textAlign: TextAlign.center,
                // controller: textController,
                initialValue: '',
                // focusNode: _focus, // 5) pass our focusNode to our textfield
                // keyboardType: TextInputType.none,
                TextInputType.numberWithOptions(signed: true),
                onFieldSubmitted: (newValue) {
                  setState(() {
                    repository.points[roundIndex][index] =
                        int.tryParse(newValue) ?? score;
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
