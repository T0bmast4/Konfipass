import 'package:flutter/material.dart';
import 'package:konfipass/designables/event_card.dart';
import 'package:konfipass/designables/user_qr_dialog.dart';
import 'package:konfipass/models/event_status.dart';
import 'package:konfipass/models/user.dart';
import 'package:konfipass/models/user_event.dart';
import 'package:konfipass/providers/auth_provider.dart';
import 'package:konfipass/screens/create/create_event_screen.dart';
import 'package:konfipass/services/event_service.dart';
import 'package:provider/provider.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  late EventService eventService;
  late AuthProvider authProvider;

  final List<String> categories = [
    "Anstehend",
    "Alle",
    "Anwesend",
    "Abwesend",
  ];

  String selectedCategory = "Anstehend";

  final List<UserEvent> allEvents = [];

  List<UserEvent> get filteredEvents {
    switch (selectedCategory) {
      case "Anwesend":
        return allEvents.where((e) => e.status == EventStatus.attended).toList();
      case "Abwesend":
        return allEvents.where((e) => e.status == EventStatus.absent).toList();
      case "Anstehend":
        return allEvents.where((e) => e.status == EventStatus.pending).toList();
      default:
        return allEvents;
    }
  }

  Future<void> loadEvents() async {
    final events = await eventService.getAllEventsWithStatus();
    setState(() {
      allEvents.clear();
      allEvents.addAll(events);
    });
  }

  @override
  void initState() {
    super.initState();
    eventService = context.read<EventService>();
    authProvider = context.read<AuthProvider>();
    loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final months = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Termine"),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: screenWidth * 0.7,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 120,
                  physics: const FixedExtentScrollPhysics(),
                  diameterRatio: 20.0,
                  perspective: 0.003,
                  childDelegate: ListWheelChildListDelegate(
                    children: filteredEvents.map((event) {
                      final eventDate = DateTime(event.startDate.year, event.startDate.month, event.startDate.day);
                      final daysRemaining = eventDate.difference(todayDate).inDays;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: EventCard(
                          id: event.id,
                          weekday: weekdays[event.startDate.weekday - 1],
                          dayFrom: event.startDate.day.toString(),
                          dayTo: event.endDate.day.toString(),
                          month: months[event.startDate.month - 1],
                          timeFrom: "${event.startTime.hour.toString().padLeft(2, "0")}:${event.startTime.minute.toString().padLeft(2, "0")}",
                          timeTo: "${event.endTime.hour.toString().padLeft(2, "0")}:${event.endTime.minute.toString().padLeft(2, "0")}",
                          title: event.title,
                          description: event.description,
                          daysRemaining: daysRemaining,
                          status: event.status,
                          year: event.startDate.year,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: authProvider.user?.role == UserRole.admin ? FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventScreen()));
        },
        label: const Text("Neuer Termin"),
        icon: const Icon(Icons.add),
      )
      // USER Floating Action Button
      : FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => UserQrDialog(user: authProvider.user!, pdfDownload: false),
          );
        },
        label: const Text("Mein QR-Code"),
        icon: const Icon(Icons.qr_code_2),
      ),
    );
  }
}
