import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/book_item.dart';
import '../providers/easy_word_provider.dart';
import '../services/dropbox_service.dart';
import '../services/pdf_reader_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';

class DropboxSheet extends StatefulWidget {
  const DropboxSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DropboxSheet(),
    );
  }

  @override
  State<DropboxSheet> createState() => _DropboxSheetState();
}

class _DropboxSheetState extends State<DropboxSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  bool _isLoading = true;
  bool _isConnecting = false;
  bool _isDownloading = false;
  String? _downloadingFileName;
  String? _errorMessage;

  DropboxAccount? _account;
  List<DropboxFile> _allFiles = [];
  List<DropboxFile> _filteredFiles = [];

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoad() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await DropboxService.getSavedToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _account = null;
        });
        return;
      }

      // Fetch / verify account info
      DropboxAccount? account = await DropboxService.getCachedAccount();
      try {
        account = await DropboxService.fetchAccount(token);
      } catch (_) {
        if (account == null) {
          setState(() {
            _isLoading = false;
            _account = null;
          });
          return;
        }
      }

      _account = account;

      // Fetch files
      final files = await DropboxService.fetchFiles();
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

  Future<void> _handleConnect() async {
    final input = _tokenController.text.trim();
    if (input.isEmpty) {
      showEasyToast(context, 'Please paste your authorization code or token');
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final account = await DropboxService.connectWithCodeOrToken(input);
      _tokenController.clear();
      if (mounted) {
        showEasyToast(context, 'Connected to Dropbox as ${account.displayName}');
      }
      await _checkAuthAndLoad();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        showEasyToast(context, 'Connection failed. Please check code or token.');
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _handleDisconnect() async {
    await DropboxService.disconnect();
    if (mounted) {
      setState(() {
        _account = null;
        _allFiles.clear();
        _filteredFiles.clear();
      });
      showEasyToast(context, 'Disconnected from Dropbox');
    }
  }

  Future<void> _openDropboxAuthInBrowser() async {
    final authUrl = await DropboxService.getAuthorizeUrl();
    final opened = await DropboxService.openUrl(authUrl);
    if (!opened && mounted) {
      // Fallback: Copy auth URL to clipboard
      await Clipboard.setData(ClipboardData(text: authUrl));
      if (!mounted) return;
      showEasyToast(context, 'Authorization link copied to clipboard. Open in browser.');
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

  Future<void> _selectAndImport(DropboxFile dropboxFile) async {
    final provider = context.read<EasyReadProvider>();
    final normTitle = provider.normalizeBookTitle(dropboxFile.name);

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

    // 2. Download from Dropbox
    setState(() {
      _isDownloading = true;
      _downloadingFileName = dropboxFile.name;
    });

    try {
      final File localFile = await DropboxService.downloadFile(dropboxFile);
      final ext = dropboxFile.fileExtension;

      if (!mounted) return;

      // Close bottom sheet before reader transition
      Navigator.of(context).pop();
      provider.setDocumentLoading(true);
      provider.activeTab = 'reader';

      // 3. Parse downloaded file according to format
      if (ext == 'PDF') {
        final parsed = await PdfReaderService.extractFromPath(localFile.path);
        provider.importBook(BookItem(
          title: parsed.title,
          meta: 'PDF · ${parsed.pageCount} pages · Dropbox',
          color: AppColors.plum,
          tag: 'imported',
          paragraphs: parsed.paragraphs,
        ));
        provider.openArticleWithContent(
          title: parsed.title,
          byline: 'PDF Document · Dropbox · ${parsed.wordCount} words',
          paragraphs: parsed.paragraphs,
          banner: 'Dropbox PDF: Tap any word for definitions & smart AI assist',
        );
      } else if (ext == 'EPUB') {
        final bytes = await localFile.readAsBytes();
        final paragraphs = _parseEpubBytes(bytes);
        final cleanTitle = dropboxFile.name.replaceAll(RegExp(r'\.epub$', caseSensitive: false), '');
        provider.importBook(BookItem(
          title: cleanTitle,
          meta: 'EPUB · ${paragraphs.length} sections · Dropbox',
          color: const Color(0xFF5B4FCF),
          tag: 'imported',
          paragraphs: paragraphs,
        ));
        provider.openArticleWithContent(
          title: cleanTitle,
          byline: 'eBook · Dropbox · ${paragraphs.length} sections',
          paragraphs: paragraphs,
          banner: 'Dropbox EPUB: Tap any word for definitions & smart AI assist',
        );
      } else if (ext == 'DOCX' || ext == 'DOC') {
        final bytes = await localFile.readAsBytes();
        final paragraphs = _parseDocxBytes(bytes);
        final cleanTitle = dropboxFile.name.replaceAll(RegExp(r'\.(docx?|doc)$', caseSensitive: false), '');
        provider.importBook(BookItem(
          title: cleanTitle,
          meta: '$ext · ${paragraphs.length} paragraphs · Dropbox',
          color: const Color(0xFF1565C0),
          tag: 'imported',
          paragraphs: paragraphs,
        ));
        provider.openArticleWithContent(
          title: cleanTitle,
          byline: 'Word Document · Dropbox · ${paragraphs.length} paragraphs',
          paragraphs: paragraphs,
          banner: 'Dropbox Document: Tap any word for definitions & smart AI assist',
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
        final cleanTitle = dropboxFile.name.replaceAll(RegExp(r'\.txt$', caseSensitive: false), '');
        provider.importBook(BookItem(
          title: cleanTitle,
          meta: 'TXT · ${finalParas.length} sections · Dropbox',
          color: AppColors.moss,
          tag: 'imported',
          paragraphs: finalParas,
        ));
        provider.openArticleWithContent(
          title: cleanTitle,
          byline: 'Plain Text · Dropbox',
          paragraphs: finalParas,
          banner: 'Dropbox Text: Tap any word for definitions & smart AI assist',
        );
      }

      if (mounted) {
        showEasyToast(context, 'Imported "${dropboxFile.name}" from Dropbox');
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

  // ─── EPUB Parser ─────────────────────────────────────────────────────────────
  List<String> _parseEpubBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final textFiles = archive.files
          .where((f) => f.isFile && RegExp(r'\.(html|xhtml|xml)$', caseSensitive: false).hasMatch(f.name))
          .toList();
      textFiles.sort((a, b) => a.name.compareTo(b.name));

      final allSections = <String>[];
      for (final tf in textFiles) {
        if (tf.content == null) continue;
        final raw = utf8.decode(tf.content as Uint8List, allowMalformed: true);
        final clean = raw
            .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?<\/style>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?<\/script>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (clean.length > 30) {
          allSections.add(clean);
        }
      }
      return allSections.isNotEmpty ? allSections : ['Could not extract text from this EPUB.'];
    } catch (_) {
      return ['Could not read this EPUB file.'];
    }
  }

  // ─── DOCX Parser ─────────────────────────────────────────────────────────────
  List<String> _parseDocxBytes(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docXml = archive.files.firstWhere(
        (f) => f.isFile && f.name == 'word/document.xml',
        orElse: () => ArchiveFile('', 0, Uint8List(0)),
      );
      if (docXml.content == null || (docXml.content as Uint8List).isEmpty) {
        return ['Could not read this Word document.'];
      }

      final xmlContent = utf8.decode(docXml.content as Uint8List, allowMalformed: true);
      final paraRe = RegExp(r'<w:p[ >](.*?)<\/w:p>', caseSensitive: false, dotAll: true);
      final textRe = RegExp(r'<w:t[^>]*>(.*?)<\/w:t>', caseSensitive: false, dotAll: true);

      final paras = <String>[];
      for (final paraMatch in paraRe.allMatches(xmlContent)) {
        final paraXml = paraMatch.group(1) ?? '';
        final sb = StringBuffer();
        for (final m in textRe.allMatches(paraXml)) {
          sb.write(m.group(1) ?? '');
        }
        final text = sb.toString().trim();
        if (text.length > 2) paras.add(text);
      }

      return paras.isNotEmpty ? paras : ['Could not read this Word document.'];
    } catch (_) {
      return ['Could not read this Word document.'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Sheet Handle Bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0061FF).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.cloud_queue_outlined, color: Color(0xFF0061FF), size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dropbox',
                            style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            _account != null
                                ? '${_account!.displayName} · ${_account!.email}'
                                : 'Connect your account to browse books',
                            style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (_account != null) ...[
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.moss),
                        tooltip: 'Refresh file list',
                        onPressed: _checkAuthAndLoad,
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 19, color: Color(0xFFC0392B)),
                        tooltip: 'Disconnect Dropbox',
                        onPressed: _handleDisconnect,
                      ),
                    ],
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: AppColors.textMute),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(color: AppColors.line, height: 1),

              // Main Body Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _account == null
                        ? _buildAuthView()
                        : _buildFilesView(),
              ),
            ],
          ),

          // Downloading Progress Overlay
          if (_isDownloading)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 36),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                  decoration: BoxDecoration(
                    color: AppColors.paperSoft,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 38,
                        height: 38,
                        child: CircularProgressIndicator(color: Color(0xFF0061FF), strokeWidth: 3.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Downloading from Dropbox',
                        style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _downloadingFileName ?? 'Document',
                        style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Loading State ───────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(color: Color(0xFF0061FF), strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'Accessing Dropbox...',
            style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Retrieving your documents & library files',
            style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
          ),
        ],
      ),
    );
  }

  // ─── Authentication View ─────────────────────────────────────────────────────
  Widget _buildAuthView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF0061FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.cloud_queue_outlined, size: 36, color: Color(0xFF0061FF)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Connect your Dropbox',
            textAlign: TextAlign.center,
            style: AppTypography.fraunces(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse and read PDF, EPUB, DOCX, and TXT files directly from your Dropbox cloud.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(fontSize: 12.5, color: AppColors.textMute, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Step 1: Authorize in Browser
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0061FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            label: Text(
              '1. Authorize in Dropbox',
              style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            onPressed: _openDropboxAuthInBrowser,
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('THEN PASTE CODE BELOW', style: AppTypography.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMute)),
              ),
              const Expanded(child: Divider(color: AppColors.line)),
            ],
          ),

          const SizedBox(height: 16),

          // Step 2: Code / Token Input
          Container(
            decoration: BoxDecoration(
              color: AppColors.paperSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, size: 18, color: AppColors.textMute),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      hintText: 'Paste authorization code or access token',
                      hintStyle: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                      border: InputBorder.none,
                    ),
                    style: AppTypography.inter(fontSize: 12.5, fontStyle: FontStyle.italic),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data != null && data.text != null && data.text!.isNotEmpty) {
                      _tokenController.text = data.text!.trim();
                    }
                  },
                  child: Text('Paste', style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0061FF))),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: AppTypography.inter(fontSize: 11.5, color: const Color(0xFFC0392B)),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.moss,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _isConnecting ? null : _handleConnect,
            child: _isConnecting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    '2. Complete Connection',
                    style: AppTypography.inter(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Files View ──────────────────────────────────────────────────────────────
  Widget _buildFilesView() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.paperSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.textMute),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: AppTypography.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search books in Dropbox...',
                      hintStyle: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    child: const Icon(Icons.clear, size: 16, color: AppColors.textMute),
                  ),
              ],
            ),
          ),
        ),

        // Files List
        Expanded(
          child: _filteredFiles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_outlined, size: 48, color: AppColors.textMute.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'No reader documents found',
                          style: AppTypography.fraunces(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upload PDF, EPUB, DOCX, or TXT books to your Dropbox to see them here.',
                          textAlign: TextAlign.center,
                          style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: _filteredFiles.length,
                  separatorBuilder: (_, _) => const Divider(color: AppColors.line, height: 1),
                  itemBuilder: (context, index) {
                    final file = _filteredFiles[index];
                    return _buildFileTile(file);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFileTile(DropboxFile file) {
    Color badgeColor;
    switch (file.fileExtension) {
      case 'PDF':
        badgeColor = AppColors.plum;
        break;
      case 'EPUB':
        badgeColor = const Color(0xFF5B4FCF);
        break;
      case 'DOCX':
        badgeColor = const Color(0xFF1565C0);
        break;
      default:
        badgeColor = AppColors.moss;
    }

    return InkWell(
      onTap: () => _selectAndImport(file),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            // Badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  file.fileExtension,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (file.formattedSize.isNotEmpty) ...[
                        Text(
                          file.formattedSize,
                          style: AppTypography.inter(fontSize: 11, color: AppColors.textMute),
                        ),
                        const Text(' · ', style: TextStyle(color: AppColors.line, fontSize: 11)),
                      ],
                      Text(
                        'Dropbox',
                        style: AppTypography.inter(fontSize: 11, color: const Color(0xFF0061FF), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.paperSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.file_download_outlined, size: 16, color: AppColors.moss),
            ),
          ],
        ),
      ),
    );
  }
}
