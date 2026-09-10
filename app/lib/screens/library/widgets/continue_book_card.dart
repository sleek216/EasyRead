import 'package:flutter/material.dart';
import 'package:book_reading/theme/app_colors.dart';
import 'package:book_reading/theme/app_typography.dart';
import 'package:book_reading/models/book_item.dart';
import 'package:book_reading/sheets/book_options_sheet.dart';

class ContinueBookCard extends StatelessWidget {
  final BookItem book;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const ContinueBookCard({
    super.key,
    required this.book,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  void _showBookOptionsSheet(BuildContext context) {
    showBookOptionsSheet(context: context, book: book);
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = (book.progress ?? 0) >= 100;
    final displayProgress = (book.progress ?? 0).clamp(0, 100);

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showBookOptionsSheet(context),
      child: Container(
        width: 104,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 104,
              height: 140,
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
                    // Bottom dark gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            stops: const [0.35, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Top Actions
                    Positioned(
                      top: 6,
                      left: 6,
                      right: 6,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.moss,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "DONE ✓",
                                style: AppTypography.inter(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onFavoriteToggle,
                            child: Icon(
                              book.isFavorite ? Icons.star : Icons.star_border,
                              color: book.isFavorite ? AppColors.goldSoft : Colors.white70,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Title in Fraunces font
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
            Text(
              book.author ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
            ),
            const SizedBox(height: 4),

            // Reading Progress Bar Line & Label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 3.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (displayProgress / 100).clamp(0.05, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.moss : AppColors.moss,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        isCompleted ? "Completed ✓" : "$displayProgress% read",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isCompleted ? AppColors.moss : AppColors.textMute,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showBookOptionsSheet(context),
                      child: const Icon(Icons.more_horiz, size: 14, color: AppColors.textMute),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
