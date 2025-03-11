import 'dart:io';

void main() {
  final configPath = 'config/config.properties';
  final properties = readProperties(configPath);
  final packageName = properties['flutter.namespace'];
  final buildName = properties['flutter.versionName'];
  final buildNumber = properties['flutter.versionCode'];
  final appLabel = properties['flutter.label'];
  final apiMap = properties['flutter.apiMap'];
  if (packageName == null ||
      buildName == null ||
      buildNumber == null ||
      appLabel == null) {
    throw Exception('Required properties are missing in the config file.');
  }

  updateMainActivity(packageName);
  updateAppInfoXcconfig(packageName, buildName, buildNumber, appLabel);
  if (apiMap != null && apiMap.isNotEmpty) {
    updateAppDelegate(apiMap);
  }
  updatePubspecYaml(buildName, buildNumber);
  stdout.write('Properties read from config file: $properties');
}

Map<String, String> readProperties(String filePath) {
  final properties = <String, String>{};
  final file = File(filePath);
  if (!file.existsSync()) {
    throw FileNotFoundException('Config file not found: $filePath');
  }
  final lines = file.readAsLinesSync();
  for (var line in lines) {
    if (line.contains('=')) {
      final parts = line.split('=');
      properties[parts[0].trim()] = parts[1].trim();
    }
  }
  return properties;
}

void updateMainActivity(String packageName) {
  final mainActivityPath =
      'android/app/src/main/kotlin/com/enerren/MainActivity.kt';
  final file = File(mainActivityPath);
  if (!file.existsSync()) {
    throw FileNotFoundException(
      'MainActivity.kt file not found: $mainActivityPath',
    );
  }
  var content = file.readAsStringSync();
  content = content.replaceAll(
    RegExp(r'package\s+[\w.]+'),
    'package $packageName',
  );
  file.writeAsStringSync(content);
}

// void updateInfoPlist(
//     String bundleIdentifier, String buildName, String buildNumber) {
//   final plistPath = 'ios/Runner/Info.plist';
//   final file = File(plistPath);
//   if (!file.existsSync()) {
//     throw FileNotFoundException('Info.plist file not found: $plistPath');
//   }
//   var content = file.readAsStringSync();
//   content = content.replaceAllMapped(
//       RegExp(r'<key>CFBundleIdentifier</key>\s*<string>.*?</string>'),
//       (match) =>
//           '<key>CFBundleIdentifier</key>\n\t<string>$bundleIdentifier</string>');
//   content = content.replaceAllMapped(
//       RegExp(r'<key>CFBundleShortVersionString</key>\s*<string>.*?</string>'),
//       (match) =>
//           '<key>CFBundleShortVersionString</key>\n\t<string>$buildName</string>');
//   content = content.replaceAllMapped(
//       RegExp(r'<key>CFBundleVersion</key>\s*<string>.*?</string>'),
//       (match) => '<key>CFBundleVersion</key>\n\t<string>$buildNumber</string>');
//   file.writeAsStringSync(content);
// }

void updateAppInfoXcconfig(
  String bundleIdentifier,
  String buildName,
  String buildNumber,
  String appName,
) {
  final pbxprojPath = 'ios/Runner.xcodeproj/project.pbxproj';
  final file = File(pbxprojPath);
  if (!file.existsSync()) {
    throw FileNotFoundException('project.pbxproj file not found: $pbxprojPath');
  }
  var content = file.readAsStringSync();
  content = content.replaceAllMapped(
    RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([\w.]+\.RunnerTests);'),
    (match) => 'PRODUCT_BUNDLE_IDENTIFIER = $bundleIdentifier.RunnerTests;',
  );

  content = content.replaceAllMapped(
    RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([\w.]+);'),
    (match) => 'PRODUCT_BUNDLE_IDENTIFIER = $bundleIdentifier;',
  );

  content = content.replaceAllMapped(
    RegExp(r'MARKETING_VERSION\s*=\s*[\d.]+;'),
    (match) => 'MARKETING_VERSION = $buildName;',
  );
  content = content.replaceAllMapped(
    RegExp(r'CURRENT_PROJECT_VERSION\s*=\s*\d+;'),
    (match) => 'CURRENT_PROJECT_VERSION = $buildNumber;',
  );
  content = content.replaceAllMapped(
    RegExp(r'PRODUCT_NAME\s*=\s*.*?;'),
    (match) => 'PRODUCT_NAME = $appName;',
  );
  file.writeAsStringSync(content);
}

void updateAppDelegate(String apiMap) {
  final appDelegatePath = 'ios/Runner/AppDelegate.swift';
  final file = File(appDelegatePath);
  if (!file.existsSync()) {
    throw FileNotFoundException(
      'AppDelegate.swift file not found: $appDelegatePath',
    );
  }
  var content = file.readAsStringSync();
  if (content.contains('GMSServices.provideAPIKey')) {
    content = content.replaceAll(
      RegExp(r'GMSServices.provideAPIKey\(".*?"\)'),
      'GMSServices.provideAPIKey("$apiMap")',
    );
  } else {
    content = content.replaceFirst(
      'GeneratedPluginRegistrant.register(with: self)',
      'GMSServices.provideAPIKey("$apiMap")\n    GeneratedPluginRegistrant.register(with: self)',
    );
    if (!content.contains('import GoogleMaps')) {
      content = content.replaceFirst(
        'import UIKit',
        'import UIKit\nimport GoogleMaps',
      );
    }
  }
  file.writeAsStringSync(content);
}

void updatePubspecYaml(String buildName, String buildNumber) {
  final pubspecPath = 'pubspec.yaml';
  final file = File(pubspecPath);
  if (!file.existsSync()) {
    throw FileNotFoundException('pubspec.yaml file not found: $pubspecPath');
  }
  var content = file.readAsStringSync();
  content = content.replaceAllMapped(
    RegExp(r'version:\s*\d+\.\d+\.\d+\+\d+'),
    (match) => 'version: $buildName+$buildNumber',
  );
  file.writeAsStringSync(content);
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => 'FileNotFoundException: $message';
}
