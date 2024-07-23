import 'package:flutter/material.dart';

class CRMDashboard extends StatelessWidget {
  final List<String> cardTitles;

  CRMDashboard({required this.cardTitles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('CRM Dashboard'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: cardTitles.length,
          itemBuilder: (context, index) {
            return Card(
              color: Colors.grey[850],
              child: Center(
                child: Text(
                  cardTitles[index],
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

