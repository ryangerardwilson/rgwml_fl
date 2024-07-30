import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dynamic_table_searchable_data_view.dart';

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
  final bool create;
  final List<String> readFields;
  final List<String> updateFields;
  final bool delete;

  DynamicTable({
    required this.apiHost,
    required this.modal,
    required this.route,
    required this.create,
    required this.readFields,
    required this.updateFields,
    required this.delete
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
        child: SearchableDataView(
          apiHost: widget.apiHost,
          modal: widget.modal,
          route: widget.route,
          create: widget.create,
          readFields: widget.readFields,
          updateFields: widget.updateFields,
          delete: widget.delete,
          searchData: _searchData,
          queryError: _queryError,
          handleSearchSubmit: handleSearchSubmit,
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
}

