// dynamic_table_edit_dialog.dart 
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'modal_config.dart';
import 'validator.dart';
import 'ai_validator.dart';
import 'xoror_edit.dart';

class DynamicTableEditDialog extends StatefulWidget {
  final String apiHost;
  final String modal;
  final Map<String, dynamic> item;
  final List<String> updateFields;
  final List<String> columns;
  final Map<String, List<String>> validationRules;
  final dynamic aiQualityChecks;
  final String userId;
  final String openAiJsonModeModel;
  final String openAiApiKey;
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final VoidCallback onEdit;

  const DynamicTableEditDialog({
    required this.apiHost,
    required this.modal,
    required this.item,
    required this.updateFields,
    required this.columns,
    required this.validationRules,
    required this.aiQualityChecks,
    required this.userId,
    required this.openAiJsonModeModel,
    required this.openAiApiKey,
    required this.options,
    required this.conditionalOptions,
    required this.onEdit,
  });

  @override
  _DynamicTableEditDialogState createState() => _DynamicTableEditDialogState();
}

class _DynamicTableEditDialogState extends State<DynamicTableEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _formData = Map.from(widget.item);
  }

  void _handleUpdate() async {
    try {
      _formData['user_id'] = widget.userId;

      final response = await http.put(
        Uri.parse('${widget.apiHost}update/${widget.modal}/${widget.item['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_formData),
      );

      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record updated successfully')),
        );
        Navigator.of(context).pop(true);
         widget.onEdit();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update record')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating record')),
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
    for (String column in widget.updateFields) {
      final validationRules = widget.validationRules[column] ?? [];
      String? errorMessage = Validator.validateField(column, _formData[column], validationRules);
      if (errorMessage != null) {
        errorMessages.add(errorMessage);
      }

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
    return errorMessages;
  }

  Widget _buildTextFormField(String column) {
    return TextFormField(
      initialValue: _formData[column]?.toString() ?? '',
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
        setState(() { _formData[column] = value; });
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
            preselected: _formData[column]?.toString(),
            columnName: column,
            onSelectionChanged: (selectedValue) {
              setState(() { _formData[column] = selectedValue; });
            },
          );
        }
      }
      return Container();
    } else {
      return _buildTextFormField(column);
    }
  }

  Widget _buildNonEditableField(String column) {
    return TextFormField(
      initialValue: _formData[column]?.toString() ?? '',
      decoration: InputDecoration(
        labelText: column,
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        disabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.black,
      ),
      style: TextStyle(color: Colors.grey[850]),
      enabled: false,
    );
  }

  List<Widget> _buildFormFields() {
    return widget.columns.map((column) {
      if (!widget.updateFields.contains(column)) {
        return _buildNonEditableField(column);
      }

      final xorOptions = widget.options.xorOptions[column];
      final orOptions = widget.options.orOptions[column];

      if (xorOptions != null && xorOptions.isNotEmpty) {
        return XorOrSelector(
          options: xorOptions,
          isXor: true,
          preselected: _formData[column]?.toString(),
          columnName: column,
          onSelectionChanged: (selectedValue) {
            setState(() { _formData[column] = selectedValue; });
          },
        );
      } else if (orOptions != null && orOptions.isNotEmpty) {
        return XorOrSelector(
          options: orOptions,
          isXor: false,
          preselected: _formData[column]?.toString(),
          columnName: column,
          onSelectionChanged: (selectedValue) {
            setState(() { _formData[column] = selectedValue; });
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
      title: Text('Edit Record', style: TextStyle(color: Colors.white)),
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
                _handleUpdate();
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



