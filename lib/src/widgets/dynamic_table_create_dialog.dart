import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'modal_config.dart';
import 'xoror.dart';
import 'validator.dart';
import 'ai_validator.dart';

class DynamicTableCreateDialog extends StatefulWidget {
  final String userId;
  final String apiHost;
  final String modal;
  final List<String> columns;
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final Map<String, List<String>> validationRules;
  final dynamic aiQualityChecks;
  final String openAiJsonModeModel;
  final String openAiApiKey;

  const DynamicTableCreateDialog({
    required this.userId,
    required this.apiHost,
    required this.modal,
    required this.columns,
    required this.options,
    required this.conditionalOptions,
    required this.validationRules,
    required this.aiQualityChecks,
    required this.openAiJsonModeModel,
    required this.openAiApiKey,
  });

  @override
  _DynamicTableCreateDialogState createState() => _DynamicTableCreateDialogState();
}

class _DynamicTableCreateDialogState extends State<DynamicTableCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {};

void _handleCreate() async {
  try {
    _formData['user_id'] = widget.userId;
    print(widget.userId);
    print(_formData);

    final response = await http.post(
      Uri.parse('${widget.apiHost}create/${widget.modal}'),
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
      Navigator.of(context).pop(true); // Return true to indicate success
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


  void _showValidationErrorDialog(List<String> errorMessages) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text('Validation Error', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: errorMessages.map((e) => Text(e, style: TextStyle(color: Colors.white))).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<String>> _validateForm() async {
    List<String> errorMessages = [];
    for (String column in widget.columns) {
      if (!['id', 'user_id', 'created_at', 'updated_at'].contains(column)) {
        // Traditional validation
        final validationRules = widget.validationRules[column] ?? [];
        String? errorMessage = Validator.validateField(column, _formData[column], validationRules);
        if (errorMessage != null) {
          errorMessages.add(errorMessage);
        }

        // AI quality checks
        if (widget.aiQualityChecks is Map<String, dynamic> && widget.aiQualityChecks.containsKey(column)) {
          final aiQualityChecks = widget.aiQualityChecks[column] ?? [];
          if (aiQualityChecks.isNotEmpty) {
            final aiErrors = await openAiQualityChecks(
              apiKey: widget.openAiApiKey,
              model: widget.openAiJsonModeModel,
              field: column,
              value: _formData[column],
              checks: aiQualityChecks,
            );
            errorMessages.addAll(aiErrors);
          }
        }
      }
    }
    return errorMessages;
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
      onChanged: (value) {
        setState(() {
          _formData[column] = value;
        });
      },
      validator: (value) {
        final validationRules = widget.validationRules[column] ?? [];
        String? errorMessage = Validator.validateField(column, value, validationRules);
        if (errorMessage != null) {
          return errorMessage;
        }
        _formData[column] = value;
        return null;
      },
    );
  }

  Widget _buildConditionalField(String column) {
    if (widget.conditionalOptions.containsKey(column)) {
      for (var conditionalOption in widget.conditionalOptions[column]!) {
        final conditionParts = conditionalOption.condition.split(' == ');
        final conditionKey = conditionParts[0];
        final conditionValue = conditionParts[1];

        if (_formData[conditionKey] == conditionValue) {
          return XorOrSelector(
            options: conditionalOption.options,
            isXor: true,
            columnName: column,
            onSelectionChanged: (selectedValue) {
              setState(() {
                _formData[column] = selectedValue;
              });
            },
          );
        }
      }
      return Container();
    } else {
      return _buildTextFormField(column);
    }
  }

  List<Widget> _buildFormFields() {
    final filteredColumns = widget.columns
        .where((col) => !['id', 'user_id', 'created_at', 'updated_at'].contains(col))
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
        return _buildConditionalField(column);
      }
    }).toList();
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              List<String> errorMessages = await _validateForm();
              if (errorMessages.isEmpty) {
                _handleCreate();
              } else {
                _showValidationErrorDialog(errorMessages);
              }
            } else {
              List<String> errorMessages = await _validateForm();
              _showValidationErrorDialog(errorMessages);
            }
          },
        ),
      ],
    );
  }
}

