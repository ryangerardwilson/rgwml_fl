import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dashboard_view.dart';
import 'login.dart';
import 'dashboard_utils.dart';
import 'crontab.dart';


class CRMDashboard extends StatefulWidget {
  final String title;
  final List<String> cardTitles;
  final String versionUrl;
  final String currentVersion;
  final String apiHost;
  
  CRMDashboard({
    required this.title,
    required this.cardTitles,
    required this.versionUrl,
    required this.currentVersion,
    required this.apiHost,
  });

  @override
  _CRMDashboardState createState() => _CRMDashboardState();
}

class _CRMDashboardState extends State<CRMDashboard> with DashboardUtils {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  bool _updateAvailable = false;
  String? _updateUrl;
  String _latestVersion = "";
  double _latitude = 0.0;
  double _longitude = 0.0;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isSettingsDialogOpen = false;
  String? _username;
  String? _userId;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    checkAuthentication(context, widget, onAuthentication: (username, userId) {
      setState(() {
        _username = username;
        _userId = userId;
        _isAuthenticated = true;
      });
    });
    Crontab().scheduleJob('checkForUpdate', Duration(hours: 1), checkForUpdate);
    initLocationUpdates((latitude, longitude) {
      setState(() {
        _latitude = latitude;
        _longitude = longitude;
      });
    }).then((sub) => _locationSubscription = sub);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    Crontab().cancelJob('checkForUpdate');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_username == null || _userId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DashboardView(
      scaffoldKey: _scaffoldKey,
      title: widget.title,
      username: _username!,
      userId: _userId!,
      cardTitles: widget.cardTitles,
      currentVersion: widget.currentVersion,
      updateAvailable: _updateAvailable,
      latestVersion: _latestVersion,
      updateUrl: _updateUrl,
      latitude: _latitude,
      longitude: _longitude,
      onSettingsPressed: (context) => _openSettings(context),
    );
  }

  Future<void> checkForUpdate() async {
    print('Executing checkForUpdate Job');
    await checkForAppUpdate(
      versionUrl: widget.versionUrl,
      currentVersion: widget.currentVersion,
      context: context,
      onUpdateAvailable: (latestVersion, updateUrl) {
        setState(() {
          _updateAvailable = true;
          _latestVersion = latestVersion;
          _updateUrl = updateUrl;
        });
        if (!_isSettingsDialogOpen) {
          _openSettings(context);
        }
      },
      onLatestVersionFetched: (latestVersion) {
        setState(() {
          _latestVersion = latestVersion;
        });
      },
      onError: (message) {
        showSnack(_scaffoldKey, message);
      },
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    await checkForUpdate();
    setState(() {
      _isSettingsDialogOpen = true;
    });
    showSettingsDialog(
      context: context,
      username: _username ?? 'N/A',
      userId: _userId ?? 'N/A',
      currentVersion: widget.currentVersion,
      updateAvailable: _updateAvailable,
      latestVersion: _latestVersion,
      updateUrl: _updateUrl,
      locationStream: Location.instance.onLocationChanged,
      isAuthenticated: _isAuthenticated,
      onLogout: () => _logout(context),
    ).then((_) {
      setState(() {
        _isSettingsDialogOpen = false;
      });
    });
  }

  Future<void> _logout(BuildContext context) async {
    await logoutUser();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          apiHost: widget.apiHost,
          title: widget.title,
          cardTitles: widget.cardTitles,
          versionUrl: widget.versionUrl,
          currentVersion: widget.currentVersion,
        ),
      ),
    );
  }
}

