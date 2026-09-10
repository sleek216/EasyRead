import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/easy_word_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';
import '../widgets/bottom_sheet_wrapper.dart';
import 'share_export_sheet.dart';

class ReadingSettingsSheetContent extends StatelessWidget {
  const ReadingSettingsSheetContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(
          title: "Text size",
          trailing: Row(
            children: [
              _buildRoundBtn("A-", () => provider.setFontSize(provider.readerFontSize - 1)),
              SizedBox(
                width: 32,
                child: Text(
                  "${provider.readerFontSize.round()}",
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                ),
              ),
              _buildRoundBtn("A+", () => provider.setFontSize(provider.readerFontSize + 1)),
            ],
          ),
        ),
        const Divider(color: AppColors.line, height: 1),
        _buildRow(
          title: "Theme",
          trailing: Row(
            children: [
              _buildThemeDot(const Color(0xFFEFE6D0), AppColors.textDark, provider),
              const SizedBox(width: 8),
              _buildThemeDot(const Color(0xFFF5F0E4), AppColors.textDark, provider),
              const SizedBox(width: 8),
              _buildThemeDot(const Color(0xFF16241D), const Color(0xFFEFE6D0), provider),
              const SizedBox(width: 8),
              _buildThemeDot(const Color(0xFF000000), const Color(0xFFD8D2C4), provider),
            ],
          ),
        ),

        const Divider(color: AppColors.line, height: 1),
        _buildRow(
          title: "Offline download",
          trailing: Builder(
            builder: (ctx) {
              final isDownloaded = provider.isBookDownloaded(provider.readerTitle);
              final isDownloading = provider.isBookDownloading(provider.readerTitle);

              if (isDownloading) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.moss),
                );
              }

              if (isDownloaded) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.moss.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 13, color: AppColors.moss),
                          const SizedBox(width: 4),
                          Text(
                            "Downloaded",
                            style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.moss),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.plum),
                      onPressed: () async {
                        await provider.removeDownloadedBook(provider.readerTitle);
                        if (ctx.mounted) {
                          showEasyToast(ctx, 'Removed "${provider.readerTitle}" from downloads');
                        }
                      },
                    ),
                  ],
                );
              }

              return IconButton(
                icon: const Icon(Icons.download_outlined, size: 20, color: AppColors.textDark),
                onPressed: () async {
                  final cur = provider.continueShelf.firstWhere(
                    (b) => b.title.trim().toLowerCase() == provider.readerTitle.trim().toLowerCase(),
                    orElse: () => BookItem(
                      title: provider.readerTitle,
                      author: provider.readerByline,
                      paragraphs: List<String>.from(provider.articleParagraphs),
                      color: AppColors.moss,
                      tag: 'offline',
                    ),
                  );
                  final success = await provider.downloadBookForOffline(cur);
                  if (ctx.mounted) {
                    if (success) {
                      showEasyToast(ctx, 'Downloaded "${provider.readerTitle}" for offline reading');
                    } else {
                      showEasyToast(ctx, 'Failed to download book');
                    }
                  }
                },
              );
            },
          ),
        ),
        const Divider(color: AppColors.line, height: 1),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
            resetSheetGuard();
            showEasyModalSheet(
              context: context,
              builder: (ctx) => const ShareExportSheetContent(),
            );
          },
          child: _buildRow(
            title: "Share & export",
            trailing: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(Icons.share_outlined, size: 20, color: AppColors.textDark),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.paper,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Done",
              style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.paper),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildRow({required String title, required Widget trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          trailing,
        ],
      ),
    );
  }

  Widget _buildRoundBtn(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        alignment: Alignment.center,
        child: Text(text, style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildThemeDot(Color bg, Color text, EasyReadProvider provider) {
    final active = provider.readerBackground == bg;
    return GestureDetector(
      onTap: () => provider.setTheme(bg, text),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: active ? AppColors.gold : Colors.transparent, width: 2),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
      ),
    );
  }
}
