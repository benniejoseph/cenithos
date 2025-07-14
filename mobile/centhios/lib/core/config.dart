import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConfig {
  static const String _localIp = '192.168.29.82'; 
  static const String _localHttpProtocol = 'http://';
  static const String _localBackendPort = '5001';
  static const String _localAiPort = '8000';
  static const String _firebaseProjectId = 'cenithos';

  static String get backendBaseUrl {
    // For physical device testing with the local emulator
    return '${_localHttpProtocol}$_localIp:$_localBackendPort/$_firebaseProjectId/us-central1/api';
  }

  static String get aiBaseUrl {
    // For physical device testing, all platforms connect to the host's local IP.
    return '${_localHttpProtocol}$_localIp:$_localAiPort';
  }
}
