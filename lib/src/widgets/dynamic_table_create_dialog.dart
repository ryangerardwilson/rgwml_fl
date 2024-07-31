import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'modal_config.dart';
import 'xoror.dart';

class DynamicTableCreateDialog extends StatefulWidget {
  final String apiHost;
  final String modal;
  final List<String> columns;
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final Map<String, List<String>> validationRules;
  final String openAiJsonModeModel;
  final String openAiApiKey;

  const DynamicTableCreateDialog({
    required this.apiHost,
    required this.modal,
    required this.columns,
    required this.options,
    required this.conditionalOptions,
    required this.validationRules,
    required this.openAiJsonModeModel,
    required this.openAiApiKey,
  });

  @override
  _DynamicTableCreateDialogState createState() => _DynamicTableCreateDialogState();
}

class _DynamicTableCreateDialogState extends State<DynamicTableCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};
  late String _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    setState(() {
      _userId = userId;
      _formData['user_id'] = userId;
    });
  }

  void _handleCreate() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiHost}/create/${widget.modal}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_formData),
      );

      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record created successfully')),
        );
        Navigator.of(context).pop();
      } else {
        print('Failed to create record: $result');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create record')),
        );
      }
    } catch (error) {
      print('Error creating record: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating record')),
      );
    }
  }

  List<Widget> _buildFormFields() {
    final filteredColumns = widget.columns
        .where((col) => !['id', 'created_at', 'updated_at'].contains(col))
        .toList();

    return filteredColumns.map((column) {
      final xorOptions = widget.options.xorOptions[column];
      final orOptions = widget.options.orOptions[column];

      if (xorOptions != null && xorOptions.isNotEmpty) {
        return XorOrSelector(
          options: xorOptions,
          isXor: true,
          columnName: column,
          onSelectionChanged: (selectedValue) {
            setState(() {
              _formData[column] = selectedValue;
            });
          },
        );
      } else if (orOptions != null && orOptions.isNotEmpty) {
        return XorOrSelector(
          options: orOptions,
          isXor: false,
          columnName: column,
          onSelectionChanged: (selectedValue) {
            setState(() {
              _formData[column] = selectedValue;
            });
          },
        );
      } else {
        return _buildTextFormField(column);
      }
    }).toList();
  }

  Widget _buildTextFormField(String column) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: column,
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.black,
      ),
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some text';
        }
        _formData[column] = value;
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Record', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildFormFields(),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: Colors.white)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Submit', style: TextStyle(color: Colors.white)),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _handleCreate();
            }
          },
        ),
      ],
    );
  }
}

