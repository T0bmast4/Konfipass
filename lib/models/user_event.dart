import 'package:flutter/material.dart';
import 'package:konfipass/models/event_status.dart';

class UserEvent {
  final int id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final EventStatus status;

  UserEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  static TimeOfDay _timeOfDayFromDateTime(DateTime dt) {
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  factory UserEvent.fromJson(Map<String, dynamic> json) {
    EventStatus status;

    switch (json['status']) {
      case 'pending':
        status = EventStatus.pending;
        break;
      case 'attended':
        status = EventStatus.attended;
        break;
      case 'absent':
        status = EventStatus.absent;
        break;
      default:
        status = EventStatus.pending;
    }

    final startDateTime = DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now();
    final endDateTime = DateTime.tryParse(json['endTime'].toString()) ?? DateTime.now();

    return UserEvent(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      startDate: DateTime(startDateTime.year, startDateTime.month, startDateTime.day),
      endDate: DateTime(endDateTime.year, endDateTime.month, endDateTime.day),
      startTime: _timeOfDayFromDateTime(startDateTime),
      endTime: _timeOfDayFromDateTime(endDateTime),
      status: status,
    );
  }
}
