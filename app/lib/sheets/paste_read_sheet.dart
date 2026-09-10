import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/easy_word_provider.dart';
import '../models/book_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';

class PasteReadSheetContent extends StatefulWidget {
  const PasteReadSheetContent({super.key});

  @override
  State<PasteReadSheetContent> createState() => _PasteReadSheetContentState();
}

class _PasteReadSheetContentState extends State<PasteReadSheetContent> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _readNow(BuildContext context) {
    final raw = _textCtrl.text.trim();
    if (raw.isEmpty) {
      showEasyToast(context, "Paste something to read first");
      return;
    }

    final title = _titleCtrl.text.trim().isEmpty ? "Pasted text" : _titleCtrl.text.trim();
    final wordCount = raw.split(RegExp(r'\s+')).length;
    final paragraphs = raw
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final paras = paragraphs.isNotEmpty ? paragraphs : [raw];

    final provider = context.read<EasyReadProvider>();
    provider.importBook(
      BookItem(
        title: title,
        meta: "Pasted · $wordCount words",
        color: AppColors.plum,
        tag: "pasted",
        paragraphs: paras,
      ),
    );

    Navigator.of(context).pop();
    showEasyToast(context, "Added to your library");

    provider.openArticleWithContent(
      title: title,
      byline: "Pasted · $wordCount words",
      paragraphs: paras,
      banner: "Cleaned up and formatted for easy reading",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Paste & Read",
          style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: _titleCtrl,
            style: AppTypography.inter(fontSize: 13, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: "Give it a title (optional)",
              hintStyle: AppTypography.inter(fontSize: 13, color: AppColors.textMute),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: TextField(
            controller: _textCtrl,
            maxLines: null,
            style: AppTypography.literata(fontSize: 13.5, color: AppColors.textDark, height: 1.5),
            decoration: InputDecoration(
              hintText: "Paste or type any text — an article, notes, an email, a passage from a book...",
              hintStyle: AppTypography.inter(fontSize: 12.5, color: AppColors.textMute),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.paper,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          onPressed: () => _readNow(context),
          child: Text(
            "Read now",
            style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.paper),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
