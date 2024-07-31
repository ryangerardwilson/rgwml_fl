// dynamic_table.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dynamic_table_searchable_data_view.dart';
import 'dynamic_table_create_dialog.dart';
import 'modal_config.dart';


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
  final String userId;
  final String apiHost;
  final String modal;
  final String route;
  final bool create;
  final List<String> readFields;
  final List<String> updateFields;
  final bool delete;
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final Map<String, List<String>> validationRules;
  final dynamic aiQualityChecks;
  final String openAiJsonModeModel;
  final String openAiApiKey;

  DynamicTable({
    required this.userId,
    required this.apiHost,
    required this.modal,
    required this.route,
    required this.create,
    required this.readFields,
    required this.updateFields,
    required this.delete,
    required this.options,
    required this.conditionalOptions,
    required this.validationRules,
    required this.aiQualityChecks,
    required this.openAiJsonModeModel,
    required this.openAiApiKey,
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

void _showCreateDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return DynamicTableCreateDialog(
        userId: widget.userId,
        apiHost: widget.apiHost,
        modal: widget.modal,
        columns: widget.readFields,
        options: widget.options,
        conditionalOptions: widget.conditionalOptions,
        validationRules: widget.validationRules,
        aiQualityChecks: widget.aiQualityChecks,
        openAiJsonModeModel: widget.openAiJsonModeModel,
        openAiApiKey: widget.openAiApiKey,
      );
    },
  ).then((result) {
    if (result == true) {
      // Reload data if the create dialog returns success
      fetchData(widget.apiHost, widget.modal, widget.route).then((data) {
        setState(() {
          _searchData = data;
        });
      });
    }
  });
}


  void _showSearchDialog() {
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
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
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
          ],
        ),
      ),
      bottomNavigationBar: widget.create 
        ? BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              _showCreateDialog();
            } else if (index == 1) {
              _showSearchDialog();
            }
          },
          backgroundColor: Colors.black,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          items: [
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Icon(Icons.add, color: Colors.white),
                  Text('Create', style: TextStyle(color: Colors.white)),
                ],
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Column(
                children: [
                  Icon(Icons.search, color: Colors.white),
                  Text('Search', style: TextStyle(color: Colors.white)),
                ],
              ),
              label: '',
            ),
          ],
        )
        : BottomAppBar(
          color: Colors.black,
          child: IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: _showSearchDialog,
          ),
        ),
    );
  }
}

