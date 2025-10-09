import 'package:flutter/material.dart';
import 'package:konfipass/models/event_args.dart';
import 'package:konfipass/models/event_status.dart';
import 'package:konfipass/models/user.dart';
import 'package:konfipass/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EventCard extends StatelessWidget {
  final int id;
  final String weekday;
  final String dayFrom;
  final String dayTo;
  final String month;
  final String timeFrom;
  final String timeTo;
  final String title;
  final String description;
  final int daysRemaining;
  final EventStatus status;

  const EventCard({
    super.key,
    required this.id,
    required this.weekday,
    required this.dayFrom,
    required this.dayTo,
    required this.month,
    required this.timeFrom,
    required this.timeTo,
    required this.title,
    required this.description,
    required this.daysRemaining,
    required this.status,
  });

  String _clipText(String text, [int maxLength = 24]) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final statusColor = {
      EventStatus.attended: Colors.green,
      EventStatus.absent: Colors.red,
      EventStatus.pending: Colors.grey,
    }[status]!;

    final daysText = daysRemaining == 0
        ? 'Heute'
        : daysRemaining == 1
        ? 'Morgen'
        : daysRemaining > 1
        ? 'In $daysRemaining Tagen'
        : 'Vor ${-daysRemaining} Tagen';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          if(authProvider.user!.role == UserRole.admin) {
            Navigator.of(context).pushNamed(
              '/eventDetail',
              arguments: EventArgs(
                id: id,
                title: title,
                description: description,
                weekday: weekday,
                dayFrom: dayFrom,
                dayTo: dayTo,
                month: month,
                timeFrom: timeFrom,
                timeTo: timeTo,
                status: status,
              ),
            );
          }
        },
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT: Date
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekday,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          dayFrom,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          month,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),

                    SizedBox(
                      height: 74,
                      child: VerticalDivider(
                        color: statusColor,
                        thickness: 4,
                        width: 16,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // RIGHT: Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            _clipText(title),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(height: 4),

                          // Description
                          Text(
                            _clipText(description),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 14),
                          ),
                          const SizedBox(height: 8),

                          // Time + Days + Status
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey.shade700),
                              const SizedBox(width: 4),
                              Text('$timeFrom – $timeTo',
                                  style:
                                  TextStyle(color: Colors.grey.shade800)),

                              const SizedBox(width: 16),
                              if (MediaQuery.of(context).size.width > 455) ...[
                                Icon(Icons.hourglass_bottom,
                                    size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  daysText,
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              ],

                              const Spacer(),

                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  border:
                                  Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
