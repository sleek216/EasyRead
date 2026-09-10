import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_item.dart';
import '../../providers/easy_word_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bottom_sheet_wrapper.dart';
import '../../widgets/easy_toast.dart';

class AllBooksScreen extends StatefulWidget {
  final String title;
  const AllBooksScreen({super.key, this.title = "Featured Reads & Catalog"});

  @override
  State<AllBooksScreen> createState() => _AllBooksScreenState();
}

class _AllBooksScreenState extends State<AllBooksScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isGridView = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddToCollectionModal(BuildContext context, EasyReadProvider provider, BookItem book) {
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
          const SizedBox(height: 4),
          Text(
            'Organize "${book.title}" into your custom shelves',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
          ),
          const SizedBox(height: 14),
          if (provider.collections.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  "No custom collections yet.\nCreate one from the Library screen.",
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.moss : AppColors.line,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
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
                            fontSize: 13.5,
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final allCategories = provider.dynamicCategoryTags;

    // Filter books based on category, search query
    List<BookItem> filteredBooks = (widget.title == "Your Library" || widget.title == "Recent Views")
        ? provider.userLibraryBooks
        : provider.featuredBooks;

    if (_selectedCategory.toLowerCase() != 'all') {
      final cat = _selectedCategory.toLowerCase();
      filteredBooks = filteredBooks.where((b) {
        final tag = b.tag.toLowerCase();
        return tag == cat || tag.contains(cat) || cat.contains(tag);
      }).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      filteredBooks = filteredBooks.where((b) {
        return b.title.toLowerCase().contains(query) ||
            (b.author ?? '').toLowerCase().contains(query) ||
            b.tag.toLowerCase().contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                          widget.title,
                          style: AppTypography.fraunces(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          "${filteredBooks.length} book${filteredBooks.length == 1 ? '' : 's'} available",
                          style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                      color: AppColors.textDark,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.line, height: 1),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textMute, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: AppTypography.inter(fontSize: 12.5, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: "Search by title, author, or topic...",
                          hintStyle: AppTypography.inter(fontSize: 12.5, color: AppColors.textMute),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(Icons.close, size: 16, color: AppColors.textMute),
                      ),
                  ],
                ),
              ),
            ),

            // Category Filter Chips
            SizedBox(
              height: 32,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: allCategories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final cat = allCategories[i];
                  final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();

                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.moss : AppColors.paperSoft,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isSelected ? AppColors.moss : AppColors.line),
                      ),
                      child: Text(
                        cat,
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Main Books Content
            Expanded(
              child: filteredBooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.paperSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: const Icon(Icons.menu_book_outlined, size: 26, color: AppColors.textMute),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No books found",
                            style: AppTypography.fraunces(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? "Try a different search term"
                                : "No books in this category yet",
                            style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                          ),
                        ],
                      ),
                    )
                  : _isGridView
                      ? _buildGridView(context, provider, filteredBooks)
                      : _buildListView(context, provider, filteredBooks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, EasyReadProvider provider, List<BookItem> books) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(color: AppColors.line, height: 1),
      itemBuilder: (ctx, i) {
        final book = books[i];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  provider.openBook(book);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 44,
                  height: 58,
                  decoration: BoxDecoration(
                    color: book.color,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.menu_book, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    provider.openBook(book);
                    Navigator.pop(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: AppTypography.fraunces(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${book.author ?? 'Library Book'}${book.meta != null && book.meta!.isNotEmpty ? ' · ${book.meta}' : ''}",
                        style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.moss.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          book.tag.toUpperCase(),
                          style: AppTypography.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.moss, letterSpacing: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: Icon(
                      book.isFavorite ? Icons.star : Icons.star_border,
                      size: 19,
                      color: book.isFavorite ? AppColors.gold : AppColors.textMute,
                    ),
                    onPressed: () {
                      provider.toggleFavorite(book.title);
                      showEasyToast(
                        context,
                        book.isFavorite ? "Saved to Favorites" : "Removed from Favorites",
                      );
                    },
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.folder_open_outlined, size: 17, color: AppColors.textMute),
                    onPressed: () => _showAddToCollectionModal(context, provider, book),
                  ),
                  if (provider.isUserDocument(book))
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: "Remove Document",
                      icon: const Icon(Icons.close_rounded, size: 19, color: AppColors.plum),
                      onPressed: () => _confirmDeleteDocument(context, provider, book),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, EasyReadProvider provider, List<BookItem> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (ctx, i) {
        final book = books[i];

        final card = Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: book.color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.menu_book, color: Colors.white70, size: 36),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: AppTypography.fraunces(fontSize: 13, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author ?? "Library Book",
                        style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

        return GestureDetector(
          onTap: () {
            provider.openBook(book);
            Navigator.pop(context);
          },
          onLongPress: () => _showAddToCollectionModal(context, provider, book),
          child: (widget.title == "Your Library" || widget.title == "Recent Views" || provider.isUserDocument(book))
              ? Stack(
                  children: [
                    card,
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _confirmDeleteDocument(context, provider, book),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.close_rounded, size: 15, color: AppColors.plum),
                        ),
                      ),
                    ),
                  ],
                )
              : card,
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
}
