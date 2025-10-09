import 'package:flutter/material.dart';
import 'package:konfipass/models/konfipass_pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UserCreateDialog extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final String profileImageUrl;
  final String uuid;

  const UserCreateDialog({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.uuid,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    KonfipassPdf konfipassPdf = new KonfipassPdf(firstName: firstName, lastName: lastName, username: username, password: password, uuid: uuid);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 300, maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$firstName $lastName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Username: $username'),
                        Text('Password: $password'),
                      ],
                    ),
                  ),
                  QrImageView(data: uuid, version: QrVersions.auto, size: 100),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => konfipassPdf.downloadPdfWeb(context),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Als PDF herunterladen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
