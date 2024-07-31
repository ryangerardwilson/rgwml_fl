// dynamic_table_scrollable_dialog.dart 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'modal_config.dart';
import 'xoror.dart';
import 'validator.dart'; 
import 'ai_validator.dart';


class ScrollableDialog extends StatelessWidget {
  final String apiHost;
  final String modal;
  final Map<String, dynamic> item;
  final bool create;
  final List<String> readFields;
  final List<String> updateFields;
  final bool delete;
  final VoidCallback onDelete;

  final String userId;
  final List<String> columns;
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final Map<String, List<String>> validationRules;
  final dynamic aiQualityChecks;
  final String openAiJsonModeModel;
  final String openAiApiKey;


  ScrollableDialog({
    required this.apiHost,
    required this.modal,
    required this.item,
    required this.create,
    required this.readFields,
    required this.updateFields,
    required this.delete,
    required this.onDelete,
    required this.userId,
    required this.columns,
    required this.options,
    required this.conditionalOptions,
    required this.validationRules,
    required this.aiQualityChecks,
    required this.openAiJsonModeModel,
    required this.openAiApiKey,
  });

  Future<void> _launchInBrowser(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  void _shareContent() {
    String content = item.entries.map((entry) => '${entry.key}: ${entry.value}').join('\n');
    Share.share(content);
  }

  void _deleteItem(BuildContext context) async {
    final id = item['id']; // Assuming 'id' is the key for item ID
    final userId = item['user_id']; // Assuming 'user_id' is present in the item map
    final success = await deleteItemFromAPI(id, userId);
    if (success) {
      Navigator.of(context).pop();
      onDelete(); // Notify the parent widget to remove the item
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete the item.')),
      );
    }
  }

  Future<bool> deleteItemFromAPI(dynamic id, dynamic userId) async {
    final apiUrl = apiHost + 'delete/$modal/$id';
    print('DELETE API URL: $apiUrl');

    final url = Uri.parse(apiUrl);

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['status'] == 'success';
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black, // Set the dialog background to black
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: item.entries.map((entry) {
            if (Uri.tryParse(entry.value.toString()) != null && Uri.parse(entry.value.toString()).isAbsolute) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: TextStyle(color: Colors.white), // Set text color to white
                  ),
                  SizedBox(height: 4), // Adding some spacing
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey, // Set button background color to grey
                    ),
                    onPressed: () => _launchInBrowser(entry.value.toString(), context),
                    child: Text(
                      'Open URL',
                      style: TextStyle(color: Colors.white), // Set button text color to white
                    ),
                  ),
                  SizedBox(height: 16), // Adding some spacing after each entry
                ],
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(color: Colors.white), // Set text color to white
                ),
              );
            }
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _shareContent,
          child: Icon(Icons.share, color: Colors.white),
        ),
        if (delete)
          TextButton(
            onPressed: () => _deleteItem(context),
            child: Icon(Icons.delete, color: Colors.red),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(color: Colors.white), // Set text color to white
          ),
        ),
      ],
    );
  }

}

