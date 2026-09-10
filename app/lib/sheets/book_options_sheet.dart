import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_reading/theme/app_colors.dart';
import 'package:book_reading/theme/app_typography.dart';
import 'package:book_reading/models/book_item.dart';
import 'package:book_reading/providers/easy_word_provider.dart';
import 'package:book_reading/widgets/bottom_sheet_wrapper.dart';
import 'package:book_reading/widgets/easy_toast.dart';
import 'package:book_reading/sheets/feature_upgrade_sheet.dart';

/// Shows the unified, context-aware book options bottom sheet.
void showBookOptionsSheet({
  required BuildContext context,
  required BookItem book,
}) {
  showEasyModalSheet(
    context: context,
    builder: (ctx) => Consumer<EasyReadProvider>(
      builder: (sheetContext, provider, _) {
        final isCompleted = (book.progress ?? 0) >= 100;
        final currentTag = (provider.bookCollections[book.title.trim().toLowerCase()] ?? book.tag).toLowerCase();
        final matchedCol = currentTag.isEmpty
            ? null
            : provider.collections.where((c) => c.tag.toLowerCase() == currentTag).firstOrNull;
        final isInCollection = matchedCol != null;
        final isDownloaded = provider.isBookDownloaded(book.title);
        final isDownloading = provider.isBookDownloading(book.title);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sheet Header: Book title & context status
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Text(
              "${book.author ?? 'Document'} · ${isCompleted ? 'Completed ✓' : '${book.progress ?? 0}% read'}",
              style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
            ),
            const SizedBox(height: 16),

            // Option 1: Reading Lifecycle / Progress Action
            if (isCompleted)
              _buildOptionCard(
                icon: Icons.replay_rounded,
                iconColor: AppColors.moss,
                badgeBg: AppColors.moss.withValues(alpha: 0.1),
                title: "Start Over / Re-read",
                subtitle: "Reset progress and read again from start",
                onTap: () {
                  Navigator.pop(ctx);
                  provider.resetBookProgress(book.title);
                  showEasyToast(context, 'Reset progress for "${book.title}"');
                },
              )
            else ...[
              _buildOptionCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.moss,
                badgeBg: AppColors.moss.withValues(alpha: 0.1),
                title: "Mark as Completed",
                subtitle: "Mark reading progress as 100% finished",
                onTap: () {
                  Navigator.pop(ctx);
                  provider.markBookCompleted(book.title);
                  showEasyToast(context, 'Marked "${book.title}" as completed');
                },
              ),
              if ((book.progress ?? 0) > 0)
                _buildOptionCard(
                  icon: Icons.restart_alt_rounded,
                  iconColor: AppColors.moss,
                  badgeBg: AppColors.moss.withValues(alpha: 0.1),
                  title: "Restart from Beginning",
                  subtitle: "Reset progress from ${book.progress}% back to 0%",
                  onTap: () {
                    Navigator.pop(ctx);
                    provider.resetBookProgress(book.title);
                    showEasyToast(context, 'Reset progress for "${book.title}"');
                  },
                ),
            ],

            // Option 2: Collection Management Context
            _buildOptionCard(
              icon: isInCollection ? Icons.folder_special_rounded : Icons.folder_outlined,
              iconColor: AppColors.moss,
              badgeBg: AppColors.moss.withValues(alpha: 0.1),
              title: isInCollection ? "Change Collection" : "Add to Collection",
              subtitle: isInCollection
                  ? 'Currently in "${matchedCol.name}" · Tap to change'
                  : "Organize into a custom reading shelf",
              trailing: isInCollection
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(matchedCol.colorValue).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Color(matchedCol.colorValue).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Color(matchedCol.colorValue),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            matchedCol.name,
                            style: AppTypography.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(matchedCol.colorValue),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                resetSheetGuard();
                showBookAddToCollectionSheet(context: context, book: book);
              },
            ),

            // Option 3: Offline Download Context
            _buildOptionCard(
              icon: isDownloaded ? Icons.offline_pin_rounded : Icons.download_rounded,
              iconColor: AppColors.moss,
              badgeBg: isDownloaded
                  ? AppColors.moss.withValues(alpha: 0.15)
                  : AppColors.moss.withValues(alpha: 0.1),
              title: isDownloading
                  ? "Downloading Book..."
                  : (isDownloaded ? "Downloaded (Offline Ready)" : "Download for Offline"),
              subtitle: isDownloading
                  ? "Saving full text for offline reading"
                  : (isDownloaded
                      ? "Saved on device · Tap to remove"
                      : "Save to read anytime without internet"),
              trailing: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.moss),
                    )
                  : (isDownloaded
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.moss.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.moss),
                              const SizedBox(width: 4),
                              Text(
                                "Saved",
                                style: AppTypography.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.moss,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null),
              onTap: () async {
                if (isDownloading) return;
                Navigator.pop(ctx);
                if (isDownloaded) {
                  await provider.removeDownloadedBook(book.title);
                  if (context.mounted) {
                    showEasyToast(context, 'Removed "${book.title}" from offline downloads');
                  }
                } else {
                  final success = await provider.downloadBookForOffline(book);
                  if (context.mounted) {
                    if (success) {
                      showEasyToast(context, 'Downloaded "${book.title}" for offline reading');
                    } else {
                      showEasyToast(context, 'Failed to download book');
                    }
                  }
                }
              },
            ),

            // Option 4: Remove from Shelf Context
            _buildOptionCard(
              icon: Icons.bookmark_remove_outlined,
              iconColor: AppColors.plum,
              badgeBg: AppColors.plum.withValues(alpha: 0.1),
              title: "Remove from Shelf",
              subtitle: "Remove this book from Continue Reading",
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                provider.removeFromContinueShelf(book.title);
                showEasyToast(context, 'Removed from Continue Reading');
              },
            ),
          ],
        );
      },
    ),
  );
}

