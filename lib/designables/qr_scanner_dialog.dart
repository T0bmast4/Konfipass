import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web';

class QrScannerDialogContent extends StatefulWidget {
  final void Function(String result) onScanned;

  const QrScannerDialogContent({super.key, required this.onScanned});

  @override
  State<QrScannerDialogContent> createState() => _QrScannerDialogContentState();
}

class _QrScannerDialogContentState extends State<QrScannerDialogContent> {
  late html.VideoElement video;
  late html.CanvasElement canvas;
  late html.CanvasRenderingContext2D ctx;
  html.MediaStream? stream;
  bool _scanned = false;
  late final String viewType; // dynamischer viewType

  @override
  void initState() {
    super.initState();

    // dynamischen viewType erzeugen
    viewType = 'videoElementDialog_${DateTime.now().millisecondsSinceEpoch}';

    video = html.VideoElement()
      ..autoplay = true
      ..style.borderRadius = '12px'
      ..style.objectFit = 'cover';

    if (kIsWeb) {
      platformViewRegistry.registerViewFactory(
        viewType,
            (int viewId) => video,
      );
    }

    canvas = html.CanvasElement();
    ctx = canvas.getContext('2d') as html.CanvasRenderingContext2D;

    startCamera();
  }

  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }

  Future<void> startCamera() async {
    try {
      stream = await html.window.navigator.mediaDevices!
          .getUserMedia({'video': {'facingMode': 'environment'}});
      video.srcObject = stream;
      await video.play();

      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;

      // Nicht überall supported
      //if (js.context.hasProperty('BarcodeDetector')) {
        //detectWithBarcodeDetector();
      //} else {
        detectWithJsQR();
      //}
    } catch (e) {
      print('Fehler beim Zugriff auf die Kamera: $e');
    }
  }

  void stopCamera() {
    if (stream != null) {
      stream!.getTracks().forEach((t) => t.stop());
      stream = null;
    }
    video.pause();
    video.srcObject = null;
  }

  void detectWithBarcodeDetector() {
    void detect() async {
      if (stream == null || _scanned) return;

      var detector = js.JsObject(
          js.context['BarcodeDetector'],
          [js.JsObject.jsify({'formats': ['qr_code']})]
      );

      detector.callMethod('detect', [video]).then((barcodes) {
        if (!_scanned && barcodes.length > 0) {
          _scanned = true;
          stopCamera();
          widget.onScanned(barcodes[0]['rawValue']);
        } else if (!_scanned) {
          html.window.requestAnimationFrame((_) => detect());
        }
      }).catchError((e) {
        print('Fehler bei BarcodeDetector: $e');
      });
    }
    detect();
  }

  void detectWithJsQR() {
    void loop(num _) {
      if (stream == null || _scanned) return;

      ctx.drawImage(video, 0, 0);
      final imgData = ctx.getImageData(0, 0, canvas.width!, canvas.height!);
      var code = js.context.callMethod('jsQR', [imgData.data, imgData.width, imgData.height]);

      if (!_scanned && code != null) {
        _scanned = true;
        stopCamera();
        widget.onScanned(code['data']);
      } else if (!_scanned) {
        html.window.requestAnimationFrame(loop);
      }
    }
    html.window.requestAnimationFrame(loop);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 360,
      child: kIsWeb
          ? HtmlElementView(viewType: viewType)
          : const Center(child: Text('Nur Web unterstützt Video')),
    );
  }
}

