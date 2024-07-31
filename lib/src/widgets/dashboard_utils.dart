import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'settings.dart';
import 'login.dart';

mixin DashboardUtils {
  Future<void> checkForAppUpdate({
    required String versionUrl,
    required String currentVersion,
    required BuildContext context,
    required Function(String, String) onUpdateAvailable,
    required Function(String) onLatestVersionFetched,
    required Function(String) onError,
  }) async {
    try {
      final response = await http.get(Uri.parse(versionUrl));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final latestVersion = jsonResponse['version'];
        final apkUrl = jsonResponse['apk_url'];

        if (compareVersions(latestVersion, currentVersion)) {
          onUpdateAvailable(latestVersion, apkUrl);
        } else {
          onLatestVersionFetched(latestVersion);
        }
      } else {
        onError("Failed to check for updates.");
      }
    } catch (e) {
      onError("Error: $e");
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

  void showSnack(GlobalKey<ScaffoldState> scaffoldKey, String text) {
    if (scaffoldKey.currentContext != null) {
      ScaffoldMessenger.of(scaffoldKey.currentContext!)
          .showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<StreamSubscription<LocationData>> initLocationUpdates(
    void Function(double latitude, double longitude) onLocationChanged,
  ) async {
    final Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return throw 'Location services are disabled.';
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return throw 'Location permissions are denied';
      }
    }

    return location.onLocationChanged.listen((LocationData currentLocation) {
      onLocationChanged(currentLocation.latitude!, currentLocation.longitude!);
    });
  }

  Future<void> checkAuthentication(
    BuildContext context, dynamic widget,
    {required Function(String username, String userId) onAuthentication}
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isAuthenticated = prefs.getBool('auth') ?? false;

    if (!isAuthenticated) {
      Navigator.pushReplacement(
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
        )
      );
    } else {
      onAuthentication(
        prefs.getString('username') ?? '',
        prefs.getString('user_id') ?? '',
      );
    }
  }

  Future<void> showSettingsDialog({
    required BuildContext context,
    required String username,
    required String userId,
    required String currentVersion,
    required bool updateAvailable,
    required String latestVersion,
    required String? updateUrl,
    required Stream<LocationData> locationStream,
    required bool isAuthenticated,
    required Future<void> Function() onLogout,
  }) async {
    showDialog(
      context: context,
      builder: (context) {
        return SettingsDialog(
          username: username,
          userId: userId,
          currentVersion: currentVersion,
          updateAvailable: updateAvailable,
          latestVersion: latestVersion,
          updateUrl: updateUrl,
          locationStream: locationStream,
          isAuthenticated: isAuthenticated,
          logout: onLogout,
        );
      }
    );
  }

  Future<void> logoutUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

