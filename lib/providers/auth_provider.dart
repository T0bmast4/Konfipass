import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:konfipass/models/constants.dart';
import 'package:konfipass/models/user.dart';
import 'dart:html' as html;

class AuthProvider extends ChangeNotifier {
  User? _user;
  User? get user => _user;

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

  /// Login und JWT speichern (unverändert)
  Future<String?> login() async {
    try {
      final result = await http.post(
        Uri.parse('$serverUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': usernameInput, 'password': passwordInput}),
      );

      if (result.statusCode == 200) {
        final data = jsonDecode(result.body);
        _jwtToken = data['token'];
        html.window.localStorage['jwt'] = _jwtToken!;

        _isLoggedIn = true;
        _username = usernameInput;

        if (data.containsKey('id')) {
          _user = User.fromJson(data);
          _userRole = _user!.role;
        }

        notifyListeners();
        return null;
      }

      if (result.statusCode >= 400 && result.statusCode < 500) {
        try {
          final data = jsonDecode(result.body);
          final msg = data['error'] ?? "Benutzername oder Passwort falsch.";
          return msg;
        } catch (_) {
          return "Benutzername oder Passwort falsch.";
        }
      }

      return "Serverfehler (${result.statusCode}). Bitte später erneut versuchen.";

    } catch (e) {
      print("Login failed: $e");
      return "Server nicht erreichbar. Bitte Verbindung prüfen. Fehler: $e";
    }
  }

  /// Prüfen, ob bereits eingeloggt (Token validieren) und User direkt speichern
  Future<bool> checkLoginStatus() async {
    _jwtToken ??= html.window.localStorage['jwt'];
    if (_jwtToken == null) return false;

    final response = await http.get(
      Uri.parse('$serverUrl/auth/me'),
      headers: {'Authorization': 'Bearer $_jwtToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // User direkt aus den Serverdaten erstellen
      _user = User.fromJson(data);
      _username = _user!.username;
      _userRole = _user!.role;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }

    _jwtToken = null;
    _isLoggedIn = false;
    _user = null;
    return false;
  }

  /// Logout
  Future<void> logout() async {
    _jwtToken = null;
    html.window.localStorage.remove('jwt');
    _isLoggedIn = false;
    _username = "";
    _userRole = UserRole.user;
    _user = null;
    notifyListeners();
  }
}