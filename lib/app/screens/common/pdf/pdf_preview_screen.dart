import 'dart:async';
import 'dart:typed_data';

import 'package:clicknow_version2/app/services/pdf/pdf_file_service.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({
    super.key,
    required this.title,
    required this.fileName,
    required this.buildPdf,
  });

  final String title;
  final String fileName;
  final FutureOr<Uint8List> Function() buildPdf;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Future<Uint8List>? _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = Future<Uint8List>.value(widget.buildPdf());
  }

  Future<Uint8List> _bytes() {
    return _bytesFuture ??= Future<Uint8List>.value(widget.buildPdf());
  }

  Future<void> _save() async {
    try {
      final file = await PdfFileService.savePdf(
        bytes: await _bytes(),
        fileName: widget.fileName,
      );
      AppSnackbar.success('PDF Saved', 'Saved to ${file.path}');
    } catch (_) {
      AppSnackbar.error('Unable to Save', 'Unable to save PDF.');
    }
  }

  Future<void> _share() async {
    try {
      final file = await PdfFileService.savePdf(
        bytes: await _bytes(),
        fileName: widget.fileName,
      );
      await PdfFileService.sharePdf(file, subject: widget.title);
    } catch (_) {
      AppSnackbar.error('Unable to Share', 'Unable to share PDF.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: const Icon(Icons.download_rounded),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: _share,
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfFileName: widget.fileName,
        build: (_) async => _bytes(),
      ),
    );
  }
}
