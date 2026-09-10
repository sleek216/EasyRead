import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../providers/easy_word_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/easy_toast.dart';
import '../../services/vocab_export_service.dart';

class FlashcardsScreen extends StatefulWidget {
  final int startIndex;
  const FlashcardsScreen({super.key, this.startIndex = 0});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  late List<String> sessionWords;
  List<String> toReviewNextRound = [];
  bool isRevealed = false;
  int masteredInSessionCount = 0;
  bool isDone = false;
  int currentCardIndex = 0;
  
  Key swiperKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<EasyReadProvider>(context, listen: false);
    sessionWords = List<String>.from(provider.vocabWords);
    
    // In a swipe stack, starting from a specific index means we should probably 
    // just put that card on top, or just use the list as is. For simplicity, 
    // we'll keep the list as is, since standard flashcard decks start from 0.
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final w in sessionWords) {
        provider.getWordData(w);
      }
    });
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  bool _isButtonSwipe = false;

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    setState(() {
      isRevealed = false;
      currentCardIndex = currentIndex ?? sessionWords.length;
    });

    final word = sessionWords[previousIndex];
    final provider = Provider.of<EasyReadProvider>(context, listen: false);

    // Only mark as learned if the Got It button was explicitly pressed.
    if ((direction == CardSwiperDirection.right || direction == CardSwiperDirection.top) && _isButtonSwipe) {
      provider.markWordAsMastered(word, true);
      masteredInSessionCount++;
      showEasyToast(context, "'$word' learned!");
    } else {
      // Finger swipes (left, right, top, bottom) just skip the card without learning it.
      toReviewNextRound.add(word);
    }
    
    _isButtonSwipe = false; // Reset for next interaction
    return true; // Return true to allow swipe
  }

  void _onEnd() {
    if (toReviewNextRound.isEmpty) {
      setState(() {
        isDone = true;
      });
    } else {
      showEasyToast(context, "Review round repeated. Keep going!");
      setState(() {
        sessionWords = List.from(toReviewNextRound);
        toReviewNextRound.clear();
        currentCardIndex = 0;
        swiperKey = UniqueKey(); // Force rebuild of CardSwiper for the new round
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final total = sessionWords.length;
    final displayIndex = (currentCardIndex >= total) ? total : currentCardIndex + 1;

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0x1FEFE6D0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: AppColors.paper, size: 18),
                    ),
                  ),
                  Text(
                    isDone ? "Completed" : "Card $displayIndex of $total",
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0x99EFE6D0),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => VocabExportService.showExportOptionsSheet(
                      context,
                      provider,
                      currentWord: isDone ? null : (currentCardIndex < sessionWords.length ? sessionWords[currentCardIndex] : null),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0x1FEFE6D0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.file_download_outlined, color: AppColors.paper, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Swipeable Card Stack / Done State
            Expanded(
              child: isDone
                  ? _buildDoneState(context)
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      child: CardSwiper(
                        key: swiperKey,
                        controller: _swiperController,
                        cardsCount: sessionWords.length,
                        onSwipe: _onSwipe,
                        onEnd: _onEnd,
                        padding: const EdgeInsets.all(0),
                        isLoop: false,
                        numberOfCardsDisplayed: sessionWords.length > 2 ? 3 : sessionWords.length,
                        backCardOffset: const Offset(0, 30),
                        cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                          final word = sessionWords[index];
                          // Only allow tapping the top card
                          final isTopCard = index == currentCardIndex;
                          return _buildCardState(provider, word, isTopCard);
                        },
                      ),
                    ),
            ),

            if (!isDone)
              Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 12),
                child: SizedBox(
                  width: 320,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0x1FEFE6D0),
                            foregroundColor: AppColors.paper,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () => _swiperController.swipe(CardSwiperDirection.left),
                          icon: const Icon(Icons.refresh, size: 16, color: AppColors.paper),
                          label: Text(
                            "Still learning",
                            style: AppTypography.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.paper,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.moss,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                          ),
                          onPressed: () {
                            _isButtonSwipe = true;
                            _swiperController.swipe(CardSwiperDirection.right);
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                          label: Text(
                            "Got it",
                            style: AppTypography.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardState(EasyReadProvider provider, String word, bool isTopCard) {
    final data = provider.getWordData(word);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Flashcard Container
        Expanded(
          child: GestureDetector(
            onTap: isTopCard ? () => setState(() => isRevealed = !isRevealed) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.paperSoft,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 15),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          word,
                          textAlign: TextAlign.center,
                          style: AppTypography.fraunces(
                            fontSize: isRevealed && isTopCard ? 24 : 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => provider.speakWord(word),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.paper,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.line),
                          ),
                          child: const Icon(Icons.volume_up_outlined, size: 16, color: AppColors.moss),
                        ),
                      ),
                    ],
                  ),
                  if (data.phonetic != null && data.phonetic!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      data.phonetic!,
                      style: AppTypography.inter(
                        fontSize: 12,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Text(
                      data.pos,
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textMute,
                      ),
                    ),
                  ),
                  if (!isRevealed || !isTopCard) ...[
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.gold),
                        const SizedBox(width: 6),
                        Text(
                          "Tap card to flip meaning",
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 18),
                    if (data.meaning.startsWith("Looking up") || data.meaning.startsWith("Loading")) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.moss),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Fetching definition...",
                            style: AppTypography.inter(fontSize: 13, color: AppColors.textMute),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        data.meaning,
                        textAlign: TextAlign.center,
                        style: AppTypography.literata(
                          fontSize: 15,
                          color: AppColors.textDark,
                          height: 1.5,
                        ),
                      ),
                    ],
                    if (data.example.isNotEmpty &&
                        !data.example.contains("Fetching authentic") &&
                        !data.example.contains("Looking up")) ...[
                      const SizedBox(height: 14),
                      Text(
                        '"${data.example}"',
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMute,
                        ),
                      ),
                    ],
                    if (data.synonyms.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        alignment: WrapAlignment.center,
                        children: data.synonyms.take(4).map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: Text(
                              s,
                              style: AppTypography.inter(fontSize: 10, color: AppColors.textDark, fontWeight: FontWeight.w500),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoneState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events_outlined, size: 52, color: AppColors.goldSoft),
        const SizedBox(height: 14),
        Text(
          "Great Progress!",
          style: AppTypography.fraunces(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.paper),
        ),
        const SizedBox(height: 8),
        Text(
          masteredInSessionCount > 0
              ? "You learned $masteredInSessionCount word${masteredInSessionCount == 1 ? '' : 's'} in this session!"
              : "You completed reviewing all cards.",
          textAlign: TextAlign.center,
          style: AppTypography.inter(fontSize: 13, color: const Color(0xB2EFE6D0)),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldSoft,
                foregroundColor: AppColors.ink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check, size: 16, color: AppColors.ink),
              label: Text(
                "Done",
                style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
