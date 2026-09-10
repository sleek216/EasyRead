import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:book_reading/models/dictionary_entry.dart';
import 'package:book_reading/providers/easy_word_provider.dart';
import 'package:book_reading/theme/app_colors.dart';
import 'package:book_reading/theme/app_typography.dart';

class DefinitionCardOverlay extends StatefulWidget {
  final String word;
  final DictionaryEntry entry;
  final bool isSaved;
  final VoidCallback onSpeak;
  final void Function(DictionaryEntry entry)? onSaveWithEntry;
  final VoidCallback onToggleSave;
  final VoidCallback onClose;
  final VoidCallback? onExpand;
  final Offset tapPosition;

  const DefinitionCardOverlay({
    super.key,
    required this.word,
    required this.entry,
    required this.isSaved,
    required this.onSpeak,
    required this.onToggleSave,
    this.onSaveWithEntry,
    required this.onClose,
    this.onExpand,
    required this.tapPosition,
  });

  @override
  State<DefinitionCardOverlay> createState() => _DefinitionCardOverlayState();
}

class _DefinitionCardOverlayState extends State<DefinitionCardOverlay> {
  final GlobalKey _cardKey = GlobalKey();
  bool isExpanded = false;
  late DictionaryEntry _entry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _fetchLiveDefinition();
  }

  Future<void> _fetchLiveDefinition() async {
    final clean = widget.word.toLowerCase().replaceAll(RegExp(r"[^a-zA-Z]"), '').trim();
    if (clean.isEmpty) return;

    // Check if current entry is a placeholder or missing detailed definition
    final isGeneric = _entry.meaning.isEmpty ||
        _entry.meaning == "Looking up definition..." ||
        _entry.meaning == "General reading term." ||
        _entry.synonyms.isEmpty;

    if (isGeneric) {
      setState(() => _isLoading = true);
    }

    try {
      final provider = context.read<EasyReadProvider>();
      final liveEntry = await provider.fetchWordDefinition(clean);
      if (mounted) {
        setState(() {
          _entry = liveEntry;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const cardWidth = 275.0;
    final estimatedCardHeight = isExpanded ? 310.0 : 180.0;

    // Horizontally center card around tap, clamped safely within screen margins
    double left = (widget.tapPosition.dx - cardWidth / 2).clamp(16.0, screenSize.width - cardWidth - 16.0);

    // Smart vertical placement:
    // If tap is in lower half of screen, position card ABOVE the tap position so it never cuts off at bottom.
    // If tap is in upper half of screen, position card BELOW the tap position.
    double top;
    if (widget.tapPosition.dy > screenSize.height * 0.52) {
      top = widget.tapPosition.dy - estimatedCardHeight - 20.0;
    } else {
      top = widget.tapPosition.dy + 24.0;
    }

    // STRICT SAFE BOUNDS CLAMPING:
    // Ensure card top is ALWAYS below top app bar (>= 72.0)
    // AND card bottom is ALWAYS above bottom navigation bar (<= screenSize.height - estimatedCardHeight - 75.0)
    top = top.clamp(72.0, (screenSize.height - estimatedCardHeight - 75.0).clamp(72.0, screenSize.height - 180.0));

    final maxInnerHeight = (screenSize.height - top - 85.0).clamp(160.0, 320.0);

    return Stack(
      children: [
        // Translucent Listener backdrop to dismiss immediately on touch outside without blocking scroll/taps
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              final renderBox = _cardKey.currentContext?.findRenderObject() as RenderBox?;
              if (renderBox != null) {
                final offset = renderBox.localToGlobal(Offset.zero);
                final bounds = offset & renderBox.size;
                if (bounds.contains(event.position)) {
                  // Touch occurred inside card: do not close
                  return;
                }
              }
              widget.onClose();
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Material(
            color: Colors.transparent,
            child: Container(
              key: _cardKey,
              width: cardWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  )
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxInnerHeight),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.word.toLowerCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.fraunces(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.paper,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  _entry.pos,
                                  style: AppTypography.inter(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.goldSoft,
                                  ),
                                ),
                                if (_entry.phonetic != null && _entry.phonetic!.isNotEmpty) ...[
                                  Text(
                                    " · ${_entry.phonetic}",
                                    style: AppTypography.inter(
                                      fontSize: 10,
                                      color: const Color(0x99EFE6D0),
                                    ),
                                  ),
                                ],
                                if (_isLoading) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: AppColors.goldSoft,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onSpeak,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0x1FEFE6D0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volume_up_outlined, color: Color(0xFFEFE6D0), size: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoading && _entry.meaning.isEmpty ? "Looking up real definition..." : _entry.meaning,
                    style: AppTypography.literata(
                      fontSize: 13,
                      color: const Color(0xEBEFE6D0),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => isExpanded = !isExpanded);
                          if (isExpanded) {
                            widget.onExpand?.call();
                          }
                        },
                        child: Row(
                          children: [
                            Text(
                              isExpanded ? "See less" : "See more",
                              style: AppTypography.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldSoft,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 14,
                              color: AppColors.goldSoft,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (widget.onSaveWithEntry != null) {
                            widget.onSaveWithEntry!(_entry);
                          } else {
                            widget.onToggleSave();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.isSaved ? AppColors.moss : AppColors.goldSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.isSaved ? Icons.bookmark : Icons.bookmark_border,
                                size: 12,
                                color: widget.isSaved ? Colors.white : AppColors.ink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.isSaved ? "Saved" : "Save",
                                style: AppTypography.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.isSaved ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    const Divider(color: Color(0x26EFE6D0), height: 1),
                    const SizedBox(height: 10),
                    if (_entry.example.isNotEmpty) ...[
                      _buildExtraRow("EXAMPLE", _entry.example),
                      const SizedBox(height: 8),
                    ],
                    if (_entry.synonyms.isNotEmpty) ...[
                      Text(
                        "SYNONYMS",
                        style: AppTypography.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0x80EFE6D0),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: _entry.synonyms.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0x1AEFE6D0),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              s,
                              style: AppTypography.inter(fontSize: 10.5, color: AppColors.paper),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildExtraRow("ORIGIN", _entry.origin),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ],
);
  }

  Widget _buildExtraRow(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: const Color(0x80EFE6D0),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: AppTypography.literata(
            fontSize: 12.5,
            color: const Color(0xEBEFE6D0),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
