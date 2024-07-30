import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ScrollableDialog extends StatelessWidget {
  final Map<String, dynamic> item;

  ScrollableDialog({required this.item});

  Future<void> _launchInBrowser(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
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

