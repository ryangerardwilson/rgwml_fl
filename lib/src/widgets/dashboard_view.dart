import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'settings.dart';

class DashboardView extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final String username;
  final String userId;
  final List<String> cardTitles;
  final String currentVersion;
  final bool updateAvailable;
  final String latestVersion;
  final String? updateUrl;
  final double latitude;
  final double longitude;
  final void Function(BuildContext) onSettingsPressed;

  DashboardView({
    required this.scaffoldKey,
    required this.title,
    required this.username,
    required this.userId,
    required this.cardTitles,
    required this.currentVersion,
    required this.updateAvailable,
    required this.latestVersion,
    required this.updateUrl,
    required this.latitude,
    required this.longitude,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () => onSettingsPressed(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
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
          ],
        ),
      ),
    );
  }
}

