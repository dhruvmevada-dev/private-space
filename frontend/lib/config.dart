import 'package:flutter/widgets.dart';

/// Single place to switch environments.
///
/// Default is the Android emulator's alias for the host machine.
/// Override at build/run time without editing code:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
///   flutter build apk --release --dart-define=API_BASE_URL=https://your-app.onrender.com
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',
);

const int maxMessageLength = 2000;

/// Lets services (e.g. on session expiry) navigate without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// https://private-space-tri4.onrender.com