import 'package:konfipass/models/event_status.dart';

class EventArgs {
  final int id;
  final String title;
  final String description;
  final String weekday;
  final String dayFrom;
  final String dayTo;
  final String month;
  final String timeFrom;
  final String timeTo;
  final int year;
  final EventStatus status;

  EventArgs({
    required this.id,
    required this.title,
    required this.description,
    required this.weekday,
    required this.dayFrom,
    required this.dayTo,
    required this.month,
    required this.timeFrom,
    required this.timeTo,
    required this.year,
    required this.status,
  });
}