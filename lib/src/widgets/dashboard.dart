import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    checkForUpdate();
  }

  Future<void> checkForUpdate() async {
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

  Future<void> _launchInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showSnack("Could not launch $url");
    }
  }

  void openUpdateLink() {
    if (_updateUrl != null) {
      _launchInBrowser(_updateUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_updateAvailable)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: openUpdateLink,
                  child: Text('Update from v${widget.currentVersion} to v$_latestVersion'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Welcome, ${widget.username} (ID: ${widget.userId})',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Current Version: ${widget.currentVersion}',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Latest Version: $_latestVersion',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.cardTitles.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: Colors.grey[850],
                    child: Center(
                      child: Text(
                        widget.cardTitles[index],
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

