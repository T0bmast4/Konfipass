import 'package:flutter/material.dart';

class Event {
  final int id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
  });

  static TimeOfDay _timeOfDayFromDateTime(DateTime dt) {
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  static DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    final startDateTime = DateTime.parse(json['start_datetime']);
    final endDateTime = DateTime.parse(json['end_datetime']);

    return Event(
      id: int.parse(json['id'].toString()),
      title: json['title'],
      description: json['description'],
      startDate: DateTime(startDateTime.year, startDateTime.month, startDateTime.day),
      endDate: DateTime(endDateTime.year, endDateTime.month, endDateTime.day),
      startTime: _timeOfDayFromDateTime(startDateTime),
      endTime: _timeOfDayFromDateTime(endDateTime),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_datetime': _combineDateAndTime(startDate, startTime).toIso8601String(),
      'end_datetime': _combineDateAndTime(endDate, endTime).toIso8601String(),
    };
  }
}
