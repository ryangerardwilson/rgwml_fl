import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';
import 'dart:async';

class SettingsDialog extends StatefulWidget {
  final String username;
  final String userId;
  final String userType;
  final String currentVersion;
  final bool updateAvailable;
  final String latestVersion;
  final String? updateUrl;
  final Stream<LocationData> locationStream;
  final bool isAuthenticated;
  final Future<void> Function() logout;

  SettingsDialog({
    required this.username,
    required this.userId,
    required this.userType,
    required this.currentVersion,
    required this.updateAvailable,
    required this.latestVersion,
    required this.updateUrl,
    required this.locationStream,
    required this.isAuthenticated,
    required this.logout,
  });

  @override
  _SettingsDialogState createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  double? _latitude;
  double? _longitude;
  late StreamSubscription<LocationData> _locationSubscription;

  @override
  void initState() {
    super.initState();
    _locationSubscription = widget.locationStream.listen((locationData) {
      setState(() {
        _latitude = locationData.latitude;
        _longitude = locationData.longitude;
      });
    });
  }

  @override
  void dispose() {
    _locationSubscription.cancel();
    super.dispose();
  }

  Future<void> _launchInBrowser(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Logged in as: ${widget.username}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                'User ID: ${widget.userId}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                'User Type: ${widget.userType}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                'Current Version: ${widget.currentVersion}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                'Latest Version: ${widget.latestVersion}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                'Latitude: ${_latitude ?? 'loading...'}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                'Longitude: ${_longitude ?? 'loading...'}',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 16),
              if (widget.updateAvailable)
                ElevatedButton(
                  onPressed: () {
                    if (widget.updateUrl != null) {
                      _launchInBrowser(widget.updateUrl!, context);
                    }
                  },
                  child: Text(
                    'Update to v${widget.latestVersion}',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                ),
            ],
          ),
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isAuthenticated)
                ElevatedButton(
                  onPressed: () => widget.logout(),
                  child: Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                ),
              if (widget.isAuthenticated)
                SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

