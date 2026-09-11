import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book_item.dart';

class ApiService {
  static const List<String> _baseUrls = [
    'https://easyread.aibit.services/api', // Production Server
    // 'http://172.31.2.224:8000/api', // Current Active LAN Wi-Fi IP
    // 'http://172.31.2.125:8000/api', // Previous LAN Wi-Fi IP
    // 'http://172.31.2.46:8000/api',  // Previous LAN Wi-Fi IP
    // 'http://127.0.0.1:8000/api',    // Web / Desktop / Localhost
    // 'http://10.0.2.2:8000/api',     // Android Emulator
  ];

  static String _activeBaseUrl = 'https://easyread.aibit.services/api';
  // static String _activeBaseUrl = 'http://172.31.2.224:8000/api';
  static String get baseUrl => _activeBaseUrl;
  
  static String? authToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  static void Function()? onUnauthorized;

  // Ultra-reliable request sender with automatic multi-IP failover
  static Future<http.Response> _sendWithFailover(
    Future<http.Response> Function(String base) fn, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      return await fn(_activeBaseUrl).timeout(timeout);
    } catch (_) {}

    for (final base in _baseUrls) {
      if (base == _activeBaseUrl) continue;
      try {
        final res = await fn(base).timeout(timeout);
        _activeBaseUrl = base;
        return res;
      } catch (_) {}
    }

