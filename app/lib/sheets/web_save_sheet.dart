import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/easy_word_provider.dart';
import '../models/book_item.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';

class WebSaveSheetContent extends StatefulWidget {
  const WebSaveSheetContent({super.key});

  @override
  State<WebSaveSheetContent> createState() => _WebSaveSheetContentState();
}

class _WebSaveSheetContentState extends State<WebSaveSheetContent> {
  final TextEditingController _urlCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _urlCtrl.text = data.text!.trim();
      });
      if (mounted) {
        showEasyToast(context, "Link pasted from clipboard");
      }
    }
  }

  Future<void> _saveFromWeb(BuildContext context) async {
    String raw = _urlCtrl.text.replaceAll('"', '').replaceAll("'", '').trim();
    if (raw.isEmpty) {
      showEasyToast(context, "Paste an article link first");
      return;
    }

    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = 'https://$raw';
    }

    String hostname = "the web";
    try {
      final uri = Uri.parse(raw);
      hostname = uri.host.replaceFirst('www.', '');
    } catch (_) {}

    final provider = context.read<EasyReadProvider>();
    setState(() => _isLoading = true);

    try {
      final res = await ApiService.extractWebArticle(raw);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success'] == true && res['paragraphs'] != null && (res['paragraphs'] as List).isNotEmpty) {
        final title = res['title'] ?? "Article from $hostname";
        final paragraphs = List<String>.from(res['paragraphs']);
        final wordCount = res['word_count'] ?? paragraphs.join(' ').split(' ').length;

        provider.importBook(
          BookItem(
            title: title,
            meta: "Web Article · $hostname · $wordCount words",
            color: AppColors.gold,
            tag: "web",
            paragraphs: paragraphs,
          ),
        );

        if (context.mounted) {
          Navigator.of(context).pop();
          showEasyToast(context, 'Saved clean article from $hostname');
        }

        provider.openArticleWithContent(
          title: title,
          byline: "Web Article · $hostname · $wordCount words",
          paragraphs: paragraphs,
          banner: "Clean Web Reader: 0 Images, Ads & Navigation Stripped",
        );
      } else {
        if (context.mounted) {
          showEasyToast(context, res['message'] ?? "Could not extract article text from this link");
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (context.mounted) {
        showEasyToast(context, "Failed to connect to web page");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Save from the web",
              style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: _pasteFromClipboard,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.paperSoft,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.content_paste, size: 12, color: AppColors.moss),
                    const SizedBox(width: 4),
                    Text(
                      "Paste Link",
                      style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.moss),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.only(left: 14, right: 4),
          child: Row(
            children: [
              const Icon(Icons.link, size: 18, color: AppColors.textMute),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _urlCtrl,
                  onChanged: (_) {
                    setState(() {});
                  },
                  style: AppTypography.inter(fontSize: 13, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: "Paste an article link (e.g. medium.com/...)",
                    hintStyle: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_urlCtrl.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textMute),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: "Clear",
                  onPressed: () {
                    _urlCtrl.clear();
                    setState(() {});
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _saveFromWeb(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.ink.withValues(alpha: 0.7),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Extracting Pure Text...",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  )
                : Text(
                    "Extract Pure Text & Read",
                    style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "• Strips all ads, images, popups, cookie banners & menus.\n• Converts web page into pure distraction-free reading typography.",
          style: AppTypography.inter(fontSize: 11, color: AppColors.textMute, height: 1.4),
        ),
      ],
    );
  }
}
