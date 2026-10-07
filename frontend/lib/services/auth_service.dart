import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config.dart';
import '../models/user.dart';
import '../screens/user_selection_screen.dart';
import 'api_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  User? currentUser;

  Future<String?> get token async => _token ??= await _storage.read(key: _tokenKey);

  Future<void> login(int userId, String pin) async {
    final data = await ApiService.instance.login(userId, pin);
    _token = data['access_token'] as String;
    await _storage.write(key: _tokenKey, value: _token);
    currentUser = User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// true  -> stored token is valid, go Home
  /// false -> no/invalid token, go to login
  /// throws ApiException on network/server problems (caller shows retry).
  Future<bool> restoreSession() async {
    final t = await token;
    if (t == null) return false;
    try {
      currentUser = await ApiService.instance.me();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) return false; // already cleared by expireSession()
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    await _storage.delete(key: _tokenKey);
  }

  /// Called by ApiService on any authenticated 401.
  Future<void> expireSession() async {
    await logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const UserSelectionScreen(
            notice: 'Your session has expired. Please log in again.'),
      ),
      (_) => false,
    );
  }
}
