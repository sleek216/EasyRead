import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/easy_word_provider.dart';
import '../models/book_item.dart';
import '../services/pdf_reader_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';
import 'google_drive_sheet.dart';
import 'dropbox_sheet.dart';

class ImportSheetContent extends StatelessWidget {
  const ImportSheetContent({super.key});

  // ─── File Picker (Device / Google Drive / Dropbox) ──────────────────────────
  Future<void> _pickFile(BuildContext context) async {
    // Capture references BEFORE any Navigator.pop (context may deactivate)
    final provider = context.read<EasyReadProvider>();
    final rootCtx = context;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'doc', 'docx', 'epub'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final ext = (file.extension ?? '').toUpperCase();
      final fileName = file.name;
      final filePath = file.path;

      // ── Duplicate Detection ──────────────────────────────────────────────────
      // If this exact file was already imported, just open the existing copy.
      // No re-parsing, no duplicate shelf entries, no duplicate word counts.
      final normFileName = provider.normalizeBookTitle(fileName);
      final alreadyImported = provider.userLocalBooks.any(
        (b) => provider.normalizeBookTitle(b.title) == normFileName,
      );
      if (alreadyImported) {
        final existing = provider.userLocalBooks.firstWhere(
          (b) => provider.normalizeBookTitle(b.title) == normFileName,
        );
        provider.activeTab = 'reader';
        provider.openBook(existing);
        if (rootCtx.mounted) {
          Navigator.of(rootCtx).pop();
          showEasyToast(rootCtx, 'Opened existing "${existing.title}" from Your Library');
        }
        return;
      }
      // ────────────────────────────────────────────────────────────────────────

      // Show loading + switch tab BEFORE closing sheet so loader is visible
      provider.setDocumentLoading(true);
      provider.activeTab = 'reader';

      // Dismiss the bottom sheet
      if (rootCtx.mounted) {
        Navigator.of(rootCtx).pop();
      }

      // Process in background — context no longer needed here
      try {
        if (ext == 'PDF') {
          await _handlePdf(provider, file, fileName, filePath);
        } else if (ext == 'TXT') {
          await _handleTxt(provider, file, fileName, filePath);
        } else if (ext == 'EPUB') {
          await _handleEpub(provider, file, fileName, filePath);
        } else if (ext == 'DOC' || ext == 'DOCX') {
          await _handleDocx(provider, file, fileName, filePath, ext);
        } else {
          // Fallback: import as placeholder
          provider.importBook(BookItem(
            title: fileName,
            meta: '$ext · Imported from device',
            color: AppColors.blueTheme,
            tag: 'imported',
            paragraphs: ['Document imported: $fileName'],
          ));
          provider.setDocumentLoading(false);
        }
      } catch (e) {
        provider.setDocumentLoading(false);
        if (rootCtx.mounted) {
          showEasyToast(rootCtx, 'Could not open file: ${e.toString().split('\n').first}');
        }
      }
    } catch (_) {
      provider.setDocumentLoading(false);
      if (rootCtx.mounted) {
        showEasyToast(rootCtx, 'Could not open file picker. Please try again.');
      }
    }
  }

  // ─── PDF ─────────────────────────────────────────────────────────────────────
  Future<void> _handlePdf(EasyReadProvider provider, PlatformFile file,
      String fileName, String? filePath) async {
    try {
      ParsedPdfResult parsed;
      if (filePath != null && filePath.isNotEmpty) {
        parsed = await PdfReaderService.extractFromPath(filePath);
      } else if (file.bytes != null) {
        final cleanTitle = fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
        parsed = await PdfReaderService.extractFromBytes(file.bytes!, cleanTitle);
      } else {
        return;
      }

      provider.importBook(BookItem(
        title: parsed.title,
        meta: 'PDF · ${parsed.pageCount} pages · Imported',
        color: AppColors.plum,
        tag: 'imported',
        paragraphs: parsed.paragraphs,
      ));

      provider.openArticleWithContent(
        title: parsed.title,
        byline: 'PDF Document · ${parsed.pageCount} pages · ${parsed.wordCount} words',
        paragraphs: parsed.paragraphs,
        banner: 'PDF Reader Mode: Tap any word for instant definitions & AI lookup',
      );
    } finally {
      provider.setDocumentLoading(false);
    }
  }

  // ─── TXT ─────────────────────────────────────────────────────────────────────
  Future<void> _handleTxt(EasyReadProvider provider, PlatformFile file,
      String fileName, String? filePath) async {
    try {
      String content = '';
      if (filePath != null && filePath.isNotEmpty) {
        final f = File(filePath);
        if (await f.exists()) content = await f.readAsString();
      } else if (file.bytes != null) {
        content = utf8.decode(file.bytes!, allowMalformed: true);
      }

      final paras = content
          .split(RegExp(r'\n\s*\n'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      final finalParas = paras.isNotEmpty ? paras : [content];
      final cleanTitle = fileName.replaceAll(RegExp(r'\.txt$', caseSensitive: false), '');

      provider.importBook(BookItem(
        title: cleanTitle,
        meta: 'TXT · ${finalParas.length} sections · Imported',
        color: AppColors.moss,
        tag: 'imported',
        paragraphs: finalParas,
      ));

      provider.openArticleWithContent(
        title: cleanTitle,
        byline: 'Plain Text · ${content.split(RegExp(r'\s+')).length} words',
        paragraphs: finalParas,
        banner: 'Text Reader Mode: Tap any word for instant definitions & AI lookup',
      );
    } finally {
      provider.setDocumentLoading(false);
    }
  }

  // ─── EPUB ─────────────────────────────────────────────────────────────────────
  // EPUBs are ZIP archives containing HTML/XHTML content files. We extract the
  // readable text from the HTML tags without needing any external package.
  Future<void> _handleEpub(EasyReadProvider provider, PlatformFile file,
      String fileName, String? filePath) async {
    try {
      Uint8List? bytes;
      if (filePath != null && filePath.isNotEmpty) {
        final f = File(filePath);
        if (await f.exists()) bytes = await f.readAsBytes();
      } else if (file.bytes != null) {
        bytes = file.bytes!;
      }

      if (bytes == null) return;

      final paragraphs = _parseEpubBytes(bytes);
      final cleanTitle = fileName.replaceAll(RegExp(r'\.epub$', caseSensitive: false), '');

      provider.importBook(BookItem(
        title: cleanTitle,
        meta: 'EPUB · ${paragraphs.length} sections · Imported',
        color: const Color(0xFF5B4FCF),
        tag: 'imported',
        paragraphs: paragraphs,
      ));

      provider.openArticleWithContent(
        title: cleanTitle,
        byline: 'eBook · ${paragraphs.length} sections',
        paragraphs: paragraphs,
        banner: 'EPUB Reader Mode: Tap any word for instant definitions & AI lookup',
      );
    } finally {
      provider.setDocumentLoading(false);
    }
  }

  List<String> _parseEpubBytes(Uint8List bytes) {
    try {
      // EPUB is a ZIP archive — properly unzip it and read HTML content files
      final archive = ZipDecoder().decodeBytes(bytes);
      final htmlRe = RegExp(r'<(p|div|h[1-6]|li)[^>]*>(.*?)<\/\1>',
          caseSensitive: false, dotAll: true);
      final tagRe = RegExp(r'<[^>]+>');
      final entityRe = RegExp(r'&(?:[a-zA-Z]+|#\d+);');

      final paragraphs = <String>[];

      // Sort HTML/XHTML files for reading order
      final contentFiles = archive.files
          .where((f) => f.isFile &&
              (f.name.endsWith('.html') ||
               f.name.endsWith('.htm') ||
               f.name.endsWith('.xhtml')))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      for (final file in contentFiles) {
        final content = utf8.decode(file.content as Uint8List, allowMalformed: true);
        for (final m in htmlRe.allMatches(content)) {
          var text = m.group(2) ?? '';
          text = text.replaceAll(tagRe, ' ');
          text = text.replaceAll(entityRe, ' ');
          text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (text.length > 20) paragraphs.add(text);
        }
      }

      return paragraphs.isNotEmpty
          ? paragraphs
          : ['This EPUB file could not be parsed. It may use an unsupported format or be DRM-protected.'];
    } catch (_) {
      return ['Unable to extract text from this EPUB file.'];
    }
  }

  // ─── DOC / DOCX ──────────────────────────────────────────────────────────────
  // DOCX is a ZIP with word/document.xml. We extract <w:t> XML text nodes.
  Future<void> _handleDocx(EasyReadProvider provider, PlatformFile file,
      String fileName, String? filePath, String ext) async {
    try {
      Uint8List? bytes;
      if (filePath != null && filePath.isNotEmpty) {
        final f = File(filePath);
        if (await f.exists()) bytes = await f.readAsBytes();
      } else if (file.bytes != null) {
        bytes = file.bytes!;
      }

      if (bytes == null) return;

      final paragraphs = _parseDocxBytes(bytes);
      final cleanTitle = fileName.replaceAll(RegExp(r'\.(docx?|doc)$', caseSensitive: false), '');

      provider.importBook(BookItem(
        title: cleanTitle,
        meta: '$ext · ${paragraphs.length} paragraphs · Imported',
        color: const Color(0xFF1565C0),
        tag: 'imported',
        paragraphs: paragraphs,
      ));

      provider.openArticleWithContent(
        title: cleanTitle,
        byline: 'Word Document · ${paragraphs.length} paragraphs',
        paragraphs: paragraphs,
        banner: '$ext Reader Mode: Tap any word for instant definitions & AI lookup',
      );
    } finally {
      provider.setDocumentLoading(false);
    }
  }

  List<String> _parseDocxBytes(Uint8List bytes) {
    try {
      // DOCX is a ZIP archive — unzip it and read word/document.xml
      final archive = ZipDecoder().decodeBytes(bytes);

      // Find word/document.xml inside the ZIP
      final docXml = archive.files.firstWhere(
        (f) => f.isFile && f.name == 'word/document.xml',
        orElse: () => ArchiveFile('', 0, Uint8List(0)),
      );

      if (docXml.content == null || (docXml.content as Uint8List).isEmpty) {
        return ['This document could not be read. It may be in an older DOC format or protected.'];
      }

      final xmlContent = utf8.decode(docXml.content as Uint8List, allowMalformed: true);

      // Extract <w:p> paragraph blocks then get all <w:t> text runs within each
      final paraRe = RegExp(r'<w:p[ >](.*?)<\/w:p>', caseSensitive: false, dotAll: true);
      final textRe = RegExp(r'<w:t[^>]*>(.*?)<\/w:t>', caseSensitive: false, dotAll: true);

      final paras = <String>[];
      for (final paraMatch in paraRe.allMatches(xmlContent)) {
        final paraXml = paraMatch.group(1) ?? '';
        final sb = StringBuffer();
        for (final m in textRe.allMatches(paraXml)) {
          sb.write(m.group(1) ?? '');
        }
        final text = sb.toString().trim();
        if (text.length > 2) paras.add(text);
      }

      // Merge short paragraphs into ~400 char reading chunks
      if (paras.isEmpty) {
        return ['This document could not be read. It may be in an older DOC format or protected.'];
      }

      final chunks = <String>[];
      final chunk = StringBuffer();
      for (final p in paras) {
        if (chunk.isNotEmpty) chunk.write(' ');
        chunk.write(p);
        if (chunk.length >= 300) {
          chunks.add(chunk.toString().trim());
          chunk.clear();
        }
      }
      if (chunk.isNotEmpty) chunks.add(chunk.toString().trim());

      return chunks.where((c) => c.length > 5).toList();
    } catch (_) {
      return ['Unable to read this Word document.'];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Import a file',
          style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        _buildOption(
          iconBg: AppColors.moss,
          icon: Icons.smartphone,
          title: 'From this device',
          subtitle: 'PDF, EPUB, DOC/DOCX, or TXT',
          onTap: () => _pickFile(context),
        ),
        _buildOption(
          iconBg: const Color(0xFF1A73E8),
          icon: Icons.add_to_drive_outlined,
          title: 'Google Drive',
          subtitle: 'Pick & scan from your Google Drive',
          onTap: () {
            Navigator.of(context).pop();
            GoogleDriveSheet.show(context);
          },
        ),
        _buildOption(
          iconBg: const Color(0xFF0061FF),
          icon: Icons.cloud_queue_outlined,
          title: 'Dropbox',
          subtitle: 'Pick & scan from your Dropbox',
          onTap: () {
            Navigator.of(context).pop();
            DropboxSheet.show(context);
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }


  Widget _buildOption({
    required Color iconBg,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: AppTypography.inter(fontSize: 11, color: AppColors.textMute)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMute),
          ],
        ),
      ),
    );
  }
}

