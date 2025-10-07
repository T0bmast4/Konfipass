import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:konfipass/models/constants.dart';
import 'package:konfipass/models/user.dart';
import 'dart:html' as html;

class AuthProvider extends ChangeNotifier {
  String _username = "";
  String get username => _username;
  String usernameInput = "";
  String passwordInput = "";

  late UserRole _userRole;
  UserRole get userRole => _userRole;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? _jwtToken;
  String? get jwtToken => _jwtToken;

  /// Login und JWT speichern
  Future<bool> login() async {
    final result = await http.post(
      Uri.parse('$serverUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': usernameInput, 'password': passwordInput}),
    );

    if(result.statusCode == 200) {
      final data = jsonDecode(result.body);
      _jwtToken = data['token'];
      html.window.localStorage['jwt'] = _jwtToken!;

      _isLoggedIn = true;
      _username = usernameInput;
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Prüfen, ob bereits eingeloggt (Token validieren)
  Future<bool> checkLoginStatus() async {
    _jwtToken ??= html.window.localStorage['jwt'];
    if(_jwtToken == null) return false;

    final response = await http.get(
      Uri.parse('$serverUrl/auth/me'),
      headers: {'Authorization': 'Bearer $_jwtToken'},
    );

    if(response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _username = data['username'];
      _userRole = UserRole.fromId(data['role']);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    _jwtToken = null;
    _isLoggedIn = false;
    return false;
  }

  /// Logout
  Future<void> logout() async {
    _jwtToken = null;
    html.window.localStorage['jwt'] = "";
    _isLoggedIn = false;
    _username = "";
    _userRole = UserRole.user;
    notifyListeners();
  }
}
