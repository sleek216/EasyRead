import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/easy_word_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_top_bar.dart';
import '../../widgets/easy_toast.dart';
import '../../services/vocab_export_service.dart';
import 'flashcards_screen.dart';

class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  bool isCardsMode = false;
  bool _learnedSheetOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EasyReadProvider>(context, listen: false);
      for (final w in provider.vocabWords) {
        provider.getWordData(w);
      }
      for (final w in provider.masteredWords) {
        provider.getWordData(w);
      }
    });
  }

  void _showLearnedWordsModal(BuildContext context, EasyReadProvider provider) {
    if (_learnedSheetOpen) return;
    _learnedSheetOpen = true;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, modalSetState) {
            final updatedLearned = provider.masteredWords.toList();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Learned Words (${updatedLearned.length})",
                        style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "These words were marked as 'Got it' and removed from your active saved list.",
                    style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                  ),
                  const SizedBox(height: 14),
                  if (updatedLearned.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          "No learned words yet. Practice saved cards and tap 'Got it'!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMute, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: updatedLearned.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final word = updatedLearned[i];
                          final data = provider.getWordData(word);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.moss, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        word,
                                        style: AppTypography.fraunces(fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        data.meaning,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    provider.markWordAsMastered(word, false);
                                    modalSetState(() {});
                                    showEasyToast(context, "'$word' moved back to saved list");
                                  },
                                  child: Text(
                                    "Un-learn",
                                    style: AppTypography.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _learnedSheetOpen = false;
    });
  }

  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final vocabList = provider.vocabWords;
    final savedBooks = provider.libraryItems.where((b) => b.isFavorite).toList();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomAppTopBar(
              title: "Saved Items",
              trailing: Row(
                children: [
                  GestureDetector(
                    onTap: () => VocabExportService.showExportOptionsSheet(context, provider),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.paperSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Icons.file_download_outlined, size: 16, color: AppColors.textDark),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (vocabList.isEmpty) {
                        showEasyToast(context, "Save some words first to practice them");
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const FlashcardsScreen()),
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
                      child: const Icon(Icons.style_outlined, size: 16, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? AppColors.moss : AppColors.paperSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: _selectedTab == 0 ? null : Border.all(color: AppColors.line),
                        ),
                        alignment: Alignment.center,
                        child: Text("Vocabulary", style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _selectedTab == 0 ? Colors.white : AppColors.textDark)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? AppColors.moss : AppColors.paperSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: _selectedTab == 1 ? null : Border.all(color: AppColors.line),
                        ),
                        alignment: Alignment.center,
                        child: Text("Saved Books", style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _selectedTab == 1 ? Colors.white : AppColors.textDark)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedTab == 0)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live Stats Row
                    Row(
                      children: [
                        _buildStatBox("${vocabList.length}", "SAVED", () {}),
                        const SizedBox(width: 10),
                        _buildStatBox("${provider.dayStreak}", "DAY STREAK", () {}),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          "${provider.masteredWordsCount}",
                          "LEARNED",
                          () => _showLearnedWordsModal(context, provider),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Practice button (Swipeable cards mode)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.moss,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        if (vocabList.isEmpty) {
                          showEasyToast(context, "Save some words first to practice them");
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (ctx) => const FlashcardsScreen()),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.style_outlined, size: 16, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            "Practice Swipeable Flashcards",
                            style: AppTypography.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Saved words (${vocabList.length})",
                          style: AppTypography.fraunces(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        if (vocabList.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => VocabExportService.showExportOptionsSheet(context, provider),
                            icon: const Icon(Icons.download, size: 14, color: AppColors.moss),
                            label: Text(
                              "Export Cards",
                              style: AppTypography.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.moss),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (vocabList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.menu_book, size: 40, color: Color(0x7F6B6154)),
                              const SizedBox(height: 12),
                              Text(
                                "Tap any word while reading and hit Save — it'll show up here, ready to review as swipeable flashcard cards.",
                                textAlign: TextAlign.center,
                                style: AppTypography.inter(fontSize: 12.5, color: AppColors.textMute, height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: vocabList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final word = vocabList[i];
                          final data = provider.getWordData(word);

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            word,
                                            style: AppTypography.fraunces(fontSize: 15, fontWeight: FontWeight.w600),
                                          ),
                                          if (data.pos.isNotEmpty && data.pos != 'word') ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              "(${data.pos})",
                                              style: AppTypography.inter(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: AppColors.gold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        data.meaning,
                                        style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute, height: 1.3),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "FROM: ${provider.readerTitle.toUpperCase()}",
                                        style: AppTypography.inter(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gold,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quick "Got it" action button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.paperSoft,
                                    foregroundColor: AppColors.moss,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: AppColors.line),
                                    ),
                                  ),
                                  onPressed: () {
                                    provider.markWordAsMastered(word, true);
                                    showEasyToast(context, "'$word' learned & removed from saved words!");
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check, size: 13, color: AppColors.moss),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Got it",
                                        style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.moss),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (c) => FlashcardsScreen(startIndex: i)),
                                    );
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.paperSoft,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.moss),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            if (_selectedTab == 1)
              Expanded(
                child: savedBooks.isEmpty
                    ? Center(
                        child: Text(
                          "No saved books yet.\nRead a book and tap the bookmark icon to save it.",
                          textAlign: TextAlign.center,
                          style: AppTypography.inter(fontSize: 13, color: AppColors.textMute),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        itemCount: savedBooks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final book = savedBooks[i];
                          return GestureDetector(
                            onTap: () => provider.openBook(book),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color: book.color ?? AppColors.moss,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.book, size: 20, color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          style: AppTypography.fraunces(fontSize: 14.5, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          book.author ?? "Library Book",
                                          style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.bookmark, color: AppColors.gold, size: 20),
                                    onPressed: () {
                                      provider.toggleFavorite(book.title);
                                      showEasyToast(context, "Removed from saved books");
                                    },
                                  ),
                                ],
                              ),
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

  Widget _buildStatBox(String number, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.paperSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              Text(
                number,
                style: AppTypography.fraunces(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.moss),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.inter(fontSize: 9.5, color: AppColors.textMute, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
