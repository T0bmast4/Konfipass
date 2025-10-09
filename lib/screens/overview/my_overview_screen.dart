import 'package:flutter/material.dart';
import 'package:konfipass/models/user.dart';
import 'package:konfipass/models/user_event.dart';
import 'package:konfipass/models/event_status.dart';
import 'package:konfipass/providers/auth_provider.dart';
import 'package:konfipass/services/event_service.dart';
import 'package:provider/provider.dart';

class MyOverviewScreen extends StatefulWidget {
  final User? user;

  const MyOverviewScreen({Key? key, this.user}) : super(key: key);

  @override
  State<MyOverviewScreen> createState() => _MyOverviewScreenState();
}

class _MyOverviewScreenState extends State<MyOverviewScreen> {
  late EventService eventService;
  late AuthProvider authProvider;

  bool isLoading = true;
  List<UserEvent> events = [];

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    eventService = context.read<EventService>();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      List<UserEvent> result;

      if (widget.user == null) {
        result = await eventService.getAllEventsWithStatus();
      } else {
        result = [];
        result = await eventService.getAllEventsWithStatus(userId: widget.user!.id);
      }

      setState(() {
        events = result.where((e) =>
        e.status == EventStatus.attended || e.status == EventStatus.absent).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Fehler beim Laden der Daten: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = events.length;
    final attended = events.where((e) => e.status == EventStatus.attended).length;
    final absent = events.where((e) => e.status == EventStatus.absent).length;
    final attendanceRate = total == 0 ? 0 : (attended / total * 100).round();

    final isAdminView = widget.user != null;
    final userName = isAdminView
        ? '${widget.user!.firstName} ${widget.user!.lastName}'
        : authProvider.user?.firstName ?? 'Meine Übersicht';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdminView ? 'Übersicht von $userName' : 'Meine Übersicht'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatsCard(total, attended, absent, attendanceRate),
            const SizedBox(height: 20),
            ...events.map(_buildEventTile).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(int total, int attended, int absent, int rate) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Übersicht', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('Gesamt', total.toString(), Colors.blue),
                _buildStatBox('Anwesend', attended.toString(), Colors.green),
                _buildStatBox('Gefehlt', absent.toString(), Colors.red),
                _buildStatBox('Quote', '$rate%', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }

  Widget _buildEventTile(UserEvent event) {
    IconData icon;
    Color color;
    String statusText;

    switch (event.status) {
      case EventStatus.attended:
        icon = Icons.check_circle;
        color = Colors.green;
        statusText = 'Anwesend';
        break;
      case EventStatus.absent:
        icon = Icons.cancel;
        color = Colors.red;
        statusText = 'Gefehlt';
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.orange;
        statusText = 'Offen';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(event.title),
        subtitle: Text(
          '${event.startDate.day}.${event.startDate.month}.${event.startDate.year} '
              '(${event.startTime.format(context)} - ${event.endTime.format(context)})',
        ),
        trailing: Text(
          statusText,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
