import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_view.dart';
import 'login.dart';
import 'crontab.dart';
import 'dashboard_utils.dart'; // Ensure the correct path
import 'modal_config.dart'; // Ensure the correct path

class CRMDashboard extends StatefulWidget {
  final String title;
  final String versionUrl;
  final String currentVersion;
  final String apiHost;
  final ModalConfigMap modalConfig;
  final String openAiJsonModeModel;
  final String openAiApiKey;

  CRMDashboard({
    required this.title,
    required this.versionUrl,
    required this.currentVersion,
    required this.apiHost,
    required this.modalConfig,
    required this.openAiJsonModeModel,
    required this.openAiApiKey,
  });

  @override
  _CRMDashboardState createState() => _CRMDashboardState();
}

class _CRMDashboardState extends State<CRMDashboard> with DashboardUtils {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  bool _updateAvailable = false;
  String _updateUrl = "";
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
      if (mounted) {
        setState(() {
          _username = username;
          _userId = userId;
          _isAuthenticated = true;
        });
      }
    });

    Crontab().scheduleJob('checkForUpdate', Duration(hours: 1), () async {
      if (mounted) {
        await checkForUpdate();
      }
    });

    initLocationUpdates((latitude, longitude) {
      if (mounted) {
        setState(() {
          _latitude = latitude;
          _longitude = longitude;
        });
      }
    }).then((sub) {
      if (mounted) {
        _locationSubscription = sub;
      }
    });
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
      currentVersion: widget.currentVersion,
      updateAvailable: _updateAvailable,
      latestVersion: _latestVersion,
      updateUrl: _updateUrl,
      latitude: _latitude,
      longitude: _longitude,
      onSettingsPressed: (context) => _openSettings(context),
      modalConfig: widget.modalConfig,
      apiHost: widget.apiHost,
      openAiJsonModeModel: widget.openAiJsonModeModel,
      openAiApiKey: widget.openAiApiKey
    );
  }

  Future<void> checkForUpdate() async {
    print('Executing checkForUpdate Job');
    await checkForAppUpdate(
      versionUrl: widget.versionUrl,
      currentVersion: widget.currentVersion,
      context: context,
      onUpdateAvailable: (latestVersion, updateUrl) {
        if (mounted) {
          setState(() {
            _updateAvailable = true;
            _latestVersion = latestVersion;
            _updateUrl = updateUrl;
          });
          if (!_isSettingsDialogOpen) {
            _openSettings(context);
          }
        }
      },
      onLatestVersionFetched: (latestVersion) {
        if (mounted) {
          setState(() {
            _latestVersion = latestVersion;
          });
        }
      },
      onError: (message) {
        if (mounted) {
          showSnack(_scaffoldKey, message);
        }
      },
    );
  }

  Future<void> _openSettings(BuildContext context) async {
    if (!mounted) return; // additional check to ensure widget is still mounted
    await checkForUpdate();
    if (mounted) {
      setState(() {
        _isSettingsDialogOpen = true;
      });
    }
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
      if (mounted) {
        setState(() {
          _isSettingsDialogOpen = false;
        });
      }
    });
  }

Future<void> _logout(BuildContext context) async {
  await logoutUser();
  
  // Clear the SharedPreferences to remove stored authentication data
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (context) => LoginPage(
        apiHost: widget.apiHost,
        title: widget.title,
        versionUrl: widget.versionUrl,
        currentVersion: widget.currentVersion,
        modalConfig: widget.modalConfig,
        openAiJsonModeModel: widget.openAiJsonModeModel,
        openAiApiKey: widget.openAiApiKey
      ),
    ),
    (Route<dynamic> route) => false, // This removes all previous routes
  );
}


}