    return await fn(_activeBaseUrl).timeout(timeout);
  }

  // Auth: Login
  static Future<Map<String, dynamic>> login(String email, String password, {String? deviceName}) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/auth/login'),
          headers: _headers,
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'password': password,
            'device_name': deviceName ?? 'Mobile App',
          }),
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        authToken = data['token'];
        return {'success': true, 'token': data['token'], 'user': data['user'], 'message': data['message'] ?? 'Login successful'};
      } else {
        final msg = data['message'] ?? (data['errors'] != null ? data['errors'].values.first[0] : 'Login failed');
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Check your connection.'};
    }
  }

  // Auth: Send Signup OTP
  static Future<Map<String, dynamic>> sendSignupOtp(String name, String email, String password) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/auth/send-signup-otp'),
          headers: _headers,
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
          }),
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'OTP sent'};
      } else {
        String msg = data['message'] ?? 'Failed to send OTP';
        if (data['errors'] != null && data['errors'] is Map) {
          final firstKey = (data['errors'] as Map).keys.first;
          msg = (data['errors'][firstKey] as List).first.toString();
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Check your connection.'};
    }
  }

  // Auth: Register
  static Future<Map<String, dynamic>> register(String name, String email, String password, String otp, {String? deviceName}) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/auth/register'),
          headers: _headers,
          body: jsonEncode({
            'name': name.trim(),
            'email': email.trim().toLowerCase(),
            'password': password,
            'otp': otp,
            'device_name': deviceName ?? 'Mobile App',
          }),
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['token'] != null) {
        authToken = data['token'];
        return {'success': true, 'token': data['token'], 'user': data['user'], 'message': data['message'] ?? 'Registration successful'};
      } else {
        String msg = data['message'] ?? 'Registration failed';
        if (data['errors'] != null && data['errors'] is Map) {
          final firstKey = (data['errors'] as Map).keys.first;
          msg = (data['errors'][firstKey] as List).first.toString();
        }
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Check your connection.'};
    }
  }

  // Auth: Forgot Password (Request 6-digit OTP via Email)
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/auth/forgot-password'),
          headers: _headers,
          body: jsonEncode({'email': email.trim().toLowerCase()}),
        ),
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': data['message'] ?? (res.statusCode == 200 ? 'OTP sent to your email.' : 'Failed to send OTP.'),
        'account_deleted': data['account_deleted'] == true,
        'retry_after': data['retry_after'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Check your connection.'};
    }
  }

  // Auth: Verify OTP Code
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/auth/verify-otp'),
          headers: _headers,
          body: jsonEncode({
            'email': email.trim().toLowerCase(),
            'otp': otp.trim(),
          }),
        ),
      );
      final data = jsonDecode(res.body);
      return {
        'success': res.statusCode == 200,
        'message': data['message'] ?? (res.statusCode == 200 ? 'OTP verified.' : 'Invalid code.'),
        'reset_token': data['reset_token'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Check your connection.'};
    }
  }

  // Auth: Reset Password & Auto Login
  static Future<Map<String, dynamic>> resetPassword({
    required String resetToken,
    required String password,
    required String passwordConfirmation,
    String? deviceName,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/auth/reset-password'),
          headers: _headers,
          body: jsonEncode({
            'reset_token': resetToken,
            'password': password,
            'password_confirmation': passwordConfirmation,
            'device_name': deviceName ?? 'Mobile App',
          }),
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        authToken = data['token'];
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message'] ?? 'Password reset successfully.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Password reset failed.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Check your connection.'};
    }
  }

  // Auth: Fetch Dynamic Social Auth Config from Admin Settings
  static Future<Map<String, dynamic>> getSocialAuthConfig() async {
    try {
      final res = await _sendWithFailover(
        (base) => http.get(Uri.parse('$base/social-auth-config'), headers: _headers),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {
      'success': true,
      'google_enabled': true,
      'google_web_client_id': '',
      'apple_enabled': true,
    };
  }

  // Auth: Social Login (Google / Apple)
  static Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String email,
    String? name,
    String? providerId,
    String? avatarUrl,
    String? idToken,
    String? deviceName,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/auth/social'),
          headers: _headers,
          body: jsonEncode({
            'provider': provider,
            'email': email.trim().toLowerCase(),
            'name': name,
            'provider_id': providerId,
            'avatar_url': avatarUrl,
            'id_token': idToken,
            'device_name': deviceName ?? 'Mobile App',
          }),
        ),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['token'] != null) {
        authToken = data['token'];
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message'] ?? 'Logged in successfully',
        };
      } else {
        final msg = data['message'] ?? 'Social login failed';
        return {
          'success': false,
          'message': msg,
          'is_active': data['is_active'] ?? true,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server. Check your connection.'};
    }
  }

  // Auth: Get Profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/user/profile'), headers: _headers));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false};
    } catch (_) {
      return {'success': false};
    }
  }

  // Auth: Realtime Live State Sync (< 20ms ping)
  static Future<Map<String, dynamic>> syncUserLiveState() async {
    try {
      if (authToken == null || authToken!.isEmpty) return {'success': false, 'not_logged_in': true};
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/user/sync'), headers: _headers));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // Extra safety: even a 200 response might carry is_active=false if account was just suspended
        if (data['is_active'] == false) {
          return {
            'success': false,
            'is_active': false,
            'message': data['message'] ?? 'Your account has been suspended by administrator.',
          };
        }
        return data;
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        // Any 401/403 on the sync route means the session is invalid or the account is suspended/deleted
        try {
          final data = jsonDecode(res.body);
          String rawMsg = data['message']?.toString().trim() ?? '';
          if (rawMsg.isEmpty || rawMsg == 'Unauthenticated.' || rawMsg.toLowerCase().contains('unauthenticated')) {
            rawMsg = res.statusCode == 403
                ? 'Your account has been suspended by EasyRead.'
                : 'Your account has been deleted by EasyRead.';
          }
          return {
            'success': false,
            'is_active': false,
            'unauthorized': true,
            'message': rawMsg,
          };
        } catch (_) {
          return {
            'success': false,
            'is_active': false,
            'unauthorized': true,
            'message': res.statusCode == 403
                ? 'Your account has been suspended by EasyRead.'
                : 'Your account has been deleted by EasyRead.',
          };
        }
      }
      // Any other failure (5xx, etc.) — silently ignore, do NOT logout
      return {'success': false, 'is_active': true};
    } catch (_) {
      // Network failure — silently ignore
      return {'success': false, 'is_active': true};
    }
  }

  // Check whether an account was deleted or suspended by EasyRead
  static Future<Map<String, dynamic>> checkAccountStatus(String email) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/auth/check-status'),
          headers: _headers,
          body: jsonEncode({'email': email.trim().toLowerCase()}),
        ),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'status': 'deleted', 'message': 'Your account has been deleted by EasyRead.'};
  }

  // Auth: Logout
  static Future<void> logout() async {
    try {
      await _sendWithFailover((base) => http.post(Uri.parse('$base/auth/logout'), headers: _headers));
    } catch (_) {}
    authToken = null;
  }

  // Library: Get Books
  static Future<List<dynamic>> getBooks({String? category, String? search}) async {
    try {
      final res = await _sendWithFailover((base) {
        String url = '$base/books?';
        if (category != null && category != 'All') url += 'category=$category&';
        if (search != null && search.isNotEmpty) url += 'search=$search&';
        return http.get(Uri.parse(url), headers: _headers);
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['books'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // Library: Continue Reading Shelf
  static Future<List<dynamic>> getContinueReading() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/library/continue-reading'), headers: _headers));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['items'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // Translation Languages — dynamically configured by Admin Studio
  static Future<List<String>> getTranslationLanguages() async {
    try {
      final res = await _sendWithFailover(
        (base) => http.get(Uri.parse('$base/translation-languages'), headers: _headers),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['languages'] is List && (data['languages'] as List).isNotEmpty) {
          return List<String>.from(data['languages']);
        }
      }
    } catch (_) {}
    return ['Urdu', 'Spanish', 'French', 'German', 'Arabic', 'Hindi', 'Chinese', 'Turkish'];
  }

  // AI Assistant Proxy — uses admin-configured LLM (Google AI Studio / OpenRouter / OpenAI)
  static Future<Map<String, dynamic>> runAiAction({
    required String action,
    required String passage,
    String targetLanguage = 'Spanish',
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/ai/assist'),
          headers: _headers,
          body: jsonEncode({
            'action': action,
            'passage': passage,
            'target_language': targetLanguage,
          }),
        ),
        timeout: const Duration(seconds: 30),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'response': 'Could not connect to AI service.'};
    }
  }

  // Vocabulary: Save Word
  static Future<Map<String, dynamic>> saveWord({
    required String word,
    String? pos,
    required String meaning,
    String? example,
    String? sourceTitle,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/vocabulary'),
          headers: _headers,
          body: jsonEncode({
            'word': word,
            'pos': pos ?? 'noun',
            'meaning': meaning,
            'example': example,
            'source_title': sourceTitle,
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false};
    }
  }

  // Vocabulary: Delete Word
  static Future<bool> deleteWord(String word) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.delete(Uri.parse('$base/vocabulary/$word'), headers: _headers),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Vocabulary: Record Flashcard Review / Mastered Status
  static Future<bool> recordVocabReview(String word, {required bool isMastered}) async {
    try {
      final cleanWord = Uri.encodeComponent(word.trim().toLowerCase());
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/vocabulary/$cleanWord/review'),
          headers: _headers,
          body: jsonEncode({'is_mastered': isMastered}),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Vocabulary: Fetch User Saved Vocabulary Bank
  static Future<Map<String, dynamic>> getVocabulary() async {
    try {
      final res = await _sendWithFailover(
        (base) => http.get(Uri.parse('$base/vocabulary'), headers: _headers),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'success': false, 'vocabulary': []};
  }

  // Backup: List user cloud backups
  static Future<List<Map<String, dynamic>>> getBackups() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/backups'), headers: _headers));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['backups'] != null) {
        return List<Map<String, dynamic>>.from(data['backups']);
      }
    } catch (_) {}
    return [];
  }

  // Backup: Create Restore Point Snapshot with rich local payload
  static Future<Map<String, dynamic>> createBackup({Map<String, dynamic>? localPayload}) async {
    try {
      // Offload massive JSON encoding to a background isolate to prevent UI freeze/ANR
      final String encodedBody = await compute(jsonEncode, localPayload ?? {});

      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/backups'),
          headers: _headers,
          body: encodedBody,
        ),
        timeout: const Duration(seconds: 60), // Increased timeout for large payloads
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network timeout creating backup'};
    }
  }

  // Backup: Restore to Point
  static Future<Map<String, dynamic>> restoreBackup(int id) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(Uri.parse('$base/backups/$id/restore'), headers: _headers),
        timeout: const Duration(seconds: 15),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network timeout restoring backup'};
    }
  }

  // In-App Notifications: Fetch all notifications & unread count
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/notifications'), headers: _headers));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return {'success': false, 'notifications': [], 'unread_count': 0};
    } catch (_) {
      return {'success': false, 'notifications': [], 'unread_count': 0};
    }
  }

  // In-App Notifications: Mark Single as Read
  static Future<bool> markNotificationRead(int id) async {
    try {
      final res = await _sendWithFailover((base) => http.post(Uri.parse('$base/notifications/$id/read'), headers: _headers));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // In-App Notifications: Mark All as Read
  static Future<bool> markAllNotificationsRead() async {
    try {
      final res = await _sendWithFailover((base) => http.post(Uri.parse('$base/notifications/mark-all-read'), headers: _headers));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // In-App Notifications: Dismiss / Delete
  static Future<bool> deleteNotification(int id) async {
    try {
      final res = await _sendWithFailover((base) => http.delete(Uri.parse('$base/notifications/$id'), headers: _headers));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Push Notifications: Register FCM Device Token with Backend
  static Future<bool> registerDeviceFcmToken(String fcmToken) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/user/fcm-token'),
          headers: _headers,
          body: jsonEncode({'fcm_token': fcmToken}),
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Sync: Pull delta updates from cloud
  static Future<Map<String, dynamic>> pullSync({String? since}) async {
    try {
      final url = since != null ? '/sync/pull?since=$since' : '/sync/pull';
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base$url'), headers: _headers));
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // User Settings: Update Cloud Settings (e.g. sync_enabled)
  // User Settings: Update Cloud Settings (e.g. sync_enabled, day_streak, total_words_read)
  static Future<Map<String, dynamic>> updateSettings({
    bool? syncEnabled,
    int? dayStreak,
    int? totalWordsRead,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/user/settings'),
          headers: _headers,
          body: jsonEncode({
            'sync_enabled': ?syncEnabled,
            'day_streak': ?dayStreak,
            'total_words_read': ?totalWordsRead,
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Sync: Push highlights & notes to cloud
  static Future<Map<String, dynamic>> pushHighlights(List<Map<String, dynamic>> highlights) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/sync/push-highlights'),
          headers: _headers,
          body: jsonEncode({'highlights': highlights}),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Sync: Delete highlight from cloud
  static Future<Map<String, dynamic>> deleteHighlight({
    required String bookTitle,
    required int paragraphIndex,
    int? bookId,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/sync/delete-highlight'),
          headers: _headers,
          body: jsonEncode({
            'book_title': bookTitle,
            'paragraph_index': paragraphIndex,
            'book_id': ?bookId,
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Sync: Push Offline Downloads to cloud
  static Future<Map<String, dynamic>> pushDownloads(List<Map<String, dynamic>> downloads) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/sync/downloads'),
          headers: _headers,
          body: jsonEncode({'downloads': downloads}),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Sync: Remove Offline Download from cloud
  static Future<Map<String, dynamic>> removeDownload(String bookTitle) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/sync/downloads/remove'),
          headers: _headers,
          body: jsonEncode({'book_title': bookTitle}),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Sync: Push Reading Progress to cloud
  static Future<Map<String, dynamic>> pushReadingProgress(
    String bookTitle,
    int progressPercent, {
    int? bookId,
    int? currentParagraph,
    bool isReset = false,
    DateTime? lastReadAt,
  }) async {
    try {
      final effectiveTime = (lastReadAt ?? DateTime.now()).toUtc().toIso8601String();
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/sync/push-progress'),
          headers: _headers,
          body: jsonEncode({
            'book_title': bookTitle,
            'progress_percent': progressPercent,
            'book_id': ?bookId,
            'current_paragraph': ?currentParagraph,
            if (isReset) 'is_reset': true,
            'last_read_at': effectiveTime,
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Sync: Remove book progress from cloud when removed from shelf
  static Future<Map<String, dynamic>> removeReadingProgress(String bookTitle, {int? bookId, String? removedAt}) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/sync/remove-progress'),
          headers: _headers,
          body: jsonEncode({
            'book_title': bookTitle,
            'book_id': ?bookId,
            'removed_at': ?removedAt,
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // User Profile: Update Name / Email
  static Future<Map<String, dynamic>> updateProfile({String? name, String? email}) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.put(
          Uri.parse('$base/user/profile'),
          headers: _headers,
          body: jsonEncode({
            if (name != null) 'name': name.trim(),
            if (email != null) 'email': email.trim().toLowerCase(),
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  // User Profile: Fetch current user profile from server
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/user/profile'), headers: _headers));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['user'] != null) {
        return data['user'];
      }
    } catch (_) {}
    return null;
  }

  // User Profile: Change Password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/user/change-password'),
          headers: _headers,
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Failed to change password'};
    }
  }

  // Apple Guideline 5.1.1: Delete Account
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final res = await _sendWithFailover((base) => http.delete(Uri.parse('$base/user/account'), headers: _headers));
      authToken = null;
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Connected Devices: Fetch live active sessions for current user
  static Future<List<Map<String, dynamic>>> getConnectedDevices() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/user/devices'), headers: _headers));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['devices'] != null) {
        return List<Map<String, dynamic>>.from(data['devices']);
      }
    } catch (_) {}
    return [];
  }

  // Connected Devices: Disconnect / revoke specific session
  static Future<Map<String, dynamic>> revokeDevice(int id) async {
    try {
      final res = await _sendWithFailover((base) => http.delete(Uri.parse('$base/user/devices/$id'), headers: _headers));
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Failed to disconnect device'};
    }
  }

  // Connected Devices: Logout from all other devices in 1 single fast API call
  static Future<Map<String, dynamic>> logoutOtherDevices() async {
    try {
      final res = await _sendWithFailover((base) => http.post(Uri.parse('$base/user/devices/logout-others'), headers: _headers));
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Failed to log out other sessions'};
    }
  }

  // Connected Devices: Logout from all devices
  static Future<Map<String, dynamic>> logoutAllDevices() async {
    try {
      final res = await _sendWithFailover((base) => http.post(Uri.parse('$base/auth/logout-all'), headers: _headers));
      authToken = null;
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Failed to log out from all devices'};
    }
  }

  // Privacy Policy: Fetch live dynamic policy set by admin
  static Future<String?> getPrivacyPolicy() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/privacy-policy')));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['privacy_policy'] != null) {
        return data['privacy_policy'].toString();
      }
    } catch (_) {}
    return null;
  }

  // Web Extractor: Extract clean pure text from any URL (0 images, stripped ads)
  static Future<Map<String, dynamic>> extractWebArticle(String url) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/web/extract'),
          headers: _headers,
          body: jsonEncode({'url': url.trim()}),
        ),
        timeout: const Duration(seconds: 15),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'message': 'Could not extract article from link'};
    }
  }

  // Plans: Fetch live subscription tiers configured by admin
  static Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/plans')));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['plans'] != null) {
        return List<Map<String, dynamic>>.from(data['plans']);
      }
    } catch (_) {}
    return [];
  }

  // RevenueCat Configuration: Fetch public API keys and entitlement ID
  static Future<Map<String, dynamic>?> getRevenueCatConfig() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/revenuecat-config')));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return data;
      }
    } catch (_) {}
    return null;
  }

  // Categories: Fetch live Admin Global Categories (For Top Filter Chips)
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/categories')));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['categories'] != null) {
        return List<Map<String, dynamic>>.from(data['categories']);
      }
    } catch (_) {}
    return [];
  }

  // Collections: Fetch live User Custom Shelves & Folders
  static Future<List<Map<String, dynamic>>> getCollections() async {
    try {
      final res = await _sendWithFailover((base) => http.get(Uri.parse('$base/collections'), headers: _headers));
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['collections'] != null) {
        return List<Map<String, dynamic>>.from(data['collections']);
      }
    } catch (_) {}
    return [];
  }

  // Collections: Create custom user collection in database
  static Future<Map<String, dynamic>> createCollection({
    required String name,
    String? colorHex,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/collections'),
          headers: _headers,
          body: jsonEncode({
            'name': name.trim(),
            'color_hex': colorHex ?? '#4B6B4A',
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Collections: Delete user custom collection from database
  static Future<Map<String, dynamic>> deleteCollection(int id) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.delete(
          Uri.parse('$base/collections/$id'),
          headers: _headers,
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Collections: Assign or remove a book to/from a user collection
  static Future<Map<String, dynamic>> assignBookToCollection({
    required String bookTitle,
    int? bookId,
    required String collectionTag,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/collections/assign-book'),
          headers: _headers,
          body: jsonEncode({
            'book_title': bookTitle.trim(),
            'book_id': ?bookId,
            'collection_tag': collectionTag.trim(),
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Subscription: Update user subscription state on backend
  static Future<Map<String, dynamic>> updateSubscription({
    required String planSlug,
    required bool isPremium,
  }) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/user/subscription'),
          headers: _headers,
          body: jsonEncode({
            'plan_slug': planSlug,
            'is_premium': isPremium,
          }),
        ),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }

  // Library: Push personal document (Web, Paste, File import) to user's cloud library
  static Future<Map<String, dynamic>> saveUserBook(BookItem book) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.post(
          Uri.parse('$base/books/import'),
          headers: _headers,
          body: jsonEncode({
            'title': book.title.trim(),
            'author': book.author ?? 'Personal Document',
            'category': book.tag.isNotEmpty ? book.tag : 'General',
            'cover_color': 'forest',
            'source_type': book.tag.isNotEmpty ? book.tag : 'imported',
            'read_time': book.meta ?? '5 min read',
            'paragraphs': book.paragraphs.isNotEmpty ? book.paragraphs : [book.title],
          }),
        ),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'success': false};
  }

  // Library: Delete personal document from cloud library
  static Future<Map<String, dynamic>> deleteUserBookFromServer(String title) async {
    try {
      final res = await _sendWithFailover(
        (base) => http.delete(
          Uri.parse('$base/books/user-doc'),
          headers: _headers,
          body: jsonEncode({
            'title': title.trim(),
          }),
        ),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'success': false};
  }

  // Dropbox Cloud Configuration
  static Future<Map<String, dynamic>> getDropboxConfig() async {
    try {
      final res = await _sendWithFailover(
        (base) => http.get(Uri.parse('$base/dropbox-config'), headers: _headers),
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {
      'success': true,
      'dropbox_enabled': true,
      'dropbox_app_key': '1j22ldywe7y316j',
      'dropbox_app_secret': '5vl09ge69dbawph',
    };
  }
}

