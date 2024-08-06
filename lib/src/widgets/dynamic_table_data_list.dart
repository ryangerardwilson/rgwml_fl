import 'package:flutter/material.dart';
import 'dynamic_table_scrollable_dialog.dart';
import 'modal_config.dart';

class DataList extends StatelessWidget { // Note: This is now StatelessWidget
  final String apiHost;
  final String modal;
  final List<Map<String, dynamic>> data;
  final bool create;
  final List<String> readFields;
  final List<String> readSummaryFields;
  final List<String> updateFields;
  final bool delete;
  final VoidCallback onDeleteItem;
  final VoidCallback onEditItem;
  final String userId;
  final List<String> columns;
  final Options options;
  final Map<String, List<ConditionalOption>> conditionalOptions;
  final Map<String, List<String>> validationRules;
  final dynamic aiQualityChecks;
  final String openAiJsonModeModel;
  final String openAiApiKey;

  DataList({
    required this.apiHost,
    required this.modal,
    required this.data,
    required this.readFields,
    required this.readSummaryFields,
    required this.updateFields,
    required this.create,
    required this.delete,
    required this.onDeleteItem,
    required this.onEditItem,

    required this.userId,
    required this.columns,
    required this.options,
    required this.conditionalOptions,
    required this.validationRules,
    required this.aiQualityChecks,
    required this.openAiJsonModeModel,
    required this.openAiApiKey,

  });

  void _reloadData(BuildContext context, int index) {
    // Deleting the item directly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item deleted successfully!')),
    );
    onDeleteItem(); // Call the callback to refresh data in the parent
  }

  void _reloadDataEdit(BuildContext context, int index) {
    Navigator.of(context).pop();
    // Deleting the item directly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item edited successfully!')),
    );
    onEditItem(); // Call the callback to refresh data in the parent
  }


  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: data.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => ScrollableDialog(
                apiHost: apiHost,
                modal: modal,
                item: data[index],
                create: create,
                readFields: readFields,
                updateFields: updateFields,
                delete: delete,
                onDelete: () => _reloadData(context, index),
                onEdit: () => _reloadDataEdit(context, index),
                userId: userId,
                columns: columns,
                options: options,
                conditionalOptions: conditionalOptions,
                validationRules: validationRules,
                aiQualityChecks: aiQualityChecks,
                openAiJsonModeModel: openAiJsonModeModel,
                openAiApiKey: openAiApiKey,
              ),
            );
          },
          child: Card(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < readSummaryFields.length; i++)
                    if (i < 5 || i >= readSummaryFields.length - 2)
                      Text(
                        '${readSummaryFields[i]}: ${data[index][readSummaryFields[i]]}',
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
}

