import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ParsedPdfResult {
  final String title;
  final List<String> paragraphs;
  final int pageCount;
  final int wordCount;

  ParsedPdfResult({
    required this.title,
    required this.paragraphs,
    required this.pageCount,
    required this.wordCount,
  });
}

class _PdfExtractArgs {
  final Uint8List bytes;
  final String title;
  _PdfExtractArgs(this.bytes, this.title);
}

class _PdfPathExtractArgs {
  final String path;
  final String title;
  _PdfPathExtractArgs(this.path, this.title);
}

class PdfReaderService {
  /// Extract clean, formatted paragraphs from a PDF file path completely in a background isolate
  static Future<ParsedPdfResult> extractFromPath(String filePath) async {
    try {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final cleanTitle = fileName
          .replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')
          .replaceAll(RegExp(r'[_-]'), ' ');

      return compute(_extractPathWorker, _PdfPathExtractArgs(filePath, cleanTitle.isNotEmpty ? cleanTitle : "Document"));
    } catch (e) {
      return ParsedPdfResult(
        title: "Document",
        paragraphs: ["Error loading document: $e"],
        pageCount: 1,
        wordCount: 0,
      );
    }
  }

  /// Worker to read disk bytes and parse in background isolate
  static ParsedPdfResult _extractPathWorker(_PdfPathExtractArgs args) {
    try {
      final file = File(args.path);
      if (!file.existsSync()) {
        return ParsedPdfResult(
          title: args.title,
          paragraphs: ["Could not find the document on disk."],
          pageCount: 1,
          wordCount: 0,
        );
      }
      final bytes = file.readAsBytesSync();
      return _extractWorker(_PdfExtractArgs(bytes, args.title));
    } catch (e) {
      return ParsedPdfResult(
        title: args.title,
        paragraphs: ["Error reading document file: $e"],
        pageCount: 1,
        wordCount: 0,
      );
    }
  }

  /// Extract clean, formatted paragraphs from raw PDF bytes in a background isolate
  static Future<ParsedPdfResult> extractFromBytes(Uint8List bytes, String title) async {
    return compute(_extractWorker, _PdfExtractArgs(bytes, title));
  }

  /// Background isolate worker to prevent freezing the main UI thread
  static ParsedPdfResult _extractWorker(_PdfExtractArgs args) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: args.bytes);
      final int pageCount = document.pages.count;

      final textExtractor = PdfTextExtractor(document);
      // Fast instant opening for first 15 pages (< 150ms)
      final int maxEndIndex = pageCount > 15 ? 14 : (pageCount - 1);
      final rawText = textExtractor.extractText(
        startPageIndex: 0,
        endPageIndex: maxEndIndex >= 0 ? maxEndIndex : 0,
      );

      // Fast single-pass string segmentation
      final cleanParagraphs = _cleanAndSegmentText(rawText);

      // Fast word count calculation
      int totalWords = 0;
      for (final p in cleanParagraphs) {
        totalWords += p.split(' ').where((w) => w.isNotEmpty).length;
      }

      return ParsedPdfResult(
        title: args.title,
        paragraphs: cleanParagraphs.isNotEmpty
            ? cleanParagraphs
            : ["This PDF contains scanned images or no selectable text."],
        pageCount: pageCount,
        wordCount: totalWords,
      );
    } catch (e) {
      return ParsedPdfResult(
        title: args.title,
        paragraphs: [
          "Unable to read this document. It may be password-protected or corrupted."
        ],
        pageCount: 1,
        wordCount: 0,
      );
    } finally {
      document?.dispose();
    }
  }

  /// High-performance O(N) single-pass paragraph parser
  static List<String> _cleanAndSegmentText(String text) {
    if (text.isEmpty) return [];

    final lines = text.split('\n');
    final List<String> paragraphs = [];
    final StringBuffer currentBlock = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) {
        if (currentBlock.isNotEmpty) {
          final blockStr = currentBlock.toString().trim();
          if (blockStr.length > 5 && !RegExp(r'^\d+$').hasMatch(blockStr)) {
            paragraphs.add(blockStr);
          }
          currentBlock.clear();
        }
        continue;
      }

      // Hyphenated word wrap merge
      if (line.endsWith('-') && line.length > 1) {
        currentBlock.write(line.substring(0, line.length - 1));
      } else {
        if (currentBlock.isNotEmpty) {
          currentBlock.write(' ');
        }
        currentBlock.write(line);
      }
    }

    if (currentBlock.isNotEmpty) {
      final blockStr = currentBlock.toString().trim();
      if (blockStr.length > 5 && !RegExp(r'^\d+$').hasMatch(blockStr)) {
        paragraphs.add(blockStr);
      }
    }

    return paragraphs;
  }
}

