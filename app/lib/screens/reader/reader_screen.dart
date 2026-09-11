import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/easy_word_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/bottom_sheet_wrapper.dart';
import '../../widgets/easy_toast.dart';
import '../../sheets/reading_settings_sheet.dart';
import '../../sheets/highlights_sheet.dart';
import '../../sheets/upgrade_sheet.dart';
import '../../services/api_service.dart';
import '../../models/book_item.dart';
import '../../sheets/feature_upgrade_sheet.dart';
import 'widgets/def_card_overlay.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int? activeToolbarIndex;
  int? activeHighlightIndex;
  final Map<int, String> aiResponses = {};
  final Map<int, String> aiActionLabels = {};
  final Map<int, bool> aiLoading = {};
  final Map<int, TextEditingController> noteControllers = {};

  OverlayEntry? _defOverlay;
  String? _tappedWord;
  Offset? _defCardTapPosition;
  final ScrollController _scrollController = ScrollController();
  bool _isAutoRestoringScroll = false;
  String? _lastRestoredTitle;
  final Map<int, GlobalKey> _paragraphKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }


  void _resetBookSpecificState() {
    _removeOverlay();
    activeToolbarIndex = null;
    activeHighlightIndex = null;
    aiResponses.clear();
    aiActionLabels.clear();
    aiLoading.clear();
    for (var controller in noteControllers.values) {
      controller.dispose();
    }
    noteControllers.clear();
    _paragraphKeys.clear();
  }

  void _checkAndRestoreScrollPosition(EasyReadProvider provider) {
    // 1. If provider signaled a reset, force jump to top 0
    if (provider.readerShouldResetScroll && provider.readerTitle == _lastRestoredTitle) {
      provider.readerShouldResetScroll = false;
      _resetBookSpecificState();
      _isAutoRestoringScroll = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _isAutoRestoringScroll = false;
        });
      });
      return;
    }

    if (_lastRestoredTitle != provider.readerTitle) {
      _lastRestoredTitle = provider.readerTitle;
      _resetBookSpecificState();
      final savedProg = provider.getBookProgress(provider.readerTitle);
      if (savedProg > 3) {
        _isAutoRestoringScroll = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
            final target = _scrollController.position.maxScrollExtent * (savedProg / 100.0);
            _scrollController.jumpTo(target.clamp(0.0, _scrollController.position.maxScrollExtent));
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _isAutoRestoringScroll = false;
            });
            showEasyToast(context, "Resumed at $savedProg% where you left off 📖");
          } else {
            _isAutoRestoringScroll = false;
          }
        });
      } else {
        // Book progress is 0% (Start Over / fresh read)! Jump to top!
        _isAutoRestoringScroll = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) _isAutoRestoringScroll = false;
          });
        });
      }
    }
  }

  void _onScroll() {
    if (_tappedWord != null || _defCardTapPosition != null) {
      _removeOverlay();
    }
    if (_isAutoRestoringScroll || !_scrollController.hasClients) return;
    // CRITICAL: Only record reading progress when user physically scrolls with finger!
    // Never trigger on tab switch, programmatic jump, or background layout recalculation!
    if (!_scrollController.position.isScrollingNotifier.value) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0 && currentScroll > 15) {
      final progressPercent = ((currentScroll / maxScroll) * 100).clamp(1, 100).toInt();
      final provider = context.read<EasyReadProvider>();
      provider.updateCurrentBookProgress(progressPercent);
    }
  }

  void _scrollToParagraph(int pIdx) {
    if (!_scrollController.hasClients) return;
    final provider = context.read<EasyReadProvider>();
    if (pIdx < 0 || pIdx >= provider.articleParagraphs.length) return;

    setState(() {
      activeHighlightIndex = pIdx;
    });

    void tryEnsureVisible() {
      final key = _paragraphKeys[pIdx];
      final currentContext = key?.currentContext;
      if (currentContext != null) {
        Scrollable.ensureVisible(
          currentContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
    }

    final key = _paragraphKeys[pIdx];
    if (key?.currentContext != null) {
      tryEnsureVisible();
    } else {
      double estimatedOffset = 140.0;
      for (int i = 0; i < pIdx; i++) {
        final pText = provider.articleParagraphs[i];
        final lines = (pText.length / 40.0).ceil().clamp(1, 100);
        estimatedOffset += (lines * 28.0) + 70.0;
      }

      _scrollController.jumpTo(estimatedOffset);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final k2 = _paragraphKeys[pIdx];
        if (k2?.currentContext != null) {
          tryEnsureVisible();
        } else {
          // Fallback: wait a bit more for layout if it jumped really far
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) tryEnsureVisible();
          });
        }
      });
    }
  }

  @override
  void deactivate() {
    _removeOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _removeOverlay();
    for (var c in noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showAddToCollectionModal(BuildContext context, EasyReadProvider provider, {BookItem? targetBook}) {
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

    final book = targetBook ??
        provider.libraryItems.firstWhere(
          (b) => b.title == provider.readerTitle,
          orElse: () => BookItem(
            title: provider.readerTitle,
            color: AppColors.moss,
            tag: 'general',
            paragraphs: provider.articleParagraphs,
          ),
        );

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

  void _removeOverlay() {
    _defOverlay?.remove();
    _defOverlay = null;
    if (_tappedWord != null || _defCardTapPosition != null) {
      setState(() {
        _tappedWord = null;
        _defCardTapPosition = null;
      });
    }
  }

  void _showDefinitionOverlay(BuildContext context, String word, Offset globalPosition) {
    _removeOverlay();
    setState(() {
      _tappedWord = word;
      _defCardTapPosition = globalPosition;
    });
  }

  void _showLanguagePickerAndTranslate(int pIdx, String passage) {
    final provider = context.read<EasyReadProvider>();
    // Auto-ping Admin settings immediately on tap
    provider.fetchTranslationLanguages();

    final textController = TextEditingController(text: provider.selectedTranslationLanguage);

    showEasyModalSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final prov = ctx.watch<EasyReadProvider>();
          final languages = prov.availableTranslationLanguages;

          void executeTranslation(String targetLanguage) {
            final cleanLang = targetLanguage.trim();
            if (cleanLang.isEmpty) return;
            prov.setTranslationLanguage(cleanLang);
            Navigator.of(ctx).pop();
            _runAiAction(pIdx, 'translate', passage, targetLang: cleanLang);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.moss.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.translate, size: 18, color: AppColors.moss),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Translate Passage",
                          style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "Type any language or select from below",
                          style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Custom Language Input Box with "Translate" Action Button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.paperSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.moss),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: textController,
                        autofocus: false,
                        textInputAction: TextInputAction.done,
                        style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        decoration: InputDecoration(
                          hintText: "Type language (e.g. Urdu, French, German...)",
                          hintStyle: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (value) => executeTranslation(value),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.moss,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => executeTranslation(textController.text),
                      child: Text(
                        "Translate",
                        style: AppTypography.inter(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              Text(
                "Available Languages:",
                style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMute),
              ),
              const SizedBox(height: 8),

              // Quick Selection Chips & List
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: languages.map((lang) {
                      final isSelected = lang.toLowerCase() == textController.text.trim().toLowerCase();
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            textController.text = lang;
                          });
                          executeTranslation(lang);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.moss : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.moss : AppColors.line,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check, size: 12, color: Colors.white),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                lang,
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _runAiAction(int pIdx, String action, String passage, {String? targetLang}) async {
    final provider = context.read<EasyReadProvider>();
    final isPremiumAction = (action == 'explain');
    final hasAi = provider.hasFeature('unlimited_ai') || provider.isPremium;

    // Must be logged in to use AI
    if (!provider.isLoggedIn) {
      setState(() {
        aiLoading[pIdx] = false;
        aiResponses[pIdx] = '⚠️ Please log in to use AI features.';
        aiActionLabels[pIdx] = 'LOGIN REQUIRED';
      });
      return;
    }

    if (isPremiumAction && !hasAi) {
      setState(() => activeToolbarIndex = null);
      showEasyModalSheet(
        context: context,
        force: true,
        builder: (ctx) => const UpgradeSheetContent(),
      );
      return;
    }

    if (!isPremiumAction && !hasAi) {
      if (provider.aiFreeUsesLeft <= 0) {
        setState(() => activeToolbarIndex = null);
        showEasyToast(context, "You've used today's free AI lookups");
        showEasyModalSheet(
          context: context,
          force: true,
          builder: (ctx) => const UpgradeSheetContent(),
        );
        return;
      }
    }

    final lang = targetLang ?? provider.selectedTranslationLanguage;

    String label = "ASSISTANT RESPONSE";
    if (action == 'simplify') label = "SIMPLIFIED PASSAGE";
    if (action == 'summarize') label = "CORE SUMMARY";
    if (action == 'explain') label = "KEY TERMS EXPLAINED";
    if (action == 'translate') label = "TRANSLATION ($lang)";

    setState(() {
      activeToolbarIndex = null;
      aiLoading[pIdx] = true;
      aiResponses.remove(pIdx);
      aiActionLabels[pIdx] = label;
    });

    try {
      final res = await ApiService.runAiAction(
        action: action,
        passage: passage,
        targetLanguage: lang,
      );

      if (!mounted) return;

      if (res['free_uses_left'] != null) {
        provider.aiFreeUsesLeft = res['free_uses_left'];
      }

      final response = res['response'];
      final success = res['success'] == true;

      setState(() {
        aiLoading[pIdx] = false;
        if (success && response != null && response.toString().isNotEmpty) {
          final cleanText = response.toString().replaceAll('**', '').replaceAll('__', '');
          aiResponses[pIdx] = cleanText;
        } else if (res['is_paywall'] == true) {
          aiResponses[pIdx] = '⭐ Upgrade to EasyRead Plus for unlimited AI access.';
        } else {
          aiResponses[pIdx] = response?.toString() ?? '⚠️ AI response unavailable. Please try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        aiLoading[pIdx] = false;
        aiResponses[pIdx] = '⚠️ Could not connect to AI service. Check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    _checkAndRestoreScrollPosition(provider);

    // If active tab is no longer reader, auto-dismiss any active definition card!
    if (provider.activeTab != 'reader' && (_tappedWord != null || _defCardTapPosition != null)) {
      _defOverlay?.remove();
      _defOverlay = null;
      _tappedWord = null;
      _defCardTapPosition = null;
    }

    return Scaffold(
      backgroundColor: provider.readerBackground,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Navigation & Action tools
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      _buildCircleBtn(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () {
                          _removeOverlay();
                          if (!provider.handleBackNavigation()) {
                            provider.switchTab('library');
                          }
                        },
                      ),
                  Expanded(
                    child: Center(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "SMART MODE ",
                              style: AppTypography.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMute,
                                letterSpacing: 0.6,
                              ),
                            ),
                            TextSpan(
                              text: provider.smartReaderMode ? "ON" : "OFF",
                              style: AppTypography.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: provider.smartReaderMode ? AppColors.moss : AppColors.textMute,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCircleBtn(
                        icon: provider.isFavorite(provider.readerTitle) ? Icons.bookmark : Icons.bookmark_border,
                        color: provider.isFavorite(provider.readerTitle) ? AppColors.gold : null,
                        onTap: () {
                          provider.toggleFavorite(provider.readerTitle);
                          showEasyToast(
                            context,
                            provider.isFavorite(provider.readerTitle) ? "Added to bookmarks" : "Removed from bookmarks",
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                      _buildCircleBtn(
                        icon: Icons.create_new_folder_outlined,
                        onTap: () => _showAddToCollectionModal(context, provider),
                      ),
                      const SizedBox(width: 5),
                      _buildCircleBtn(
                        icon: Icons.edit_note,
                        onTap: () {
                          showEasyModalSheet(
                            context: context,
                            builder: (ctx) => HighlightsSheetContent(
                              onGoToParagraph: (pIdx) => _scrollToParagraph(pIdx),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 5),
                      _buildCircleBtn(
                        icon: provider.isSpeaking ? Icons.stop_rounded : Icons.volume_up_outlined,
                        color: provider.isSpeaking ? Colors.white : null,
                        bgColor: provider.isSpeaking ? AppColors.moss : null,
                        onTap: () async {
                          final started = await provider.toggleSpeakArticle();
                          if (context.mounted) {
                            showEasyToast(
                              context,
                              started ? "Reading article aloud 🔊" : "Speech stopped ⏹",
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 5),
                      _buildCircleBtn(
                        icon: Icons.tune,
                        onTap: () {
                          showEasyModalSheet(
                            context: context,
                            builder: (ctx) => const ReadingSettingsSheetContent(),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.line, height: 1),

            // Main Reader Content Scroll (Virtualized for 200+ pages performance)
            Expanded(
              child: provider.isDocumentLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(color: AppColors.moss, strokeWidth: 3),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "Opening Document...",
                            style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Extracting clean reader text for you",
                            style: AppTypography.inter(fontSize: 12.5, color: AppColors.textMute),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
                      itemCount: 1 + provider.articleParagraphs.length + 1,
                      itemBuilder: (context, index) {
                  // Index 0: Header (Banner + Title + Byline)
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.smartReaderMode) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0x1F4B6B4A),
                              border: Border.all(color: const Color(0x404B6B4A)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.moss),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.smartBannerText,
                                    style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.moss),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          provider.readerTitle,
                          style: AppTypography.fraunces(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: provider.readerTextColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.readerByline,
                          style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }

                  // Last item: End of Reading Completion & Re-read Card
                  if (index == provider.articleParagraphs.length + 1) {
                    return Container(
                      margin: const EdgeInsets.only(top: 20, bottom: 90),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.paperSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.moss.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.moss, size: 28),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Finished Reading!",
                            style: AppTypography.fraunces(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "This book is marked as 100% Completed in your library.",
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.restart_alt_rounded, size: 16, color: AppColors.moss),
                                  label: Text(
                                    "Start Over",
                                    style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.moss),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.moss),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    _isAutoRestoringScroll = true;
                                    provider.resetBookProgress(provider.readerTitle);
                                    _scrollController.animateTo(
                                      0,
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeOut,
                                    ).then((_) {
                                      if (mounted) _isAutoRestoringScroll = false;
                                    });
                                    showEasyToast(context, "Progress reset to 0% — Happy Re-reading!");
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.library_books_rounded, size: 16, color: Colors.white),
                                  label: Text(
                                    "Library",
                                    style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.moss,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    provider.switchTab('library');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  // Paragraph item
                  final pIdx = index - 1;
                  final text = provider.articleParagraphs[pIdx];
                  final hl = provider.getHighlight(pIdx);
                  final hasAi = aiResponses.containsKey(pIdx);
                  final isLoadingAi = aiLoading[pIdx] == true;

                  return Container(
                    key: _paragraphKeys.putIfAbsent(pIdx, () => GlobalKey()),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInteractiveParagraph(context, text, pIdx, hl, provider),
                      if (hl?.note != null && hl!.note.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.paperSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit, size: 11, color: AppColors.gold),
                              const SizedBox(width: 5),
                              Text(
                                hl.note,
                                style: AppTypography.inter(
                                  fontSize: 11,
                                  color: AppColors.textDark,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                activeHighlightIndex = null;
                                activeToolbarIndex = activeToolbarIndex == pIdx ? null : pIdx;
                              });
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.auto_awesome, size: 12, color: AppColors.gold),
                                const SizedBox(width: 4),
                                Text(
                                  "Ask about this passage",
                                  style: AppTypography.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                activeToolbarIndex = null;
                                activeHighlightIndex = activeHighlightIndex == pIdx ? null : pIdx;
                              });
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.brush_outlined, size: 12, color: AppColors.plum),
                                const SizedBox(width: 4),
                                Text(
                                  "Highlight",
                                  style: AppTypography.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.plum,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Highlight Popover
                      if (activeHighlightIndex == pIdx) ...[
                        const SizedBox(height: 8),
                        _buildHighlightPopover(context, pIdx, hl, provider),
                      ],

                      // AI Toolbar
                      if (activeToolbarIndex == pIdx) ...[
                        const SizedBox(height: 8),
                        _buildAiToolbar(context, pIdx, text, provider),
                      ],

                      // AI Loading & Result
                      if (isLoadingAi) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.paperSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: const Border(left: BorderSide(color: AppColors.gold, width: 3)),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                              ),
                              const SizedBox(width: 10),
                              Text("Thinking...", style: AppTypography.inter(fontSize: 12, color: AppColors.textMute)),
                            ],
                          ),
                        ),
                      ] else if (hasAi) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.paperSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: const Border(left: BorderSide(color: AppColors.gold, width: 3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                aiActionLabels[pIdx] ?? "ASSISTANT RESPONSE",
                                style: AppTypography.inter(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.moss),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                aiResponses[pIdx]!,
                                style: AppTypography.literata(fontSize: 13.5, color: AppColors.textDark, height: 1.6),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => setState(() => aiResponses.remove(pIdx)),
                                child: Text(
                                  "Close",
                                  style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMute),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                    ],
                  ),
                );
                },
              ),
            ),
          ],
        ),
      ),
      if (_tappedWord != null && _defCardTapPosition != null)
        DefinitionCardOverlay(
          word: _tappedWord!,
          entry: provider.getWordData(_tappedWord!),
          isSaved: provider.isWordSaved(_tappedWord!),
          tapPosition: _defCardTapPosition!,
          onSpeak: () => provider.speakWord(_tappedWord!),
          onSaveWithEntry: (liveEntry) {
            final saved = provider.toggleSaveWord(
              _tappedWord!,
              meaning: liveEntry.meaning,
              pos: liveEntry.pos,
              example: liveEntry.example,
              sourceTitle: provider.readerTitle,
            );
            if (!saved && !provider.isPremium && provider.vocabWords.length >= EasyReadProvider.freeVocabLimit) {
              _removeOverlay();
              showEasyModalSheet(
                context: context,
                builder: (c) => const UpgradeSheetContent(),
              );
              return;
            }
            showEasyToast(context, saved ? '"$_tappedWord" saved to Your Words' : 'Removed from Your Words');
            _removeOverlay();
          },
          onToggleSave: () {
            final entry = provider.getWordData(_tappedWord!);
            final saved = provider.toggleSaveWord(
              _tappedWord!,
              meaning: entry.meaning,
              pos: entry.pos,
              example: entry.example,
              sourceTitle: provider.readerTitle,
            );
            if (!saved && !provider.isPremium && provider.vocabWords.length >= EasyReadProvider.freeVocabLimit) {
              _removeOverlay();
              showEasyModalSheet(
                context: context,
                builder: (c) => const UpgradeSheetContent(),
              );
              return;
            }
            showEasyToast(context, saved ? '"$_tappedWord" saved to Your Words' : 'Removed from Your Words');
            _removeOverlay();
          },
          onClose: _removeOverlay,
        ),
    ],
  ),
);
  }

  Widget _buildInteractiveParagraph(
    BuildContext context,
    String text,
    int pIdx,
    dynamic hl,
    EasyReadProvider provider,
  ) {
    Color? hlBg;
    if (hl != null) {
      if (hl.color == 'yellow') hlBg = AppColors.hlYellow.withValues(alpha: 0.35);
      if (hl.color == 'green') hlBg = AppColors.hlGreen.withValues(alpha: 0.35);
      if (hl.color == 'pink') hlBg = AppColors.hlPink.withValues(alpha: 0.3);
    }

    final words = text.split(RegExp(r'\s+'));
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      if (w.isEmpty) continue;
      final clean = w.toLowerCase().replaceAll(RegExp(r"[^a-zA-Z]"), '');
      final isTapped = _tappedWord == clean && clean.isNotEmpty;
      final isSaved = clean.isNotEmpty && provider.isWordSaved(clean);

      Color? wordColor = provider.readerTextColor;
      Color? wordBg;
      FontWeight fontWeight = FontWeight.normal;

      if (isTapped) {
        wordColor = AppColors.gold;
        wordBg = AppColors.gold.withValues(alpha: 0.25);
        fontWeight = FontWeight.w600;
      } else if (isSaved) {
        wordColor = AppColors.moss;
        wordBg = AppColors.moss.withValues(alpha: 0.18);
        fontWeight = FontWeight.w600;
      }

      spans.add(
        TextSpan(
          text: i == words.length - 1 ? w : '$w ',
          style: AppTypography.literata(
            fontSize: provider.readerFontSize,
            color: wordColor,
            fontWeight: fontWeight,
            height: 1.85,
          ).copyWith(backgroundColor: wordBg),
          recognizer: TapGestureRecognizer()
            ..onTapDown = (details) {
              if (clean.isNotEmpty) {
                _showDefinitionOverlay(context, clean, details.globalPosition);
              }
            },
        ),
      );
    }

    final isCurrentSpeaking = provider.isSpeaking && provider.currentSpeakingParagraph == pIdx;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentSpeaking
            ? AppColors.moss.withValues(alpha: 0.12)
            : hlBg,
        borderRadius: BorderRadius.circular(6),
        border: isCurrentSpeaking
            ? Border.all(color: AppColors.moss.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Text.rich(
        TextSpan(children: spans),
      ),
    );
  }

  Widget _buildHighlightPopover(BuildContext context, int pIdx, dynamic hl, EasyReadProvider provider) {
    if (!noteControllers.containsKey(pIdx)) {
      noteControllers[pIdx] = TextEditingController(text: hl?.note ?? '');
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildColorDot(pIdx, 'yellow', AppColors.hlYellow, hl?.color == 'yellow', provider),
              const SizedBox(width: 8),
              _buildColorDot(pIdx, 'green', AppColors.hlGreen, hl?.color == 'green', provider),
              const SizedBox(width: 8),
              _buildColorDot(pIdx, 'pink', AppColors.hlPink, hl?.color == 'pink', provider),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  provider.removeHighlight(pIdx);
                  setState(() => activeHighlightIndex = null);
                  showEasyToast(context, "Highlight removed");
                },
                child: Text(
                  "Clear",
                  style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMute),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteControllers[pIdx],
            style: AppTypography.inter(fontSize: 12),
            decoration: InputDecoration(
              hintText: "Write a note about this passage...",
              hintStyle: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.moss,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              elevation: 0,
            ),
            onPressed: () {
              final note = noteControllers[pIdx]?.text.trim() ?? '';
              provider.saveNote(pIdx, note);
              setState(() => activeHighlightIndex = null);
              showEasyToast(context, note.isNotEmpty ? "Note saved" : "Note cleared");
            },
            child: Text("Save note", style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(int pIdx, String colorName, Color color, bool active, EasyReadProvider provider) {
    return GestureDetector(
      onTap: () {
        provider.setHighlight(pIdx, colorName);
        showEasyToast(context, "Highlighted");
      },
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: active ? AppColors.textDark : Colors.transparent, width: 2),
        ),
      ),
    );
  }

  Widget _buildAiToolbar(BuildContext context, int pIdx, String passage, EasyReadProvider provider) {
    final hasAi = provider.hasFeature('unlimited_ai') || provider.isPremium;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _buildAiBtn(Icons.short_text, "Simplify", () => _runAiAction(pIdx, 'simplify', passage)),
        _buildAiBtn(Icons.summarize_outlined, "Summarize", () => _runAiAction(pIdx, 'summarize', passage)),
        _buildAiBtn(
          Icons.help_outline,
          "Explain terms",
          () => _runAiAction(pIdx, 'explain', passage),
          isLocked: !hasAi && provider.aiFreeUsesLeft <= 0,
        ),
        _buildAiBtn(
          Icons.translate,
          "Translate",
          () => _showLanguagePickerAndTranslate(pIdx, passage),
          isLocked: !hasAi && provider.aiFreeUsesLeft <= 0,
        ),
      ],
    );
  }

  Widget _buildAiBtn(IconData icon, String label, VoidCallback onTap, {bool isLocked = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.paperSoft,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppColors.textDark),
            const SizedBox(width: 5),
            Text(label, style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w600)),
            if (isLocked) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock, size: 10, color: AppColors.gold),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    Color? bgColor,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.paperSoft,
          shape: BoxShape.circle,
          border: Border.all(color: bgColor ?? AppColors.line),
        ),
        child: Icon(icon, size: 16, color: color ?? AppColors.textDark),
      ),
    );
  }
}
