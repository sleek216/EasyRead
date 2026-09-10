import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/easy_word_provider.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';

class ShareExportSheetContent extends StatelessWidget {
  const ShareExportSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EasyReadProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Share & export",
          style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        _buildOption(
          iconBg: AppColors.moss,
          icon: Icons.picture_as_pdf_outlined,
          title: "Share this article (PDF)",
          subtitle: "Export and share formatted PDF document",
          onTap: () async {
            Navigator.of(context).pop();
            showEasyToast(context, "Preparing PDF to share... 📄");
            await PdfExportService.exportAndShareArticle(
              title: provider.readerTitle,
              byline: provider.readerByline,
              paragraphs: provider.articleParagraphs,
            );
          },
        ),
        _buildOption(
          iconBg: AppColors.blueTheme,
          icon: Icons.copy_outlined,
          title: "Copy full text",
          subtitle: "Copies the article to your clipboard",
          onTap: () {
            Navigator.of(context).pop();
            final fullText = provider.articleParagraphs.join('\n\n');
            Clipboard.setData(ClipboardData(text: fullText));
            showEasyToast(context, "Article copied to clipboard");
          },
        ),
        _buildOption(
          iconBg: AppColors.gold,
          icon: Icons.file_download_outlined,
          title: "Export highlights & notes",
          subtitle: "Share everything you've marked",
          onTap: () {
            Navigator.of(context).pop();
            if (provider.highlights.isEmpty) {
              showEasyToast(context, "No highlights or notes to export yet");
              return;
            }

            final buffer = StringBuffer();
            buffer.writeln(provider.readerTitle);
            buffer.writeln("Highlights & notes — exported from EasyRead");
            buffer.writeln("========================================");
            buffer.writeln();

            for (var hl in provider.highlights) {
              final text = provider.articleParagraphs.length > hl.paragraphIndex
                  ? provider.articleParagraphs[hl.paragraphIndex]
                  : "";
              buffer.writeln("[${hl.color.toUpperCase()} highlight]");
              buffer.writeln('"$text"');
              if (hl.note.isNotEmpty) {
                buffer.writeln("Note: ${hl.note}");
              }
              buffer.writeln();
            }

            Share.share(buffer.toString(), subject: "${provider.readerTitle} - Highlights");
            showEasyToast(context, "Highlights exported");
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                Text(subtitle, style: AppTypography.inter(fontSize: 11, color: AppColors.textMute)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
