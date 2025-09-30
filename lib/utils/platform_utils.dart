import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;

class PlatformUtils {
  /// Returns true if running on web platform
  static bool get isWeb => kIsWeb;

  /// Returns true if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Returns true if running on Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Returns true if running on iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Downloads a file for web platform
  static Future<void> downloadFileForWeb({
    required String url,
    required String fileName,
  }) async {
    if (!isWeb) {
      throw UnsupportedError('This method is only supported on web platform');
    }

    try {
      // Create an anchor element and trigger download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..setAttribute('target', '_blank');
      
      // Add to document, click, and remove
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  /// Gets user agent string for web platform
  static String? getUserAgent() {
    if (!isWeb) return null;
    return html.window.navigator.userAgent;
  }

  /// Checks if the web browser supports PWA installation
  static bool canInstallPWA() {
    if (!isWeb) return false;
    
    try {
      return html.window.navigator.serviceWorker != null;
    } catch (e) {
      return false;
    }
  }
}