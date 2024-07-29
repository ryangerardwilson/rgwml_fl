import 'package:flutter/material.dart';
import 'dynamic_table.dart';  // Ensure you have the correct import path
import '../modal_config.dart'; // Ensure the correct path

class DashboardView extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final String username;
  final String userId;
  final String currentVersion;
  final bool updateAvailable;
  final String latestVersion;
  final String? updateUrl;
  final double latitude;
  final double longitude;
  final void Function(BuildContext) onSettingsPressed;
  final ModalConfigMap modalConfig;
  final String apiHost;

  DashboardView({
    required this.scaffoldKey,
    required this.title,
    required this.username,
    required this.userId,
    required this.currentVersion,
    required this.updateAvailable,
    required this.latestVersion,
    this.updateUrl,
    required this.latitude,
    required this.longitude,
    required this.onSettingsPressed,
    required this.modalConfig,
    required this.apiHost,
  });

  @override
  Widget build(BuildContext context) {
    final modalKeys = modalConfig.configs.keys.toList();

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
              child: ListView.builder(
                itemCount: modalKeys.length,
                itemBuilder: (context, index) {
                  final modalKey = modalKeys[index];
                  final modal = modalConfig.configs[modalKey];

                  if (modal != null) {
                    final readRoute = modal.readRoutes.isNotEmpty
                        ? modal.readRoutes[0]
                        : '';
                    final readFields = modal.scopes.read;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                title: Text(
                                  modalKey,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.black,
                              ),
                              body: DynamicTable(
                                apiHost: apiHost,
                                modal: modalKey,
                                route: readRoute,
                                readFields: readFields,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Card(
                        color: Colors.grey[850],
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                modalKey,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Tap to view details',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    return SizedBox.shrink(); // Return an empty widget if modal is null
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

