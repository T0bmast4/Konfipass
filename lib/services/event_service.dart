import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:konfipass/models/user.dart';
import 'package:konfipass/models/user_event.dart';
import 'package:konfipass/providers/auth_provider.dart';
import 'dart:convert';
import '../models/event.dart';

class EventService {
  final String baseUrl;
  final AuthProvider authProvider;

  EventService({required this.baseUrl, required this.authProvider});

  Future<List<Event>> getAllEvents() async {
    final res = await http.get(Uri.parse('$baseUrl/events'));
    final data = jsonDecode(res.body) as List;
    return data.map((e) => Event.fromJson(e)).toList();
  }

  Future<List<UserEvent>> getAllEventsWithStatus() async {
    final res = await http.post(
      Uri.parse('$baseUrl/eventsFromUser'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${authProvider.jwtToken}'
      },
    );

    if (res.statusCode != 200) {
      throw Exception("Fehler beim Laden der Events: ${res.body}");
    }

    final data = jsonDecode(res.body);

    if (data == null) return [];

    final eventsList = (data as List<dynamic>)
        .map((e) => UserEvent.fromJson(e as Map<String, dynamic>))
        .toList();

    return eventsList;
  }

  Future<List<User>> getAttendees(int eventId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendees'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${authProvider.jwtToken}'},
      body: jsonEncode({"eventId": eventId}),
    );
    final data = jsonDecode(res.body);
    if (data == null) return [];

    final attendeesList = (data as List<dynamic>)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();

    return attendeesList;
  }

  Future<List<User>> getAbsents(int eventId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/absents'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${authProvider.jwtToken}'},
      body: jsonEncode({"eventId": eventId}),
    );
    final data = jsonDecode(res.body);
    if (data == null) return [];

    final absentsList = (data as List<dynamic>)
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();

    return absentsList;
  }

  Future<bool> setAttended(int userId, int eventId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/setAttended'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${authProvider.jwtToken}'},
      body: jsonEncode({"userId": userId, "eventId": eventId}),
    );

    if (res.statusCode == 200) {
      return true;
    } else {
      throw Exception('Fehler Anwesenheit setzen: ${res.body}');
    }
  }

  Future<bool> createEvent(String title, String description, DateTime startDate, DateTime endDate, TimeOfDay startTime, TimeOfDay endTime) async {
    final startDateTime = _combineDateAndTime(startDate, startTime);
    final endDateTime = _combineDateAndTime(endDate, endTime);

    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${authProvider.jwtToken}'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'start_datetime': startDateTime.toIso8601String(),
        'end_datetime': endDateTime.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Event konnte nicht erstellt werden: ${response.body}');
    }
  }
  static DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

}
