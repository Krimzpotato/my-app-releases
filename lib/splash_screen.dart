import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'login_page.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _currentStatus = 'Checking for updates...';
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  String _currentVersion = '';
  String _latestVersion = '';

  @override
  void initState() {
    super.initState();
    _requestPermissions().then((_) {
      _initializeFirebase().then((_) {
        _checkForUpdates();
      });
    });
  }

  // Request necessary permissions
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.manageExternalStorage, // Android 11+
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    if (statuses[Permission.manageExternalStorage]?.isDenied == true) {
      _showPermissionDeniedDialog();
    } else {
      print('All required permissions granted');
    }
  }

  // Show permission denied dialog
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text('This app requires additional permissions to continue. Please enable them in settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Initialize Firebase and check app version
  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    print('Firebase initialized');
    _currentVersion = (await PackageInfo.fromPlatform()).version;
    print('Current version: $_currentVersion');
  }

  // Check for app updates using Firebase Remote Config
  Future<void> _checkForUpdates() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: Duration(seconds: 30), // Shorter timeout for testing
          minimumFetchInterval: Duration(seconds: 0), // No caching for testing
        ),
      );
      bool updated = await _remoteConfig.fetchAndActivate();
      print('Config updated: $updated');

      _latestVersion = _remoteConfig.getString('latest_version');
      bool updateAvailable = _compareVersions(_currentVersion, _latestVersion);
      String apkUrl = _remoteConfig.getString('apk_url');
      print('updateAvailable: $updateAvailable');
      print('latestVersion: $_latestVersion'); // Add logging
      print('currentVersion: $_currentVersion'); // Add logging
      print('apkUrl: $apkUrl');

      if (updateAvailable) {
        _showUpdateDialog(apkUrl);
      } else {
        _navigateToNextScreen();
      }
    } catch (e) {
      print('Failed to check for update: $e');
      _navigateToNextScreen();
    }
  }

  // Compare current version with the latest version
  bool _compareVersions(String currentVersion, String latestVersion) {
    try {
      List<int> currentParts = currentVersion.split('.').map(int.parse).toList();
      List<int> latestParts = latestVersion.split('.').map(int.parse).toList();
      for (int i = 0; i < latestParts.length; i++) {
        if (currentParts[i] < latestParts[i]) {
          return true;
        } else if (currentParts[i] > latestParts[i]) {
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }

  // Show update dialog when update is available
  void _showUpdateDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Available'),
        content: Text('A new update is available. Would you like to update now?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToNextScreen();
            },
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _redirectToUpdatePage(url);
            },
            child: Text('Yes'),
          ),
        ],
      ),
    );
  }

  // Redirect to the update page (APK URL)
  void _redirectToUpdatePage(String url) async {
    setState(() {
      _currentStatus = 'Redirecting to update page...';
    });

    print('Attempting to launch URL: $url');
    if (await canLaunch(url)) {
      try {
        await launch(
          url,
          forceSafariVC: false,
          forceWebView: false,
          enableJavaScript: true,
        );
        print('URL launched successfully');
      } catch (e) {
        print('Error launching URL: $e');
        _showErrorDialog('Failed to open update page.');
      }
    } else {
      print('Could not launch URL: $url');
      _showErrorDialog('Invalid update URL.');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Navigate to the next screen based on user authentication status
  void _navigateToNextScreen() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 200,
              width: 200,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20),
            Text(
              _currentStatus,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
