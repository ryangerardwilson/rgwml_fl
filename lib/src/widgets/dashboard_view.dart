import 'package:flutter/material.dart';
import 'dynamic_table.dart';  // Ensure you have the correct import path
import '../modal_config.dart'; // Ensure the correct path

class DashboardView extends StatefulWidget {
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
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Map<String, String?> _selectedReadRoute = {};

  @override
  Widget build(BuildContext context) {
    final modalKeys = widget.modalConfig.configs.keys.toList();

    return Scaffold(
      key: widget.scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () => widget.onSettingsPressed(context),
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
                  final modal = widget.modalConfig.configs[modalKey];

                  if (modal != null) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedReadRoute[modalKey] = modal.readRoutes.isNotEmpty
                              ? modal.readRoutes[0]
                              : null;
                        });

                        showDialog(
                          context: context,
                          builder: (context) {
                            return _buildRouteSelectionDialog(context, modalKey, modal.readRoutes);
                          },
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
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Tap to view details',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildRouteSelectionDialog(BuildContext context, String modalKey, List<String> routes) {
  return AlertDialog(
    backgroundColor: Colors.black,  // Set dialog background color
    title: Text(
      'Select filter for $modalKey',
      style: TextStyle(color: Colors.white),
    ),
    content: Container(
      width: double.maxFinite,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: routes.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[850],  // Set button background color
              ),
              onPressed: () {
                setState(() {
                  _selectedReadRoute[modalKey] = routes[index];
                });
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(
                          modalKey,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.black,
                      ),
                      body: DynamicTable(
                        apiHost: widget.apiHost,
                        modal: modalKey,
                        route: _selectedReadRoute[modalKey] ?? '',
                        readFields: widget.modalConfig.configs[modalKey]!.scopes.read,
                      ),
                    ),
                  ),
                );
              },
              child: Text(
                routes[index],
                style: TextStyle(color: Colors.white),  // Set text color to white
              ),
            ),
          );
        },
      ),
    ),
  );
}


}

