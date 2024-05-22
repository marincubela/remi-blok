import 'package:flutter/material.dart';

class NumericKeypad extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const NumericKeypad(
      {super.key, required this.controller, required this.focusNode});

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  late TextEditingController _controller;
  late TextSelection _selection;
  late FocusNode _focusNode; // <----------------

  @override
  void initState() {
    super.initState();
    // add listener to controller
    _controller = widget.controller..addListener(_onSelectionChanged);
    _selection = _controller.selection;
    // add this line in initState
    _focusNode = widget.focusNode; // <----------------
  }

  @override
  void dispose() {
    // remove listener
    _controller.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    setState(() {
      // update selection on change (updating position too)
      _selection = _controller.selection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _buildButton('1'),
            _buildButton('2'),
            _buildButton('3'),
            _buildButton('⌫'),
          ],
        ),
        Row(
          children: [
            _buildButton('4'),
            _buildButton('5'),
            _buildButton('6'),
            _buildButton('100'),
          ],
        ),
        Row(
          children: [
            _buildButton('7'),
            _buildButton('8'),
            _buildButton('9'),
            _buildButton('200'),
          ],
        ),
        Row(
          children: [
            _buildButton('-40'),
            _buildButton('0'),
            _buildButton('0', onPressed: _backspace),
            _buildButton('⇓', onPressed: _hideKeyboard),
          ],
        ),
      ],
    );
  }

  // Individual keys
  Widget _buildButton(String text, {VoidCallback? onPressed}) {
    return Expanded(
      child: TextButton(
        onPressed: onPressed ?? () => _input(text),
        child: Text(text),
      ),
    );
  }

  void _input(String text) {
    int position = _selection.base.offset; // gets position of cursor
    var value = _controller.text; // text in our textfield

    if (value.isNotEmpty) {
      var suffix =
          value.substring(position, value.length); // 1) suffix: the string
      // from the position of the cursor to the end of the text in the controller

      value = value.substring(0, position) +
          text +
          suffix; // 2) value.substring gets
      // a new string from start of the string in our textfield, appends the new input to our
      // new string and appends the suffix to it.

      _controller.text =
          value; // 3) set our controller text to the gotten value
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: position + 1)); // 4) update selection
      // to update our position.
    } else {
      value =
          _controller.text + text; // 5) appends controller text and new input
      // and assigns to value
      _controller.text =
          value; // 6) set our controller text to the gotten value
      _controller.selection = TextSelection.fromPosition(
          const TextPosition(offset: 1)); // 7) since this is the first input
      // set position of cursor to 1, so the cursor is placed at the end
    }
  }

  void _backspace() {
    int position = _selection.base.offset; // cursor position
    final value = _controller.text; // string in out textfield

    // 1) only erase when string in textfield is not empty and when position is not zero (at the start)
    if (value.isNotEmpty && position != 0) {
      var suffix = value.substring(
          position, value.length); // 2) get string after cursor position
      _controller.text = value.substring(0, position - 1) +
          suffix; // 3) get string before the cursor and append to
      // suffix after removing the last char before the cursor
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: position - 1)); // 4) update the cursor
    }
  }

   _hideKeyboard() => _focusNode.unfocus();
}
