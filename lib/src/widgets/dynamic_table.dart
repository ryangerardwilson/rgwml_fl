import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';


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

class DynamicTable extends StatefulWidget {
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
  _DynamicTableState createState() => _DynamicTableState();
}

class _DynamicTableState extends State<DynamicTable> {
  List<Map<String, dynamic>> _searchData = [];
  String? _queryError;

  Future<void> handleSearchSubmit(String apiHost, String modal, String queryInput) async {
    final fullUrl = apiHost + 'search/$modal';
    print('Requesting URL: $fullUrl');

    final payload = jsonEncode({'search_string': queryInput.trim()});
    print('Payload: $payload');

    try {
      final response = await http.post(
        Uri.parse(fullUrl),
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );

      print('Full Response: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        List<String> columns = List<String>.from(result["columns"]);
        List<List<dynamic>> data = List<List<dynamic>>.from(result["data"]);
        List<Map<String, dynamic>> dataList = data.map((row) {
          return Map<String, dynamic>.fromIterables(columns, row);
        }).toList();

        setState(() {
          _searchData = dataList;
          _queryError = null;
        });
      } else {
        print('Error fetching search results: ${response.body}');
        setState(() {
          _queryError = 'Error fetching search results: ${response.reasonPhrase}';
        });
      }
    } catch (error) {
      print('Error fetching search results: $error');
      setState(() {
        _queryError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black, // Set background color to black
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchData(widget.apiHost, widget.modal, widget.route),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              final data = _searchData.isNotEmpty ? _searchData : snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Filter: ${widget.route}', // Display the name of the route
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Rows Fetched: ${data.length}', // Display the count of data rows
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
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
                                  for (int i = 0; i < widget.readFields.length; i++)
                                    if (i < 5 || i >= widget.readFields.length - 2)
                                      Text(
                                        '${widget.readFields[i]}: ${data[index][widget.readFields[i]]}',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String queryInput = '';
              return AlertDialog(
                title: Text('Search', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.black,
                content: TextField(
                  onChanged: (value) {
                    queryInput = value;
                  },
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter search query',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
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
                    child: Text('Search', style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      handleSearchSubmit(widget.apiHost, widget.modal, queryInput);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.search, color: Colors.white),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.white, width: 2.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: _queryError != null ? BottomAppBar(
        child: Text(_queryError!, style: TextStyle(color: Colors.red)),
      ) : null,
    );
  }

  Future<void> _launchInBrowser(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  Widget _buildScrollableDialog(BuildContext context, Map<String, dynamic> item) {
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

