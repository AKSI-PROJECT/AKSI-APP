import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'ml_service.dart';

class PDFGenerator {
  static Future<File?> redactAndGeneratePDF(
    String imagePath,
    List<RedactRegion> regions, [
    String? customFileName,
  ]) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return null;
      for (var region in regions.where((r) => r.isApplied)) {
        final x1 = region.rect.left.toInt().clamp(0, originalImage.width);
        final y1 = region.rect.top.toInt().clamp(0, originalImage.height);
        final x2 = region.rect.right.toInt().clamp(0, originalImage.width);
        final y2 = region.rect.bottom.toInt().clamp(0, originalImage.height);

        img.fillRect(
          originalImage,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: img.ColorRgb8(0, 0, 0),
        );
      }

      final redactedBytes = img.encodeJpg(originalImage, quality: 85);

      final pdf = pw.Document();
      final imagePdf = pw.MemoryImage(redactedBytes);

      final pageFormat = PdfPageFormat(
        originalImage.width.toDouble(),
        originalImage.height.toDouble(),
        marginAll: 0,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(imagePdf, fit: pw.BoxFit.contain));
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName =
          customFileName != null && customFileName.trim().isNotEmpty
          ? customFileName.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
          : 'AKSI_Redacted_$timestamp';
      final targetFile = File('${tempDir.path}/$safeName.pdf');

      await targetFile.writeAsBytes(await pdf.save());
      return targetFile;
    } catch (e) {
      debugPrint('Error generating PDF: $e');
      return null;
    }
  }
}
