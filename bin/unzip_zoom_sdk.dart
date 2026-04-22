import 'dart:core';
import 'dart:io';
import 'dart:convert';

/// gr_zoom SDK Setup Script
///
/// Android: Zoom SDK 6.3.0 is now fetched automatically via Maven Central.
///          No download needed — just run `flutter pub get` and build.
///
/// iOS: MobileRTC.xcframework is NOT on Maven/CocoaPods for Flutter.
///      We still download it from the hosted location below.
///      Version: 5.17.11 (iOS upgrade to 6.x is a separate task)

void main(List<String> args) async {
  var location = Platform.script.toString();
  var isNewFlutter = location.contains(".snapshot");
  if (isNewFlutter) {
    var sp = Platform.script.toFilePath();
    var sd = sp.split(Platform.pathSeparator);
    sd.removeLast();
    var scriptDir = sd.join(Platform.pathSeparator);
    var packageConfigPath = [scriptDir, '..', '..', '..', 'package_config.json']
        .join(Platform.pathSeparator);

    var jsonString = File(packageConfigPath).readAsStringSync();

    Map<String, dynamic> packages = jsonDecode(jsonString);
    var packageList = packages["packages"];
    String? zoomFileUri;
    for (var package in packageList) {
      if (package["name"] == "gr_zoom") {
        zoomFileUri = package["rootUri"];
        break;
      }
    }
    if (zoomFileUri == null) {
      print("gr_zoom package not found!");
      return;
    }
    location = zoomFileUri;
  }
  if (Platform.isWindows) {
    location = location.replaceFirst("file:///", "");
  } else {
    location = location.replaceFirst("file://", "");
  }
  if (!isNewFlutter)
    location = location.replaceFirst("/bin/unzip_zoom_sdk.dart", "");

  await checkAndDownloadSDK(location);
  print('Complete');
}

Future<void> checkAndDownloadSDK(String location) async {
  // ── Android ────────────────────────────────────────────────────────────────
  // Zoom SDK 6.3.0 for Android is now on Maven Central.
  // Gradle downloads it automatically — no manual download needed here.
  print('[Android] Using Zoom Meeting SDK 6.3.0 via Maven Central (no download needed).');

  // ── iOS ────────────────────────────────────────────────────────────────────
  // iOS MobileRTC.xcframework is NOT on CocoaPods for this Flutter plugin.
  // We continue downloading from the hosted S3 location.

  if (!Platform.isLinux) {
    // Skip iOS download on Linux CI (Android-only runners)
    var iosSDKFile = location +
        '/ios/MobileRTC.xcframework/ios-arm64/MobileRTC.framework/MobileRTC';
    bool exists = await File(iosSDKFile).exists();

    if (!exists) {
      await downloadFile(
          Uri.parse(
              'https://com21-static.s3.sa-east-1.amazonaws.com/zoom/ios/5.17.11/ios-arm64/MobileRTC?dl=1'),
          iosSDKFile);
    } else {
      print('[iOS] arm64 MobileRTC already present, skipping download.');
    }

    var iosSimulateSDKFile = location +
        '/ios/MobileRTC.xcframework/ios-arm64_x86_64-simulator/MobileRTC.framework/MobileRTC';
    exists = await File(iosSimulateSDKFile).exists();

    if (!exists) {
      await downloadFile(
          Uri.parse(
              'https://com21-static.s3.sa-east-1.amazonaws.com/zoom/ios/5.17.11/ios-arm64_x86_64-simulator/MobileRTC'),
          iosSimulateSDKFile);
    } else {
      print('[iOS] simulator MobileRTC already present, skipping download.');
    }
  } else {
    print('[iOS] Skipping iOS download on Linux runner.');
  }
}

Future<void> downloadFile(Uri uri, String savePath) async {
  print('Downloading ${uri.toString()} → $savePath');
  File destinationFile = await File(savePath).create(recursive: true);
  final request = await HttpClient().getUrl(uri);
  final response = await request.close();
  await response.pipe(destinationFile.openWrite());
}
