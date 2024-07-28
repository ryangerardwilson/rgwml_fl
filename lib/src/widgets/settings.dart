import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:location/location.dart';
import 'dart:async';

class SettingsDialog extends StatefulWidget {
  final String username;
  final String userId;
  final String currentVersion;
  final bool updateAvailable;
  final String latestVersion;
  final String? updateUrl;
  final Stream<LocationData> locationStream;

  SettingsDialog({
    required this.username,
    required this.userId,
    required this.currentVersion,
    required this.updateAvailable,
    required this.latestVersion,
    required this.updateUrl,
    required this.locationStream,
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
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Settings',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
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
              child: Text('Update to v${widget.latestVersion}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
        ],
      ),
      actions: <Widget>[
        if (!widget.updateAvailable) // Only show the close button if no update is available
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.teal),
            ),
          ),
      ],
    );
  }
}

