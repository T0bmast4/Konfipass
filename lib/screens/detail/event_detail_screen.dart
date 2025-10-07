import 'package:flutter/material.dart';
import 'package:konfipass/designables/qr_scanner_dialog.dart';
import 'package:konfipass/models/event_status.dart';
import 'package:konfipass/models/user.dart';
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
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  List<User> attendees = [];
  List<User> absents = [];

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Termin Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Titel + Beschreibung
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
            FilledButton(
              onPressed: scanQrCode,
              child: const Text('Anwesenheit kontrollieren'),
            ),

            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Anwesende:",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent),
              ),
            ),
            const SizedBox(height: 8),
            ...attendees.map((user) => ListTile(
              leading: MouseRegion(
                cursor: user.profileImgPath != null
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: GestureDetector(
                  onTap: () {
                    if (user.profileImgPath != null) {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          child: InteractiveViewer(
                            child: Image.network(user.profileImgPath!),
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.purple.shade200,
                    backgroundImage: user.profileImgPath != null
                        ? NetworkImage(user.profileImgPath!)
                        : null,
                    child: user.profileImgPath == null
                        ? Text(
                      "${user.firstName[0].toUpperCase()}${user.lastName.isNotEmpty ? user.lastName[0].toUpperCase() : ''}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : null,
                  ),
                ),
              ),
              title: Text("${user.firstName} ${user.lastName}"),
            )),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Abwesende:",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
              ),
            ),
            const SizedBox(height: 8),
            ...absents.map((e) => ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey.shade400,
                backgroundImage: (e.profileImgPath != null && e.profileImgPath!.isNotEmpty)
                    ? NetworkImage(e.profileImgPath!)
                    : null,
                child: (e.profileImgPath == null || e.profileImgPath!.isEmpty)
                    ? Text(
                  "${e.firstName[0].toUpperCase()}${e.lastName.isNotEmpty ? e.lastName[0].toUpperCase() : ''}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              title: Text("${e.firstName} ${e.lastName}"),
            )),
          ],
        ),
      ),
    );
  }
}
