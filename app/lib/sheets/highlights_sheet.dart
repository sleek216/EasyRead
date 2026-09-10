import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/easy_word_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class HighlightsSheetContent extends StatelessWidget {
  final void Function(int)? onGoToParagraph;

  const HighlightsSheetContent({super.key, this.onGoToParagraph});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final highlights = provider.highlights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Highlights & notes",
          style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (highlights.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No highlights yet — tap "Highlight" under any paragraph while reading.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: highlights.length,
              separatorBuilder: (context, index) => const Divider(color: AppColors.line, height: 1),
              itemBuilder: (ctx, i) {
                final hl = highlights[i];
                final passage = provider.articleParagraphs.length > hl.paragraphIndex
                    ? provider.articleParagraphs[hl.paragraphIndex]
                    : "";
                final snippet = passage.length > 110 ? "${passage.substring(0, 110)}…" : passage;

                Color swatchColor = AppColors.hlYellow;
                if (hl.color == 'green') swatchColor = AppColors.hlGreen;
                if (hl.color == 'pink') swatchColor = AppColors.hlPink;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 54,
                        decoration: BoxDecoration(
                          color: swatchColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snippet,
                              style: AppTypography.literata(fontSize: 12.5, height: 1.45),
                            ),
                            if (hl.note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '"${hl.note}"',
                                style: AppTypography.inter(
                                  fontSize: 11,
                                  color: AppColors.textMute,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                                onGoToParagraph?.call(hl.paragraphIndex);
                              },
                              child: Text(
                                "Go to passage →",
                                style: AppTypography.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.moss,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16, color: AppColors.textMute),
                        onPressed: () => provider.removeHighlight(hl.paragraphIndex),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.paper,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Done", style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.paper)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
