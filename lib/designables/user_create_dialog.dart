import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;

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

  // QR-Code als PNG erzeugen
  Future<Uint8List> _generateQrCode(String data, {int size = 100}) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.Q,
    );
    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception("Ungültiger QR-Code");
    }
    final qrCode = qrValidationResult.qrCode!;
    final painter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    );
    final picData = await painter.toImageData(size.toDouble());
    return picData!.buffer.asUint8List();
  }

  Future<void> _downloadPdfWeb(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final frontData = await rootBundle.load('template_front.png');
      final backData = await rootBundle.load('template_back.png');
      final frontBytes = frontData.buffer.asUint8List();
      final backBytes = backData.buffer.asUint8List();

      final qrBytes = await _generateQrCode(uuid, size: 300);

      final worker = html.Worker('pdf_worker.js');
      final completer = Completer<Uint8List>();

      worker.onMessage.listen((event) {
        final pdfBytes = event.data as List<int>;
        completer.complete(Uint8List.fromList(pdfBytes));
        worker.terminate();
      });

      worker.postMessage({
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'password': password,
        'uuid': uuid,
        'frontImage': frontBytes,
        'backImage': backBytes,
        'qrImage': qrBytes,
      });

      final pdfBytes = await completer.future;

      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '$username-konfipass.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Erstellen des PDFs: $e')),
      );
    } finally {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => _downloadPdfWeb(context),
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
