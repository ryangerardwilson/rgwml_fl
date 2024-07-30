import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../modal_config.dart'; 

class DynamicTableCreateDialog extends StatefulWidget {
  final String apiHost;
  final String modal;
  final List<String> columns;
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final Map<String, List<String>> validationRules;

  const DynamicTableCreateDialog({
    required this.apiHost,
    required this.modal,
    required this.columns,
    required this.options,
    required this.conditionalOptions,
    required this.validationRules,
  });

  @override
  _DynamicTableCreateDialogState createState() => _DynamicTableCreateDialogState();
}

class _DynamicTableCreateDialogState extends State<DynamicTableCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? ''; // Adjust the key as necessary
    setState(() {
      _formData['user_id'] = userId;
    });
  }

  void _handleCreate() async {
    try {
      final response = await http.post(
        Uri.parse('${widget.apiHost}create/${widget.modal}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(_formData),
      );

      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Record created successfully')));
        Navigator.of(context).pop();
      } else {
        print('Failed to create record: $result');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create record')));
      }
    } catch (error) {
      print('Error creating record: $error');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating record')));
    }
  }

  List<Widget> _buildFormFields() {
    // Filter out columns that shouldn't be included in the form
    final filteredColumns = widget.columns.where((col) => !['id', 'created_at', 'updated_at'].contains(col)).toList();
    return filteredColumns.map((column) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: column,
          labelStyle: TextStyle(color: Colors.white),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
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
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Record', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _buildFormFields(),
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
          child: Text('Create', style: TextStyle(color: Colors.white)),
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

