import 'package:flutter/material.dart';
import 'package:konfipass/designables/qr_scanner_dialog.dart';
import 'package:konfipass/designables/user_profile_img.dart';
import 'package:konfipass/models/event.dart';
import 'package:konfipass/models/event_status.dart';
import 'package:konfipass/models/user.dart';
import 'package:konfipass/screens/create/create_event_screen.dart';
import 'package:konfipass/services/event_service.dart';
import 'package:konfipass/services/user_service.dart';
import 'package:provider/provider.dart';

class EventDetailScreen extends StatefulWidget {
  final int id;
  final String title;
  final String description;
  final String weekday;
  final String dayFrom;
  final String dayTo;
  final String month;
  final String timeFrom;
  final String timeTo;
  final EventStatus status;
  final int year;

  const EventDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.weekday,
    required this.dayFrom,
    required this.dayTo,
    required this.month,
    required this.timeFrom,
    required this.timeTo,
    required this.status,
    required this.year,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<User> attendees = [];
  List<User> absents = [];
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    loadAttendees();
    loadAbsents();
  }

  Future<void> loadAttendees() async {
    final attendees = await context.read<EventService>().getAttendees(widget.id);
    setState(() => this.attendees.addAll(attendees));
  }

  Future<void> loadAbsents() async {
    final absents = await context.read<EventService>().getAbsents(widget.id);
    setState(() => this.absents.addAll(absents));
  }

  Future<void> scanQrCode() async {
    String? scannedResult;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            width: 400,
            height: 450,
            child: Column(
              children: [
                Expanded(child: QrScannerDialogContent(
                  onScanned: (result) {
                    scannedResult = result;
                    Navigator.pop(context);
                  },
                )),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Abbrechen'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (scannedResult != null) {
      final user = await context.read<UserService>().getUserFromUuid(scannedResult!);
      if(user == null) {
        showDialog(context: context, builder: (context) => AlertDialog(
          title: const Text('Fehler'),
          content: Text('Benutzer nicht gefunden! Bitte versuchen Sie es erneut!'),
        ));
        return;
      }


      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Anwesenheit bestätigen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 60, // größer für Dialog
                backgroundColor: Colors.purple.shade200,
                backgroundImage: user.profileImgPath != null
                    ? NetworkImage(user.profileImgPath!)
                    : null,
                child: user.profileImgPath == null
                    ? Text(
                  "${user.firstName[0].toUpperCase()}${user.lastName[0].toUpperCase()}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),

              const SizedBox(height: 16),

              Text(
                'Soll "${user.firstName} ${user.lastName}" als anwesend eingetragen werden?',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nein'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ja'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() {
          context.read<EventService>().setAttended(user.id, widget.id);
          attendees.add(user);
          absents.removeWhere((element) => element.id == user.id);
        });
      }
    }
  }

  int _monthNumber(String monthAbbr) {
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mär': 3,
      'Apr': 4,
      'Mai': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Okt': 10,
      'Nov': 11,
      'Dez': 12,
    };
    return months[monthAbbr] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Termin Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Bearbeiten',
            onPressed: () {
              final startDate = DateTime(
                widget.year,
                _monthNumber(widget.month),
                int.parse(widget.dayFrom),
                int.parse(widget.timeFrom.split(':')[0]),
                int.parse(widget.timeFrom.split(':')[1]),
              );

              final endDate = DateTime(
                widget.year,
                _monthNumber(widget.month),
                int.parse(widget.dayTo),
                int.parse(widget.timeTo.split(':')[0]),
                int.parse(widget.timeTo.split(':')[1]),
              );

              final startTime = TimeOfDay(
                hour: int.parse(widget.timeFrom.split(':')[0]),
                minute: int.parse(widget.timeFrom.split(':')[1]),
              );

              final endTime = TimeOfDay(
                hour: int.parse(widget.timeTo.split(':')[0]),
                minute: int.parse(widget.timeTo.split(':')[1]),
              );

              final event = Event(
                id: widget.id,
                title: widget.title,
                description: widget.description,
                startDate: startDate,
                endDate: endDate,
                startTime: startTime,
                endTime: endTime,
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateEventScreen(event: event),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  widget.dayFrom != widget.dayTo
                      ? "${widget.weekday}. ${widget.dayFrom}. ${widget.month}. ${widget.timeFrom} - ${widget.dayTo}. ${widget.month} - ${widget.timeTo}"
                      : "${widget.weekday}. ${widget.dayFrom}. ${widget.month} ${widget.timeFrom} - ${widget.timeTo}",
                )
              ],
            ),
            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              onPressed: scanQrCode,
              child: const Text('Anwesenheit kontrollieren'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Autocomplete<User>(
                    displayStringForOption: (user) => "${user.firstName} ${user.lastName}",
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) return [];
                      return await context.read<UserService>().getUsers(
                        search: textEditingValue.text,
                        limit: 5,
                      );
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: "Benutzer suchen",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Material(
                        child: ListView(
                          shrinkWrap: true,
                          children: options.map((user) {
                            return ListTile(
                              leading: UserProfileImg(user: user),
                              title: Text("${user.firstName} ${user.lastName}"),
                              onTap: () => onSelected(user),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    onSelected: (User user) {
                      setState(() {
                        _selectedUser = user;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                      ),
                      onPressed: _selectedUser != null
                          ? () async {
                        final user = _selectedUser!;
                        await context.read<EventService>().setAttended(user.id, widget.id);
                        setState(() {
                          attendees.add(user);
                          absents.removeWhere((a) => a.id == user.id);
                          _selectedUser = null;
                        });
                      }
                          : null,
                      child: const Text("Anwesend"),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _selectedUser != null  ? () async {
                        final user = _selectedUser!;
                        await context.read<EventService>().setAbsent(user.id, widget.id);
                        setState(() {
                          absents.add(user);
                          attendees.removeWhere((a) => a.id == user.id);
                          _selectedUser = null;
                        });
                      }
                          : null,
                      child: const Text("Abwesend"),
                    ),
                  ],
                )
              ],
            ),


            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Anwesende: (${attendees.length})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
              ),
            ),

            const SizedBox(height: 8),
            ...attendees.map((user) => ListTile(
              leading: UserProfileImg(user: user),
              title: Text("${user.firstName} ${user.lastName}"),
            )),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Abwesende: (${absents.length})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 8),
            ...absents.map((user) => ListTile(
              leading: UserProfileImg(user: user),
              title: Text("${user.firstName} ${user.lastName}"),
            )),
          ],
        ),
      ),
    );
  }
}
