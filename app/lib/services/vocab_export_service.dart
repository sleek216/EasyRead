import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img_lib;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../providers/easy_word_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';

class VocabExportService {
  static bool _exportSheetOpen = false;
  static const MethodChannel _mediaChannel = MethodChannel('com.easyread.app/media_saver');

  /// Show modal sheet offering PNG Image, JPG Image, or PDF export
  static void showExportOptionsSheet(
    BuildContext context,
    EasyReadProvider provider, {
    String? currentWord,
  }) {
    final vocabWords = provider.vocabWords;
    final masteredWords = provider.masteredWords.toList();

    if (vocabWords.isEmpty && masteredWords.isEmpty && currentWord == null) {
      showEasyToast(context, "Save some words first to export them");
      return;
    }

    if (_exportSheetOpen) return;
    _exportSheetOpen = true;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentWord != null ? "Download Flashcard" : "Download Vocab Cards",
                      style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                Text(
                  currentWord != null
                      ? "Download 4K flashcard directly to your phone's Gallery:"
                      : "Choose high-quality export format below:",
                  style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                ),
                const SizedBox(height: 16),

                // Option 1: Current Card as 4K PNG to Gallery
                if (currentWord != null && currentWord.trim().isNotEmpty) ...[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.moss, width: 1.5),
                    ),
                    tileColor: AppColors.paperSoft,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.moss,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.download_for_offline_outlined, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      "Save '$currentWord' to Gallery (4K PNG)",
                      style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    subtitle: Text(
                      "Ultra HD 4K image saved directly to Pictures/EasyRead",
                      style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      exportSingleFlashcardImage(context, provider, currentWord, isJpg: false);
                    },
                  ),
                  const SizedBox(height: 10),

                  // Current Card as 4K JPG to Gallery
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.line),
                    ),
                    tileColor: Colors.white,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.paperSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Icons.photo_outlined, color: AppColors.textDark, size: 20),
                    ),
                    title: Text(
                      "Save '$currentWord' to Gallery (4K JPG)",
                      style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    subtitle: Text(
                      "Compact 4K photo format saved directly to Gallery",
                      style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      exportSingleFlashcardImage(context, provider, currentWord, isJpg: true);
                    },
                  ),
                  const SizedBox(height: 14),

                  const Divider(color: AppColors.line, height: 1),
                  const SizedBox(height: 12),

                  Text(
                    "OR EXPORT ENTIRE DECK:",
                    style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMute, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                ],

                // Export All as 4K PNG Image to Gallery
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: currentWord == null ? AppColors.moss : AppColors.line, width: currentWord == null ? 1.5 : 1.0),
                  ),
                  tileColor: currentWord == null ? AppColors.paperSoft : Colors.white,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: currentWord == null ? AppColors.moss : AppColors.paperSoft,
                      shape: BoxShape.circle,
                      border: currentWord == null ? null : Border.all(color: AppColors.line),
                    ),
                    child: Icon(Icons.collections_outlined, color: currentWord == null ? Colors.white : AppColors.textDark, size: 20),
                  ),
                  title: Text(
                    "All Cards to Gallery (4K PNG)",
                    style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  subtitle: Text(
                    "High-resolution 4K grid saved directly to Gallery",
                    style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    exportVocabularyImage(context, provider, isJpg: false);
                  },
                ),

                const SizedBox(height: 10),

                // Export All as 4K JPG Image to Gallery
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  tileColor: Colors.white,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.paperSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppColors.textDark, size: 20),
                  ),
                  title: Text(
                    "All Cards to Gallery (4K JPG)",
                    style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  subtitle: Text(
                    "Compact 4K photo deck saved directly to Gallery",
                    style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    exportVocabularyImage(context, provider, isJpg: true);
                  },
                ),

                const SizedBox(height: 10),

                // Export All as PDF Document
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.line),
                  ),
                  tileColor: Colors.white,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.paperSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.textDark, size: 20),
                  ),
                  title: Text(
                    "All Cards as PDF Document (.pdf)",
                    style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  subtitle: Text(
                    "Printable document saved directly to Downloads",
                    style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    exportVocabularyPdf(context, provider);
                  },
                ),

                const SizedBox(height: 10),


              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _exportSheetOpen = false;
    });
  }

  /// Saves media directly into Android Gallery (MediaStore.Images in Pictures/EasyRead)
  /// or Downloads (MediaStore.Downloads in Downloads/EasyRead) so it instantly appears
  /// in the Samsung / Xiaomi / Android Gallery and Files app!
  static Future<File> _saveFileToStorage({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    bool isImage = true,
  }) async {
    // 1. Android Native MediaStore via MethodChannel: Instant Gallery & Downloads indexing!
    if (Platform.isAndroid) {
      try {
        final methodName = isImage ? 'saveImageToGallery' : 'saveDocumentToDownloads';
        await _mediaChannel.invokeMethod(methodName, {
          'bytes': bytes,
          'fileName': fileName,
          'mimeType': mimeType,
        });
      } catch (e) {
        debugPrint("Notice: MediaStore channel failed: $e");
      }
    }

    // 2. Write local copy
    try {
      final tempDir = await getTemporaryDirectory();
      final targetFile = File('${tempDir.path}/$fileName');
      await targetFile.writeAsBytes(bytes, flush: true);
      return targetFile;
    } catch (_) {
      final docDir = await getApplicationDocumentsDirectory();
      final targetFile = File('${docDir.path}/$fileName');
      await targetFile.writeAsBytes(bytes, flush: true);
      return targetFile;
    }
  }

  /// Export a single Flashcard as 4K Ultra HD PNG or JPG Image directly to Gallery
  static Future<void> exportSingleFlashcardImage(
    BuildContext context,
    EasyReadProvider provider,
    String rawWord, {
    bool isJpg = false,
    bool triggerShare = false,
  }) async {
    final clean = rawWord.trim();
    if (clean.isEmpty) return;

    final formatLabel = isJpg ? "JPG" : "PNG";
    showEasyToast(context, "Generating 4K $formatLabel flashcard...");

    try {
      final data = provider.getWordData(clean);
      
      // Full 4K Canvas Dimensions (2160 x 2560 pixels for crystal clear resolution)
      const double width = 2160.0;
      const double height = 2560.0;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      // 1. Warm cream paper background
      final Paint bgPaint = Paint()..color = const Color(0xFFF9F6EE);
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

      // 2. Card Shadow & Background
      final cardRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(120, 150, width - 240, height - 300),
        const Radius.circular(72),
      );

      final Paint cardShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
      canvas.drawRRect(cardRect.shift(const Offset(0, 24)), cardShadow);

      final Paint cardPaint = Paint()..color = Colors.white;
      canvas.drawRRect(cardRect, cardPaint);

      final Paint cardBorder = Paint()
        ..color = const Color(0xFFE5E0D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5;
      canvas.drawRRect(cardRect, cardBorder);

      // 3. Top Header Label
      final TextPainter appPainter = TextPainter(
        text: const TextSpan(
          text: "EASYREAD FLASHCARD",
          style: TextStyle(color: Color(0xFF8C8270), fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      appPainter.paint(canvas, Offset((width - appPainter.width) / 2, 260));

      // 4. Large Word Title
      final TextPainter wordPainter = TextPainter(
        text: TextSpan(
          text: clean,
          style: const TextStyle(color: Color(0xFF16241D), fontSize: 108, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width - 360);
      wordPainter.paint(canvas, Offset((width - wordPainter.width) / 2, 390));

      double currentY = 390 + wordPainter.height + 30;

      // 5. Phonetic (if available)
      if (data.phonetic != null && data.phonetic!.isNotEmpty) {
        final TextPainter phPainter = TextPainter(
          text: TextSpan(
            text: data.phonetic!,
            style: const TextStyle(color: Color(0xFFB8860B), fontSize: 46, fontWeight: FontWeight.w600),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        phPainter.paint(canvas, Offset((width - phPainter.width) / 2, currentY));
        currentY += phPainter.height + 36;
      }

      // 6. Part of Speech Pill
      final String posText = data.pos.isNotEmpty ? data.pos : "word";
      final TextPainter posPainter = TextPainter(
        text: TextSpan(
          text: posText,
          style: const TextStyle(color: Color(0xFF7A7569), fontSize: 38, fontStyle: FontStyle.italic),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double posW = posPainter.width + 72;
      final posRect = RRect.fromRectAndRadius(
        Rect.fromLTWH((width - posW) / 2, currentY, posW, 80),
        const Radius.circular(99),
      );
      final Paint posBg = Paint()..color = const Color(0xFFF3EFE6);
      canvas.drawRRect(posRect, posBg);
      canvas.drawRRect(posRect, cardBorder);
      posPainter.paint(canvas, Offset((width - posPainter.width) / 2, currentY + 16));

      currentY += 140;

      // 7. Divider
      final Paint dividerPaint = Paint()
        ..color = const Color(0xFFEFE6D0)
        ..strokeWidth = 3.0;
      canvas.drawLine(Offset(240, currentY), Offset(width - 240, currentY), dividerPaint);
      currentY += 70;

      // 8. Meaning / Definition
      final TextPainter meaningPainter = TextPainter(
        text: TextSpan(
          text: data.meaning,
          style: const TextStyle(color: Color(0xFF241F17), fontSize: 52, height: 1.45),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 5,
      )..layout(maxWidth: width - 420);
      meaningPainter.paint(canvas, Offset((width - meaningPainter.width) / 2, currentY));
      currentY += meaningPainter.height + 66;

      // 9. Example Sentence
      if (data.example.isNotEmpty) {
        final TextPainter exPainter = TextPainter(
          text: TextSpan(
            text: '“${data.example}”',
            style: const TextStyle(color: Color(0xFF7A7569), fontSize: 40, fontStyle: FontStyle.italic, height: 1.4),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 3,
        )..layout(maxWidth: width - 420);
        exPainter.paint(canvas, Offset((width - exPainter.width) / 2, currentY));
        currentY += exPainter.height + 60;
      }

      // 10. Synonyms (if available)
      if (data.synonyms.isNotEmpty) {
        final synStr = data.synonyms.take(4).join('   •   ');
        final TextPainter synPainter = TextPainter(
          text: TextSpan(
            text: 'SYNONYMS: $synStr',
            style: const TextStyle(color: Color(0xFF2E4F3E), fontSize: 34, fontWeight: FontWeight.w600, letterSpacing: 1.2),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: width - 420);
        synPainter.paint(canvas, Offset((width - synPainter.width) / 2, currentY));
      }

      // 11. Footer
      final TextPainter footerPainter = TextPainter(
        text: const TextSpan(
          text: "Saved with EasyRead • Reading & Vocabulary",
          style: TextStyle(color: Color(0xFF8C8270), fontSize: 34),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      footerPainter.paint(canvas, Offset((width - footerPainter.width) / 2, height - 240));

      final ui.Picture picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(width.toInt(), height.toInt());

      final Uint8List fileBytes;
      final String extension;
      final String mimeType;

      if (isJpg) {
        extension = 'jpg';
        mimeType = 'image/jpeg';
        final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData == null) throw Exception("Failed to extract image pixels for JPG");
        final imageObj = img_lib.Image.fromBytes(
          width: img.width,
          height: img.height,
          bytes: byteData.buffer,
          order: img_lib.ChannelOrder.rgba,
        );
        fileBytes = Uint8List.fromList(img_lib.encodeJpg(imageObj, quality: 98));
      } else {
        extension = 'png';
        mimeType = 'image/png';
        final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw Exception("Failed to encode PNG image");
        fileBytes = byteData.buffer.asUint8List();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'Card_${clean}_4K_$timestamp.$extension';
      final file = await _saveFileToStorage(
        bytes: fileBytes,
        fileName: fileName,
        mimeType: mimeType,
        isImage: true,
      );

      if (context.mounted) {
        showEasyToast(context, "Saved 4K Card directly to Gallery (Pictures/EasyRead)! 🖼️");

        if (triggerShare) {
          await Share.shareXFiles(
            [
              XFile(
                file.path,
                mimeType: mimeType,
                name: fileName,
              ),
            ],
            subject: 'EasyRead Flashcard: $clean ($formatLabel)',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showEasyToast(context, "Export error: $e");
      }
    }
  }

  /// Export All Vocab Cards as 4K Ultra HD PNG or JPG Image directly to Gallery
  static Future<void> exportVocabularyImage(
    BuildContext context,
    EasyReadProvider provider, {
    bool isJpg = false,
    bool triggerShare = false,
  }) async {
    final vocabWords = provider.vocabWords;
    final masteredWords = provider.masteredWords.toList();

    if (vocabWords.isEmpty && masteredWords.isEmpty) {
      showEasyToast(context, "Save some words first to export them");
      return;
    }

    final formatLabel = isJpg ? "JPG" : "PNG";
    try {
      showEasyToast(context, "Generating 4K $formatLabel cards for Gallery...");

      // Prepare items and deduplicate if necessary
      final Set<String> seen = {};
      final List<Map<String, dynamic>> allItems = [];

      for (final w in vocabWords) {
        final clean = w.trim();
        if (clean.isNotEmpty && seen.add(clean.toLowerCase())) {
          allItems.add({'word': clean, 'status': 'Saved', 'isLearned': false});
        }
      }

      for (final w in masteredWords) {
        final clean = w.trim();
        if (clean.isNotEmpty && seen.add(clean.toLowerCase())) {
          allItems.add({'word': clean, 'status': 'Learned', 'isLearned': true});
        }
      }

      final int totalWords = allItems.length;
      const double cardHeight = 350.0;
      const double headerHeight = 450.0;
      final bool isTwoColumns = totalWords > 10;
      final double width = isTwoColumns ? 2700.0 : 2400.0;
      final int rows = isTwoColumns ? (totalWords / 2).ceil() : totalWords;
      final double height = headerHeight + (rows * cardHeight) + 180.0;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

      // Background - Warm Paper Cream
      final Paint bgPaint = Paint()..color = const Color(0xFFF9F6EE);
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

      // Header Banner - Forest Green
      final Paint headerBg = Paint()..color = const Color(0xFF2E4F3E);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(60, 60, width - 120, 300), const Radius.circular(48)),
        headerBg,
      );

      final TextPainter titlePainter = TextPainter(
        text: const TextSpan(
          text: "EasyRead Vocabulary Flashcards",
          style: TextStyle(color: Colors.white, fontSize: 66, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      titlePainter.paint(canvas, const Offset(120, 110));

      final dateStr = DateTime.now().toString().split('.')[0];
      final TextPainter subPainter = TextPainter(
        text: TextSpan(
          text: "Exported: $dateStr  |  Saved Words: ${vocabWords.length}  |  Learned: ${masteredWords.length}",
          style: const TextStyle(color: Color(0xFFE8DCC2), fontSize: 36),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      subPainter.paint(canvas, const Offset(120, 210));

      // Word Cards
      final Paint cardBg = Paint()..color = Colors.white;
      final Paint cardBorder = Paint()
        ..color = const Color(0xFFE5E0D8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6;

      final double cardWidth = isTwoColumns ? (width - 180.0) / 2 : (width - 120.0);

      for (int i = 0; i < allItems.length; i++) {
        final item = allItems[i];
        final String word = item['word'] as String;
        final String status = item['status'] as String;
        final bool isLearned = item['isLearned'] as bool;
        final data = provider.getWordData(word);

        final int col = isTwoColumns ? (i % 2) : 0;
        final int row = isTwoColumns ? (i ~/ 2) : i;

        final double currentX = isTwoColumns ? (60.0 + col * (cardWidth + 60.0)) : 60.0;
        final double currentY = headerHeight + (row * cardHeight);

        // Card Box
        final RRect cardRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(currentX, currentY, cardWidth, 310),
          const Radius.circular(42),
        );
        canvas.drawRRect(cardRect, cardBg);
        canvas.drawRRect(cardRect, cardBorder);

        // Badge (Saved / Learned)
        final Paint badgeBg = Paint()
          ..color = isLearned ? const Color(0xFF2E7D32) : const Color(0xFFB8860B);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(currentX + cardWidth - 270, currentY + 42, 230, 72),
            const Radius.circular(99),
          ),
          badgeBg,
        );

        final TextPainter badgePainter = TextPainter(
          text: TextSpan(
            text: status.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        badgePainter.paint(
          canvas,
          Offset(currentX + cardWidth - 270 + (230 - badgePainter.width) / 2, currentY + 54),
        );

        // Word Title
        final TextPainter wordPainter = TextPainter(
          text: TextSpan(
            text: word,
            style: const TextStyle(color: Color(0xFF16241D), fontSize: 52, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        wordPainter.paint(canvas, Offset(currentX + 54, currentY + 48));

        // Part of Speech & Phonetic
        final String phStr = (data.phonetic != null && data.phonetic!.isNotEmpty) ? '  ${data.phonetic!}' : '';
        final TextPainter posPainter = TextPainter(
          text: TextSpan(
            text: "(${data.pos})$phStr",
            style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 34, fontStyle: FontStyle.italic),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        posPainter.paint(canvas, Offset(currentX + 54 + wordPainter.width + 30, currentY + 60));

        // Meaning
        final TextPainter meaningPainter = TextPainter(
          text: TextSpan(
            text: data.meaning.isNotEmpty ? data.meaning : "General reading term.",
            style: const TextStyle(color: Color(0xFF37474F), fontSize: 38),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '...',
        )..layout(maxWidth: cardWidth - 330);
        meaningPainter.paint(canvas, Offset(currentX + 54, currentY + 132));

        // Example (if available)
        if (data.example.isNotEmpty) {
          final TextPainter examplePainter = TextPainter(
            text: TextSpan(
              text: '“${data.example}”',
              style: const TextStyle(color: Color(0xFF78909C), fontSize: 34, fontStyle: FontStyle.italic),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            ellipsis: '...',
          )..layout(maxWidth: cardWidth - 108);
          examplePainter.paint(canvas, Offset(currentX + 54, currentY + 228));
        }
      }

      // Footer
      final TextPainter footerPainter = TextPainter(
        text: const TextSpan(
          text: "EasyRead • Your Personal Vocabulary & Reading Companion",
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 34),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      footerPainter.paint(canvas, Offset((width - footerPainter.width) / 2, height - 96));

      // End Recording
      final ui.Picture picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(width.toInt(), height.toInt());

      final Uint8List fileBytes;
      final String extension;
      final String mimeType;

      if (isJpg) {
        extension = 'jpg';
        mimeType = 'image/jpeg';
        final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData == null) throw Exception("Failed to extract image pixels for JPG");
        final imageObj = img_lib.Image.fromBytes(
          width: img.width,
          height: img.height,
          bytes: byteData.buffer,
          order: img_lib.ChannelOrder.rgba,
        );
        fileBytes = Uint8List.fromList(img_lib.encodeJpg(imageObj, quality: 98));
      } else {
        extension = 'png';
        mimeType = 'image/png';
        final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw Exception("Failed to encode PNG image");
        fileBytes = byteData.buffer.asUint8List();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'EasyRead_Vocab_4K_$timestamp.$extension';
      final file = await _saveFileToStorage(
        bytes: fileBytes,
        fileName: fileName,
        mimeType: mimeType,
        isImage: true,
      );

      if (context.mounted) {
        showEasyToast(context, "Saved 4K Cards directly to Gallery (Pictures/EasyRead)! 🖼️");

        if (triggerShare) {
          await Share.shareXFiles(
            [
              XFile(
                file.path,
                mimeType: mimeType,
                name: fileName,
              ),
            ],
            subject: 'EasyRead Vocabulary Cards ($formatLabel)',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showEasyToast(context, "Export error: $e");
      }
    }
  }

  /// Export as Printable Multi-page PDF Document directly to Downloads
  static Future<void> exportVocabularyPdf(
    BuildContext context,
    EasyReadProvider provider,
  ) async {
    final vocabWords = provider.vocabWords;
    final masteredWords = provider.masteredWords.toList();

    if (vocabWords.isEmpty && masteredWords.isEmpty) {
      showEasyToast(context, "Save some words first to export them");
      return;
    }

    try {
      showEasyToast(context, "Generating PDF document for Downloads...");

      final PdfDocument document = PdfDocument();
      document.pageSettings.margins.all = 25;

      final PdfPage page = document.pages.add();
      final double pageWidth = page.getClientSize().width;

      final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 18, style: PdfFontStyle.bold);
      final PdfFont subFont = PdfStandardFont(PdfFontFamily.helvetica, 10);
      final PdfFont bodyFont = PdfStandardFont(PdfFontFamily.helvetica, 9.5);
      final PdfFont boldFont = PdfStandardFont(PdfFontFamily.helvetica, 9.5, style: PdfFontStyle.bold);

      // Title & Header
      page.graphics.drawString(
        'EasyRead Vocabulary Flashcards',
        headerFont,
        brush: PdfSolidBrush(PdfColor(46, 79, 62)),
        bounds: Rect.fromLTWH(0, 0, pageWidth, 24),
      );

      final dateStr = DateTime.now().toString().split('.')[0];
      page.graphics.drawString(
        'Exported: $dateStr  |  Saved Words: ${vocabWords.length}  |  Learned: ${masteredWords.length}',
        subFont,
        brush: PdfSolidBrush(PdfColor(120, 120, 120)),
        bounds: Rect.fromLTWH(0, 26, pageWidth, 16),
      );

      page.graphics.drawLine(
        PdfPen(PdfColor(220, 220, 220), width: 1),
        const Offset(0, 48),
        Offset(pageWidth, 48),
      );

      // PDF Table Grid
      final PdfGrid grid = PdfGrid();
      grid.columns.add(count: 4);
      grid.headers.add(1);

      final PdfGridRow headerRow = grid.headers[0];
      headerRow.cells[0].value = 'Word';
      headerRow.cells[1].value = 'Type';
      headerRow.cells[2].value = 'Meaning & Example';
      headerRow.cells[3].value = 'Status';

      headerRow.style = PdfGridRowStyle(
        backgroundBrush: PdfSolidBrush(PdfColor(46, 79, 62)),
        textBrush: PdfBrushes.white,
        font: boldFont,
      );

      grid.columns[0].width = 90;
      grid.columns[1].width = 65;
      grid.columns[2].width = pageWidth - 90 - 65 - 65;
      grid.columns[3].width = 65;

      final Set<String> seen = {};
      final List<Map<String, dynamic>> allItems = [];

      for (final w in vocabWords) {
        final clean = w.trim();
        if (clean.isNotEmpty && seen.add(clean.toLowerCase())) {
          allItems.add({'word': clean, 'status': 'Saved'});
        }
      }

      for (final w in masteredWords) {
        final clean = w.trim();
        if (clean.isNotEmpty && seen.add(clean.toLowerCase())) {
          allItems.add({'word': clean, 'status': 'Learned'});
        }
      }

      for (var item in allItems) {
        final String w = item['word'] as String;
        final String status = item['status'] as String;
        final data = provider.getWordData(w);

        final PdfGridRow row = grid.rows.add();
        row.cells[0].value = w;
        row.cells[1].value = data.pos;

        String meaningText = data.meaning;
        if (data.example.isNotEmpty) {
          meaningText += '\nEx: "${data.example}"';
        }
        row.cells[2].value = meaningText;
        row.cells[3].value = status;
      }

      grid.style = PdfGridStyle(
        cellPadding: PdfPaddings(left: 6, right: 6, top: 6, bottom: 6),
        font: bodyFont,
      );

      grid.draw(
        page: page,
        bounds: Rect.fromLTWH(0, 62, pageWidth, page.getClientSize().height - 70),
      );

      final List<int> bytes = await document.save();
      document.dispose();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'EasyRead_Vocab_$timestamp.pdf';
      final file = await _saveFileToStorage(
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType: 'application/pdf',
        isImage: false,
      );

      if (context.mounted) {
        showEasyToast(context, "Saved to Downloads (Downloads/EasyRead)!");
        await Share.shareXFiles(
          [
            XFile(
              file.path,
              mimeType: 'application/pdf',
              name: fileName,
            ),
          ],
          subject: 'EasyRead Vocabulary Flashcards (PDF)',
        );
      }
    } catch (e) {
      if (context.mounted) {
        showEasyToast(context, "Export error: $e");
      }
    }
  }
}
