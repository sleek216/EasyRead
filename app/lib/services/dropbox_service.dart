import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class DropboxFile {
  final String id;
  final String name;
  final String pathLower;
  final String pathDisplay;
  final int sizeBytes;
  final DateTime? serverModified;

  DropboxFile({
    required this.id,
    required this.name,
    required this.pathLower,
    required this.pathDisplay,
    required this.sizeBytes,
    this.serverModified,
  });

  factory DropboxFile.fromJson(Map<String, dynamic> json) {
    return DropboxFile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Document',
      pathLower: json['path_lower']?.toString() ?? '',
      pathDisplay: json['path_display']?.toString() ?? '',
      sizeBytes: int.tryParse(json['size']?.toString() ?? '0') ?? 0,
      serverModified: json['server_modified'] != null
          ? DateTime.tryParse(json['server_modified'].toString())
          : null,
    );
  }

  String get fileExtension {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'PDF';
    if (lower.endsWith('.epub')) return 'EPUB';
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return 'DOCX';
    if (lower.endsWith('.txt')) return 'TXT';
    return 'DOC';
  }

  String get formattedSize {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DropboxAccount {
  final String displayName;
  final String email;
  final String accountId;

  DropboxAccount({
    required this.displayName,
    required this.email,
    required this.accountId,
  });

  factory DropboxAccount.fromJson(Map<String, dynamic> json) {
    final nameObj = json['name'] as Map<String, dynamic>?;
    return DropboxAccount(
      displayName: nameObj?['display_name']?.toString() ?? 'Dropbox User',
      email: json['email']?.toString() ?? '',
      accountId: json['account_id']?.toString() ?? '',
    );
  }
}

class DropboxService {
  static const String _tokenPrefKey = 'easyread_dropbox_access_token';
  static const String _accountPrefKey = 'easyread_dropbox_account_info';
  static const MethodChannel _channel = MethodChannel('com.easyread.app/media_saver');

  static String defaultAppKey = '1j22ldywe7y316j';
  static String defaultAppSecret = '5vl09ge69dbawph';

  /// Open external URL in device browser
  static Future<bool> openUrl(String url) async {
    try {
      final res = await _channel.invokeMethod('launchUrl', {'url': url});
      return res == true;
    } catch (_) {
      return false;
    }
  }

  /// Get credentials dynamically from backend or fallback to defaults
  static Future<Map<String, String>> getCredentials() async {
    try {
      final config = await ApiService.getDropboxConfig();
      final key = config['dropbox_app_key']?.toString().trim();
      final secret = config['dropbox_app_secret']?.toString().trim();
      return {
        'app_key': (key != null && key.isNotEmpty) ? key : defaultAppKey,
        'app_secret': (secret != null && secret.isNotEmpty) ? secret : defaultAppSecret,
      };
    } catch (_) {
      return {
        'app_key': defaultAppKey,
        'app_secret': defaultAppSecret,
      };
    }
  }

  /// URL for OAuth Authorization
  static Future<String> getAuthorizeUrl() async {
    final creds = await getCredentials();
    final key = creds['app_key']!;
    return 'https://www.dropbox.com/oauth2/authorize?client_id=$key&response_type=code&token_access_type=offline';
  }

  /// Check if a token is saved
  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenPrefKey);
  }

  /// Get cached account information
  static Future<DropboxAccount?> getCachedAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountPrefKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DropboxAccount.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// Verify token and fetch user profile
  static Future<DropboxAccount> fetchAccount(String token) async {
    final res = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/users/get_current_account'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final account = DropboxAccount.fromJson(data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accountPrefKey, jsonEncode(data));
      return account;
    } else {
      throw Exception('Invalid or expired Dropbox token (${res.statusCode}): ${res.body}');
    }
  }

  /// Connect using an authorization code or direct access token
  static Future<DropboxAccount> connectWithCodeOrToken(String rawInput) async {
    final input = rawInput.trim();
    if (input.isEmpty) throw Exception('Please enter a valid code or token.');

    final creds = await getCredentials();
    final appKey = creds['app_key']!;
    final appSecret = creds['app_secret']!;

    String token = input;

    // If it looks like an auth code, exchange it for an access token
    if (!input.startsWith('sl.u.') && input.length < 60) {
      final tokenRes = await http.post(
        Uri.parse('https://api.dropboxapi.com/oauth2/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': input,
          'grant_type': 'authorization_code',
          'client_id': appKey,
          'client_secret': appSecret,
        },
      );

      if (tokenRes.statusCode == 200) {
        final tokenData = jsonDecode(tokenRes.body) as Map<String, dynamic>;
        token = tokenData['access_token']?.toString() ?? '';
      } else {
        // Fallback: try using input directly in case user pasted an access token
        token = input;
      }
    }

    // Verify token with get_current_account
    final account = await fetchAccount(token);

    // Save token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenPrefKey, token);

    return account;
  }

  /// Disconnect session
  static Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenPrefKey);
    await prefs.remove(_accountPrefKey);
  }

  /// List reader-compatible files (PDF, EPUB, DOCX, TXT)
  static Future<List<DropboxFile>> fetchFiles({String? searchQuery}) async {
    final token = await getSavedToken();
    if (token == null) {
      throw Exception('Not connected to Dropbox. Please authenticate first.');
    }

    final res = await http.post(
      Uri.parse('https://api.dropboxapi.com/2/files/list_folder'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'path': '',
        'recursive': true,
        'include_media_info': false,
        'include_deleted': false,
      }),
    );

    if (res.statusCode != 200) {
      if (res.statusCode == 401) {
        await disconnect();
        throw Exception('Your Dropbox session expired. Please connect again.');
      }
      throw Exception('Could not fetch Dropbox files (${res.statusCode}).');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final entries = data['entries'] as List<dynamic>? ?? [];

    final allowedExts = ['.pdf', '.epub', '.docx', '.doc', '.txt'];
    final List<DropboxFile> files = [];

    for (final item in entries) {
      if (item is Map<String, dynamic> && item['.tag'] == 'file') {
        final name = item['name']?.toString().toLowerCase() ?? '';
        if (allowedExts.any((ext) => name.endsWith(ext))) {
          files.add(DropboxFile.fromJson(item));
        }
      }
    }

    // Sort by server modified descending
    files.sort((a, b) {
      if (a.serverModified == null && b.serverModified == null) return 0;
      if (a.serverModified == null) return 1;
      if (b.serverModified == null) return -1;
      return b.serverModified!.compareTo(a.serverModified!);
    });

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      return files.where((f) => f.name.toLowerCase().contains(q)).toList();
    }

    return files;
  }

  /// Download file bytes from Dropbox and save to temporary local file
  static Future<File> downloadFile(DropboxFile file) async {
    final token = await getSavedToken();
    if (token == null) {
      throw Exception('Not connected to Dropbox.');
    }

    final res = await http.post(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      headers: {
        'Authorization': 'Bearer $token',
        'Dropbox-API-Arg': jsonEncode({'path': file.id.isNotEmpty ? file.id : file.pathLower}),
      },
    );

    if (res.statusCode == 200) {
      final tempDir = await getTemporaryDirectory();
      final localFile = File('${tempDir.path}/${file.name}');
      await localFile.writeAsBytes(res.bodyBytes, flush: true);
      return localFile;
    } else {
      throw Exception('Failed to download file from Dropbox (${res.statusCode}).');
    }
  }
}
