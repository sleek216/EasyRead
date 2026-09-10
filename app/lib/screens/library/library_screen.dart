import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/easy_word_provider.dart';
import '../../models/book_item.dart';
import '../../models/app_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_top_bar.dart';
import '../../widgets/bottom_sheet_wrapper.dart';
import '../../widgets/easy_toast.dart';
import '../../sheets/search_sheet.dart';
import '../../sheets/upgrade_sheet.dart';
import '../../sheets/import_sheet.dart';
import '../../sheets/paste_read_sheet.dart';
import '../../sheets/web_save_sheet.dart';
import '../../sheets/feature_upgrade_sheet.dart';
import '../../sheets/notification_sheet.dart';
import 'widgets/continue_book_card.dart';
import 'widgets/trending_book_card.dart';
import 'continue_reading_screen.dart';
import 'all_books_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final tags = provider.dynamicCategoryTags;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppTopBar(
              trailing: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (provider.isPremium) {
                        provider.switchTab('profile');
                      } else {
                        showEasyModalSheet(
                          context: context,
                          builder: (ctx) => const UpgradeSheetContent(),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: provider.isPremium
                            ? const LinearGradient(colors: [AppColors.gold, AppColors.goldSoft])
                            : null,
                        color: provider.isPremium ? null : AppColors.paperSoft,
                        border: provider.isPremium ? null : Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        provider.planDisplayName,
                        style: AppTypography.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: provider.isPremium ? Colors.white : AppColors.textMute,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // In-App Notification Center Bell Icon with Dynamic Badge
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showEasyModalSheet(
                        context: context,
                        builder: (ctx) => const NotificationSheetContent(),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.paperSoft,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Icon(Icons.notifications_outlined, size: 18, color: AppColors.textDark),
                        ),
                        if (provider.unreadNotificationCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE02424),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Center(
                                child: Text(
                                  provider.unreadNotificationCount > 9 ? "9+" : "${provider.unreadNotificationCount}",
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      showEasyModalSheet(
                        context: context,
                        builder: (ctx) => const SearchSheetContent(),
                      );
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.paperSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Icons.search, size: 16, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.moss,
                backgroundColor: AppColors.paperSoft,
                displacement: 20,
                onRefresh: () async {
                  await provider.refreshLibraryData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dynamic Category Tags from Database
                      SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: tags.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (ctx, i) {
                            final t = tags[i];
                            final active = provider.selectedTag.toLowerCase() == t.toLowerCase();
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                provider.selectTag(t);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: active ? AppColors.moss : AppColors.paperSoft,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: active ? AppColors.moss : AppColors.line),
                                ),
                                child: Text(
                                  t,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: active ? Colors.white : AppColors.textDark,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Import Chips Row
                      Row(
                        children: [
                          _buildImportChip(
                            icon: Icons.file_download_outlined,
                            title: "Import file",
                            onTap: () async {
                              final allowed = await provider.checkFeatureAccess('import_pdf');
                              if (!context.mounted) return;
                              if (!allowed) {
                                showFeatureUpgradeSheet(
                                  context: context,
                                  featureKey: 'import_pdf',
                                  featureTitle: "Import File & PDF",
                                  featureDescription: "Read your custom PDFs, research papers, and eBooks inside the distraction-free reader with instant AI dictionary lookup.",
                                  icon: Icons.file_download_outlined,
                                );
                                return;
                              }
                              showEasyModalSheet(
                                context: context,
                                builder: (ctx) => const ImportSheetContent(),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildImportChip(
                            icon: Icons.content_paste_outlined,
                            title: "Paste & Read",
                            onTap: () async {
                              final allowed = await provider.checkFeatureAccess('paste_read');
                              if (!context.mounted) return;
                              if (!allowed) {
                                showFeatureUpgradeSheet(
                                  context: context,
                                  featureKey: 'paste_read',
                                  featureTitle: "Paste & Read Articles",
                                  featureDescription: "Paste long articles, essays, and text notes to convert them into a distraction-free, paginated reading mode.",
                                  icon: Icons.content_paste_outlined,
                                );
                                return;
                              }
                              showEasyModalSheet(
                                context: context,
                                builder: (ctx) => const PasteReadSheetContent(),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildImportChip(
                            icon: Icons.language_outlined,
                            title: "Save from web",
                            onTap: () async {
                              final allowed = await provider.checkFeatureAccess('save_from_web');
                              if (!context.mounted) return;
                              if (!allowed) {
                                showFeatureUpgradeSheet(
                                  context: context,
                                  featureKey: 'save_from_web',
                                  featureTitle: "Save from Web URL",
                                  featureDescription: "Extract and convert articles from any web link into a clean, ad-free book directly inside your personal library.",
                                  icon: Icons.language_outlined,
                                );
                                return;
                              }
                              showEasyModalSheet(
                                context: context,
                                builder: (ctx) => const WebSaveSheetContent(),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // SECTION 1: Continue reading (Only shown if user has actually opened/read books)
                      if (provider.continueShelf.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Continue reading",
                              style: AppTypography.fraunces(fontSize: 15.5, fontWeight: FontWeight.w700),
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => const ContinueReadingScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "SEE ALL",
                                      style: AppTypography.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.moss,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.moss),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 195,
                          child: Builder(
                            builder: (context) {
                              List<BookItem> books = provider.continueShelf;
                              if (provider.selectedTag.toLowerCase() != 'all') {
                                final sel = provider.selectedTag.toLowerCase();
                                books = books.where((b) {
                                  final tag = b.tag.toLowerCase();
                                  return tag == sel || tag.contains(sel) || sel.contains(tag);
                                }).toList();
                              }

                              if (books.isEmpty) {
                                return Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.paperSoft,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Text(
                                    "No active books in \"${provider.selectedTag}\"",
                                    style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                                  ),
                                );
                              }

                              return ListView(
                                scrollDirection: Axis.horizontal,
                                children: books.map((book) {
                                  return ContinueBookCard(
                                    book: book,
                                    onTap: () => provider.openBook(book),
                                    onFavoriteToggle: () {
                                      provider.toggleFavorite(book.title);
                                      showEasyToast(
                                        context,
                                        book.isFavorite ? "Added to Favorites" : "Removed from Favorites",
                                      );
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // SECTION 2: Featured Reads (Curated Admin Catalog Only)
                      if (provider.featuredBooks.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Featured Reads",
                                  style: AppTypography.fraunces(fontSize: 15.5, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  "Hand-picked books & timeless ideas",
                                  style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute),
                                ),
                              ],
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => const ContinueReadingScreen(type: 'featured'),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "SEE ALL",
                                      style: AppTypography.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.moss,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.moss),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: Builder(
                            builder: (context) {
                              List<BookItem> featured = provider.featuredBooks;
                              if (provider.selectedTag.toLowerCase() != 'all') {
                                final sel = provider.selectedTag.toLowerCase();
                                featured = featured.where((b) {
                                  final tag = b.tag.toLowerCase();
                                  return tag == sel || tag.contains(sel) || sel.contains(tag);
                                }).toList();
                              }

                              if (featured.isEmpty) {
                                return Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.paperSoft,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.line),
                                  ),
                                  child: Text(
                                    "No featured reads in \"${provider.selectedTag}\"",
                                    style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                                  ),
                                );
                              }

                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: featured.take(8).length,
                                itemBuilder: (ctx, i) {
                                  final book = featured[i];
                                  return TrendingBookCard(
                                    book: book,
                                    badgeText: i == 0 ? "Bestseller" : (i == 1 ? "Popular" : null),
                                    onTap: () => provider.openBook(book),
                                    onFavoriteToggle: () {
                                      provider.toggleFavorite(book.title);
                                      showEasyToast(
                                        context,
                                        book.isFavorite ? "Saved to Favorites" : "Removed from Favorites",
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // SECTION 3: Custom Collections
                      Text(
                        "Collections",
                        style: AppTypography.fraunces(fontSize: 15.5, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 84,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ...provider.collections.map((col) {
                              final count = provider.getBookCountForCollection(col.tag);
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  provider.filterByCollection(col.tag);
                                  showEasyToast(context, "Showing: ${col.name}");
                                },
                                onLongPress: () => _showCollectionOptionsSheet(context, provider, col),
                                child: Container(
                                  width: 122,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(col.colorValue),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              col.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.fraunces(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                                            ),
                                          ),
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _showCollectionOptionsSheet(context, provider, col),
                                            child: const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(Icons.more_vert, size: 15, color: Colors.white70),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "$count item${count == 1 ? '' : 's'}",
                                        style: AppTypography.inter(fontSize: 10, color: Colors.white70),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: () => _showCreateCollectionDialog(context, provider),
                              child: Container(
                                width: 118,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0x3F241F17), width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_rounded, color: AppColors.textMute, size: 22),
                                    const SizedBox(height: 4),
                                    Text(
                                      "New collection",
                                      style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMute),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // SECTION 4: Your Library
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Your Library",
                                  style: AppTypography.fraunces(fontSize: 15.5, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  provider.userLibraryBooks.isEmpty
                                      ? "No items in your library yet"
                                      : "${provider.userLibraryBooks.length} item${provider.userLibraryBooks.length == 1 ? '' : 's'}",
                                  style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => provider.toggleFavoritesFilter(),
                                child: Row(
                                  children: [
                                    Icon(
                                      provider.showFavoritesOnly ? Icons.star : Icons.star_border,
                                      size: 13,
                                      color: provider.showFavoritesOnly ? AppColors.gold : AppColors.textMute,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Favorites",
                                      style: AppTypography.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: provider.showFavoritesOnly ? AppColors.gold : AppColors.textMute,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (ctx) => const AllBooksScreen(title: "Your Library"),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "SEE ALL",
                                        style: AppTypography.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.moss,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.moss),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (provider.showFavoritesOnly || provider.activeCollectionFilter != null) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => provider.clearFilter(),
                          child: Text(
                            "Clear active filter ✕",
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.moss,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),

                      // Filtered Library Items
                      _buildLibraryList(context, provider),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportChip({required IconData icon, required String title, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x3F241F17), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.textMute),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMute),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryList(BuildContext context, EasyReadProvider provider) {
    List<BookItem> items;
    if (provider.activeCollectionFilter != null) {
      final all = <BookItem>[];
      final seen = <String>{};
      for (var b in [...provider.libraryItems, ...provider.userLocalBooks, ...provider.continueShelf]) {
        final norm = b.title.trim().toLowerCase();
        if (!seen.contains(norm)) {
          seen.add(norm);
          all.add(b);
        }
      }
      items = all.where((i) {
        final tag = (provider.bookCollections[i.title.trim().toLowerCase()] ?? i.tag).toLowerCase();
        return tag == provider.activeCollectionFilter!.toLowerCase();
      }).toList();
    } else {
      // Use userLibraryBooks: all user books, web articles, pasted text, and imported documents
      items = provider.userLibraryBooks;
      if (provider.selectedTag.toLowerCase() != 'all') {
        final sel = provider.selectedTag.toLowerCase();
        items = items.where((i) {
          final tag = i.tag.toLowerCase();
          return tag == sel || tag.contains(sel) || sel.contains(tag);
        }).toList();
      }
    }
    if (provider.showFavoritesOnly) {
      items = items.where((i) => i.isFavorite).toList();
    }

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.menu_book_outlined, size: 36, color: AppColors.textMute),
              const SizedBox(height: 10),
              Text(
                provider.showFavoritesOnly
                    ? "No favorites yet — tap the star on anything to save it here."
                    : provider.activeCollectionFilter != null
                        ? "Nothing in this collection yet."
                        : "Your library is empty.\nImport a document, save an article from web, or paste text to get started!",
                style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(color: AppColors.line, height: 1),
      itemBuilder: (ctx, i) {
        final item = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => provider.openBook(item),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(Icons.menu_book, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.openBook(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.fraunces(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.meta ?? item.author ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showAddToCollectionSheet(context, provider, item),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Icon(
                    Icons.create_new_folder_outlined,
                    size: 18,
                    color: AppColors.textMute,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  provider.toggleFavorite(item.title);
                  showEasyToast(
                    context,
                    item.isFavorite ? "Added to Favorites" : "Removed from Favorites",
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 6.0, top: 8.0, bottom: 8.0),
                  child: Icon(
                    item.isFavorite ? Icons.star : Icons.star_border,
                    size: 18,
                    color: item.isFavorite ? AppColors.gold : AppColors.textMute,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _confirmDeleteDocument(context, provider, item),
                child: const Padding(
                  padding: EdgeInsets.only(left: 4.0, right: 4.0, top: 8.0, bottom: 8.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: AppColors.plum,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteDocument(BuildContext context, EasyReadProvider provider, BookItem book) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.plum.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.plum, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              "Remove from Library",
              style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${book.title}" from your library? It will also be removed from Continue Reading.',
          style: AppTypography.inter(fontSize: 13, color: AppColors.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text("Cancel", style: AppTypography.inter(fontSize: 13, color: AppColors.textMute, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plum,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              Navigator.pop(dCtx);
              provider.removeBookFromLibrary(book);
              showEasyToast(context, 'Removed from Library and Continue Reading');
            },
            child: Text(
              "Remove",
              style: AppTypography.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddToCollectionSheet(BuildContext context, EasyReadProvider provider, BookItem book) {
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
                  "No custom collections created yet.\nTap 'New collection' above to create one.",
                  style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ] else ...[
            ...provider.collections.map((col) {
              final isSelected = book.tag.toLowerCase() == col.tag.toLowerCase();
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

  void _showCollectionOptionsSheet(BuildContext context, EasyReadProvider provider, CollectionItem col) {
    final count = provider.libraryItems.where((i) => i.tag == col.tag).length;

    showEasyModalSheet(
      context: context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color(col.colorValue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      col.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "$count book${count == 1 ? '' : 's'} in this collection",
                      style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action 1: Filter / View Books
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pop(ctx);
              provider.filterByCollection(col.tag);
              showEasyToast(context, "Showing: ${col.name}");
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 18, color: AppColors.textDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "View books in this shelf",
                      style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action 2: Delete Collection
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteCollection(context, provider, col);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.plum),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Delete Collection",
                      style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.plum),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCollection(BuildContext context, EasyReadProvider provider, CollectionItem col) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paperSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete "${col.name}"?',
          style: AppTypography.fraunces(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        content: Text(
          'Are you sure you want to delete this custom shelf? The books inside will not be deleted, only the shelf category will be removed.',
          style: AppTypography.inter(fontSize: 12.5, color: AppColors.textDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: AppTypography.inter(fontWeight: FontWeight.w600, color: AppColors.textMute)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plum,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              provider.deleteCollection(col);
              Navigator.pop(ctx);
              showEasyToast(context, 'Deleted shelf "${col.name}"');
            },
            child: Text("Delete Shelf", style: AppTypography.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showCreateCollectionDialog(BuildContext context, EasyReadProvider provider) {
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

    final ctrl = TextEditingController();
    int selectedColor = 0xFF4B6B4A;
    final List<int> palette = [
      0xFF4B6B4A, // Moss Green
      0xFF2E4C6D, // Deep Navy
      0xFF6E3B4E, // Plum
      0xFF8B5A2B, // Warm Ochre
      0xFF7A3E65, // Burgundy
      0xFFC28B38, // Gold
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.paperSoft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Create New Shelf", style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("NAME", style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: AppTypography.inter(fontSize: 13.5, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: "e.g. Favorite Classics, Night Reads",
                  hintStyle: AppTypography.inter(fontSize: 12.5, color: AppColors.textMute),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.moss, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              Text("COLOR THEME", style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: palette.map((col) {
                  final isSelected = selectedColor == col;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = col),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(col),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                        boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)] : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text("Cancel", style: AppTypography.inter(fontWeight: FontWeight.w600, color: AppColors.textMute)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.moss,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) {
                  provider.createCollection(name, colorValue: selectedColor);
                  Navigator.of(ctx).pop();
                  showEasyToast(context, 'Created shelf "$name"');
                }
              },
              child: Text("Create Shelf", style: AppTypography.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
