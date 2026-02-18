import 'package:flutter/material.dart';
import 'package:kartaski_blok/remi_repository.dart';
import 'package:kartaski_blok/remi_storage.dart';

enum ScoreDisplayMode {
  roundScore, // Show round score as display text, cumulative as badge
  cumulativeScore, // Show cumulative score as display text, round as badge
  roundOnly, // Show only round score as display text
  cumulativeOnly // Show only cumulative score as display text
}

class RemiPage extends StatefulWidget {
  const RemiPage({
    super.key,
    required this.title,
    required this.storage,
    required this.gameId,
  });

  final String title;
  final RemiStorage storage;
  final String gameId;

  @override
  State<RemiPage> createState() => _RemiPageState();
}

class _RemiPageState extends State<RemiPage> {
  RemiRepository repository = RemiRepository([]);
  static final insideBorder =
      BorderSide(color: Colors.grey[300]!, width: 0.5); // Thin vertical lines
  static const Color headerFooterColor =
      Colors.white; // Reverted to white as requested

  ScoreDisplayMode displayMode = ScoreDisplayMode.roundScore;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _resetGame() {
    setState(() {
      repository = RemiRepository([]);
    });

    widget.storage.writeGame(widget.gameId, repository);
  }

  void _addPlayer() {
    final added = repository.addPlayer('');
    if (!added) {
      _showSnackBar(
          'Maximum number of players reached (${RemiRepository.maxPlayers}).');
      return;
    }

    setState(() {
      // Repository already updated.
    });

    widget.storage.writeGame(widget.gameId, repository);
  }

  void _removePlayer() {
    final removed = repository.removeLastPlayer();
    if (!removed) {
      _showSnackBar(
          'At least ${RemiRepository.minPlayers} players are required.');
      return;
    }

    setState(() {
      // Repository already updated.
    });

    widget.storage.writeGame(widget.gameId, repository);
  }

  void _addRound() {
    setState(() {
      repository.addRound();
    });

    widget.storage.writeGame(widget.gameId, repository);
  }

  void _removeRound() {
    final removed = repository.removeLastRound();
    if (!removed) {
      _showSnackBar('Cannot remove the last round.');
      return;
    }

    setState(() {
      // Repository already updated.
    });

    widget.storage.writeGame(widget.gameId, repository);
  }

  void _updatePlayerName(int index, String newName) {
    setState(() {
      repository.updatePlayerName(index, newName);
    });

    widget.storage.writeGame(widget.gameId, repository);
  }

  void _toggleDisplayMode() {
    setState(() {
      switch (displayMode) {
        case ScoreDisplayMode.roundScore:
          displayMode = ScoreDisplayMode.cumulativeScore;
          break;
        case ScoreDisplayMode.cumulativeScore:
          displayMode = ScoreDisplayMode.roundOnly;
          break;
        case ScoreDisplayMode.roundOnly:
          displayMode = ScoreDisplayMode.cumulativeOnly;
          break;
        case ScoreDisplayMode.cumulativeOnly:
          displayMode = ScoreDisplayMode.roundScore;
          break;
      }
    });
  }

  String _getDisplayModeTooltip() {
    switch (displayMode) {
      case ScoreDisplayMode.roundScore:
        return 'Show round scores (with cumulative badge)';
      case ScoreDisplayMode.cumulativeScore:
        return 'Show cumulative scores (with round badge)';
      case ScoreDisplayMode.roundOnly:
        return 'Show round scores only';
      case ScoreDisplayMode.cumulativeOnly:
        return 'Show cumulative scores only';
    }
  }

  IconData _getDisplayModeIcon() {
    switch (displayMode) {
      case ScoreDisplayMode.roundScore:
        return Icons.looks_one;
      case ScoreDisplayMode.cumulativeScore:
        return Icons.trending_up;
      case ScoreDisplayMode.roundOnly:
        return Icons.circle_outlined;
      case ScoreDisplayMode.cumulativeOnly:
        return Icons.analytics;
    }
  }

