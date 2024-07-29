import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define a function to fetch data from the API
Future<List<Map<String, dynamic>>> fetchData(String apiHost, String modal, String route) async {
  final apiUrl = apiHost + 'read/$modal/$route';
  print('API URL: $apiUrl');

  try {
    final response = await http.get(Uri.parse(apiUrl));
    print('API Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // Ensuring the result contains the expected keys
      if (result.containsKey('columns') && result.containsKey('data')) {
        List<String> columns = List<String>.from(result['columns']);
        List<List<dynamic>> data = List<List<dynamic>>.from(result['data']);

        // Converting list of lists to list of maps
        List<Map<String, dynamic>> dataList = data.map((row) {
          return Map<String, dynamic>.fromIterables(columns, row);
        }).toList();

        return dataList;
      } else {
        throw Exception('Unexpected API Response format');
      }
    } else {
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print('Error: $e');
    return [];
  }
}



class DynamicTable extends StatelessWidget {
  final String apiHost;
  final String modal;
  final String route;
  final List<String> readFields;

  DynamicTable({
    required this.apiHost,
    required this.modal,
    required this.route,
    required this.readFields,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,  // Set background color to black
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchData(apiHost, modal, route),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No data available', style: TextStyle(color: Colors.white));
          } else {
            final data = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),  // Disable ListView scrolling
              itemCount: data.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildScrollableDialog(context, data[index]),
                    );
                  },
                  child: Card(
                    color: Colors.grey[850],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < readFields.length; i++)
                            if (i < 5 || i >= readFields.length - 2)
                              Text(
                                '${readFields[i]}: ${data[index][readFields[i]]}',
                                style: TextStyle(color: Colors.white),
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildScrollableDialog(BuildContext context, Map<String, dynamic> item) {
    return AlertDialog(
      backgroundColor: Colors.black,  // Set the dialog background to black
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: item.entries.map((entry) => Text(
            '${entry.key}: ${entry.value}',
            style: TextStyle(color: Colors.white),  // Set text color to white
          )).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(color: Colors.white),  // Set text color to white
          ),
        ),
      ],
    );
  }
}