/// Unified, high-polish option card with 40x40 icon container and consistent 2-line layout
Widget _buildOptionCard({
  required IconData icon,
  required Color iconColor,
  required Color badgeBg,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
  Widget? trailing,
  bool isDestructive = false,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 40x40 Icon Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle with consistent vertical rhythm
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDestructive ? AppColors.plum : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: isDestructive
                        ? AppColors.plum.withValues(alpha: 0.75)
                        : AppColors.textMute,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Trailing Indicator
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDestructive
                    ? AppColors.plum.withValues(alpha: 0.4)
                    : AppColors.textMute.withValues(alpha: 0.5),
              ),
        ],
      ),
    ),
  );
}

/// Collection selection modal sheet
void showBookAddToCollectionSheet({
  required BuildContext context,
  required BookItem book,
}) {
  final provider = context.read<EasyReadProvider>();
  if (!provider.hasFeature('custom_shelves')) {
    showFeatureUpgradeSheet(
      context: context,
      featureKey: 'custom_shelves',
      featureTitle: 'Custom Collections & Shelves',
      featureDescription: 'Personalized reading folders and custom bookshelves are part of the EasyRead Plus package. Upgrade now to organize your library.',
      icon: Icons.folder_special_rounded,
    );
    return;
  }
  showEasyModalSheet(
    context: context,
    builder: (ctx) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Add to Collection",
          style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose a collection for "${book.title}"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
        ),
        const SizedBox(height: 14),
        if (provider.collections.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                "No custom collections created yet.\nCreate one from the Library screen.",
                style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ] else ...[
          ...provider.collections.map((col) {
            final currentTag = (provider.bookCollections[book.title.trim().toLowerCase()] ?? book.tag).toLowerCase();
            final isSelected = currentTag == col.tag.toLowerCase();
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                provider.addBookToCollection(book: book, collectionTag: col.tag);
                Navigator.pop(ctx);
                showEasyToast(context, 'Moved "${book.title}" to ${col.name}');
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.moss.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.moss : AppColors.line,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(col.colorValue),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.folder, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        col.name,
                        style: AppTypography.fraunces(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: AppColors.moss, size: 18),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    ),
  );
}