  // Use a simple Point class or just storing indices.
  // Using a custom Record or relying on Point from dart:math is fine, or simple MapEntry.
  // Let's use a simple class or just two variables.
  int? _editingRoundIndex;
  int? _editingPlayerIndex;

  @override
  void initState() {
    super.initState();
    // ... (rest of initState)
    widget.storage.readGame(widget.gameId).then((value) {
      if (!mounted) return;
      setState(() {
        repository = value;
        // ... (rest of loading logic)
        if (repository.players.isEmpty) {
          repository.addPlayer('');
          repository.addPlayer('');
        }
        if (repository.points.isEmpty) {
          repository.addRound();
        }
        for (var round in repository.points) {
          if (round.length < repository.players.length) {
            round.addAll(
                List<int>.filled(repository.players.length - round.length, 0));
          } else if (round.length > repository.players.length) {
            round.removeRange(repository.players.length, round.length);
          }
        }
      });
      widget.storage.writeGame(widget.gameId, repository);
    });
  }

  void _setEditingCell(int? roundIndex, int? playerIndex) {
    setState(() {
      _editingRoundIndex = roundIndex;
      _editingPlayerIndex = playerIndex;
    });
  }

  void _handleNextCell(int currentRound, int currentPlayer) {
    // Save is handled by ScoreCell before calling this? No, ScoreCell calls onScoreChanged then onNext.
    // Logic to find next cell
    int nextPlayer = currentPlayer + 1;
    int nextRound = currentRound;

    if (nextPlayer >= repository.players.length) {
      nextPlayer = 0;
      nextRound = currentRound + 1;
    }

    // If we need to add a new round because we are at the end
    if (nextRound >= repository.points.length) {
      // Optional: Add new round automatically?
      // For now, let's just stop or cycle. User request doesn't specify adding rounds.
      // But often in these apps, "Next" at end adds a round.
      _addRound(); // This calls writeGame and setState
    }

    _setEditingCell(nextRound, nextPlayer);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(_getDisplayModeIcon()),
            onPressed: _toggleDisplayMode,
            tooltip: _getDisplayModeTooltip(),
            color: Theme.of(context).colorScheme.primary,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: Theme.of(context).colorScheme.primary),
            onSelected: (value) {
              switch (value) {
                case 'add_player':
                  _addPlayer();
                  break;
                case 'remove_player':
                  _removePlayer();
                  break;
                case 'reset_game':
                  _resetGame();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'add_player',
                child: ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Add Player'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'remove_player',
                child: ListTile(
                  leading: Icon(Icons.person_remove),
                  title: Text('Remove Last Player'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'reset_game',
                child: ListTile(
                  leading: Icon(Icons.playlist_remove, color: Colors.red),
                  title:
                      Text('Reset Game', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky Header
          Table(
            columnWidths: repository.players
                .map((e) => const FlexColumnWidth())
                .toList()
                .asMap(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(verticalInside: insideBorder),
            children: _buildHeader(),
          ),
          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                columnWidths: repository.players
                    .map((e) => const FlexColumnWidth())
                    .toList()
                    .asMap(),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(verticalInside: insideBorder),
                children: _buildBody(),
              ),
            ),
          ),
          // Sticky Footer (Total)
          Table(
            columnWidths: repository.players
                .map((e) => const FlexColumnWidth())
                .toList()
                .asMap(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder(verticalInside: insideBorder),
            children: _buildFooter(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 3))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OverflowBar(
            alignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                heroTag: 'add_round_fab',
                backgroundColor: Theme.of(context).colorScheme.surface,
                onPressed: _addRound,
                tooltip: 'Add Round',
                child: Icon(Icons.add,
                    color: Theme.of(context).colorScheme.primary),
              ),
              FloatingActionButton(
                heroTag: 'remove_round_fab',
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

  List<TableRow> _buildHeader() {
    List<TableRow> tableRows = [];
    var primary = Theme.of(context).colorScheme.primary;

    if (repository.players.isEmpty) {
      return tableRows;
    }

    // Header row with player names
    tableRows.add(TableRow(
      decoration: BoxDecoration(
        color: headerFooterColor,
        border: Border(bottom: BorderSide(color: primary, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      children: [
        ...repository.players.asMap().entries.map((entry) {
          var index = entry.key;
          var player = entry.value;
          return TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
              child: TextFormField(
                initialValue: repository.players[index].toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Explicitly black for contrast on white
                ),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Player ${index + 1}',
                  hintStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (newValue) => _updatePlayerName(
                    repository.players.indexOf(player), newValue),
                onFieldSubmitted: (newValue) => _updatePlayerName(
                    repository.players.indexOf(player), newValue),
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ),
          );
        }),
      ],
    ));
    return tableRows;
  }

  List<TableRow> _buildBody() {
    List<TableRow> tableRows = [];

    if (repository.players.isEmpty) {
      return tableRows;
    }

    // Data rows for each round
    for (int roundIndex = 0;
        roundIndex < repository.points.length;
        roundIndex++) {
      var round = repository.points[roundIndex];
      // Alternating row colors - kept subtle or white based on preference,
      // but user asked for "white again as default".
      // Let's keep it very clean/white as primary, maybe extremely subtle grey for alt?
      // User said "Make it white again as default" referring to "color in result row".
      // I will interpret this as removing the surfaceContainerHighest background.
      const rowColor = Colors.white;

      // Fatter line logic: after N rounds where N is number of players
      final isFatLine = (roundIndex + 1) % repository.numberOfPlayers() == 0;
      final bottomBorderSide = isFatLine
          ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0)
          : BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1));

      tableRows.add(TableRow(
        decoration: BoxDecoration(
          color: rowColor,
          border: Border(
            bottom: bottomBorderSide,
          ),
        ),
        children: [
          ...round.asMap().entries.map((entry) {
            final index = entry.key;
            final cumulativeTotal =
                repository.calculateCumulativeTotals(roundIndex)[index];

            // Helper to get color for score
            Color getScoreColor(int score) {
              if (score > 0) return Colors.red.shade700;
              if (score < 0) return Colors.green.shade700;
              return Colors.black; // Forced black for white rows
            }

            // Determine if editable based on display mode
            // User requested editing regardless of mode.
            bool isEditable = true;
            Color? scoreColor;

            switch (displayMode) {
              case ScoreDisplayMode.roundScore:
              case ScoreDisplayMode.roundOnly:
                scoreColor =
                    getScoreColor(repository.points[roundIndex][index]);
                break;
              case ScoreDisplayMode.cumulativeScore:
              case ScoreDisplayMode.cumulativeOnly:
                scoreColor =
                    null; // Color handled by ScoreCell schema for cumulative
                break;
            }

            return TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: ScoreCell(
                key: ValueKey('${roundIndex}_$index'),
                roundScore: repository.points[roundIndex][index],
                cumulativeScore: cumulativeTotal,
                displayMode: displayMode,
                isEditable: isEditable,
                isEditing: _editingRoundIndex == roundIndex &&
                    _editingPlayerIndex == index,
                onTap: () => _setEditingCell(roundIndex, index),
                onScoreChanged: (newScore) {
                  setState(() {
                    repository.setScore(roundIndex, index, newScore);
                    widget.storage.writeGame(widget.gameId, repository);
                  });
                },
                onNext: () => _handleNextCell(roundIndex, index),
                onFocusLost: () => _setEditingCell(null, null),
                scoreColor: scoreColor,
              ),
            );
          }),
        ],
      ));
    }
    return tableRows;
  }

  List<TableRow> _buildFooter() {
    List<TableRow> tableRows = [];
    var primary = Theme.of(context).colorScheme.primary;

    if (repository.players.isEmpty) {
      return tableRows;
    }

    // Total row
    tableRows.add(TableRow(
      decoration: BoxDecoration(
        color: headerFooterColor,
        border: Border(top: BorderSide(width: 2, color: primary)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
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

class ScoreCell extends StatefulWidget {
  final int roundScore;
  final int cumulativeScore;
  final ScoreDisplayMode displayMode;
  final bool isEditable;
  final bool isEditing; // Active editing state from parent
  final VoidCallback onTap;
  final ValueChanged<int> onScoreChanged;
  final VoidCallback onNext;
  final VoidCallback onFocusLost;
  final Color? scoreColor;

  const ScoreCell({
    super.key,
    required this.roundScore,
    required this.cumulativeScore,
    required this.displayMode,
    required this.isEditable,
    required this.isEditing,
    required this.onTap,
    required this.onScoreChanged,
    required this.onNext,
    required this.onFocusLost,
    this.scoreColor,
  });

  @override
  State<ScoreCell> createState() => _ScoreCellState();
}

class _ScoreCellState extends State<ScoreCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.roundScore != 0 ? widget.roundScore.toString() : '');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (widget.isEditing) {
      setState(() {
        // Just trigger rebuild for color update
      });
    }
  }

  @override
  void didUpdateWidget(ScoreCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEditing && widget.roundScore != oldWidget.roundScore) {
      _controller.text =
          widget.roundScore != 0 ? widget.roundScore.toString() : '';
    }
    // If we entered editing mode programmatically
    if (widget.isEditing && !oldWidget.isEditing) {
      _controller.text =
          widget.roundScore != 0 ? widget.roundScore.toString() : '';
      // Select all text
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      // Ensure it gets focus
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // If we lost focus, save and notify parent to exit editing mode.
    if (!_focusNode.hasFocus && widget.isEditing) {
      _submitScore(_controller.text);
      widget.onFocusLost();
    }
  }

  void _submitScore(String value) {
    int? newScore = int.tryParse(value);
    if (value.isEmpty) newScore = 0;

    // Only notify if valid integer
    if (newScore != null) {
      widget.onScoreChanged(newScore);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditable) {
      return _buildDisplay(context);
    }

    if (widget.isEditing) {
      final val = int.tryParse(_controller.text) ?? 0;
      final inputColor = val > 0
          ? Colors.red.shade700
          : (val < 0 ? Colors.green.shade700 : Colors.black);

      return Container(
        height: 64,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true, // Key to working with parent state
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          textAlign: TextAlign.center,
          style: TextStyle(
              color: inputColor, fontSize: 20, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: (val) {
            _submitScore(val);
            widget.onNext();
          },
          onTapOutside: (_) {
            _submitScore(_controller.text);
            _focusNode.unfocus();
          },
        ),
      );
    } else {
      return GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: _buildDisplay(context),
      );
    }
  }

  Widget _buildDisplay(BuildContext context) {
    String mainText = '';
    String? subText;
    Color? mainColor = widget.scoreColor;

    switch (widget.displayMode) {
      case ScoreDisplayMode.roundScore:
        mainText = widget.roundScore != 0 ? widget.roundScore.toString() : '';
        subText = widget.cumulativeScore.toString();
        break;
      case ScoreDisplayMode.cumulativeScore:
        mainText = widget.cumulativeScore.toString();
        final rs = widget.roundScore;
        subText = rs != 0 ? rs.toString() : '0';
        mainColor = Colors.black; // Ensure visible on white
        break;
      case ScoreDisplayMode.roundOnly:
        mainText = widget.roundScore != 0 ? widget.roundScore.toString() : '';
        break;
      case ScoreDisplayMode.cumulativeOnly:
        mainText = widget.cumulativeScore.toString();
        mainColor = Colors.black; // Ensure visible on white
        break;
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            mainText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: mainColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subText != null)
            Text(
              subText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: widget.roundScore > 0
                    ? Colors.red.shade700
                    : (widget.roundScore < 0
                        ? Colors.green.shade700
                        : Colors.grey[800]),
              ),
            ),
        ],
      ),
    );
  }
}
