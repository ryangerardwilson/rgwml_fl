import 'package:flutter/material.dart';

class XorOrSelector extends StatefulWidget {
  final List<String> options;
  final bool isXor;
  final String columnName;
  final Function(String) onSelectionChanged;

  const XorOrSelector({
    Key? key, // Add the key parameter to the constructor
    required this.options,
    required this.isXor,
    required this.columnName,
    required this.onSelectionChanged,
  }) : super(key: key); // Pass the key to the super constructor

  @override
  _XorOrSelectorState createState() => _XorOrSelectorState();
}

class _XorOrSelectorState extends State<XorOrSelector> {
  String? _selectedOption;
  final Set<String> _selectedOptions = {}; // Make the field final

  void _onOptionSelected(String option) {
    setState(() {
      if (widget.isXor) {
        _selectedOption = option;
        widget.onSelectionChanged(_selectedOption!);
      } else {
        if (_selectedOptions.contains(option)) {
          _selectedOptions.remove(option);
        } else {
          _selectedOptions.add(option);
        }
        _selectedOption = _selectedOptions.join(';');
        widget.onSelectionChanged(_selectedOption!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, left: 10.0), // Adjust space above and to the left
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.columnName} (${widget.isXor ? "XOR" : "OR"})',
            style: const TextStyle(color: Colors.white, fontSize: 16), // Increase font size
          ),
          Column(
            children: widget.options.map((option) {
              return ListTile(
                title: Text(option, style: const TextStyle(color: Colors.white)),
                leading: widget.isXor
                  ? Radio<String>(
                      value: option,
                      groupValue: _selectedOption,
                      onChanged: (value) => _onOptionSelected(option),
                    )
                  : Checkbox(
                      value: _selectedOptions.contains(option),
                      onChanged: (_) => _onOptionSelected(option),
                    ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

