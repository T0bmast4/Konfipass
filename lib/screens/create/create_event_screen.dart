import 'package:flutter/material.dart';
import 'package:konfipass/models/event.dart';
import 'package:konfipass/services/event_service.dart';
import 'package:provider/provider.dart';

class CreateEventScreen extends StatefulWidget {
  final Event? event; // Optionales Event zum Bearbeiten

  const CreateEventScreen({super.key, this.event});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  late String title;
  late String description;

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
  void initState() {
    super.initState();

    if (widget.event != null) {
      final e = widget.event!;
      title = e.title;
      description = e.description;
      startDate = e.startDate;
      endDate = e.endDate;
      startTime = TimeOfDay.fromDateTime(e.startDate);
      endTime = TimeOfDay.fromDateTime(e.endDate);
    } else {
      title = '';
      description = '';
    }
  }

  Future<void> pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('de', 'DE'),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        if (endDate != null && endDate!.isBefore(picked)) {
          endDate = picked;
        }
      });
    }
  }

  Future<void> pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? now,
      firstDate: startDate ?? now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('de', 'DE'),
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => startTime = picked);
    }
  }

  Future<void> pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime ?? startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => endTime = picked);
    }
  }

  Future<void> submit() async {
    setState(() => _submitted = true); // Erst jetzt Fehlermeldungen aktivieren

    if (_formKey.currentState!.validate()) {
      if (startDate == null || endDate == null || startTime == null || endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte alle Datums- und Zeitfelder ausfüllen')),
        );
        return;
      }

      final eventService = context.read<EventService>();

      if (widget.event != null) {
        // Bearbeiten
        await eventService.updateEvent(
          widget.event!.id,
          title,
          description,
          startDate!,
          endDate!,
          startTime!,
          endTime!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event aktualisiert!')),
        );
      } else {
        // Neu erstellen
        await eventService.createEvent(
          title,
          description,
          startDate!,
          endDate!,
          startTime!,
          endTime!,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event erstellt!')),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Termin bearbeiten' : 'Termin erstellen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Titel
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => title = val,
                validator: (val) => val == null || val.isEmpty ? 'Bitte Titel eingeben' : null,
              ),
              const SizedBox(height: 16),

              // Beschreibung
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (val) => description = val,
                validator: (val) => val == null || val.isEmpty ? 'Bitte Beschreibung eingeben' : null,
              ),
              const SizedBox(height: 16),

              // Startdatum
              ListTile(
                title: Text(startDate == null
                    ? 'Startdatum auswählen'
                    : 'Von: ${startDate!.day}.${startDate!.month}.${startDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickStartDate,
              ),
              if (_submitted && startDate == null)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('Bitte Startdatum auswählen', style: TextStyle(color: Colors.red)),
                ),

              // Enddatum
              ListTile(
                title: Text(endDate == null
                    ? 'Enddatum auswählen'
                    : 'Bis: ${endDate!.day}.${endDate!.month}.${endDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickEndDate,
              ),
              if (_submitted && endDate == null)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('Bitte Enddatum auswählen', style: TextStyle(color: Colors.red)),
                ),

              const Divider(),

              // Startzeit
              ListTile(
                title: Text(startTime == null
                    ? 'Startzeit auswählen'
                    : 'Von: ${startTime!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: pickStartTime,
              ),
              if (_submitted && startTime == null)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('Bitte Startzeit auswählen', style: TextStyle(color: Colors.red)),
                ),

              // Endzeit
              ListTile(
                title: Text(endTime == null
                    ? 'Endzeit auswählen'
                    : 'Bis: ${endTime!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: pickEndTime,
              ),
              if (_submitted && endTime == null)
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 4),
                  child: Text('Bitte Endzeit auswählen', style: TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 32),

              // Button
              FilledButton(
                onPressed: submit,
                child: Text(isEditing ? 'Änderungen speichern' : 'Termin erstellen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}