import 'package:http/http.dart' as http;
import 'package:konfipass/models/user.dart';
import 'package:konfipass/providers/auth_provider.dart';
import 'dart:convert';
import 'dart:html' as html;

class UserService {
  final String baseUrl;
  final AuthProvider authProvider;

  UserService({required this.baseUrl, required this.authProvider});

  Future<Map<String, dynamic>?> createUserWithFile(
      String vorname,
      String nachname,
      UserRole role,
      html.File? file,
      ) async {
    final uri = Uri.parse('$baseUrl/create');
    var request = http.MultipartRequest('POST', uri);

    request.fields['vorname'] = vorname;
    request.fields['nachname'] = nachname;
    request.fields['roleId'] = role.id.toString();

    if (authProvider.jwtToken != null) {
      request.headers['Authorization'] = 'Bearer ${authProvider.jwtToken}';
    }

    if (file != null) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as List<int>;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ));
    }

    final response = await request.send();

    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(respStr) as Map<String, dynamic>;
      print("User erfolgreich erstellt: $data");
      return data;
    } else {
      print("Fehler: ${response.statusCode}");
      print(respStr);
      return null;
    }
  }

  Future<User?> getUserFromUuid(String uuid) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/uuid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.jwtToken}'
        },
        body: jsonEncode({"uuid": uuid}),
      );

      if (res.statusCode == 200) {
        if (res.body.isEmpty) return null;

        final data = jsonDecode(res.body);
        if (data is Map<String, dynamic>) {
          return User.fromJson(data);
        } else {
          return null;
        }
      } else {
        print('Server returned status ${res.statusCode}');
        return null;
      }
    } catch (e) {
      print('Fehler beim Laden des Users: $e');
      return null;
    }
  }

  Future<List<User>> getUsers({required int page, required int limit, String? search}) async {
    final uri = Uri.parse(
      '$baseUrl/users?page=$page&limit=$limit${search != null && search.isNotEmpty ? "&search=$search" : ""}',
    );

    final headers = <String, String>{};
    if (authProvider.jwtToken != null) {
      headers['Authorization'] = 'Bearer ${authProvider.jwtToken}';
    }

    final res = await http.get(uri, headers: headers);

    if (res.statusCode != 200) {
      throw Exception("Fehler beim Abrufen der Benutzer: ${res.statusCode}");
    }

    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => User.fromJson(e)).toList();
  }

  Future<bool> resetPassword(int userId, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/resetPassword'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${authProvider.jwtToken}'},
      body: jsonEncode({"userId": userId, "password": newPassword}),
    );
    if (res.statusCode != 200) {
      throw Exception("Fehler beim Zurücksetzen des Passworts: ${res.statusCode}");
    }
    return true;
  }

  Future<bool> removeUser(int userId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/remove'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${authProvider.jwtToken}'},
      body: jsonEncode({"userId": userId}),
    );
    if (res.statusCode != 200) {
      throw Exception("Fehler beim Löschen des Benutzers: ${res.statusCode}");
    }
    return true;
  }
}
