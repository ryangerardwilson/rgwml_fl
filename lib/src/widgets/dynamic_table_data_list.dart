import 'package:flutter/material.dart';
import 'dynamic_table_scrollable_dialog.dart';

class DataList extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final List<String> readFields;

  DataList({required this.data, required this.readFields});

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
              builder: (context) => ScrollableDialog(item: data[index]),
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

