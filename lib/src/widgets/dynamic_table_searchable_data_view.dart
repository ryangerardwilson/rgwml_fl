import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dynamic_table_data_list.dart';

class SearchableDataView extends StatelessWidget {
  final String apiHost;
  final String modal;
  final String route;
  final List<String> readFields;
  final List<Map<String, dynamic>> searchData;
  final String? queryError;
  final Function handleSearchSubmit;

  const SearchableDataView({
    required this.apiHost,
    required this.modal,
    required this.route,
    required this.readFields,
    required this.searchData,
    required this.queryError,
    required this.handleSearchSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchData(apiHost, modal, route), // Update to send correct fetchData method
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
          final data = searchData.isNotEmpty ? searchData : snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Filter: $route', // Display the name of the route
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
                child: DataList(
                  data: data,
                  readFields: readFields,
                ),
              ),
            ],
          );
        }
      },
    );
  }

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
}

