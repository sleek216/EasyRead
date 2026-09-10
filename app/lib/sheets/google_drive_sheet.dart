import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/easy_word_provider.dart';
import '../services/google_drive_service.dart';
import '../services/pdf_reader_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';

class GoogleDriveSheet extends StatefulWidget {
  const GoogleDriveSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GoogleDriveSheet(),
    );
  }

  @override
  State<GoogleDriveSheet> createState() => _GoogleDriveSheetState();
}

class _GoogleDriveSheetState extends State<GoogleDriveSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _downloadingFileName;
  String? _errorMessage;
  List<GoogleDriveFile> _allFiles = [];
  List<GoogleDriveFile> _filteredFiles = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final account = await GoogleDriveService.signIn();
      if (account == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Google Sign-In was cancelled.';
        });
        return;
      }

      final files = await GoogleDriveService.fetchDriveFiles();
      if (mounted) {
        setState(() {
          _allFiles = files;
          _filteredFiles = files;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    final clean = query.trim().toLowerCase();
    setState(() {
      if (clean.isEmpty) {
        _filteredFiles = _allFiles;
      } else {
        _filteredFiles = _allFiles.where((f) => f.name.toLowerCase().contains(clean)).toList();
      }
    });
  }

  Future<void> _selectAndImport(GoogleDriveFile driveFile) async {
    final provider = context.read<EasyReadProvider>();
    final normTitle = provider.normalizeBookTitle(driveFile.name);

    // 1. Duplicate check — if already in user's library, open existing copy
    final alreadyImported = provider.userLocalBooks.any(
      (b) => provider.normalizeBookTitle(b.title) == normTitle,
    );
    if (alreadyImported) {
      final existing = provider.userLocalBooks.firstWhere(
        (b) => provider.normalizeBookTitle(b.title) == normTitle,
      );
      provider.activeTab = 'reader';
      provider.openBook(existing);
      if (mounted) {
        Navigator.of(context).pop();
        showEasyToast(context, 'Opened existing "${existing.title}" from Your Library');
      }
      return;
    }

    // 2. Download from Google Drive
    setState(() {
      _isDownloading = true;
      _downloadingFileName = driveFile.name;
    });

    try {
      final File localFile = await GoogleDriveService.downloadFile(driveFile);
      final ext = driveFile.fileExtension;

      if (!mounted) return;

      // Close modal bottom sheet before loading into reader
      Navigator.of(context).pop();
      provider.setDocumentLoading(true);
      provider.activeTab = 'reader';

      // 3. Parse downloaded file according to format
      if (ext == 'PDF') {
        final parsed = await PdfReaderService.extractFromPath(localFile.path);
        provider.importBook(BookItem(
          title: parsed.title,
          meta: 'PDF · ${parsed.pageCount} pages · Google Drive',
          color: AppColors.plum,
          tag: 'imported',
          paragraphs: parsed.paragraphs,
        ));
        provider.openArticleWithContent(
          title: parsed.title,
          byline: 'PDF Document · Google Drive · ${parsed.wordCount} words',
          paragraphs: parsed.paragraphs,
          banner: 'Google Drive PDF: Tap any word for definitions & smart AI assist',
        );
      } else if (ext == 'EPUB') {
        final bytes = await localFile.readAsBytes();
        final paragraphs = _parseEpubBytes(bytes);
        final cleanTitle = driveFile.name.replaceAll(RegExp(r'\.epub$', caseSensitive: false), '');
        provider.importBook(BookItem(
          title: cleanTitle,
          meta: 'EPUB · ${paragraphs.length} sections · Google Drive',
          color: const Color(0xFF5B4FCF),
          tag: 'imported',
          paragraphs: paragraphs,
        ));
        provider.openArticleWithContent(
          title: cleanTitle,
          byline: 'eBook · Google Drive · ${paragraphs.length} sections',
          paragraphs: paragraphs,
          banner: 'Google Drive EPUB: Tap any word for definitions & smart AI assist',
        );
      } else if (ext == 'DOCX' || ext == 'DOC') {
        final bytes = await localFile.readAsBytes();
        final paragraphs = _parseDocxBytes(bytes);
        final cleanTitle = driveFile.name.replaceAll(RegExp(r'\.(docx?|doc)$', caseSensitive: false), '');
        provider.importBook(BookItem(
          title: cleanTitle,
          meta: '$ext · ${paragraphs.length} paragraphs · Google Drive',
          color: const Color(0xFF1565C0),
          tag: 'imported',
          paragraphs: paragraphs,
        ));
        provider.openArticleWithContent(
          title: cleanTitle,
          byline: 'Word Document · Google Drive · ${paragraphs.length} paragraphs',
          paragraphs: paragraphs,
          banner: 'Google Drive Document: Tap any word for definitions & smart AI assist',
        );
      } else {
        // TXT fallback
        final content = await localFile.readAsString();
        final paras = content
            .split(RegExp(r'\n\s*\n'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        final finalParas = paras.isNotEmpty ? paras : [content];
        final cleanTitle = driveFile.name.replaceAll(RegExp(r'\.txt$', caseSensitive: false), '');
        provider.importBook(BookItem(
          title: cleanTitle,
          meta: 'TXT · ${finalParas.length} sections · Google Drive',
          color: AppColors.moss,
          tag: 'imported',
          paragraphs: finalParas,
        ));
        provider.openArticleWithContent(
          title: cleanTitle,
          byline: 'Plain Text · Google Drive',
          paragraphs: finalParas,
          banner: 'Google Drive Text: Tap any word for definitions & smart AI assist',
        );
      }

      if (mounted) {
        showEasyToast(context, 'Imported "${driveFile.name}" from Google Drive');
      }
    } catch (e) {
      provider.setDocumentLoading(false);
      if (mounted) {
        showEasyToast(context, 'Failed to open file: $e');
      }
    } finally {
      provider.setDocumentLoading(false);
    }
  }

  List<String> _parseEpubBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final htmlRe = RegExp(r'<(p|div|h[1-6]|li)[^>]*>(.*?)<\/\1>', caseSensitive: false, dotAll: true);
      final tagRe = RegExp(r'<[^>]+>');
      final entityRe = RegExp(r'&(?:[a-zA-Z]+|#\d+);');

      final paragraphs = <String>[];
      final contentFiles = archive.files
          .where((f) => f.isFile &&
              (f.name.endsWith('.html') || f.name.endsWith('.htm') || f.name.endsWith('.xhtml')))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      for (final file in contentFiles) {
        final content = utf8.decode(file.content as Uint8List, allowMalformed: true);
        for (final m in htmlRe.allMatches(content)) {
          var text = m.group(2) ?? '';
          text = text.replaceAll(tagRe, ' ');
          text = text.replaceAll(entityRe, ' ');
          text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (text.length > 20) paragraphs.add(text);
        }
      }

      return paragraphs.isNotEmpty
          ? paragraphs
          : ['This EPUB file could not be parsed.'];
    } catch (_) {
      return ['Unable to extract text from this EPUB file.'];
    }
  }

  List<String> _parseDocxBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      ArchiveFile? docFile;
      for (final file in archive.files) {
        if (file.name == 'word/document.xml') {
          docFile = file;
          break;
        }
      }
      if (docFile == null) return ['Unable to read document contents.'];

      final xml = utf8.decode(docFile.content as Uint8List, allowMalformed: true);
      final pRe = RegExp(r'<w:p[ >](.*?)<\/w:p>', dotAll: true);
      final tRe = RegExp(r'<w:t[ >](.*?)<\/w:t>', dotAll: true);

      final paragraphs = <String>[];
      for (final pMatch in pRe.allMatches(xml)) {
        final pXml = pMatch.group(1) ?? '';
        final textParts = <String>[];
        for (final tMatch in tRe.allMatches(pXml)) {
          final t = tMatch.group(1)?.replaceAll(RegExp(r'<[^>]+>'), '') ?? '';
          if (t.isNotEmpty) textParts.add(t);
        }
        final fullPara = textParts.join('').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (fullPara.isNotEmpty) {
          paragraphs.add(fullPara);
        }
      }

      return paragraphs.isNotEmpty ? paragraphs : ['No readable text found in document.'];
    } catch (_) {
      return ['Unable to read this Word document.'];
    }
  }

  Color _getBadgeColor(String ext) {
    switch (ext) {
      case 'PDF':
        return const Color(0xFFE53935);
      case 'EPUB':
        return const Color(0xFF5B4FCF);
      case 'DOCX':
      case 'DOC':
        return const Color(0xFF1565C0);
      case 'TXT':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF757575);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = GoogleDriveService.currentAccount;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.textMute.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_to_drive_outlined, color: Color(0xFF1A73E8), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Drive',
                        style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      if (account != null)
                        Text(
                          account.email,
                          style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 22, color: AppColors.textDark),
                  tooltip: 'Refresh',
                  onPressed: _isLoading || _isDownloading ? null : _loadFiles,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: AppTypography.inter(fontSize: 13.5, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Search Drive files (PDF, EPUB, Word, TXT)...',
                hintStyle: AppTypography.inter(fontSize: 12.5, color: AppColors.textMute),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMute),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMute),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.paperSoft,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          const Divider(height: 1, color: AppColors.paperSoft),

          // Body Content
          Expanded(
            child: _isDownloading
                ? _buildDownloadingView()
                : _isLoading
                    ? _buildLoadingView()
                    : _errorMessage != null
                        ? _buildErrorView()
                        : _filteredFiles.isEmpty
                            ? _buildEmptyView()
                            : _buildFilesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.8, color: Color(0xFF1A73E8)),
          ),
          const SizedBox(height: 16),
          Text(
            'Scanning Google Drive...',
            style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Looking for PDF, EPUB, Word, and TXT files',
            style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.8, color: Color(0xFF1A73E8)),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Importing from Google Drive',
              style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _downloadingFileName ?? 'Downloading document...',
              style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: Color(0xFFD32F2F)),
            const SizedBox(height: 14),
            Text(
              'Google Drive Access',
              style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Unable to connect to Google Drive.',
              style: AppTypography.inter(fontSize: 12.5, color: AppColors.textMute),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A73E8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: _loadFiles,
              icon: const Icon(Icons.login_rounded, size: 16),
              label: Text('Connect Google Drive', style: AppTypography.inter(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_open_rounded, size: 44, color: AppColors.textMute),
            const SizedBox(height: 14),
            Text(
              _searchController.text.isNotEmpty ? 'No Matching Files Found' : 'No Compatible eBooks Found',
              style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try searching with another file name.'
                  : 'Add PDF, EPUB, Word (.docx), or TXT documents to your Google Drive to see them here.',
              style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _filteredFiles.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.paperSoft),
      itemBuilder: (context, index) {
        final f = _filteredFiles[index];
        final badgeColor = _getBadgeColor(f.fileExtension);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectAndImport(f),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // File Format Badge
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                  ),
                  child: Center(
                    child: Text(
                      f.fileExtension,
                      style: AppTypography.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: AppTypography.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (f.formattedSize.isNotEmpty) ...[
                            Text(
                              f.formattedSize,
                              style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                            ),
                            const Text('  ·  ', style: TextStyle(color: AppColors.textMute, fontSize: 10)),
                          ],
                          Text(
                            'Google Drive',
                            style: AppTypography.inter(fontSize: 11, color: const Color(0xFF1A73E8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Download/Import Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.paperSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.download_rounded, size: 18, color: AppColors.moss),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
