import 'package:flutter/material.dart';
import 'dynamic_table_scrollable_dialog.dart';

class DataList extends StatelessWidget { // Note: This is now StatelessWidget
  final String apiHost;
  final String modal;
  final List<Map<String, dynamic>> data;
  final bool create;
  final List<String> readFields;
  final List<String> updateFields;
  final bool delete;
  final VoidCallback onDeleteItem;

  DataList({
    required this.apiHost,
    required this.modal,
    required this.data,
    required this.readFields,
    required this.updateFields,
    required this.create,
    required this.delete,
    required this.onDeleteItem,
  });

  void _removeItem(BuildContext context, int index) {
    // Deleting the item directly
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item deleted successfully!')),
    );
    onDeleteItem(); // Call the callback to refresh data in the parent
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
                onDelete: () => _removeItem(context, index),
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
}

