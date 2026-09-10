import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../models/book_item.dart';
import '../../providers/easy_word_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/easy_toast.dart';
import '../../sheets/book_options_sheet.dart';

class ContinueReadingScreen extends StatelessWidget {
  final String type; // 'continue' or 'featured'
  
  const ContinueReadingScreen({super.key, this.type = 'continue'});

  void _showBookOptionsSheet(BuildContext context, EasyReadProvider provider, BookItem book) {
    showBookOptionsSheet(context: context, book: book);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final books = type == 'featured' ? provider.featuredBooks : provider.continueShelf;
    final title = type == 'featured' ? "Featured Reads" : "Continue Reading";
    final subtitle = type == 'featured' 
        ? "${books.length} hand-picked books"
        : "${books.length} in progress & completed";

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.paperSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 15, color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.line, height: 1),

            // Content Grid: Compact 3-Column Bookshelf Layout
            Expanded(
              child: books.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.paperSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: const Icon(Icons.menu_book_rounded, size: 28, color: AppColors.textMute),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No active books",
                            style: AppTypography.fraunces(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Open any book or import a PDF to start reading.",
                            style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.51,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        final isCompleted = (book.progress ?? 0) >= 100;
                        final displayProgress = (book.progress ?? 0).clamp(0, 100);

                        // Match collection by tag
                        CollectionItem? matchedCollection;
                        for (final col in provider.collections) {
                          if (col.tag.toLowerCase() == book.tag.toLowerCase()) {
                            matchedCollection = col;
                            break;
                          }
                        }

                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            provider.openBook(book);
                            Navigator.of(context).pop();
                          },
                          onLongPress: () => _showBookOptionsSheet(context, provider, book),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Compact Vertical Book Cover
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: book.color,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x3316241D),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                        spreadRadius: -3,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        // Bottom gradient overlay for clear white title
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(alpha: 0.55),
                                                ],
                                                stops: const [0.35, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Top Collection Badge (if added to collection)
                                        if (matchedCollection != null) ...[
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            right: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                matchedCollection.name.toUpperCase(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.inter(
                                                  fontSize: 7.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ] else if (isCompleted) ...[
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.moss,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                "DONE ✓",
                                                style: AppTypography.inter(
                                                  fontSize: 7,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],

                                        // Favorite Star
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              provider.toggleFavorite(book.title);
                                              showEasyToast(
                                                context,
                                                book.isFavorite ? "Saved to Favorites" : "Removed from Favorites",
                                              );
                                            },
                                            child: Icon(
                                              book.isFavorite ? Icons.star : Icons.star_border,
                                              size: 16,
                                              color: book.isFavorite ? AppColors.goldSoft : Colors.white70,
                                            ),
                                          ),
                                        ),

                                        // Book Title on Cover bottom
                                        Positioned(
                                          bottom: 8,
                                          left: 7,
                                          right: 7,
                                          child: Text(
                                            book.title,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.fraunces(
                                              fontSize: 11.5,
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
                              ),
                              const SizedBox(height: 6),

                              // 2. Author / Meta Subtitle
                              Text(
                                book.author ?? book.meta ?? "Document",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize: 10,
                                  color: AppColors.textMute,
                                ),
                              ),
                              const SizedBox(height: 4),

                              // 3. Reading Progress Bar Line + % Read
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    height: 3,
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
                                          color: AppColors.moss,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isCompleted ? "Completed ✓" : "$displayProgress% read",
                                        style: AppTypography.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: isCompleted ? AppColors.moss : AppColors.textMute,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showBookOptionsSheet(context, provider, book),
                                        child: const Icon(Icons.more_horiz, size: 13, color: AppColors.textMute),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
