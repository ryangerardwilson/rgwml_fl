import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dynamic_table_data_list.dart';
import 'modal_config.dart';

class SearchableDataView extends StatefulWidget {
  final String apiHost;
  final String modal;
  final String route;
  final bool create;
  final List<String> readFields;
  final List<String> readSummaryFields;
  final List<String> updateFields;
  final bool delete;
  final List<Map<String, dynamic>> searchData;
  final String? queryError;
  final Function handleSearchSubmit;

  final String userId;
  final List<String> columns;
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final Map<String, List<String>> validationRules;
  final dynamic aiQualityChecks;
  final String openAiJsonModeModel;
  final String openAiApiKey;


  const SearchableDataView({
    required this.apiHost,
    required this.modal,
    required this.route,
    required this.create,
    required this.readFields,
    required this.readSummaryFields,
    required this.updateFields,
    required this.delete,
    required this.searchData,
    required this.queryError,
    required this.handleSearchSubmit,

    required this.userId,
    required this.columns,
    required this.options,
    required this.conditionalOptions,
    required this.validationRules,
    required this.aiQualityChecks,
    required this.openAiJsonModeModel,
    required this.openAiApiKey,

  });

  @override
  _SearchableDataViewState createState() => _SearchableDataViewState();
}

class _SearchableDataViewState extends State<SearchableDataView> {
  late Future<List<Map<String, dynamic>>> _fetchDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = fetchData();
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    final apiUrl = '${widget.apiHost}read/${widget.modal}/${widget.route}';
    //print('API URL: $apiUrl');

    try {
      final response = await http.get(Uri.parse(apiUrl));
      //print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        if (result.containsKey('columns') && result.containsKey('data')) {
          List<String> columns = List<String>.from(result['columns']);
          List<List<dynamic>> data = List<List<dynamic>>.from(result['data']);

          return data.map((row) {
            return Map<String, dynamic>.fromIterables(columns, row);
          }).toList();
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

  void _refreshData() {
    setState(() {
      _fetchDataFuture = fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchDataFuture,
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
          final data = widget.searchData.isNotEmpty ? widget.searchData : snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Filter: ${widget.route}',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Rows Fetched: ${data.length}',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Expanded(
                child: DataList(
                  apiHost: widget.apiHost,
                  modal: widget.modal,
                  data: data,
                  create: widget.create,
                  readFields: widget.readFields,
                  readSummaryFields: widget.readSummaryFields,
                  updateFields: widget.updateFields,
                  delete: widget.delete,
                  onDeleteItem: _refreshData,
                  onEditItem: _refreshData,

                userId: widget.userId,
                columns: widget.columns,
                options: widget.options,
                conditionalOptions: widget.conditionalOptions,
                validationRules: widget.validationRules,
                aiQualityChecks: widget.aiQualityChecks,
                openAiJsonModeModel: widget.openAiJsonModeModel,
                openAiApiKey: widget.openAiApiKey,


                ),
              ),
            ],
          );
        }
      },
    );
  }
}

