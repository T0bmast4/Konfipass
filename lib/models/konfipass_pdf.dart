import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class KonfipassPdf {
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final String uuid;

  KonfipassPdf({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.uuid,
  });

  // 🔹 QR-Code als PNG erzeugen
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

  Future<void> downloadPdfWeb(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final frontData = await rootBundle.load('assets/template_front.png');
      final backData = await rootBundle.load('assets/template_back.png');
      final frontBytes = frontData.buffer.asUint8List();
      final backBytes = backData.buffer.asUint8List();

      final qrBytes = await _generateQrCode(uuid, size: 300);

      final worker = html.Worker('pdf_worker.js');
      final completer = Completer<Uint8List>();

      worker.onMessage.listen((event) {
        final pdfBytes = (event.data as List).cast<int>();
        completer.complete(Uint8List.fromList(pdfBytes));
        worker.terminate();
      });

      worker.onError.listen((event) {
        final errMsg = event.toString();
        completer.completeError("Fehler im Worker: $errMsg");
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

      // Browser-Download starten
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${username}_konfipass.pdf')
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
}
