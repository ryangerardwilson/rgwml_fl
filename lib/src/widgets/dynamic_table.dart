import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dynamic_table_searchable_data_view.dart';
import 'dynamic_table_create_dialog.dart';
import 'modal_config.dart';

Future<List<Map<String, dynamic>>> fetchData(String apiHost, String modal, String route, bool belongsToUserId, String userId) async {
  final apiUrl = belongsToUserId 
      ? (apiHost + 'read/$modal/$route/$userId') 
      : (apiHost + 'read/$modal/$route');

  try {
    print(apiUrl);
    final response = await http.get(Uri.parse(apiUrl));
    print(response);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print(result);

      if (result.containsKey('columns') && result.containsKey('data')) {
        List<String> columns = List<String>.from(result['columns']);
        List<List<dynamic>> data = List<List<dynamic>>.from(result['data']);

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
  final bool belongsToUserId;
  final bool create;
  final List<String> readFields;
  final List<String> readSummaryFields;
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
    required this.belongsToUserId,
    required this.create,
    required this.readFields,
    required this.readSummaryFields,
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
  List<Map<String, dynamic>> _originalData = [];
  List<Map<String, dynamic>> _filteredData = [];
  String? _queryError;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _searchController.addListener(() {
      _filterData(_searchController.text);
    });
  }

  Future<void> _fetchInitialData() async {
    List<Map<String, dynamic>> data = await fetchData(widget.apiHost, widget.modal, widget.route, widget.belongsToUserId, widget.userId);
    setState(() {
      _originalData = data;
      _filteredData = data;
    });
  }

  void _filterData(String queryInput) {
    String query = queryInput.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredData = _originalData;
      });
      return;
    }

    setState(() {
      _filteredData = _originalData.where((row) {
        return row.values.any((value) {
          if (value == null) return false;
          return value.toString().toLowerCase().contains(query);
        });
      }).toList();
    });
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
        _fetchInitialData();
      }
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Search', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          content: TextField(
            controller: _searchController,
            onChanged: (value) {
              _filterData(value);
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
                belongsToUserId: widget.belongsToUserId,
                create: widget.create,
                readFields: widget.readFields,
                readSummaryFields: widget.readSummaryFields,
                updateFields: widget.updateFields,
                delete: widget.delete,
                searchData: _filteredData,
                queryError: _queryError,
                handleSearchSubmit: _filterData,

                userId: widget.userId,
                columns: widget.readFields,
                options: widget.options,
                conditionalOptions: widget.conditionalOptions,
                validationRules: widget.validationRules,
                aiQualityChecks: widget.aiQualityChecks,
                openAiJsonModeModel: widget.openAiJsonModeModel,
                openAiApiKey: widget.openAiApiKey,

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

