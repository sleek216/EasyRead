import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/easy_word_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../models/book_item.dart';
import '../widgets/bottom_sheet_wrapper.dart';
import 'web_save_sheet.dart';

class SearchSheetContent extends StatefulWidget {
  const SearchSheetContent({super.key});

  @override
  State<SearchSheetContent> createState() => _SearchSheetContentState();
}

class _SearchSheetContentState extends State<SearchSheetContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BookItem> _results = [];

  void _onSearch(String query, EasyReadProvider provider) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final seen = <String>{};
    final matches = <BookItem>[];
    final all = [...provider.continueShelf, ...provider.userLocalBooks, ...provider.libraryItems];

    for (final b in all) {
      final norm = b.title.trim().toLowerCase();
      if (seen.contains(norm)) continue;

      final titleMatch = b.title.toLowerCase().contains(q);
      final authorMatch = b.author?.toLowerCase().contains(q) ?? false;
      final tagMatch = b.tag.toLowerCase().contains(q);
      final metaMatch = b.meta?.toLowerCase().contains(q) ?? false;

      if (titleMatch || authorMatch || tagMatch || metaMatch) {
        seen.add(norm);
        matches.add(b);
      }
    }

    setState(() => _results = matches);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 20, color: AppColors.moss),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (val) => _onSearch(val, provider),
                  style: AppTypography.inter(fontSize: 13.5, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: "Search titles, authors, keywords...",
                    hintStyle: AppTypography.inter(fontSize: 13.5, color: AppColors.textMute),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (_searchCtrl.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    _onSearch('', provider);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.textMute),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_searchCtrl.text.isNotEmpty && _results.isEmpty) ...[
          if (_searchCtrl.text.trim().startsWith('http://') ||
              _searchCtrl.text.trim().startsWith('https://') ||
              _searchCtrl.text.trim().startsWith('www.') ||
              _searchCtrl.text.trim().contains('.com') ||
              _searchCtrl.text.trim().contains('.org'))
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.paperSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.language_outlined, size: 28, color: AppColors.gold),
                  const SizedBox(height: 8),
                  Text(
                    "Web Article Link Detected",
                    style: AppTypography.fraunces(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "This looks like an article URL. Use 'Save from Web' to read this article in distraction-free mode.",
                    textAlign: TextAlign.center,
                    style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        resetSheetGuard();
                        showEasyModalSheet(
                          context: context,
                          builder: (ctx) => const WebSaveSheetContent(),
                        );
                      },
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text("Open 'Save from Web'"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.moss,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No matches for "${_searchCtrl.text}" — try a different title or author.',
                textAlign: TextAlign.center,
                style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
              ),
            ),
        ],
        if (_results.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              "${_results.length} result${_results.length == 1 ? '' : 's'} found",
              style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMute),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.line, height: 1),
              itemBuilder: (ctx, i) {
                final item = _results[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  leading: Container(
                    width: 42,
                    height: 54,
                    decoration: BoxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu_book, color: Colors.white, size: 18),
                  ),
                  title: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.fraunces(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      if (item.author != null && item.author!.isNotEmpty) ...[
                        Flexible(
                          child: Text(
                            item.author!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text("•", style: TextStyle(fontSize: 10, color: AppColors.textMute)),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        item.meta ?? "5 min read",
                        style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMute),
                  onTap: () {
                    Navigator.of(context).pop();
                    provider.openBook(item);
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}
