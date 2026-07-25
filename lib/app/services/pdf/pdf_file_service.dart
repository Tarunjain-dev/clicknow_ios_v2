import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfFileService {
  PdfFileService._();

  static Future<File> savePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final pdfName = fileName.toLowerCase().endsWith('.pdf')
        ? fileName
        : '$fileName.pdf';
    final file = File('${directory.path}${Platform.pathSeparator}$pdfName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> sharePdf(
    File file, {
    String? subject,
    String? text,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path, mimeType: 'application/pdf')],
        subject: subject,
        text: text,
      ),
    );
  }

  static Future<void> openPdf(File file) async {
    await OpenFilex.open(file.path);
  }
}
