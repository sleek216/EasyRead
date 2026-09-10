import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfExportService {
  /// Generates a cleanly formatted PDF document containing the article title,
  /// byline, and all paragraphs, and shares it via the native share dialog.
  static Future<bool> exportAndShareArticle({
    required String title,
    required String byline,
    required List<String> paragraphs,
  }) async {
    try {
      // 1. Create a new PDF document
      final PdfDocument document = PdfDocument();
      document.pageSettings.margins.left = 40;
      document.pageSettings.margins.right = 40;
      document.pageSettings.margins.top = 40;
      document.pageSettings.margins.bottom = 60; // 60pt dedicated bottom margin to prevent footer overlap
      document.pageSettings.size = PdfPageSize.a4;

      // Fonts & Brushes
      final titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20, style: PdfFontStyle.bold);
      final bylineFont = PdfStandardFont(PdfFontFamily.helvetica, 10, style: PdfFontStyle.italic);
      final bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 11);
      final inkBrush = PdfSolidBrush(PdfColor(22, 36, 29));
      final muteBrush = PdfSolidBrush(PdfColor(110, 115, 110));
      final linePen = PdfPen(PdfColor(210, 215, 210), width: 0.8);

      // Add first page
      PdfPage currentPage = document.pages.add();
      final pageSize = currentPage.getClientSize();
      double currentY = 0;

      // 2. Draw Article Title
      final titleElement = PdfTextElement(
        text: title.trim().isNotEmpty ? title.trim() : "Document",
        font: titleFont,
        brush: inkBrush,
      );
      final titleLayout = titleElement.draw(
        page: currentPage,
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, pageSize.height),
      );
      currentY = (titleLayout?.bounds.bottom ?? 0) + 8;

      // 3. Draw Byline / Author metadata (strip reading time "min read" / "min")
      final cleanAuthor = byline
          .replaceAll(RegExp(r'·?\s*\d+\s*(min|mins|minute|minutes)?\s*read\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'·?\s*\d+\s*(min|mins|minute|minutes)\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'^\s*·\s*|\s*·\s*$', caseSensitive: false), '')
          .trim();

      if (cleanAuthor.isNotEmpty) {
        final bylineElement = PdfTextElement(
          text: cleanAuthor,
          font: bylineFont,
          brush: muteBrush,
        );
        final bylineLayout = bylineElement.draw(
          page: currentPage,
          bounds: Rect.fromLTWH(0, currentY, pageSize.width, pageSize.height),
        );
        currentY = (bylineLayout?.bounds.bottom ?? 0) + 12;
      }

      // 4. Draw Divider Line
      currentPage.graphics.drawLine(
        linePen,
        Offset(0, currentY),
        Offset(pageSize.width, currentY),
      );
      currentY += 16;

      // 5. Draw Paragraphs with automatic multi-page pagination
      final fullBodyText = paragraphs.isNotEmpty
          ? paragraphs.join('\n\n')
          : "No content available.";

      final bodyFormat = PdfStringFormat(
        lineSpacing: 4,
        alignment: PdfTextAlignment.justify,
      );

      final bodyElement = PdfTextElement(
        text: fullBodyText,
        font: bodyFont,
        brush: inkBrush,
        format: bodyFormat,
      );

      final layoutFormat = PdfLayoutFormat(
        layoutType: PdfLayoutType.paginate,
      );

      bodyElement.draw(
        page: currentPage,
        bounds: Rect.fromLTWH(0, currentY, pageSize.width, pageSize.height - currentY),
        format: layoutFormat,
      );

      // 6. Add subtle footer to every page in the dedicated bottom margin
      final footerFont = PdfStandardFont(PdfFontFamily.helvetica, 9);
      final totalPages = document.pages.count;
      for (int i = 0; i < totalPages; i++) {
        final p = document.pages[i];
        final pSize = p.getClientSize();
        final footerText = "Page ${i + 1} of $totalPages · Exported from EasyRead";
        p.graphics.drawString(
          footerText,
          footerFont,
          brush: muteBrush,
          bounds: Rect.fromLTWH(0, pSize.height + 22, pSize.width, 16),
          format: PdfStringFormat(alignment: PdfTextAlignment.center),
        );
      }

      // 7. Save document to bytes
      final List<int> bytes = await document.save();
      document.dispose();

      // 8. Write to temporary storage
      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName = sanitizedTitle.isNotEmpty ? '$sanitizedTitle.pdf' : 'EasyRead_Article.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      // 9. Launch Native Share Sheet with the PDF file attached
      final xFile = XFile(file.path, mimeType: 'application/pdf', name: fileName);
      final result = await Share.shareXFiles(
        [xFile],
        subject: title,
        text: 'Sharing "$title" as a PDF from EasyRead.',
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }
}
