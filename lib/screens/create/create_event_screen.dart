import 'package:flutter/material.dart';
import 'package:konfipass/models/event.dart';
import 'package:konfipass/services/event_service.dart';
import 'package:provider/provider.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  String title = '';
  String description = '';

  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  Future<void> pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      locale: const Locale('de', 'DE')
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

  void submit() {
    if (_formKey.currentState!.validate()) {
      if (startDate == null || endDate == null || startTime == null || endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bitte alle Datums- und Zeitfelder ausfüllen')),
        );
        return;
      }

      context.read<EventService>().createEvent(title, description, startDate!, endDate!, startTime!, endTime!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event erstellt!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Termin erstellen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Titel
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => title = val,
                validator: (val) =>
                val == null || val.isEmpty ? 'Bitte Titel eingeben' : null,
              ),
              const SizedBox(height: 16),

              // Beschreibung
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Beschreibung',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (val) => description = val,
              ),
              const SizedBox(height: 16),

              // Von-Datum
              ListTile(
                title: Text(startDate == null
                    ? 'Startdatum auswählen'
                    : 'Von: ${startDate!.day}.${startDate!.month}.${startDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickStartDate,
              ),

              // Bis-Datum
              ListTile(
                title: Text(endDate == null
                    ? 'Enddatum auswählen'
                    : 'Bis: ${endDate!.day}.${endDate!.month}.${endDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: pickEndDate,
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

              // Endzeit
              ListTile(
                title: Text(endTime == null
                    ? 'Endzeit auswählen'
                    : 'Bis: ${endTime!.format(context)}'),
                trailing: const Icon(Icons.access_time),
                onTap: pickEndTime,
              ),

              const SizedBox(height: 32),

              // Button zum Erstellen
              FilledButton(
                onPressed: submit,
                child: const Text('Termin erstellen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
