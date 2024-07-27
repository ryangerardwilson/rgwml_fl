import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'settings.dart';
import 'dashboard_view.dart';

class CRMDashboard extends StatefulWidget {
  final String title;
  final String username;
  final String userId;
  final List<String> cardTitles;
  final String versionUrl;
  final String currentVersion;

  CRMDashboard({
    required this.title,
    required this.username,
    required this.userId,
    required this.cardTitles,
    required this.versionUrl,
    required this.currentVersion,
  });

  @override
  _CRMDashboardState createState() => _CRMDashboardState();
}

class _CRMDashboardState extends State<CRMDashboard> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  bool _updateAvailable = false;
  String? _updateUrl;
  String _latestVersion = "";
  double _latitude = 0.0;
  double _longitude = 0.0;
  StreamSubscription<LocationData>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    checkForUpdate();
    _listenForLocationUpdates();
  }


  Future<void> checkForUpdate() async {
    // Your existing version-checking logic
    try {
      final response = await http.get(Uri.parse(widget.versionUrl));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final latestVersion = jsonResponse['version'];
        final apkUrl = jsonResponse['apk_url'];

        if (compareVersions(latestVersion, widget.currentVersion)) {
          setState(() {
            _updateAvailable = true;
            _latestVersion = latestVersion;
            _updateUrl = apkUrl;
          });
        } else {
          setState(() {
            _latestVersion = latestVersion;
          });
        }
      } else {
        showSnack("Failed to check for updates.");
      }
    } catch (e) {
      showSnack("Error: $e");
    }
  }




  bool compareVersions(String latestVersion, String currentVersion) {
    List<int> latest = latestVersion.split('.').map(int.parse).toList();
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    int maxLength = latest.length > current.length ? latest.length : current.length;

    for (int i = 0; i < maxLength; i++) {
      int latestSegment = (i < latest.length) ? latest[i] : 0;
      int currentSegment = (i < current.length) ? current[i] : 0;
      if (latestSegment > currentSegment) {
        return true;
      } else if (latestSegment < currentSegment) {
        return false;
      }
    }
    return false;
  }

  void showSnack(String text) {
    if (_scaffoldKey.currentContext != null) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _listenForLocationUpdates() async {
    final Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationSubscription = location.onLocationChanged.listen((LocationData currentLocation) {
      setState(() {
        _latitude = currentLocation.latitude!;
        _longitude = currentLocation.longitude!;
      });
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardView(
      scaffoldKey: _scaffoldKey,
      title: widget.title,
      username: widget.username,
      userId: widget.userId,
      cardTitles: widget.cardTitles,
      currentVersion: widget.currentVersion,
      updateAvailable: _updateAvailable,
      latestVersion: _latestVersion,
      updateUrl: _updateUrl,
      latitude: _latitude,
      longitude: _longitude,
      onSettingsPressed: _openSettings,
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await checkForUpdate(); // Ensure the latest data is fetched
    showDialog(
      context: context,
      builder: (context) {
        return SettingsDialog(
          username: widget.username,
          userId: widget.userId,
          currentVersion: widget.currentVersion,
          updateAvailable: _updateAvailable,
          latestVersion: _latestVersion,
          updateUrl: _updateUrl,
          locationStream: Location.instance.onLocationChanged,
        );
      },
    );
  }
}

