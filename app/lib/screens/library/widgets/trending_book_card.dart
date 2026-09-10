import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../models/book_item.dart';
import '../../../providers/easy_word_provider.dart';
import '../../../widgets/easy_toast.dart';
import '../../../widgets/bottom_sheet_wrapper.dart';

class TrendingBookCard extends StatelessWidget {
  final BookItem book;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final String? badgeText;

  const TrendingBookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onFavoriteToggle,
    this.badgeText,
  });

  void _showAddToCollectionSheet(BuildContext context, EasyReadProvider provider, BookItem book) {
    showEasyModalSheet(
      context: context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            book.author ?? "Library Book",
            style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
          ),
          const SizedBox(height: 14),

          // Action 1: Download for Offline
          Builder(
            builder: (bCtx) {
              final isDownloaded = provider.isBookDownloaded(book.title);
              final isDownloading = provider.isBookDownloading(book.title);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDownloaded ? AppColors.moss.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDownloaded ? AppColors.moss : AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isDownloaded ? Icons.offline_pin_rounded : Icons.download_for_offline_outlined,
                        size: 20,
                        color: isDownloaded ? AppColors.moss : AppColors.textDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDownloaded ? "Downloaded for Offline" : "Download for Offline",
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDownloaded ? AppColors.moss : AppColors.textDark,
                              ),
                            ),
                            Text(
                              isDownloaded ? "Tap to remove from offline storage" : "Save full text to read anytime without internet",
                              style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute),
                            ),
                          ],
                        ),
                      ),
                      if (isDownloading)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.moss))
                      else if (isDownloaded)
                        const Icon(Icons.check_circle, size: 16, color: AppColors.moss),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 12),

          Text(
            "Add to Collection",
            style: AppTypography.fraunces(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose a collection for this book',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
          ),
          const SizedBox(height: 10),
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
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.moss : AppColors.ink,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: AppColors.moss, size: 18),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EasyReadProvider>(context, listen: false);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: () => _showAddToCollectionSheet(context, provider, book),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover Container
            Container(
              width: 110,
              height: 148,
              decoration: BoxDecoration(
                color: book.color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4016241D),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Subtle left spine highlight
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    // Bottom gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0.35, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Top Badges & Favorite Star & Collection Button
                    Positioned(
                      top: 6,
                      left: 6,
                      right: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.ink.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (badgeText ?? book.tag).toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.paper,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _showAddToCollectionSheet(context, provider, book),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: onFavoriteToggle,
                                child: Icon(
                                  book.isFavorite ? Icons.star : Icons.star_border,
                                  color: book.isFavorite ? AppColors.goldSoft : Colors.white70,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Title in Fraunces font at bottom of cover
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        book.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.fraunces(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Author text
            Text(
              book.author ?? "EasyRead Studio",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 11,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),

            // Reading Meta
            Text(
              book.meta != null && book.meta!.isNotEmpty ? book.meta! : "Featured read",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 9.5,
                color: AppColors.textMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
