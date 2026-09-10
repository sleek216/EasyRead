import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GoogleDriveFile {
  final String id;
  final String name;
  final String mimeType;
  final int sizeBytes;
  final DateTime? modifiedTime;
  final String? thumbnailLink;

  GoogleDriveFile({
    required this.id,
    required this.name,
    required this.mimeType,
    required this.sizeBytes,
    this.modifiedTime,
    this.thumbnailLink,
  });

  factory GoogleDriveFile.fromJson(Map<String, dynamic> json) {
    return GoogleDriveFile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Untitled Document',
      mimeType: json['mimeType']?.toString() ?? '',
      sizeBytes: int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      modifiedTime: json['modifiedTime'] != null
          ? DateTime.tryParse(json['modifiedTime'].toString())
          : null,
      thumbnailLink: json['thumbnailLink']?.toString(),
    );
  }

  String get fileExtension {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf') || mimeType.contains('pdf')) return 'PDF';
    if (lower.endsWith('.epub') || mimeType.contains('epub')) return 'EPUB';
    if (lower.endsWith('.docx') || lower.endsWith('.doc') || mimeType.contains('word')) return 'DOCX';
    if (lower.endsWith('.txt') || mimeType.contains('text')) return 'TXT';
    return 'DOC';
  }

  String get formattedSize {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.readonly',
    ],
  );

  static GoogleSignInAccount? _currentAccount;
  static GoogleSignInAccount? get currentAccount => _currentAccount;

  /// Authenticate with Google and obtain Drive read-only authorization
  static Future<GoogleSignInAccount?> signIn({bool silentOnly = false}) async {
    try {
      if (silentOnly) {
        _currentAccount = await _googleSignIn.signInSilently();
      } else {
        _currentAccount = await _googleSignIn.signInSilently();
        _currentAccount ??= await _googleSignIn.signIn();
      }
      return _currentAccount;
    } catch (e) {
      debugPrint('Google Drive Sign-In error: $e');
      if (!silentOnly) {
        try {
          _currentAccount = await _googleSignIn.signIn();
          return _currentAccount;
        } catch (_) {}
      }
      return null;
    }
  }

  /// Sign out from Google Drive session
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentAccount = null;
    } catch (_) {}
  }

  /// List reader-compatible files (PDF, EPUB, DOCX, TXT) from user's personal Google Drive
  static Future<List<GoogleDriveFile>> fetchDriveFiles({String? searchQuery}) async {
    final account = _currentAccount ?? await signIn();
    if (account == null) {
      throw Exception('Please sign in to Google to access your Drive.');
    }

    final authHeaders = await account.authHeaders;

    // Filter to supported document types and exclude trashed documents
    final docFilters = [
      "mimeType = 'application/pdf'",
      "mimeType = 'application/epub+zip'",
      "mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'",
      "mimeType = 'application/msword'",
      "mimeType = 'text/plain'",
      "name contains '.pdf'",
      "name contains '.epub'",
      "name contains '.docx'",
      "name contains '.txt'",
    ].join(' or ');

    var q = "($docFilters) and trashed = false";
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final sanitized = searchQuery.replaceAll("'", "\\'");
      q += " and name contains '$sanitized'";
    }

    final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'q': q,
      'pageSize': '100',
      'fields': 'files(id, name, mimeType, size, modifiedTime, thumbnailLink)',
      'orderBy': 'modifiedTime desc',
    });

    final response = await http.get(uri, headers: authHeaders);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = (data['files'] as List? ?? []);
      return list.map((f) => GoogleDriveFile.fromJson(Map<String, dynamic>.from(f))).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Re-prompt for auth scope if expired or permission revoked
      _currentAccount = await _googleSignIn.signIn();
      if (_currentAccount != null) {
        final newHeaders = await _currentAccount!.authHeaders;
        final retry = await http.get(uri, headers: newHeaders);
        if (retry.statusCode == 200) {
          final data = jsonDecode(retry.body);
          final list = (data['files'] as List? ?? []);
          return list.map((f) => GoogleDriveFile.fromJson(Map<String, dynamic>.from(f))).toList();
        }
      }
      throw Exception('Drive permission not granted. Please sign in again.');
    } else {
      throw Exception('Failed to load files from Google Drive (${response.statusCode})');
    }
  }

  /// Download file from Google Drive to local temp storage
  static Future<File> downloadFile(GoogleDriveFile driveFile) async {
    final account = _currentAccount ?? await signIn();
    if (account == null) {
      throw Exception('Google session expired. Please sign in again.');
    }

    final authHeaders = await account.authHeaders;
    final downloadUri = Uri.parse('https://www.googleapis.com/drive/v3/files/${driveFile.id}?alt=media');

    final response = await http.get(downloadUri, headers: authHeaders);
    if (response.statusCode != 200) {
      throw Exception('Failed to download ${driveFile.name} from Google Drive');
    }

    final tempDir = await getTemporaryDirectory();
    final cleanFileName = driveFile.name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final localPath = '${tempDir.path}/gdrive_$cleanFileName';
    final localFile = File(localPath);
    await localFile.writeAsBytes(response.bodyBytes);
    return localFile;
  }
}
