import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:konfipass/models/konfipass_pdf.dart';
import 'package:konfipass/models/user.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UserQrDialog extends StatelessWidget {
  final User user;
  final bool pdfDownload;
  const UserQrDialog({super.key, required this.user, required this.pdfDownload});

  @override
  Widget build(BuildContext context) {
    KonfipassPdf konfipassPdf = new KonfipassPdf(firstName: user.firstName, lastName: user.lastName, username: user.username, password: "!! nicht verfügbar !!", uuid: user.uuid);
    return AlertDialog(
      title: Text("QR Code für ${user.username}"),
      content: SizedBox(
        width: 200,
        height: 200,
        child: Center(
          child: QrImageView(data: user.uuid, version: QrVersions.auto),
        ),
      ),
      actions: [
        if(pdfDownload) ... [
          ElevatedButton.icon(
            onPressed: () => konfipassPdf.downloadPdfWeb(
              Navigator.of(context, rootNavigator: true).context,
            ),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Als PDF herunterladen'),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Schließen"),
        ),
      ],
    );
  }
}
