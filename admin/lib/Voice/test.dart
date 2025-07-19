import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionTestPage extends StatefulWidget {
  const PermissionTestPage({super.key});

  @override
  State<PermissionTestPage> createState() => _PermissionTestPageState();
}

class _PermissionTestPageState extends State<PermissionTestPage> {
  Future<void> _requestStorage() async {
    PermissionStatus status;
    if (Platform.isAndroid &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33) {
      status = await Permission.audio.request(); // For Android 13+
    } else {
      status = await Permission.storage.request(); // For Android 12 and below
    }

    if (status.isGranted) {
      print("✅ Storage/Audio permission granted");
    } else if (status.isPermanentlyDenied) {
      print("❌ Storage/Audio permission permanently denied");
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Permission Required"),
          content: const Text(
            "Please enable storage/audio permission from settings.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
              child: const Text("Open Settings"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
          ],
        ),
      );
    } else {
      print("🙅 Permission denied (not permanently)");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permission Handler Test")),
      body: Center(
        child: ElevatedButton(
          onPressed: _requestStorage,
          child: const Text("Request Storage Permission"),
        ),
      ),
    );
  }
}
