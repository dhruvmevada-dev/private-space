import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  // Generous timeout: Render's free tier can take ~30s to wake from sleep.
  static const Duration _timeout = Duration(seconds: 40);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthService.instance.token;
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    http.Response res;
    try {
      final encoded = body == null ? null : jsonEncode(body);
      switch (method) {
        case 'POST':
          res = await http.post(uri, headers: headers, body: encoded).timeout(_timeout);
          break;
        case 'PUT':
          res = await http.put(uri, headers: headers, body: encoded).timeout(_timeout);
          break;
        default:
          res = await http.get(uri, headers: headers).timeout(_timeout);
      }
    } on SocketException {
      throw const ApiException('No internet connection.\nPlease check your network and try again.');
    } on TimeoutException {
      throw const ApiException('The server is taking too long to respond.\nPlease try again.');
    } on http.ClientException {
      throw const ApiException('Could not reach the server.\nPlease try again later.');
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return null;
      return jsonDecode(utf8.decode(res.bodyBytes));
    }

    if (res.statusCode == 401 && auth) {
      await AuthService.instance.expireSession();
      throw const ApiException('Your session has expired.\nPlease log in again.', 401);
    }
    if (res.statusCode >= 500) {
      throw ApiException('The server is unavailable.\nPlease try again later.', res.statusCode);
    }
    throw ApiException(_detail(res), res.statusCode);
  }

  String _detail(http.Response res) {
    try {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map && data['detail'] is String) return data['detail'] as String;
      if (data is Map && data['detail'] is List) {
        final first = (data['detail'] as List).firstOrNull;
        final msg = first is Map ? first['msg'] as String? : null;
        if (msg != null) return msg.replaceFirst('Value error, ', '');
        return 'Invalid input.';
      }
    } catch (_) {}
    return 'Something went wrong. Please try again.';
  }

  Future<List<User>> getUsers() async {
    final data = await _request('GET', '/users', auth: false) as List;
    return data.map((u) => User.fromJson(u as Map<String, dynamic>)).toList();
  }

  /// Returns the raw response: {access_token, user}.
  Future<Map<String, dynamic>> login(int userId, String pin) async {
    final data = await _request('POST', '/auth/login',
        body: {'user_id': userId, 'pin': pin}, auth: false);
    return data as Map<String, dynamic>;
  }

  Future<User> me() async =>
      User.fromJson(await _request('GET', '/auth/me') as Map<String, dynamic>);

  Future<void> changePin(String currentPin, String newPin) async {
    await _request('PUT', '/auth/change-pin',
        body: {'current_pin': currentPin, 'new_pin': newPin});
  }

  Future<List<Chat>> getChats() async {
    final data = await _request('GET', '/chats') as List;
    return data.map((c) => Chat.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<MessageThread> getThread(int userId, String direction) async {
    final data = await _request('GET', '/messages/$userId',
        query: {'direction': direction});
    return MessageThread.fromJson(data as Map<String, dynamic>);
  }

  Future<Message> sendMessage(int recipientId, String content) async {
    final data = await _request('POST', '/messages',
        body: {'recipient_id': recipientId, 'content': content});
    return Message.fromJson(data as Map<String, dynamic>);
  }
}
