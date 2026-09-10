import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/book_item.dart';
import '../models/dictionary_entry.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../services/pdf_reader_service.dart';
import '../services/purchase_service.dart';
import '../services/dictionary_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';

class EasyReadProvider extends ChangeNotifier {
  static EasyReadProvider? instance;
  final FlutterTts flutterTts = FlutterTts();

  EasyReadProvider({
    String? initialToken,
    String? initialUserJson,
    bool initialIsOnboarded = false,
  }) {
    instance = this;
    if (initialToken != null && initialToken.isNotEmpty) {
      ApiService.authToken = initialToken;
      isLoggedIn = true;
      isOnboarding = false;
      if (initialUserJson != null) {
        try {
          currentUser = jsonDecode(initialUserJson);
          currentUserName = currentUser?['name'] ?? currentUserName;
          currentUserEmail = currentUser?['email'] ?? currentUserEmail;
          isPremium = currentUser?['is_premium'] == true;
          aiFreeUsesLeft = currentUser?['ai_free_uses_left'] ?? aiFreeUsesLeft;
        } catch (_) {}
      }
    } else if (initialIsOnboarded) {
      isOnboarding = false;
    }

    // Register push notification deactivation / deletion listener
    PushNotificationService.onDeactivationReceived = (action, message) {
      logout(keepDeactivationNotice: true);
      showDeactivationNotice(message.isNotEmpty
          ? message
          : (action == 'account_suspended'
              ? 'Your account has been suspended by EasyRead.'
              : 'Your account has been deleted by EasyRead.'));
    };

    _initTts();
    _loadSavedSession();
    _initSharingIntent();
    DictionaryService.initCache();
    fetchDynamicCategories();
    fetchDynamicCollections();
    fetchDynamicPlans();
    fetchDynamicBooks();
    initRevenueCat();
    fetchSocialAuthConfig();
    fetchTranslationLanguages();
    ApiService.onUnauthorized = _handleUnauthorizedServerResponse;
    _startLiveSyncTimer();
  }

  void _handleUnauthorizedServerResponse() {
    // NOTE: This is called on any global 401/403 from api_service.dart.
    // We intentionally do NOT force-logout here to avoid logging out on
    // temporary network blips or server errors.
    // Suspended/deactivated user detection is handled exclusively by
    // syncUserLiveState() which checks is_active==false from /user/sync endpoint.
    // This keeps the auth flow clean and prevents false logouts.
  }

  void _initSharingIntent() {
    try {
      ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
        if (value.isNotEmpty && value.first.path.isNotEmpty) {
          handleIncomingSharedFile(value.first.path);
        }
      }, onError: (_) {});

      ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
        if (value.isNotEmpty && value.first.path.isNotEmpty) {
          handleIncomingSharedFile(value.first.path);
          ReceiveSharingIntent.instance.reset();
        }
      }).catchError((_) {});
    } catch (_) {}
  }

  // Navigation and onboarding state
  bool isOnboarding = true;
  int onboardStep = 0;
  String authMode = 'login';
  final Set<String> selectedPrefs = {};
  String activeTab = 'library'; // 'library', 'reader', 'vocab', 'profile'

  // Pending shared file — opened via "Open With" before login
  String? pendingSharedFilePath;

  // User & Auth state
  bool isLoggedIn = false;
  Map<String, dynamic>? currentUser;
  String currentUserName = 'Guest Reader';
  String currentUserEmail = 'reader@EasyRead.com';
  bool isAuthLoading = false;

  // Real-time Connected Devices State (Auto-synced across devices every few seconds)
  List<Map<String, dynamic>> connectedDevices = [];

  Future<void> refreshConnectedDevices() async {
    try {
      final list = await ApiService.getConnectedDevices();
      connectedDevices = list;
      notifyListeners();
    } catch (_) {}
  }

  // Social Auth Configuration (Dynamically synced from Admin Panel)
  bool isGoogleAuthEnabled = true;
  String googleWebClientId = '';
  bool isAppleAuthEnabled = true;

  Future<void> fetchSocialAuthConfig() async {
    try {
      final config = await ApiService.getSocialAuthConfig();
      if (config['success'] == true) {
        isGoogleAuthEnabled = config['google_enabled'] == true;
        googleWebClientId = config['google_web_client_id'] ?? '';
        isAppleAuthEnabled = config['apple_enabled'] == true;
        notifyListeners();
      }
    } catch (_) {}
  }

  // Translation Languages (Dynamically configured in Admin Studio)
  List<String> availableTranslationLanguages = ['Urdu', 'Spanish', 'French', 'German', 'Arabic', 'Hindi', 'Chinese', 'Turkish'];
  String selectedTranslationLanguage = 'Urdu';

  Future<void> fetchTranslationLanguages() async {
    try {
      final langs = await ApiService.getTranslationLanguages();
      if (langs.isNotEmpty) {
        availableTranslationLanguages = langs;
      }
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('preferred_translation_language');
      if (saved != null && availableTranslationLanguages.contains(saved)) {
        selectedTranslationLanguage = saved;
      } else if (availableTranslationLanguages.isNotEmpty) {
        selectedTranslationLanguage = availableTranslationLanguages.first;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setTranslationLanguage(String lang) async {
    selectedTranslationLanguage = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_translation_language', lang);
    } catch (_) {}
  }

  // Document Loading State
  bool isDocumentLoading = false;

  void setDocumentLoading(bool loading) {
    isDocumentLoading = loading;
    notifyListeners();
  }

  // Plan state
  bool isPremium = false;
  String? purchasedPlanId;
  String? activePlanName;
  int aiFreeUsesLeft = 10;
  static const int freeVocabLimit = 30;
  bool syncEnabled = false;
  String? lastBackupTime;

  String get planDisplayName {
    if (activePlanName != null && activePlanName!.trim().isNotEmpty) {
      final name = activePlanName!.trim();
      if (name.toLowerCase() == 'free tier' || name.toLowerCase() == 'free') {
        return isPremium ? 'Plus Member' : 'Free plan';
      }
      return name;
    }
    return isPremium ? 'Plus Member' : 'Free plan';
  }


  // Offline Downloads State
  List<BookItem> downloadedBooks = [];
  final Set<String> downloadingBookTitles = {};

  // Realtime Live State Sync & Gating
  Timer? _liveSyncTimer;
  Timer? _deactivationNoticeTimer;
  String? deactivationNotice;

  // In-App Notification Center State
  int unreadNotificationCount = 0;
  List<Map<String, dynamic>> notificationsList = [];
  bool isLoadingNotifications = false;

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!isLoggedIn) return;
    if (!silent) {
      isLoadingNotifications = true;
      notifyListeners();
    }
    try {
      final res = await ApiService.getNotifications();
      if (res['success'] == true) {
        if (res['notifications'] is List) {
          notificationsList = List<Map<String, dynamic>>.from(res['notifications']);
        }
        if (res['unread_count'] is num) {
          unreadNotificationCount = (res['unread_count'] as num).toInt();
        }
      }
    } catch (_) {}
    isLoadingNotifications = false;
    notifyListeners();
  }

  Future<void> markNotificationRead(int id) async {
    // Optimistic local update
    for (var n in notificationsList) {
      if (n['id'] == id) {
        if (n['is_read'] != true) {
          n['is_read'] = true;
          unreadNotificationCount = (unreadNotificationCount - 1).clamp(0, 9999);
        }
        break;
      }
    }
    notifyListeners();
    await ApiService.markNotificationRead(id);
  }

  Future<void> markAllNotificationsRead() async {
    for (var n in notificationsList) {
      n['is_read'] = true;
    }
    unreadNotificationCount = 0;
    notifyListeners();
    await ApiService.markAllNotificationsRead();
  }

  Future<void> deleteNotification(int id) async {
    final removed = notificationsList.firstWhere((n) => n['id'] == id, orElse: () => {});
    if (removed.isNotEmpty && removed['is_read'] != true) {
      unreadNotificationCount = (unreadNotificationCount - 1).clamp(0, 9999);
    }
    notificationsList.removeWhere((n) => n['id'] == id);
    notifyListeners();
    await ApiService.deleteNotification(id);
  }

  void clearDeactivationNotice() {
    _deactivationNoticeTimer?.cancel();
    _deactivationNoticeTimer = null;
    deactivationNotice = null;
    notifyListeners();
  }

  void showDeactivationNotice(String message) {
    _deactivationNoticeTimer?.cancel();
    deactivationNotice = message;
    notifyListeners();
    // Auto-dismiss popup after exactly 5 seconds
    _deactivationNoticeTimer = Timer(const Duration(seconds: 5), () {
      deactivationNotice = null;
      notifyListeners();
    });
  }

  void _startLiveSyncTimer() {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (isLoggedIn) {
        syncUserLiveState();
      }
    });
  }

  void _stopLiveSyncTimer() {
    _liveSyncTimer?.cancel();
    _liveSyncTimer = null;
  }

  Future<void> syncUserLiveState() async {
    if (!isLoggedIn || ApiService.authToken == null) return;
    try {
      final res = await ApiService.syncUserLiveState();

      // 1. Account suspended / deactivated / session revoked by admin
      // is_active == false is now the single reliable signal from api_service.dart
      // for ALL 401/403/deactivation scenarios.
      // Network failures always return is_active == true so they are silently ignored.
      if (res['is_active'] == false) {
        final emailToCheck = currentUserEmail;
        String notice = res['message']?.toString() ?? '';
        
        // If message is generic, accurately check whether it was deleted or suspended
        if (notice.isEmpty || notice == 'Unauthenticated.' || notice.toLowerCase().contains('unauthenticated') || notice.contains('expired')) {
          if (emailToCheck.isNotEmpty && emailToCheck != 'guest@EasyRead.com') {
            final check = await ApiService.checkAccountStatus(emailToCheck);
            notice = check['message']?.toString() ?? (check['status'] == 'suspended'
                ? 'Your account has been suspended by EasyRead.'
                : 'Your account has been deleted by EasyRead.');
          } else {
            notice = 'Your account has been suspended by EasyRead.';
          }
        }
        
        await logout(keepDeactivationNotice: true);
        showDeactivationNotice(notice);
        return;
      }


      // 2. State & Subscription Updates
      if (res['success'] == true) {
        deactivationNotice = null; // Clear any previous deactivation warning
        bool stateChanged = false;
        final newPremium = res['is_premium'] == true;
        final newPlanId = res['plan_id']?.toString() ?? res['subscription_plan']?.toString();

        final newPlanName = res['subscription_plan']?.toString();

        if (isPremium != newPremium || purchasedPlanId != newPlanId || activePlanName != newPlanName) {
          isPremium = newPremium;
          purchasedPlanId = newPlanId;
          activePlanName = newPlanName;
          stateChanged = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_premium', isPremium);
          if (purchasedPlanId != null) {
            await prefs.setString('purchased_plan_id', purchasedPlanId!);
          } else {
            await prefs.remove('purchased_plan_id');
          }
          if (activePlanName != null) {
            await prefs.setString('active_plan_name', activePlanName!);
          } else {
            await prefs.remove('active_plan_name');
          }
        }

        if (res['feature_permissions'] != null && res['feature_permissions'] is Map) {
          final newPerms = Map<String, bool>.from(res['feature_permissions']);
          if (jsonEncode(newPerms) != jsonEncode(userEntitlements)) {
            userEntitlements = newPerms;
            stateChanged = true;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_entitlements', jsonEncode(userEntitlements));
          }
        }

        // 3. Cross-Device Sync Switch State (guarded against overwriting immediate local user action)
        final bool recentlyToggledLocally = _lastLocalSyncToggleTime != null &&
            DateTime.now().difference(_lastLocalSyncToggleTime!).inSeconds < 15;

        if (!recentlyToggledLocally && res.containsKey('sync_enabled') && res['sync_enabled'] != null) {
          final serverSync = res['sync_enabled'] == true;
          if (syncEnabled != serverSync) {
            syncEnabled = serverSync;
            stateChanged = true;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sync_enabled', syncEnabled);
          }
        }

        // 4. Streak & Words Read Sync across devices
        final prefs = await SharedPreferences.getInstance();
        if (res.containsKey('day_streak') && res['day_streak'] != null) {
          final serverStreak = (res['day_streak'] as num).toInt();
          if (serverStreak > dayStreak) {
            dayStreak = serverStreak;
            stateChanged = true;
            await prefs.setInt('day_streak', dayStreak);
          }
        }
        if (res.containsKey('total_words_read') && res['total_words_read'] != null) {
          final serverWords = (res['total_words_read'] as num).toInt();
          if (serverWords > totalWordsRead) {
            totalWordsRead = serverWords;
            stateChanged = true;
            await prefs.setInt('total_words_read', totalWordsRead);
          }
        }

        // 5. Real-Time Connected Devices Sync
        if (res['devices'] is List) {
          final newDevices = List<Map<String, dynamic>>.from(res['devices']);
          if (jsonEncode(newDevices) != jsonEncode(connectedDevices)) {
            connectedDevices = newDevices;
            stateChanged = true;
          }
        }

        // 6. Live Unread Notifications Badge Sync & Sound Alert
        if (res.containsKey('unread_notifications_count') && res['unread_notifications_count'] != null) {
          final count = (res['unread_notifications_count'] as num).toInt();
          if (unreadNotificationCount != count) {
            if (count > unreadNotificationCount && unreadNotificationCount != 0) {
              // Play Native Alert Chime & Haptic Vibration on new notification
              try {
                SystemSound.play(SystemSoundType.alert);
                HapticFeedback.mediumImpact();
              } catch (_) {}
            }
            unreadNotificationCount = count;
            stateChanged = true;
          }
        }

        if (stateChanged) {
          notifyListeners();
        }

        // 6. Continuous background delta sync when enabled
        if (syncEnabled) {
          performLiveSync();
        }
      }
    } catch (_) {}
  }

  // Dynamic Feature Entitlements (Controlled by Admin Panel Packages)
  Map<String, bool> userEntitlements = {};

  bool get isAdmin => currentUser?['role'] == 'admin';

  /// Dynamic Feature Entitlements & Gating Check (Live from Database)
  bool hasFeature(String featureKey) {
    if (isAdmin) return true;
    if (isPremium) return true;
    return false;
  }

  /// Real-time live check before performing a gated action
  Future<bool> checkFeatureAccess(String featureKey) async {
    if (isAdmin) return true;
    try {
      // Fast live ping to guarantee 100% synchronization with Admin Studio
      await syncUserLiveState();
    } catch (_) {}
    return hasFeature(featureKey);
  }

  // Search & Filter
  String? activeCollectionFilter;
  bool showFavoritesOnly = false;
  String selectedTag = 'All';

  // Reader settings
  double readerFontSize = 16.0;
  bool smartReaderMode = true;
  Color readerBackground = AppColors.paper;
  Color readerTextColor = AppColors.textDark;

  // Active Reader Content
  String readerTitle = 'EasyRead Reader';
  String readerByline = 'Tap any book from your Library to begin reading';
  String smartBannerText = 'Clean Reader Mode: Powered by EasyRead Studio';
  final Set<String> bookmarkedTitles = {};

  // Paragraphs (Dynamic from selected book)
  List<String> articleParagraphs = [];

  // Highlights
  final List<HighlightItem> highlights = [];
  Map<String, List<HighlightItem>> bookHighlights = {};

  // Vocabulary & Live Learning Stats (Non-hardcoded)
  final List<String> vocabWords = [];
  final Set<String> masteredWords = {};
  int dayStreak = 1;
  int totalWordsRead = 0;
  int get masteredWordsCount => masteredWords.length;

  // User Local Books (PDFs, Web articles imported on device)
  List<BookItem> userLocalBooks = [];

  // Continue Shelf (Dynamic from Recently Opened & Local Books)
  List<BookItem> continueShelf = [];

  // Retained Library Books: Tracks all books/documents user has opened, imported, favorited, or assigned
  // Guarantees they remain in "Your Library" even if removed from the "Continue Reading" shelf!
  Set<String> retainedLibraryBookTitles = {};

  // Deleted user documents tombstone: specifically for documents permanently deleted from Your Library
  Map<String, String> _deletedUserDocTitles = {};

  // User-scoped storage key helper (ensures strict multi-user privacy on shared devices)
  String _userKey(String baseKey) {
    final uid = currentUser?['id']?.toString();
    if (uid != null && uid.isNotEmpty) {
      return '${baseKey}_u$uid';
    }
    if (currentUserEmail.isNotEmpty && currentUserEmail != 'guest@EasyRead.com') {
      return '${baseKey}_${currentUserEmail.toLowerCase().trim()}';
    }
    return baseKey;
  }

  // Complete clean wipe of active user state from memory
  void _clearActiveUserMemory() {
    continueShelf.clear();
    userLocalBooks.clear();
    retainedLibraryBookTitles.clear();
    _deletedUserDocTitles.clear();
    vocabWords.clear();
    masteredWords.clear();
    highlights.clear();
    bookHighlights.clear();
    collections.clear();
    activeCollectionFilter = null;
    bookCollections.clear();
    downloadedBooks.clear();
    _removedBooks.clear();
    _pendingRemovedBooks.clear();
    connectedDevices.clear();
    bookmarkedTitles.clear();
    dayStreak = 1;
    totalWordsRead = 0;
    syncEnabled = false;
    lastBackupTime = null;
    notificationsList.clear();
    unreadNotificationCount = 0;
    for (var b in libraryItems) {
      b.progress = 0;
      b.lastReadAt = null;
      b.isFavorite = false;
    }
  }

  // Tombstones for books removed from Continue Reading shelf: Map of normalized title -> UTC ISO timestamp
  Map<String, String> _removedBooks = {};
  // Pending removals to be pushed to the backend when sync is enabled/online
  List<String> _pendingRemovedBooks = [];

  void _unremoveBook(String bookTitle) {
    final normTitle = bookTitle.trim().toLowerCase();
    if (_removedBooks.containsKey(normTitle) || _pendingRemovedBooks.contains(bookTitle)) {
      _removedBooks.remove(normTitle);
      _pendingRemovedBooks.remove(bookTitle);
      _saveRemovedBooks();
    }
  }

  Future<void> _saveRemovedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tJson = jsonEncode(_removedBooks);
      final pJson = jsonEncode(_pendingRemovedBooks);
      await prefs.setString(_userKey('removed_books_tombstones'), tJson);
      await prefs.setString(_userKey('pending_removed_books'), pJson);
      await prefs.setString('removed_books_tombstones', tJson);
      await prefs.setString('pending_removed_books', pJson);
    } catch (_) {}
  }

  Future<void> _saveRetainedLibraryBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(retainedLibraryBookTitles.toList());
      await prefs.setString(_userKey('retained_library_book_titles'), jsonStr);
      await prefs.setString('retained_library_book_titles', jsonStr);
    } catch (_) {}
  }

  Future<void> _saveDeletedUserDocTitles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_deletedUserDocTitles);
      await prefs.setString(_userKey('deleted_user_doc_titles'), jsonStr);
      await prefs.setString('deleted_user_doc_titles', jsonStr);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _pushReadingProgressSafe(
    String bookTitle,
    int progressPercent, {
    int? currentParagraph,
    bool isReset = false,
    DateTime? lastReadAt,
  }) async {
    final res = await ApiService.pushReadingProgress(
      bookTitle,
      progressPercent,
      currentParagraph: currentParagraph,
      isReset: isReset,
      lastReadAt: lastReadAt,
    );
    if (res['is_removed'] == true) {
      final normTitle = bookTitle.trim().toLowerCase();
      _removedBooks[normTitle] = (res['last_read_at'] ?? DateTime.now().toUtc().toIso8601String()).toString();
      _pendingRemovedBooks.remove(bookTitle);
      _saveRemovedBooks();
      continueShelf.removeWhere((b) => b.title.trim().toLowerCase() == normTitle);
      for (var b in userLocalBooks) {
        if (b.title.trim().toLowerCase() == normTitle) b.progress = 0;
      }
      for (var b in libraryItems) {
        if (b.title.trim().toLowerCase() == normTitle) b.progress = 0;
      }
      _saveLocalBooks();
      notifyListeners();
    }
    return res;
  }

  // Library Items / Featured Reads (Curated Official Books from Admin Database Only)
  List<BookItem> libraryItems = [];

  /// Featured Reads: ONLY curated official books added by Admin (never contains user external/imported docs)
  List<BookItem> get featuredBooks {
    return libraryItems.where((b) {
      if (b.userId != null) return false;
      final norm = normalizeBookTitle(b.title);
      final isUserDoc = userLocalBooks.any((u) => normalizeBookTitle(u.title) == norm);
      return !isUserDoc;
    }).toList();
  }

  /// Recent Views: Books the THIS user has actually opened/read, sorted by most recent first.
  /// Merges libraryItems + userLocalBooks + continueShelf, deduplicates, and filters
  /// to only those with lastReadAt != null OR readProgress > 0.
  List<BookItem> get recentlyViewedBooks {
    final seen = <String>{};
    final all = <BookItem>[];
    for (var b in [...continueShelf, ...userLocalBooks, ...libraryItems]) {
      final norm = b.title.trim().toLowerCase();
      if (!seen.contains(norm)) {
        seen.add(norm);
        all.add(b);
      }
    }
    // Only keep books user has actually interacted with, excluding removed/deleted tombstones
    final viewed = all.where((b) {
      final norm = b.title.trim().toLowerCase();
      if (_removedBooks.containsKey(norm)) return false;
      return b.lastReadAt != null || (b.progress != null && b.progress! > 0);
    }).toList();
    // Sort by lastReadAt descending (most recently read first)
    viewed.sort((a, b) {
      final aTime = a.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return viewed;
  }

  /// Canonical book title normalizer: strips file extensions (.pdf, .epub, .txt, .docx),
  /// underscores, dashes, extra whitespace, and converts to lowercase.
  /// Guarantees zero duplicate entries across file imports, web articles, and shelves.
  String normalizeBookTitle(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\.(pdf|epub|txt|docx?|doc|html?)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Your Library: ALL user-owned books, saved web articles, pasted text, and imported documents.
  /// Preserves all userLocalBooks even if removed from the Continue Reading shelf.
  /// Also includes any books currently on the Continue Reading shelf or marked as favorite.
  List<BookItem> get userLibraryBooks {
    final seen = <String>{};
    final all = <BookItem>[];

    // 1. All user local documents (Imported files, Web articles, Pasted text)
    // These belong permanently to user's library and stay even if removed from continue shelf!
    for (var b in userLocalBooks) {
      final norm = normalizeBookTitle(b.title);
      if (norm.isNotEmpty && !seen.contains(norm)) {
        seen.add(norm);
        all.add(b);
      }
    }

    // 2. Books currently in active Continue Reading shelf
    for (var b in continueShelf) {
      final norm = normalizeBookTitle(b.title);
      if (norm.isNotEmpty && !seen.contains(norm)) {
        seen.add(norm);
        all.add(b);
      }
    }

    // 3. Any official catalog books that the user opened/read, favorited, assigned to collections, or retained in library
    for (var b in libraryItems) {
      final norm = normalizeBookTitle(b.title);
      if (norm.isNotEmpty && !seen.contains(norm)) {
        final isSavedByUser = retainedLibraryBookTitles.contains(norm) ||
            b.isFavorite ||
            bookCollections.containsKey(b.title.trim().toLowerCase()) ||
            bookCollections.containsKey(norm);
        if (isSavedByUser) {
          seen.add(norm);
          all.add(b);
        }
      }
    }

    // Sort by most recently interacted (lastReadAt) or maintain insertion order
    all.sort((a, b) {
      final aTime = a.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastReadAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    return all;
  }

  // Admin Global Categories (For Top Filters & Classification)
  List<CategoryItem> categories = [];

  // User Custom Collections & Shelves (Created by Reader in Mobile App)
  List<CollectionItem> collections = [];

  // User's Book-to-Collection mappings: Map of normalized title -> collection tag
  Map<String, String> bookCollections = {};

  void _applyBookCollections() {
    if (bookCollections.isEmpty) return;
    for (var b in libraryItems) {
      final norm = b.title.trim().toLowerCase();
      if (bookCollections.containsKey(norm)) {
        b.tag = bookCollections[norm]!;
      }
    }
    for (var b in userLocalBooks) {
      final norm = b.title.trim().toLowerCase();
      if (bookCollections.containsKey(norm)) {
        b.tag = bookCollections[norm]!;
      }
    }
    for (var b in continueShelf) {
      final norm = b.title.trim().toLowerCase();
      if (bookCollections.containsKey(norm)) {
        b.tag = bookCollections[norm]!;
      }
    }
  }

  Future<void> _saveBookCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(bookCollections);
      await prefs.setString(_userKey('book_collection_mappings'), encoded);
      await prefs.setString('book_collection_mappings', encoded);
    } catch (_) {}
  }

  int getBookCountForCollection(String collectionTag) {
    final norm = collectionTag.toLowerCase();
    final seen = <String>{};
    int count = 0;
    for (var b in [...libraryItems, ...userLocalBooks, ...continueShelf]) {
      final normTitle = b.title.trim().toLowerCase();
      if (!seen.contains(normTitle)) {
        seen.add(normTitle);
        final tag = (bookCollections[normTitle] ?? b.tag).toLowerCase();
        if (tag == norm) {
          count++;
        }
      }
    }
    return count;
  }

  // Plans (Dynamic from database)
  List<PlanItem> plans = [
    PlanItem(id: 'monthly', label: 'Monthly', price: 'R29', sub: 'billed monthly'),
    PlanItem(id: 'quarterly', label: '3 Months', price: 'R69', sub: 'R23/mo', badge: 'Popular'),
    PlanItem(id: 'biannual', label: '6 Months', price: 'R129', sub: 'R21.50/mo'),
    PlanItem(id: 'yearly', label: 'Yearly', price: 'R189', sub: 'R15.75/mo', badge: 'Best value'),
  ];
  String selectedPlanId = 'monthly';

  // Dictionary database
  final Map<String, DictionaryEntry> dictionary = {
    "ambiguous": DictionaryEntry(
      word: "ambiguous",
      pos: "adjective",
      meaning: "Open to more than one interpretation; not having one obvious meaning.",
      example: "Her reply was deliberately ambiguous.",
      synonyms: ["unclear", "vague", "equivocal"],
      origin: "From Latin ambiguus, “doubtful, shifting.”",
    ),
    "ephemeral": DictionaryEntry(
      word: "ephemeral",
      pos: "adjective",
      meaning: "Lasting for a very short time.",
      example: "The joy of finishing a good book is ephemeral, but the ideas can stay for years.",
      synonyms: ["fleeting", "transient", "momentary"],
      origin: "From Greek ephemeros, “lasting only a day.”",
    ),
    "eloquent": DictionaryEntry(
      word: "eloquent",
      pos: "adjective",
      meaning: "Fluent and persuasive in speaking or writing.",
      example: "She made an eloquent case for reading before bed.",
      synonyms: ["articulate", "expressive", "fluent"],
      origin: "From Latin eloqui, “to speak out.”",
    ),
    "resilience": DictionaryEntry(
      word: "resilience",
      pos: "noun",
      meaning: "The capacity to recover quickly from difficulty.",
      example: "Slow reading builds a kind of mental resilience.",
      synonyms: ["toughness", "adaptability", "hardiness"],
      origin: "From Latin resilire, “to rebound, spring back.”",
    ),
    "nostalgia": DictionaryEntry(
      word: "nostalgia",
      pos: "noun",
      meaning: "A sentimental longing for the past.",
      example: "The smell of an old paperback brings a wave of nostalgia.",
      synonyms: ["longing", "reminiscence", "wistfulness"],
      origin: "From Greek nostos (return home) + algos (pain).",
    ),
    "serendipity": DictionaryEntry(
      word: "serendipity",
      pos: "noun",
      meaning: "The occurrence of finding something valuable by chance.",
      example: "Browsing a library shelf still offers a kind of serendipity an algorithm can't.",
      synonyms: ["chance", "fortune", "luck"],
      origin: "Coined by Horace Walpole in 1754, from the Persian tale The Three Princes of Serendip.",
    ),
    "immersive": DictionaryEntry(
      word: "immersive",
      pos: "adjective",
      meaning: "Providing deep involvement or absorption in an activity.",
      example: "A quiet room makes for a more immersive reading session.",
      synonyms: ["engrossing", "absorbing", "captivating"],
      origin: "From Latin immergere, “to dip into.”",
    ),
    "fragmented": DictionaryEntry(
      word: "fragmented",
      pos: "adjective",
      meaning: "Broken up into small, disconnected parts.",
      example: "Constant notifications leave our attention fragmented.",
      synonyms: ["disjointed", "scattered", "broken"],
      origin: "From Latin fragmentum, “a piece broken off.”",
    ),
    "deliberate": DictionaryEntry(
      word: "deliberate",
      pos: "adjective",
      meaning: "Done consciously and intentionally.",
      example: "Reading slowly is a deliberate act of attention.",
      synonyms: ["intentional", "purposeful", "calculated"],
      origin: "From Latin deliberare, “to weigh well.”",
    ),
    "cognition": DictionaryEntry(
      word: "cognition",
      pos: "noun",
      meaning: "The mental action of acquiring knowledge and understanding.",
      example: "Researchers study how reading shapes cognition over a lifetime.",
      synonyms: ["thinking", "perception", "understanding"],
      origin: "From Latin cognoscere, “to get to know.”",
    ),
  };





  void _loadUserScopedData(SharedPreferences prefs) {
    final bool isUserAuthenticated = isLoggedIn && currentUserEmail.isNotEmpty && currentUserEmail != 'guest@EasyRead.com';

    // 1. Load persisted vocabulary words & learning stats
    final savedMastered = isUserAuthenticated
        ? prefs.getStringList(_userKey('saved_mastered_words'))
        : prefs.getStringList('saved_mastered_words');
    if (savedMastered != null && savedMastered.isNotEmpty) {
      masteredWords.clear();
      masteredWords.addAll(savedMastered);
    }

    final savedVocab = isUserAuthenticated
        ? prefs.getStringList(_userKey('saved_vocab_words'))
        : prefs.getStringList('saved_vocab_words');
    if (savedVocab != null && savedVocab.isNotEmpty) {
      vocabWords.clear();
      vocabWords.addAll(savedVocab.where((w) => !masteredWords.contains(w.toLowerCase().trim())));
    }

    totalWordsRead = isUserAuthenticated
        ? (prefs.getInt(_userKey('total_words_read')) ?? 0)
        : (prefs.getInt('total_words_read') ?? 0);

    dayStreak = isUserAuthenticated
        ? (prefs.getInt(_userKey('day_streak')) ?? 1)
        : (prefs.getInt('day_streak') ?? 1);

    lastBackupTime = isUserAuthenticated
        ? prefs.getString(_userKey('last_backup_time'))
        : prefs.getString('last_backup_time');
    checkStreakLiveness();

    // 2. Load persisted book highlights
    final savedHighlightsStr = isUserAuthenticated
        ? prefs.getString(_userKey('saved_book_highlights'))
        : prefs.getString('saved_book_highlights');
    if (savedHighlightsStr != null && savedHighlightsStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(savedHighlightsStr);
        bookHighlights = decoded.map((k, v) => MapEntry(
          k,
          (v as List).map((h) => HighlightItem.fromJson(Map<String, dynamic>.from(h))).toList(),
        ));
        if (bookHighlights.containsKey(readerTitle)) {
          highlights.clear();
          highlights.addAll(bookHighlights[readerTitle]!);
        }
      } catch (_) {}
    }

    // 3. Load local imported books (PDFs, Web articles, Docs) saved on device
    final localBooksStr = isUserAuthenticated
        ? prefs.getString(_userKey('local_imported_books'))
        : prefs.getString('local_imported_books');
    if (localBooksStr != null && localBooksStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(localBooksStr);
        userLocalBooks = decoded.map((b) => BookItem.fromJson(b)).toList();
      } catch (_) {}
    }

    // 4. Load persisted tombstoned/removed books and pending removals
    final removedBooksStr = isUserAuthenticated
        ? prefs.getString(_userKey('removed_books_tombstones'))
        : prefs.getString('removed_books_tombstones');
    if (removedBooksStr != null && removedBooksStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(removedBooksStr);
        if (decoded is Map) {
          _removedBooks = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }
    final pendingRemovalsStr = isUserAuthenticated
        ? prefs.getString(_userKey('pending_removed_books'))
        : prefs.getString('pending_removed_books');
    if (pendingRemovalsStr != null && pendingRemovalsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(pendingRemovalsStr);
        if (decoded is List) {
          _pendingRemovedBooks = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    // 5. Load persisted Continue Reading shelf
    final continueShelfStr = isUserAuthenticated
        ? prefs.getString(_userKey('continue_shelf_books'))
        : prefs.getString('continue_shelf_books');
    if (continueShelfStr != null && continueShelfStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(continueShelfStr);
        continueShelf = decoded.map((b) => BookItem.fromJson(b)).toList();
      } catch (_) {}
    }

    // 6. Load persisted book-to-collection mappings
    final collectionsStr = isUserAuthenticated
        ? prefs.getString(_userKey('book_collection_mappings'))
        : prefs.getString('book_collection_mappings');
    if (collectionsStr != null && collectionsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(collectionsStr);
        if (decoded is Map) {
          bookCollections = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }
    _applyBookCollections();

    // 7. Load persisted offline downloaded books
    final downloadedStr = isUserAuthenticated
        ? prefs.getString(_userKey('offline_downloaded_books'))
        : prefs.getString('offline_downloaded_books');
    if (downloadedStr != null && downloadedStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(downloadedStr);
        downloadedBooks = decoded.map((b) => BookItem.fromJson(b)).toList();
      } catch (_) {}
    }

    // 8. Load persisted retained library book titles
    final retainedStr = isUserAuthenticated
        ? prefs.getString(_userKey('retained_library_book_titles'))
        : prefs.getString('retained_library_book_titles');
    if (retainedStr != null && retainedStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(retainedStr);
        if (decoded is List) {
          retainedLibraryBookTitles = decoded.map((e) => normalizeBookTitle(e.toString())).where((e) => e.isNotEmpty).toSet();
        }
      } catch (_) {}
    }

    // 9. Load persisted deleted user documents tombstone
    final deletedDocsStr = isUserAuthenticated
        ? prefs.getString(_userKey('deleted_user_doc_titles'))
        : prefs.getString('deleted_user_doc_titles');
    if (deletedDocsStr != null && deletedDocsStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(deletedDocsStr);
        if (decoded is Map) {
          _deletedUserDocTitles = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      } catch (_) {}
    }

    // Auto-seed retained titles from user local books, continue shelf, collections, and favorites
    for (var b in userLocalBooks) {
      final norm = normalizeBookTitle(b.title);
      if (norm.isNotEmpty) retainedLibraryBookTitles.add(norm);
    }
    for (var b in continueShelf) {
      final norm = normalizeBookTitle(b.title);
      if (norm.isNotEmpty) retainedLibraryBookTitles.add(norm);
    }
    for (var key in bookCollections.keys) {
      final norm = normalizeBookTitle(key);
      if (norm.isNotEmpty) retainedLibraryBookTitles.add(norm);
    }
    for (var b in libraryItems) {
      if (b.isFavorite || (b.progress != null && b.progress! > 0)) {
        final norm = normalizeBookTitle(b.title);
        if (norm.isNotEmpty) retainedLibraryBookTitles.add(norm);
      }
    }

    if (_removedBooks.isNotEmpty) {
      continueShelf.removeWhere((b) => _removedBooks.containsKey(b.title.trim().toLowerCase()) || _removedBooks.containsKey(normalizeBookTitle(b.title)));
    }
    _deduplicateCollections();
  }

  void _deduplicateCollections() {
    final seen = <String>{};
    final cleanLocal = <BookItem>[];
    for (var b in userLocalBooks) {
      final key = normalizeBookTitle(b.title);
      if (key.isNotEmpty && !seen.contains(key)) {
        seen.add(key);
        cleanLocal.add(b);
      }
    }
    userLocalBooks = cleanLocal;

    final seenShelf = <String>{};
    final cleanShelf = <BookItem>[];
    for (var b in continueShelf) {
      final key = normalizeBookTitle(b.title);
      if (key.isNotEmpty && !seenShelf.contains(key)) {
        seenShelf.add(key);
        cleanShelf.add(b);
      }
    }
    continueShelf = cleanShelf;
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userStr = prefs.getString('current_user');

      // Load persisted plan & premium subscription status across app restarts
      isPremium = prefs.getBool('is_premium') ?? false;
      purchasedPlanId = prefs.getString('purchased_plan_id');
      activePlanName = prefs.getString('active_plan_name');
      syncEnabled = prefs.getBool('sync_enabled') ?? false;
      lastBackupTime = prefs.getString('last_backup_time');

      if (token != null && token.isNotEmpty) {
        ApiService.authToken = token;
        isLoggedIn = true;
        if (userStr != null) {
          try {
            currentUser = jsonDecode(userStr);
            currentUserName = currentUser?['name'] ?? currentUserName;
            currentUserEmail = currentUser?['email'] ?? currentUserEmail;
            if (currentUser?['subscription_plan'] != null) {
              activePlanName = currentUser!['subscription_plan']?.toString();
            }
            if (currentUser?['is_premium'] == true) {
              isPremium = true;
            }
            if (currentUser?['feature_permissions'] != null && currentUser?['feature_permissions'] is Map) {
              userEntitlements = Map<String, bool>.from(currentUser!['feature_permissions']);
            }
            aiFreeUsesLeft = currentUser?['ai_free_uses_left'] ?? aiFreeUsesLeft;
            dayStreak = (currentUser?['day_streak'] is num)
                ? (currentUser!['day_streak'] as num).toInt()
                : prefs.getInt(_userKey('day_streak')) ?? 1;
            totalWordsRead = (currentUser?['total_words_read'] is num)
                ? (currentUser!['total_words_read'] as num).toInt()
                : prefs.getInt(_userKey('total_words_read')) ?? 0;
            if (currentUser?['sync_enabled'] != null) {
              syncEnabled = currentUser!['sync_enabled'] == true;
            }
          } catch (_) {}
        }
        isOnboarding = false;

        // Load cached user-scoped offline storage
        _loadUserScopedData(prefs);

        // Sync live profile with backend database
        try {
          final serverUser = await ApiService.getUserProfile();
          if (serverUser != null) {
            currentUser = serverUser;
            currentUserName = serverUser['name'] ?? currentUserName;
            currentUserEmail = serverUser['email'] ?? currentUserEmail;
            if (serverUser['subscription_plan'] != null) {
              activePlanName = serverUser['subscription_plan']?.toString();
              if (activePlanName != null) {
                await prefs.setString('active_plan_name', activePlanName!);
              }
            }
            isPremium = serverUser['is_premium'] == true;
            await prefs.setBool('is_premium', isPremium);

            if (serverUser['feature_permissions'] != null && serverUser['feature_permissions'] is Map) {
              userEntitlements = Map<String, bool>.from(serverUser['feature_permissions']);
              await prefs.setString('user_entitlements', jsonEncode(userEntitlements));
            }
            if (serverUser['day_streak'] != null) {
              dayStreak = (serverUser['day_streak'] is num)
                  ? (serverUser['day_streak'] as num).toInt()
                  : int.tryParse(serverUser['day_streak'].toString()) ?? dayStreak;
              await prefs.setInt(_userKey('day_streak'), dayStreak);
            }
            if (serverUser['total_words_read'] != null) {
              totalWordsRead = (serverUser['total_words_read'] is num)
                  ? (serverUser['total_words_read'] as num).toInt()
                  : int.tryParse(serverUser['total_words_read'].toString()) ?? totalWordsRead;
              await prefs.setInt(_userKey('total_words_read'), totalWordsRead);
            }
            if (serverUser.containsKey('sync_enabled') && serverUser['sync_enabled'] != null) {
              syncEnabled = serverUser['sync_enabled'] == true;
              await prefs.setBool('sync_enabled', syncEnabled);
            }
            aiFreeUsesLeft = serverUser['ai_free_uses_left'] ?? aiFreeUsesLeft;
            await prefs.setString('current_user', jsonEncode(serverUser));
          }
        } catch (_) {}

        _startLiveSyncTimer();
        // Sync user vocabulary bank and continue reading shelf from cloud database
        fetchUserVocabulary();
        performLiveSync(force: true);
      } else {
        // No valid token = user is logged out, clear active memory so no previous user's data leaks
        isLoggedIn = false;
        isOnboarding = true;
        onboardStep = 3;
        _clearActiveUserMemory();
      }
      notifyListeners();
    } catch (_) {}
  }

  // Handle external PDF files opened via "Open With" / Share Intent
  // Requires login — stores path as pending if not yet authenticated
  Future<void> handleIncomingSharedFile(String path) async {
    if (!isLoggedIn) {
      // Store path and redirect to login — document will open after successful login
      pendingSharedFilePath = path;
      isOnboarding = true;
      onboardStep = 3; // Jump directly to login screen step
      notifyListeners();
      return;
    }

    try {
      isDocumentLoading = true;
      activeTab = 'reader';
      notifyListeners();

      final parsed = await PdfReaderService.extractFromPath(path);
      importBook(
        BookItem(
          title: parsed.title,
          meta: "PDF · ${parsed.pageCount} pages · External",
          color: AppColors.plum,
          tag: "imported",
          paragraphs: parsed.paragraphs,
        ),
      );
      openArticleWithContent(
        title: parsed.title,
        byline: "PDF Document · ${parsed.pageCount} pages · ${parsed.wordCount} words",
        paragraphs: parsed.paragraphs,
        banner: "PDF Reader Mode: Tap any word for instant definitions & AI lookup",
      );
    } catch (_) {
    } finally {
      isDocumentLoading = false;
      pendingSharedFilePath = null;
      notifyListeners();
    }
  }

  // Called after successful login to open any pending shared file
  Future<void> openPendingSharedFileIfAny() async {
    if (pendingSharedFilePath != null && pendingSharedFilePath!.isNotEmpty) {
      final path = pendingSharedFilePath!;
      pendingSharedFilePath = null;
      await handleIncomingSharedFile(path);
    }
  }

  void switchTab(String tab) {
    if (activeTab != tab) {
      activeTab = tab;
      notifyListeners();
      syncUserLiveState();
    }
  }

  void setOnboardStep(int step) {
    onboardStep = step;
    notifyListeners();
  }

  void togglePref(String pref) {
    if (selectedPrefs.contains(pref)) {
      selectedPrefs.remove(pref);
    } else {
      selectedPrefs.add(pref);
    }
    notifyListeners();
  }

  bool handleBackNavigation() {
    // If not on Home (Library), jump straight to Library
    if (activeTab != 'library') {
      activeTab = 'library';
      notifyListeners();
      return true;
    }
    return false; // Already on Home root
  }

  String get _platformDeviceName {
    try {
      if (Platform.isAndroid) {
        final version = Platform.operatingSystemVersion;
        final match = RegExp(r'Android\s*[\d\.]+').firstMatch(version);
        final osStr = match != null ? match.group(0)! : 'Android';
        return '$osStr Phone';
      }
      if (Platform.isIOS) return 'Apple iPhone';
      if (Platform.isMacOS) return 'Apple Mac';
      if (Platform.isWindows) return 'Windows PC';
    } catch (_) {}
    return 'Mobile App';
  }

  // Unified User Session Hydration (Isolates multi-user data & hydrates cloud state)
  Future<void> _hydrateUserSession(Map<String, dynamic> user, String? token) async {
    _stopLiveSyncTimer();
    final prefs = await SharedPreferences.getInstance();

    final currentId = user['id']?.toString() ?? '';
    final lastSavedId = prefs.getString('active_user_id') ?? '';
    final bool isBrandNewUser = user['is_new_user'] == true || (currentId.isNotEmpty && currentId != lastSavedId);

    // 1. Wipe previous memory state completely to prevent any cross-user leakage
    _clearActiveUserMemory();

    if (isBrandNewUser) {
      // Clear all legacy/previous device cached data so fresh user gets a 100% clean slate
      final allKeys = prefs.getKeys().toList();
      for (final k in allKeys) {
        if (k.startsWith('local_imported_books') ||
            k.startsWith('continue_shelf_books') ||
            k.startsWith('saved_vocab_words') ||
            k.startsWith('saved_mastered_words') ||
            k.startsWith('saved_book_highlights') ||
            k.startsWith('book_collection_mappings') ||
            k.startsWith('user_custom_collections') ||
            k.startsWith('collections') ||
            k.startsWith('offline_downloaded_books') ||
            k.startsWith('retained_library_book_titles') ||
            k.startsWith('deleted_user_doc_titles') ||
            k.startsWith('day_streak') ||
            k.startsWith('total_words_read')) {
          await prefs.remove(k);
        }
      }
    }

    // 2. Set credentials & stats from server payload
    deactivationNotice = null;
    isLoggedIn = true;
    currentUser = user;
    currentUserName = user['name'] ?? 'Reader';
    currentUserEmail = user['email'] ?? '';
    isPremium = user['is_premium'] == true;
    purchasedPlanId = user['plan_id']?.toString() ?? user['subscription_plan']?.toString();
    activePlanName = user['subscription_plan']?.toString();

    dayStreak = (user['day_streak'] is num)
        ? (user['day_streak'] as num).toInt()
        : int.tryParse(user['day_streak']?.toString() ?? '') ?? 1;
    totalWordsRead = (user['total_words_read'] is num)
        ? (user['total_words_read'] as num).toInt()
        : int.tryParse(user['total_words_read']?.toString() ?? '') ?? 0;
    syncEnabled = user['sync_enabled'] == true;

    if (user['feature_permissions'] != null && user['feature_permissions'] is Map) {
      userEntitlements = Map<String, bool>.from(user['feature_permissions']);
    }
    aiFreeUsesLeft = user['ai_free_uses_left'] ?? 10;
    isOnboarding = false;
    activeTab = 'library';

    // 3. Persist session
    if (token != null && token.isNotEmpty) {
      ApiService.authToken = token;
      await prefs.setString('auth_token', token);
    }
    if (currentId.isNotEmpty) {
      await prefs.setString('active_user_id', currentId);
    }
    await prefs.setString('current_user', jsonEncode(user));
    await prefs.setBool('is_onboarded', true);
    await prefs.setInt(_userKey('day_streak'), dayStreak);
    await prefs.setInt(_userKey('total_words_read'), totalWordsRead);
    await prefs.setInt('day_streak', dayStreak);
    await prefs.setInt('total_words_read', totalWordsRead);
    await prefs.setBool('sync_enabled', syncEnabled);
    await prefs.setBool('is_premium', isPremium);

    // 4. Load any device-cached data scoped to this specific user (will be empty for brand new users)
    _loadUserScopedData(prefs);

    // 5. Start live sync timer
    _startLiveSyncTimer();

    // 6. Fetch official catalog & collections from server
    await fetchDynamicBooks();
    await fetchDynamicCollections();

    // 7. Hydrate user's saved vocabulary bank from backend MySQL database
    await fetchUserVocabulary();

    // 8. Hydrate user's continue shelf, reading progress, highlights, and custom collections
    await performLiveSync(force: true);

    // 9. Sync device FCM push token with user profile
    PushNotificationService.syncDeviceToken();

    // 10. Fetch user notifications bank from server
    await fetchNotifications();

    await openPendingSharedFileIfAny();
    refreshLibraryData();
    notifyListeners();
  }

  // Real Backend Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    isAuthLoading = true;
    notifyListeners();

    final res = await ApiService.login(email, password, deviceName: _platformDeviceName);
    isAuthLoading = false;

    if (res['success'] == true && res['user'] != null) {
      await _hydrateUserSession(res['user'], res['token']);
    }

    notifyListeners();
    return res;
  }

  // Real Backend Auth: Register
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    isAuthLoading = true;
    notifyListeners();

    final res = await ApiService.register(name, email, password, deviceName: _platformDeviceName);
    isAuthLoading = false;

    if (res['success'] == true && res['user'] != null) {
      await _hydrateUserSession(res['user'], res['token']);
    }

    notifyListeners();
    return res;
  }

  // Real Backend Auth: Social Login with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    isAuthLoading = true;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: googleWebClientId.isNotEmpty ? googleWebClientId : null,
        scopes: ['email', 'profile'],
      );

      // Sign out previous cached session so Google account chooser is always shown
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled Google Sign-In sheet
        isAuthLoading = false;
        notifyListeners();
        return {'success': false, 'message': 'Google Sign-In cancelled'};
      }

      final GoogleSignInAuthentication auth = await account.authentication;

      final res = await ApiService.socialLogin(
        provider: 'google',
        email: account.email,
        name: account.displayName,
        avatarUrl: account.photoUrl,
        providerId: account.id,
        idToken: auth.idToken,
        deviceName: _platformDeviceName,
      );

      isAuthLoading = false;

      if (res['success'] == true && res['user'] != null) {
        await _hydrateUserSession(res['user'], res['token']);
      }

      notifyListeners();
      return res;
    } catch (e) {
      isAuthLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Google Sign-In failed: $e'};
    }
  }

  // Real Backend Auth: Social Login with Apple
  Future<Map<String, dynamic>> signInWithApple() async {
    isAuthLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.socialLogin(
        provider: 'apple',
        email: 'apple_user_${DateTime.now().millisecondsSinceEpoch}@privaterelay.appleid.com',
        name: 'Apple Reader',
        deviceName: _platformDeviceName,
      );

      isAuthLoading = false;

      if (res['success'] == true && res['user'] != null) {
        await _hydrateUserSession(res['user'], res['token']);
      }

      notifyListeners();
      return res;
    } catch (e) {
      isAuthLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Apple Sign-In failed: $e'};
    }
  }

  // Real Backend Auth: Reset Password & Auto Login
  Future<Map<String, dynamic>> resetPasswordAndLogin({
    required String resetToken,
    required String newPassword,
    required String passwordConfirmation,
  }) async {
    isAuthLoading = true;
    notifyListeners();

    final res = await ApiService.resetPassword(
      resetToken: resetToken,
      password: newPassword,
      passwordConfirmation: passwordConfirmation,
      deviceName: _platformDeviceName,
    );
    isAuthLoading = false;

    if (res['success'] == true && res['user'] != null && res['token'] != null) {
      await _hydrateUserSession(res['user'], res['token']);
      finishOnboarding();
    }

    notifyListeners();
    return res;
  }

  // Real Backend Auth: Logout (Cleanly wipes active user session & isolates data)
  Future<void> logout({bool keepDeactivationNotice = false}) async {
    final String? noticeToKeep = keepDeactivationNotice ? deactivationNotice : null;
    final String oldUserEmail = currentUserEmail.trim().toLowerCase();
    final String? oldUserId = currentUser?['id']?.toString();
    _stopLiveSyncTimer();
    try {
      await ApiService.logout();
    } catch (_) {}
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
    isLoggedIn = false;
    deactivationNotice = noticeToKeep;
    currentUser = null;
    currentUserName = 'Guest Reader';
    currentUserEmail = 'guest@EasyRead.com';
    isPremium = false;
    purchasedPlanId = null;
    userEntitlements.clear();
    isOnboarding = true;
    onboardStep = 3;
    authMode = 'login';
    activeTab = 'library';

    // 1. Wipe active user session from memory completely
    _clearActiveUserMemory();

    // 2. Comprehensive wipe of all user-scoped and global cache keys from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
    await prefs.remove('user_entitlements');
    await prefs.remove('is_onboarded');
    await prefs.remove('active_user_id');
    await prefs.remove('active_plan_name');
    await prefs.remove('is_premium');
    await prefs.remove('purchased_plan_id');
    await prefs.remove('sync_enabled');
    await prefs.remove('continue_shelf_books');
    await prefs.remove('local_imported_books');
    await prefs.remove('saved_vocab_words');
    await prefs.remove('saved_mastered_words');
    await prefs.remove('saved_book_highlights');
    await prefs.remove('book_collection_mappings');
    await prefs.remove('user_custom_collections');
    await prefs.remove('collections');
    await prefs.remove('offline_downloaded_books');
    await prefs.remove('removed_books_tombstones');
    await prefs.remove('pending_removed_books');
    await prefs.remove('retained_library_book_titles');
    await prefs.remove('deleted_user_doc_titles');
    await prefs.remove('day_streak');
    await prefs.remove('total_words_read');

    // Sweep all keys in SharedPreferences starting with data prefixes or containing oldUserId / oldUserEmail
    final allKeys = prefs.getKeys().toList();
    for (final k in allKeys) {
      bool shouldRemove = false;
      if (k.startsWith('local_imported_books') ||
          k.startsWith('continue_shelf_books') ||
          k.startsWith('saved_vocab_words') ||
          k.startsWith('saved_mastered_words') ||
          k.startsWith('saved_book_highlights') ||
          k.startsWith('book_collection_mappings') ||
          k.startsWith('user_custom_collections') ||
          k.startsWith('collections') ||
          k.startsWith('offline_downloaded_books') ||
          k.startsWith('removed_books_tombstones') ||
          k.startsWith('pending_removed_books') ||
          k.startsWith('retained_library_book_titles') ||
          k.startsWith('deleted_user_doc_titles') ||
          k.startsWith('day_streak') ||
          k.startsWith('total_words_read') ||
          k.startsWith('last_reading_date') ||
          k.startsWith('last_backup_time')) {
        shouldRemove = true;
      }
      if (oldUserId != null && oldUserId.isNotEmpty && k.contains('_u$oldUserId')) {
        shouldRemove = true;
      }
      if (oldUserEmail.isNotEmpty && oldUserEmail != 'guest@easyread.com' && k.contains(oldUserEmail)) {
        shouldRemove = true;
      }
      if (shouldRemove) {
        await prefs.remove(k);
      }
    }

    notifyListeners();
  }

  void finishOnboarding() {
    isOnboarding = false;
    SharedPreferences.getInstance().then((prefs) => prefs.setBool('is_onboarded', true));

    if (pendingSharedFilePath != null && pendingSharedFilePath!.isNotEmpty) {
      final path = pendingSharedFilePath!;
      pendingSharedFilePath = null;
      handleIncomingSharedFile(path);
    } else if (activeTab != 'reader') {
      activeTab = 'library';
    }
    notifyListeners();
  }

  void replayOnboarding() {
    isOnboarding = true;
    onboardStep = 0;
    notifyListeners();
  }

  // Favorite toggle
  void toggleFavorite(String title) {
    final norm = normalizeBookTitle(title);
    final rawNorm = title.trim().toLowerCase();
    bool newFav = false;

    for (var b in continueShelf) {
      if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == norm) {
        b.isFavorite = !b.isFavorite;
        newFav = b.isFavorite;
      }
    }
    for (var i in libraryItems) {
      if (i.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(i.title) == norm) {
        i.isFavorite = !i.isFavorite;
        newFav = i.isFavorite;
      }
    }
    for (var u in userLocalBooks) {
      if (u.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(u.title) == norm) {
        u.isFavorite = !u.isFavorite;
        newFav = u.isFavorite;
      }
    }

    if (newFav) {
      retainedLibraryBookTitles.add(norm);
      _saveRetainedLibraryBooks();
    }
    _saveLocalBooks();
    notifyListeners();
  }

  bool isFavorite(String title) {
    final norm = normalizeBookTitle(title);
    final rawNorm = title.trim().toLowerCase();

    for (var b in continueShelf) {
      if ((b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == norm) && b.isFavorite) {
        return true;
      }
    }
    for (var i in libraryItems) {
      if ((i.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(i.title) == norm) && i.isFavorite) {
        return true;
      }
    }
    for (var u in userLocalBooks) {
      if ((u.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(u.title) == norm) && u.isFavorite) {
        return true;
      }
    }
    return false;
  }

  void toggleFavoritesFilter() {
    showFavoritesOnly = !showFavoritesOnly;
    notifyListeners();
  }

  void filterByCollection(String tag) {
    activeCollectionFilter = tag;
    notifyListeners();
  }

  void clearFilter() {
    activeCollectionFilter = null;
    showFavoritesOnly = false;
    notifyListeners();
  }

  Future<void> createCollection(String name, {int colorValue = 0xFF4B6B4A, String? colorHex}) async {
    if (!hasFeature('custom_shelves')) return;
    final localTag = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    final localItem = CollectionItem(
      name: name,
      colorValue: colorValue,
      tag: localTag,
    );
    collections.add(localItem);
    notifyListeners();

    try {
      final hex = colorHex ?? '#${colorValue.toRadixString(16).padLeft(8, '0').substring(2)}';
      final res = await ApiService.createCollection(name: name, colorHex: hex);
      if (res['success'] == true && res['collection'] != null) {
        final serverItem = CollectionItem.fromJson(res['collection']);
        final idx = collections.indexOf(localItem);
        if (idx != -1) {
          collections[idx] = serverItem;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> deleteCollection(CollectionItem item) async {
    collections.remove(item);
    if (selectedTag.toLowerCase() == item.name.toLowerCase() || selectedTag.toLowerCase() == item.tag.toLowerCase()) {
      selectedTag = 'All';
    }
    if (activeCollectionFilter == item.tag) {
      activeCollectionFilter = null;
    }
    notifyListeners();

    if (item.id != null) {
      try {
        await ApiService.deleteCollection(item.id!);
      } catch (_) {}
    }
  }

  List<String> get dynamicCategoryTags {
    final list = <String>['All'];
    for (final cat in categories) {
      if (!list.contains(cat.name)) {
        list.add(cat.name);
      }
    }
    return list;
  }

  Future<void> fetchDynamicCategories() async {
    try {
      final rawCats = await ApiService.getCategories();
      if (rawCats.isNotEmpty) {
        categories = rawCats.map((c) => CategoryItem.fromJson(c)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchDynamicCollections() async {
    if (!isLoggedIn) {
      collections = [];
      notifyListeners();
      return;
    }
    try {
      final rawCols = await ApiService.getCollections();
      collections = rawCols.map((c) => CollectionItem.fromJson(c)).toList();
      notifyListeners();
    } catch (_) {}
  }

  /// Pull-to-Refresh: Refreshes categories, books, collections, and plans in parallel
  Future<void> refreshLibraryData() async {
    await fetchDynamicCategories();
    await fetchDynamicBooks();
    await fetchDynamicCollections();
    await fetchDynamicPlans();
    await syncUserLiveState();
  }

  bool isLoadingBooks = false;

  Future<void> fetchDynamicBooks() async {
    isLoadingBooks = true;
    notifyListeners();
    try {
      final rawBooks = await ApiService.getBooks();
      if (rawBooks.isNotEmpty) {
        final parsed = rawBooks.map((b) => BookItem.fromJson(b)).toList();
        
        // Official Admin Curated Catalog ONLY (never includes user external/imported files):
        libraryItems = parsed.where((b) {
          if (b.userId != null) return false;
          final norm = normalizeBookTitle(b.title);
          final isUserDoc = userLocalBooks.any((u) => normalizeBookTitle(u.title) == norm);
          return !isUserDoc;
        }).toList();
        _applyBookCollections();

        // Restore active progress from continueShelf
        for (var libBook in libraryItems) {
          final norm = libBook.title.trim().toLowerCase();
          for (var shelfBook in continueShelf) {
            if (shelfBook.title.trim().toLowerCase() == norm && (shelfBook.progress ?? 0) > 0) {
              libBook.progress = shelfBook.progress;
              libBook.lastReadAt = shelfBook.lastReadAt;
              break;
            }
          }
        }

        if (articleParagraphs.isEmpty && libraryItems.isNotEmpty && libraryItems.first.paragraphs.isNotEmpty) {
          readerTitle = libraryItems.first.title;
          readerByline = "${libraryItems.first.author ?? 'Library'} · ${libraryItems.first.meta ?? ''}";
          smartBannerText = "Clean Reader Mode: ${libraryItems.first.title}";
          articleParagraphs = libraryItems.first.paragraphs;
        }
      }
    } catch (_) {}
    isLoadingBooks = false;
    notifyListeners();
  }

  Future<void> fetchDynamicPlans() async {
    try {
      final rawPlans = await ApiService.getPlans();
      if (rawPlans.isNotEmpty) {
        plans = rawPlans.map((p) => PlanItem.fromJson(p)).toList();
        if (!plans.any((p) => p.id == selectedPlanId) && plans.isNotEmpty) {
          selectedPlanId = plans.first.id;
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> initRevenueCat() async {
    try {
      final config = await ApiService.getRevenueCatConfig();
      if (config != null) {
        await PurchaseService.init(
          userId: currentUserEmail.isNotEmpty ? currentUserEmail : null,
          googleKey: config['google_key'],
          appleKey: config['apple_key'],
        );
        if (config['entitlement_id'] != null && config['entitlement_id'].toString().isNotEmpty) {
          PurchaseService.entitlementId = config['entitlement_id'].toString();
        }

        final isSubActive = await PurchaseService.isUserPremium();
        final isBackendFree = activePlanName != null && activePlanName!.toLowerCase().contains('free');
        
        // Do not auto-override if the backend explicitly downgraded the user to a Free plan.
        if (isSubActive && !isPremium && !isBackendFree) {
          isPremium = true;
          purchasedPlanId = 'plus';
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_premium', true);
          await prefs.setString('purchased_plan_id', 'plus');
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  bool isPurchaseInProgress = false;

  Future<bool> purchaseSelectedPlan() async {
    isPurchaseInProgress = true;
    notifyListeners();

    try {
      debugPrint('[EasyRead Provider] Purchasing plan: $selectedPlanId');
      await initRevenueCat();
      final packages = await PurchaseService.getPackages();
      debugPrint('[EasyRead Provider] RevenueCat packages count: ${packages.length}');

      if (packages.isNotEmpty) {
        dynamic pkg;
        final norm = selectedPlanId.toLowerCase();
        for (final p in packages) {
          final id = p.identifier.toString().toLowerCase();
          if ((norm.contains('year') || norm.contains('annual')) && (id.contains('annual') || id.contains('year'))) {
            pkg = p;
            break;
          } else if ((norm.contains('biannual') || norm.contains('6') || norm.contains('six')) && (id.contains('six') || id.contains('6'))) {
            pkg = p;
            break;
          } else if ((norm.contains('quarter') || norm.contains('3') || norm.contains('three')) && (id.contains('three') || id.contains('3'))) {
            pkg = p;
            break;
          } else if ((norm.contains('month')) && (id.contains('month'))) {
            pkg = p;
            break;
          }
        }
        pkg ??= packages.first;

        final isFreePlan = selectedPlanId.toLowerCase() == 'free' || selectedPlanId.toLowerCase() == 'free tier';
        
        debugPrint('[EasyRead Provider] Executing RevenueCat purchase for: ${pkg.identifier}');
        final result = await PurchaseService.purchase(pkg);
        debugPrint('[EasyRead Provider] RevenueCat purchase result: $result');
        if (result['success'] == true) {
          isPremium = !isFreePlan;
          purchasedPlanId = selectedPlanId;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_premium', isPremium);
          await prefs.setString('purchased_plan_id', selectedPlanId);
          await ApiService.updateSubscription(planSlug: selectedPlanId, isPremium: isPremium);
          isPurchaseInProgress = false;
          notifyListeners();
          return true;
        }
      }

      // Sandbox / Test Mode Approval (For testing without live store accounts)
      debugPrint('[EasyRead Provider] Executing Sandbox Test Purchase for plan: $selectedPlanId');
      final isFreePlan = selectedPlanId.toLowerCase() == 'free' || selectedPlanId.toLowerCase() == 'free tier';
      isPremium = !isFreePlan;
      purchasedPlanId = selectedPlanId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', isPremium);
      await prefs.setString('purchased_plan_id', selectedPlanId);
      await ApiService.updateSubscription(planSlug: selectedPlanId, isPremium: isPremium);
      isPurchaseInProgress = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[EasyRead Provider Purchase Error]: $e');
      // Sandbox fallback on error during local testing
      final isFreePlan = selectedPlanId.toLowerCase() == 'free' || selectedPlanId.toLowerCase() == 'free tier';
      isPremium = !isFreePlan;
      purchasedPlanId = selectedPlanId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', isPremium);
      await prefs.setString('purchased_plan_id', selectedPlanId);
      await ApiService.updateSubscription(planSlug: selectedPlanId, isPremium: isPremium);
      isPurchaseInProgress = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final restored = await PurchaseService.restorePurchases();
      if (restored) {
        isPremium = true;
        purchasedPlanId = 'restored';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_premium', true);
        await prefs.setString('purchased_plan_id', 'restored');
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void selectTag(String tag) {
    selectedTag = tag;
    notifyListeners();
  }

  // Reader actions
  void toggleBookmark() {
    if (bookmarkedTitles.contains(readerTitle)) {
      bookmarkedTitles.remove(readerTitle);
    } else {
      bookmarkedTitles.add(readerTitle);
    }
    notifyListeners();
  }

  bool isBookmarked() => bookmarkedTitles.contains(readerTitle);

  void setFontSize(double size) {
    readerFontSize = size.clamp(13.0, 22.0);
    notifyListeners();
  }

  void setTheme(Color bg, Color text) {
    readerBackground = bg;
    readerTextColor = text;
    notifyListeners();
  }

  void toggleSmartMode() {
    smartReaderMode = !smartReaderMode;
    notifyListeners();
  }

  // Highlights & Notes
  void setHighlight(int pIdx, String color) {
    final idx = highlights.indexWhere((h) => h.paragraphIndex == pIdx);
    if (idx != -1) {
      highlights[idx].color = color;
    } else {
      highlights.add(HighlightItem(paragraphIndex: pIdx, color: color, bookTitle: readerTitle));
    }
    bookHighlights[readerTitle] = List.from(highlights);
    _saveBookHighlights();
    notifyListeners();

    if (syncEnabled && isLoggedIn) {
      ApiService.pushHighlights([
        {
          'book_title': readerTitle,
          'paragraph_index': pIdx,
          'color': color,
          'note': getHighlight(pIdx)?.note,
        }
      ]);
    }
  }

  void removeHighlight(int pIdx) {
    highlights.removeWhere((h) => h.paragraphIndex == pIdx);
    bookHighlights[readerTitle] = List.from(highlights);
    _saveBookHighlights();
    notifyListeners();

    if (syncEnabled && isLoggedIn) {
      ApiService.deleteHighlight(
        bookTitle: readerTitle,
        paragraphIndex: pIdx,
      );
    }
  }

  void saveNote(int pIdx, String note) {
    final idx = highlights.indexWhere((h) => h.paragraphIndex == pIdx);
    if (idx != -1) {
      highlights[idx].note = note;
    } else {
      highlights.add(HighlightItem(paragraphIndex: pIdx, color: 'yellow', note: note, bookTitle: readerTitle));
    }
    bookHighlights[readerTitle] = List.from(highlights);
    _saveBookHighlights();
    notifyListeners();

    if (syncEnabled && isLoggedIn) {
      ApiService.pushHighlights([
        {
          'book_title': readerTitle,
          'paragraph_index': pIdx,
          'color': getHighlight(pIdx)?.color ?? 'yellow',
          'note': note,
        }
      ]);
    }
  }

  Future<void> _saveBookHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonMap = bookHighlights.map((k, v) => MapEntry(k, v.map((h) => h.toJson()).toList()));
      final encoded = jsonEncode(jsonMap);
      await prefs.setString(_userKey('saved_book_highlights'), encoded);
      await prefs.setString('saved_book_highlights', encoded);
    } catch (_) {}
  }

  HighlightItem? getHighlight(int pIdx) {
    try {
      return highlights.firstWhere((h) => h.paragraphIndex == pIdx);
    } catch (_) {
      return null;
    }
  }

  bool _isGenericMeaning(String? m) {
    if (m == null) return true;
    final trimmed = m.trim();
    return trimmed.isEmpty ||
        trimmed == "General reading term." ||
        trimmed == "General reading vocabulary" ||
        trimmed == "Looking up definition..." ||
        trimmed == "Loading definition..." ||
        trimmed == "Selected reading text." ||
        trimmed.startsWith("We came across the word") ||
        trimmed.startsWith("Looking up definition");
  }

  bool _isGenericEntry(DictionaryEntry? entry) {
    if (entry == null) return true;
    return _isGenericMeaning(entry.meaning);
  }

  final Set<String> _pendingAutoLookups = {};

  void _autoLookupWordIfMissing(String clean) {
    if (_pendingAutoLookups.contains(clean)) return;
    _pendingAutoLookups.add(clean);
    DictionaryService.lookupWord(clean).then((entry) {
      _pendingAutoLookups.remove(clean);
      if (!_isGenericEntry(entry)) {
        dictionary[clean] = entry;
        notifyListeners();
        if (isLoggedIn && (vocabWords.contains(clean) || masteredWords.contains(clean))) {
          ApiService.saveWord(
            word: clean,
            meaning: entry.meaning,
            pos: entry.pos,
            example: entry.example,
            sourceTitle: readerTitle,
          );
        }
      }
    }).catchError((_) {
      _pendingAutoLookups.remove(clean);
    });
  }

  // Vocabulary & Dictionary
  DictionaryEntry getWordData(String word) {
    final clean = word.toLowerCase().replaceAll(RegExp(r"[^a-zA-Z]"), '').trim();
    if (clean.isEmpty) {
      return DictionaryEntry(
        word: word,
        pos: "term",
        meaning: "Selected reading text.",
        example: "Encountered in reading context.",
        synonyms: [],
        origin: "English vocabulary",
      );
    }

    // 1. If we already have a rich/authentic definition in memory, return it immediately
    final existing = dictionary[clean];
    if (existing != null && !_isGenericEntry(existing)) {
      return existing;
    }

    // 2. Check synchronous cache from DictionaryService (offline curated lexicon or persisted cache)
    final cached = DictionaryService.getCached(clean);
    if (cached != null && !_isGenericEntry(cached)) {
      dictionary[clean] = cached;
      return cached;
    }

    // 3. If word is a generic placeholder or missing, auto-fetch from dictionary in background!
    _autoLookupWordIfMissing(clean);

    return DictionaryEntry(
      word: clean,
      pos: "word",
      meaning: "Looking up definition...",
      example: "Fetching authentic dictionary definition...",
      synonyms: [],
      origin: "English vocabulary",
    );
  }

  /// Dynamically looks up real definition, part of speech, example, and synonyms
  /// from official Free Dictionary API & Datamuse with instant caching.
  Future<DictionaryEntry> fetchWordDefinition(String word) async {
    final clean = word.toLowerCase().replaceAll(RegExp(r"[^a-zA-Z]"), '').trim();
    if (clean.isEmpty) return getWordData(word);

    final entry = await DictionaryService.lookupWord(clean);
    dictionary[clean] = entry;
    notifyListeners();
    return entry;
  }

  bool isWordSaved(String word) {
    final clean = word.toLowerCase().replaceAll(RegExp(r"[^a-zA-Z]"), '');
    return vocabWords.contains(clean);
  }

  bool toggleSaveWord(
    String word, {
    String? meaning,
    String? pos,
    String? example,
    String? sourceTitle,
  }) {
    final clean = word.toLowerCase().replaceAll(RegExp(r"[^a-zA-Z]"), '').trim();
    if (clean.isEmpty) return false;

    if (vocabWords.contains(clean)) {
      vocabWords.remove(clean);
      masteredWords.remove(clean);
      _persistVocabWords();
      notifyListeners();
      if (isLoggedIn) {
        ApiService.deleteWord(clean);
      }
      return false;
    } else {
      if (!isPremium && vocabWords.length >= freeVocabLimit) {
        return false;
      }
      vocabWords.add(clean);

      final cached = DictionaryService.getCached(clean);
      final existing = dictionary[clean];

      final isMeaningValid = meaning != null && !_isGenericMeaning(meaning);

      final m = isMeaningValid
          ? meaning
          : (cached != null && !_isGenericEntry(cached)
              ? cached.meaning
              : (existing != null && !_isGenericEntry(existing)
                  ? existing.meaning
                  : "General reading vocabulary"));

      final p = (pos != null && pos != 'word')
          ? pos
          : (cached != null && cached.pos != 'word'
              ? cached.pos
              : (existing?.pos ?? "word"));

      final isExValid = example != null &&
          example.trim().isNotEmpty &&
          !example.contains("Notice the use of") &&
          !example.contains("We came across");

      final ex = isExValid
          ? example
          : (cached != null && cached.example.isNotEmpty
              ? cached.example
              : (existing?.example ?? "Encountered while reading."));

      final syns = (cached != null && cached.synonyms.isNotEmpty)
          ? cached.synonyms
          : (existing?.synonyms ?? const ["term", "expression"]);

      final orig = (cached != null && cached.origin.isNotEmpty)
          ? cached.origin
          : (existing?.origin ?? "English vocabulary");

      final ph = cached?.phonetic ?? existing?.phonetic;
      final title = (sourceTitle != null && sourceTitle.isNotEmpty) ? sourceTitle : readerTitle;

      final newEntry = DictionaryEntry(
        word: clean,
        meaning: m,
        pos: p,
        example: ex,
        synonyms: syns,
        origin: orig,
        phonetic: ph,
      );

      dictionary[clean] = newEntry;
      _persistVocabWords();
      notifyListeners();

      // If saved with a generic placeholder, auto-lookup to heal it immediately!
      if (_isGenericEntry(newEntry)) {
        _autoLookupWordIfMissing(clean);
      }

      // Persist directly into user's DB bank (even from external documents / PDFs)
      if (isLoggedIn) {
        ApiService.saveWord(
          word: clean,
          meaning: m,
          pos: p,
          example: ex,
          sourceTitle: title,
        );
      }
      return true;
    }
  }

  void markWordAsMastered(String word, bool isMastered) {
    final clean = word.toLowerCase().replaceAll(RegExp(r"[^a-zA-Z]"), '').trim();
    final rawClean = word.toLowerCase().trim();
    if (clean.isEmpty && rawClean.isEmpty) return;
    final targetWord = clean.isNotEmpty ? clean : rawClean;

    if (isMastered) {
      masteredWords.add(targetWord);
      masteredWords.add(rawClean);
      vocabWords.removeWhere((w) => w.toLowerCase().trim() == targetWord || w.toLowerCase().trim() == rawClean);
    } else {
      masteredWords.remove(targetWord);
      masteredWords.remove(rawClean);
      if (!vocabWords.contains(targetWord)) {
        vocabWords.add(targetWord);
      }
    }
    _persistVocabWords();
    notifyListeners();

    if (isLoggedIn) {
      ApiService.recordVocabReview(targetWord, isMastered: isMastered);
    }
  }

  void addWordsRead(int words) async {
    if (words <= 0) return;
    totalWordsRead += words;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userKey('total_words_read'), totalWordsRead);
      await prefs.setInt('total_words_read', totalWordsRead);
    } catch (_) {}
    if (isLoggedIn) {
      ApiService.updateSettings(totalWordsRead: totalWordsRead);
    }
  }

  void _persistVocabWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_userKey('saved_vocab_words'), vocabWords);
      await prefs.setStringList(_userKey('saved_mastered_words'), masteredWords.toList());
      await prefs.setStringList('saved_vocab_words', vocabWords);
      await prefs.setStringList('saved_mastered_words', masteredWords.toList());
    } catch (_) {}
  }

  Future<void> fetchUserVocabulary() async {
    if (!isLoggedIn) return;
    try {
      final res = await ApiService.getVocabulary();
      if (res['success'] == true && res['vocabulary'] is List) {
        final list = res['vocabulary'] as List;
        for (var item in list) {
          final w = (item['word'] ?? '').toString().toLowerCase().trim();
          if (w.isNotEmpty) {
            final clean = w.replaceAll(RegExp(r"[^a-zA-Z]"), '').trim();
            final bool isServerMastered = item['is_mastered'] == true || item['is_mastered'] == 1;
            final bool isMastered = isServerMastered || masteredWords.contains(w) || (clean.isNotEmpty && masteredWords.contains(clean));

            if (isMastered) {
              masteredWords.add(w);
              vocabWords.remove(w);
              if (clean.isNotEmpty) vocabWords.remove(clean);
              if (!isServerMastered && isLoggedIn) {
                ApiService.recordVocabReview(w, isMastered: true);
              }
            } else {
              masteredWords.remove(w);
              if (clean.isNotEmpty) masteredWords.remove(clean);
              if (!vocabWords.contains(w)) {
                vocabWords.add(w);
              }
            }
            final cached = DictionaryService.getCached(w);
            final mStr = (item['meaning'] ?? '').toString();
            final isBackendMeaningAuthentic = !_isGenericMeaning(mStr);

            if (isBackendMeaningAuthentic) {
              dictionary[w] = DictionaryEntry(
                word: w,
                pos: (item['pos'] != null && item['pos'].toString().isNotEmpty && item['pos'].toString() != 'word')
                    ? item['pos'].toString()
                    : (cached?.pos ?? 'word'),
                meaning: mStr,
                example: item['example']?.toString() ?? (cached?.example ?? ''),
                synonyms: item['synonyms'] is List
                    ? List<String>.from(item['synonyms'])
                    : (cached?.synonyms ?? const ["term", "expression"]),
                origin: item['origin']?.toString() ?? (cached?.origin ?? 'English vocabulary'),
                phonetic: item['phonetic']?.toString() ?? cached?.phonetic,
              );
            } else if (cached != null && !_isGenericEntry(cached)) {
              dictionary[w] = cached;
            } else {
              _autoLookupWordIfMissing(w);
            }
          }
        }
        _persistVocabWords();
        notifyListeners();
      }
    } catch (_) {}
  }

  // Format UTC or ISO timestamp to user device's local time string
  String formatTimestampLocal(dynamic rawTime) {
    if (rawTime == null) return "Never";
    try {
      final dt = DateTime.parse(rawTime.toString()).toLocal();
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? "PM" : "AM";
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      final timeStr = "$hour12:$minuteStr $ampm";

      if (isToday) {
        return "Today at $timeStr";
      } else if (isYesterday) {
        return "Yesterday at $timeStr";
      } else {
        return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}, $timeStr";
      }
    } catch (_) {
      return rawTime.toString();
    }
  }

  // Daily Reading Streak (Calendar Day Standard)
  void updateStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDateStr = prefs.getString(_userKey('last_reading_date')) ?? prefs.getString('last_reading_date');
      final now = DateTime.now();
      final todayStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      dayStreak = prefs.getInt(_userKey('day_streak')) ?? prefs.getInt('day_streak') ?? dayStreak;
      if (dayStreak < 1) dayStreak = 1;

      if (lastDateStr == null || lastDateStr.isEmpty) {
        // First active reading day!
        dayStreak = 1;
      } else if (lastDateStr == todayStr) {
        // Already read today, streak is safely retained for today
      } else {
        final lastDate = DateTime.tryParse(lastDateStr);
        if (lastDate != null) {
          final todayMidnight = DateTime.utc(now.year, now.month, now.day);
          final lastMidnight = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
          final dayDiff = todayMidnight.difference(lastMidnight).inDays;

          if (dayDiff == 1) {
            // Read yesterday! Consecutive day -> increment streak!
            dayStreak += 1;
          } else if (dayDiff > 1) {
            // Missed 1 or more calendar days -> reset streak to 1
            dayStreak = 1;
          }
        } else {
          dayStreak = 1;
        }
      }

      await prefs.setInt(_userKey('day_streak'), dayStreak);
      await prefs.setString(_userKey('last_reading_date'), todayStr);
      await prefs.setInt('day_streak', dayStreak);
      await prefs.setString('last_reading_date', todayStr);

      if (isLoggedIn) {
        ApiService.updateSettings(dayStreak: dayStreak);
      }
      notifyListeners();
    } catch (_) {}
  }

  // Check if existing streak expired due to missed days
  void checkStreakLiveness() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDateStr = prefs.getString(_userKey('last_reading_date')) ?? prefs.getString('last_reading_date');
      if (lastDateStr == null || lastDateStr.isEmpty) return;

      final lastDate = DateTime.tryParse(lastDateStr);
      if (lastDate != null) {
        final now = DateTime.now();
        final todayMidnight = DateTime.utc(now.year, now.month, now.day);
        final lastMidnight = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);
        final dayDiff = todayMidnight.difference(lastMidnight).inDays;

        if (dayDiff > 1) {
          // Missed yesterday or more -> streak broken, reset to 1
          dayStreak = 1;
          await prefs.setInt(_userKey('day_streak'), 1);
          await prefs.setInt('day_streak', 1);
          if (isLoggedIn) {
            ApiService.updateSettings(dayStreak: 1);
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // Audio Speech & TTS state
  bool isSpeaking = false;
  int currentSpeakingParagraph = -1;

  void _initTts() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.48);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);

      flutterTts.setCompletionHandler(() {
        if (isSpeaking && currentSpeakingParagraph >= 0 && currentSpeakingParagraph + 1 < articleParagraphs.length) {
          currentSpeakingParagraph++;
          notifyListeners();
          _speakParagraph(currentSpeakingParagraph);
        } else {
          isSpeaking = false;
          currentSpeakingParagraph = -1;
          notifyListeners();
        }
      });

      flutterTts.setCancelHandler(() {
        isSpeaking = false;
        currentSpeakingParagraph = -1;
        notifyListeners();
      });

      flutterTts.setErrorHandler((_) {
        isSpeaking = false;
        currentSpeakingParagraph = -1;
        notifyListeners();
      });
    } catch (_) {}
  }

  Future<void> _speakParagraph(int index) async {
    if (index >= 0 && index < articleParagraphs.length) {
      final p = articleParagraphs[index].trim();
      if (p.isEmpty) {
        // Skip empty paragraph and continue
        if (index + 1 < articleParagraphs.length) {
          currentSpeakingParagraph = index + 1;
          notifyListeners();
          _speakParagraph(currentSpeakingParagraph);
        } else {
          isSpeaking = false;
          currentSpeakingParagraph = -1;
          notifyListeners();
        }
        return;
      }

      // Android TTS limit safety
      final textToSpeak = p.length > 2500 ? p.substring(0, 2500) : p;
      await flutterTts.speak(textToSpeak);
    }
  }

  Future<void> speakWord(String word) async {
    try {
      await stopSpeaking();
      await flutterTts.speak(word);
    } catch (_) {}
  }

  Future<void> stopSpeaking() async {
    try {
      isSpeaking = false;
      currentSpeakingParagraph = -1;
      notifyListeners();
      await flutterTts.stop();
    } catch (_) {}
  }

  Future<bool> toggleSpeakArticle() async {
    if (isSpeaking) {
      await stopSpeaking();
      return false;
    } else {
      if (articleParagraphs.isEmpty) return false;
      try {
        await flutterTts.stop();
        isSpeaking = true;
        currentSpeakingParagraph = 0;
        notifyListeners();

        _speakParagraph(0);
        return true;
      } catch (_) {
        isSpeaking = false;
        currentSpeakingParagraph = -1;
        notifyListeners();
        return false;
      }
    }
  }

  void openBook(BookItem item) {
    _unremoveBook(item.title);
    final normTitle = normalizeBookTitle(item.title);
    final rawNorm = item.title.trim().toLowerCase();
    _unremoveBook(normTitle);
    _deletedUserDocTitles.remove(normTitle);
    _deletedUserDocTitles.remove(rawNorm);

    // Retain in user's library permanently (survives Continue Reading removals)
    if (normTitle.isNotEmpty) {
      retainedLibraryBookTitles.add(normTitle);
      _saveRetainedLibraryBooks();
    }

    // 1. Ensure active reading milestone progress (at least 5% so it appears on Continue Reading shelf and cloud)
    final existingProg = item.progress ?? getBookProgress(item.title);
    final effectiveProg = existingProg > 0 ? existingProg : 5;
    final nowUtc = DateTime.now().toUtc();

    item.progress = effectiveProg;
    item.lastReadAt = nowUtc;

    // Apply any custom user collection tag
    if (bookCollections.containsKey(rawNorm) || bookCollections.containsKey(normTitle)) {
      item.tag = bookCollections[normTitle] ?? bookCollections[rawNorm]!;
    }

    // 2. Put at the top of Continue Reading shelf
    continueShelf.removeWhere((b) =>
        b.title.trim().toLowerCase() == rawNorm ||
        normalizeBookTitle(b.title) == normTitle);
    continueShelf.insert(0, item);

    // 3. Keep libraryItems and userLocalBooks in sync with this progress & timestamp
    for (var b in libraryItems) {
      if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == normTitle) {
        b.progress = effectiveProg;
        b.lastReadAt = nowUtc;
        if (bookCollections.containsKey(normTitle) || bookCollections.containsKey(rawNorm)) {
          b.tag = bookCollections[normTitle] ?? bookCollections[rawNorm]!;
        }
      }
    }
    for (var b in userLocalBooks) {
      if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == normTitle) {
        b.progress = effectiveProg;
        b.lastReadAt = nowUtc;
        if (bookCollections.containsKey(normTitle) || bookCollections.containsKey(rawNorm)) {
          b.tag = bookCollections[normTitle] ?? bookCollections[rawNorm]!;
        }
      }
    }

    _saveLocalBooks();

    // 4. Cloud sync: Push progress to backend immediately so Device 2 receives it!
    if (syncEnabled && isLoggedIn) {
      _pushReadingProgressSafe(item.title, effectiveProg, lastReadAt: nowUtc);
    }

    openArticleWithContent(
      title: item.title,
      byline: "${item.author ?? 'Library'} · ${item.meta ?? ''}",
      paragraphs: item.paragraphs.isNotEmpty
          ? item.paragraphs
          : [
              "No text paragraphs found in this document.",
            ],
      banner: "Clean Reader Mode: ${item.title}",
    );
  }

  // Open custom article / imported content
  void openArticleWithContent({
    required String title,
    required String byline,
    required List<String> paragraphs,
    required String banner,
    bool isDuplicate = false,   // true = already imported, skip word counting
  }) {
    readerTitle = title;
    readerByline = byline;
    smartBannerText = banner;
    articleParagraphs = paragraphs;
    highlights.clear();
    final cleanTitle = title.trim().toLowerCase();
    final cleanNorm = normalizeBookTitle(title);

    // Retain in user's library permanently
    if (cleanNorm.isNotEmpty) {
      retainedLibraryBookTitles.add(cleanNorm);
      _deletedUserDocTitles.remove(cleanNorm);
      _saveRetainedLibraryBooks();
    }

    for (var entry in bookHighlights.entries) {
      if (entry.key.trim().toLowerCase() == cleanTitle || normalizeBookTitle(entry.key) == cleanNorm) {
        highlights.addAll(entry.value);
        break;
      }
    }
    activeTab = 'reader';

    // Only count words & update streak for NEW imports, not re-opens
    if (!isDuplicate) {
      int count = 0;
      for (var p in paragraphs) {
        count += p.trim().split(RegExp(r'\s+')).length;
      }
      addWordsRead(count);
      updateStreak();
    }

    notifyListeners();
  }

  void updateCurrentBookProgress(int progress) {
    bool updated = false;

    // Industry Standard Reading Progress:
    // 1. Progress represents the furthest milestone reached in the book (never decreases on scrolling back up).
    // 2. Near-end reading (>= 92%) smoothly snaps to 100% completion.
    final now = DateTime.now().toUtc();
    final targetProgress = progress >= 92 ? 100 : progress.clamp(5, 100);
    _unremoveBook(readerTitle);

    for (var b in continueShelf) {
      if (b.title.trim().toLowerCase() == readerTitle.trim().toLowerCase()) {
        final current = b.progress ?? 0;
        if (targetProgress > current) {
          b.progress = targetProgress;
          b.lastReadAt = now;
          updated = true;
        }
        break;
      }
    }
    for (var b in userLocalBooks) {
      if (b.title.trim().toLowerCase() == readerTitle.trim().toLowerCase()) {
        final current = b.progress ?? 0;
        if (targetProgress > current) {
          b.progress = targetProgress;
          b.lastReadAt = now;
          updated = true;
        }
        break;
      }
    }
    for (var b in libraryItems) {
      if (b.title.trim().toLowerCase() == readerTitle.trim().toLowerCase()) {
        final current = b.progress ?? 0;
        if (targetProgress > current) {
          b.progress = targetProgress;
          b.lastReadAt = now;
          updated = true;
        }
        break;
      }
    }
    if (updated) {
      _saveLocalBooks();
      updateStreak();
      if (syncEnabled && isLoggedIn) {
        _pushReadingProgressSafe(readerTitle, targetProgress, lastReadAt: now);
      }
      notifyListeners();
    }
  }

  int getBookProgress(String title) {
    final norm = title.trim().toLowerCase();
    for (var b in continueShelf) {
      if (b.title.trim().toLowerCase() == norm) return b.progress ?? 0;
    }
    for (var b in userLocalBooks) {
      if (b.title.trim().toLowerCase() == norm) return b.progress ?? 0;
    }
    for (var b in libraryItems) {
      if (b.title.trim().toLowerCase() == norm) return b.progress ?? 0;
    }
    return 0;
  }

  bool readerShouldResetScroll = false;

  void resetBookProgress(String bookTitle) {
    bool updated = false;
    final norm = bookTitle.trim().toLowerCase();
    final now = DateTime.now().toUtc();
    for (var b in continueShelf) {
      if (b.title.trim().toLowerCase() == norm) {
        b.progress = 0;
        b.lastReadAt = now;
        updated = true;
      }
    }
    for (var b in userLocalBooks) {
      if (b.title.trim().toLowerCase() == norm) {
        b.progress = 0;
        b.lastReadAt = now;
        updated = true;
      }
    }
    for (var b in libraryItems) {
      if (b.title.trim().toLowerCase() == norm) {
        b.progress = 0;
        b.lastReadAt = now;
        updated = true;
      }
    }
    if (readerTitle.trim().toLowerCase() == norm) {
      readerShouldResetScroll = true;
    }
    if (updated) {
      _saveLocalBooks();
      if (syncEnabled && isLoggedIn) {
        _pushReadingProgressSafe(bookTitle, 0, isReset: true, lastReadAt: now);
      }
      notifyListeners();
    }
  }

  void markBookCompleted(String bookTitle) {
    bool updated = false;
    final norm = bookTitle.trim().toLowerCase();
    final now = DateTime.now().toUtc();
    _unremoveBook(bookTitle);
    for (var b in continueShelf) {
      if (b.title.trim().toLowerCase() == norm) {
        b.progress = 100;
        b.lastReadAt = now;
        updated = true;
      }
    }
    for (var b in userLocalBooks) {
      if (b.title.trim().toLowerCase() == norm) {
        b.progress = 100;
        b.lastReadAt = now;
        updated = true;
      }
    }
    for (var b in libraryItems) {
      if (b.title.trim().toLowerCase() == norm) {
        b.progress = 100;
        b.lastReadAt = now;
        updated = true;
      }
    }
    if (updated) {
      _saveLocalBooks();
      updateStreak();
      if (syncEnabled && isLoggedIn) {
        _pushReadingProgressSafe(bookTitle, 100, lastReadAt: now);
      }
      notifyListeners();
    }
  }

  void removeFromContinueShelf(String bookTitle) {
    final rawNorm = bookTitle.trim().toLowerCase();
    final normTitle = normalizeBookTitle(bookTitle);
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    _removedBooks[rawNorm] = nowUtc;
    _removedBooks[normTitle] = nowUtc;
    if (!_pendingRemovedBooks.contains(bookTitle)) {
      _pendingRemovedBooks.add(bookTitle);
    }
    _saveRemovedBooks();

    // Strictly remove ONLY from the Continue Reading shelf!
    continueShelf.removeWhere((b) =>
        b.title.trim().toLowerCase() == rawNorm ||
        normalizeBookTitle(b.title) == normTitle);

    // Reset progress on the continue shelf to 0, but DO NOT delete the book from userLocalBooks or libraryItems!
    // It remains safely preserved in Your Library.
    for (var b in userLocalBooks) {
      if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == normTitle) {
        b.progress = 0;
      }
    }
    for (var b in libraryItems) {
      if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == normTitle) {
        b.progress = 0;
      }
    }
    if (readerTitle.trim().toLowerCase() == rawNorm || normalizeBookTitle(readerTitle) == normTitle) {
      readerShouldResetScroll = true;
    }
    _saveLocalBooks();
    if (syncEnabled && isLoggedIn) {
      ApiService.removeReadingProgress(bookTitle, removedAt: nowUtc).then((res) {
        if (res['success'] == true) {
          _pendingRemovedBooks.remove(bookTitle);
          _saveRemovedBooks();
        }
      }).catchError((_) {});
    }
    notifyListeners();
  }

  void addBookToCollection({required BookItem book, required String collectionTag}) {
    final rawNorm = book.title.trim().toLowerCase();
    final normTitle = normalizeBookTitle(book.title);
    book.tag = collectionTag;
    bookCollections[rawNorm] = collectionTag;
    bookCollections[normTitle] = collectionTag;
    _saveBookCollections();

    // Retain in Your Library
    if (normTitle.isNotEmpty) {
      retainedLibraryBookTitles.add(normTitle);
      _saveRetainedLibraryBooks();
    }

    for (var b in libraryItems) {
      if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == normTitle) {
        b.tag = collectionTag;
      }
    }
    for (var b in userLocalBooks) {
      if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == normTitle) {
        b.tag = collectionTag;
      }
    }
    for (var b in continueShelf) {
      if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == normTitle) {
        b.tag = collectionTag;
      }
    }
    _saveLocalBooks();

    if (syncEnabled && isLoggedIn) {
      ApiService.assignBookToCollection(
        bookTitle: book.title,
        bookId: book.id,
        collectionTag: collectionTag,
      );
    }
    notifyListeners();
  }

  void selectPlan(String id) {
    selectedPlanId = id;
    notifyListeners();
  }

  void importBook(BookItem item) {
    final norm = normalizeBookTitle(item.title);
    final rawNorm = item.title.trim().toLowerCase();
    _unremoveBook(item.title);
    _unremoveBook(norm);
    _deletedUserDocTitles.remove(norm);
    _deletedUserDocTitles.remove(rawNorm);

    // 1. Inherit existing progress and favorites if this book was previously imported or read
    int? inheritedProgress;
    bool inheritedFavorite = false;
    DateTime? inheritedLastRead;

    final existingLocalIdx = userLocalBooks.indexWhere((b) =>
        b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == norm);
    if (existingLocalIdx != -1) {
      final existing = userLocalBooks.removeAt(existingLocalIdx);
      inheritedProgress = existing.progress;
      inheritedFavorite = existing.isFavorite;
      inheritedLastRead = existing.lastReadAt;
    }

    // 2. Remove any duplicate copies from continueShelf
    continueShelf.removeWhere((b) =>
        b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == norm);

    // 3. Clean up display title: strip trailing file extensions (.pdf, .epub, etc.) and convert underscores/dashes to spaces
    final cleanDisplayTitle = item.title
        .replaceAll(RegExp(r'\.(pdf|epub|txt|docx?|doc)$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final effectiveProgress = (item.progress != null && item.progress! > 0)
        ? item.progress
        : inheritedProgress;

    final cleanItem = BookItem(
      id: item.id,
      title: cleanDisplayTitle.isNotEmpty ? cleanDisplayTitle : item.title,
      author: item.author,
      meta: item.meta,
      color: item.color,
      progress: effectiveProgress,
      tag: item.tag,
      paragraphs: item.paragraphs,
      isFavorite: item.isFavorite || inheritedFavorite,
      lastReadAt: item.lastReadAt ?? inheritedLastRead ?? DateTime.now().toUtc(),
    );

    // 4. Place single unified book at index 0 (Your Library & Continue Reading)
    userLocalBooks.insert(0, cleanItem);
    continueShelf.insert(0, cleanItem);

    // Retain permanently in Your Library
    final cleanNorm = normalizeBookTitle(cleanItem.title);
    if (cleanNorm.isNotEmpty) {
      retainedLibraryBookTitles.add(cleanNorm);
      _deletedUserDocTitles.remove(cleanNorm);
      _saveRetainedLibraryBooks();
      _saveDeletedUserDocTitles();
    }

    _saveLocalBooks();

    if (syncEnabled && isLoggedIn) {
      ApiService.saveUserBook(cleanItem);
    }
    notifyListeners();
  }

  Future<void> _saveLocalBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = jsonEncode(userLocalBooks.map((b) => b.toJson()).toList());
      await prefs.setString(_userKey('local_imported_books'), localJson);
      final shelfJson = jsonEncode(continueShelf.map((b) => b.toJson()).toList());
      await prefs.setString(_userKey('continue_shelf_books'), shelfJson);
    } catch (_) {}
  }

  /// Returns true if this book is a user-imported document (PDF, TXT, EPUB, DOC, Web/paste)
  /// and NOT an official curated book managed by admin.
  bool isUserDocument(BookItem book) {
    final norm = normalizeBookTitle(book.title);
    final rawNorm = book.title.trim().toLowerCase();
    if (userLocalBooks.any((b) => b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == norm)) {
      return true;
    }
    final tag = book.tag.toLowerCase();
    if (tag == 'imported' || tag == 'web' || tag == 'pasted' || tag == 'user') {
      return true;
    }
    final isAdmin = libraryItems.any((b) => b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == norm);
    if (isAdmin) return false;
    return true;
  }

  /// Returns true if this book is an official catalog book managed by admin.
  bool isAdminBook(BookItem book) => !isUserDocument(book);

  /// Deletes a user document from local books, continue shelf, offline downloads,
  /// and marks a tombstone so it won't be re-synced.
  /// Admin managed books are strictly protected and cannot be deleted by users.
  Future<void> deleteUserDocument(BookItem book) async {
    if (isAdminBook(book)) return;

    final normTitle = normalizeBookTitle(book.title);
    final rawNorm = book.title.trim().toLowerCase();
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    // 1. Tombstone in deleted user documents so it won't reappear on sync
    _deletedUserDocTitles[normTitle] = nowUtc;
    _deletedUserDocTitles[rawNorm] = nowUtc;
    await _saveDeletedUserDocTitles();

    // 2. Remove from retained library titles
    retainedLibraryBookTitles.remove(normTitle);
    retainedLibraryBookTitles.remove(rawNorm);
    await _saveRetainedLibraryBooks();

    // 3. Remove from userLocalBooks and continueShelf
    userLocalBooks.removeWhere((b) =>
        b.title.trim().toLowerCase() == rawNorm ||
        normalizeBookTitle(b.title) == normTitle);
    continueShelf.removeWhere((b) =>
        b.title.trim().toLowerCase() == rawNorm ||
        normalizeBookTitle(b.title) == normTitle);

    // 4. Clear progress and lastReadAt on this instance
    book.progress = 0;
    book.lastReadAt = null;

    // 5. Remove from offline downloads if present
    try {
      downloadedBooks.removeWhere((b) =>
          b.title.trim().toLowerCase() == rawNorm ||
          normalizeBookTitle(b.title) == normTitle);
      await _saveOfflineDownloads();
    } catch (_) {}

    // 6. Reset reader state if this document is currently open
    if (readerTitle.trim().toLowerCase() == rawNorm || normalizeBookTitle(readerTitle) == normTitle) {
      readerShouldResetScroll = true;
      if (libraryItems.isNotEmpty) {
        readerTitle = libraryItems.first.title;
        readerByline = "${libraryItems.first.author ?? 'Library'} · ${libraryItems.first.meta ?? ''}";
        smartBannerText = "Clean Reader Mode: ${libraryItems.first.title}";
        articleParagraphs = libraryItems.first.paragraphs;
      } else {
        readerTitle = '';
        articleParagraphs = [];
      }
    }

    // 7. Persist local changes
    await _saveLocalBooks();

    // 8. Sync removal to backend if online and logged in
    if (syncEnabled && isLoggedIn) {
      ApiService.removeReadingProgress(book.title, removedAt: nowUtc).catchError((_) => <String, dynamic>{});
      ApiService.deleteUserBookFromServer(book.title).catchError((_) => <String, dynamic>{});
    }

    notifyListeners();
  }

  /// Removes any book/document from the user's library.
  /// - If it is a user document (imported file, web article, pasted text): deletes it completely.
  /// - If it is an admin catalog book: resets reading progress and clears user collection/favorite flags.
  /// - CRITICAL: In all cases, it strictly removes the book from the Continue Reading shelf as well!
  Future<void> removeBookFromLibrary(BookItem book) async {
    final normTitle = normalizeBookTitle(book.title);
    final rawNorm = book.title.trim().toLowerCase();

    // 1. Strictly remove from Continue Reading shelf and retained library titles
    continueShelf.removeWhere((b) =>
        b.title.trim().toLowerCase() == rawNorm ||
        normalizeBookTitle(b.title) == normTitle);
    retainedLibraryBookTitles.remove(normTitle);
    retainedLibraryBookTitles.remove(rawNorm);
    await _saveRetainedLibraryBooks();

    if (isUserDocument(book)) {
      await deleteUserDocument(book);
    } else {
      book.progress = 0;
      book.lastReadAt = null;
      book.isFavorite = false;
      bookCollections.remove(rawNorm);
      bookCollections.remove(normTitle);
      await _saveBookCollections();
      for (var b in libraryItems) {
        if (b.title.trim().toLowerCase() == rawNorm || normalizeBookTitle(b.title) == normTitle) {
          b.progress = 0;
          b.lastReadAt = null;
          b.isFavorite = false;
        }
      }
      await _saveLocalBooks();
      if (syncEnabled && isLoggedIn) {
        final nowUtc = DateTime.now().toUtc().toIso8601String();
        ApiService.removeReadingProgress(book.title, removedAt: nowUtc).catchError((_) => <String, dynamic>{});
      }
      notifyListeners();
    }
  }

  // --- Offline Downloads Management ---

  bool isBookDownloaded(String title) {
    final norm = title.trim().toLowerCase();
    return downloadedBooks.any((b) => b.title.trim().toLowerCase() == norm);
  }

  bool isBookDownloading(String title) {
    return downloadingBookTitles.contains(title.trim().toLowerCase());
  }

  String get totalOfflineStorageSize {
    try {
      final jsonStr = jsonEncode(downloadedBooks.map((b) => b.toJson()).toList());
      final bytes = utf8.encode(jsonStr).length;
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '0 KB';
    }
  }

  String getBookStorageSize(BookItem book) {
    try {
      final jsonStr = jsonEncode(book.toJson());
      final bytes = utf8.encode(jsonStr).length;
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '0 KB';
    }
  }

  Future<bool> downloadBookForOffline(BookItem book) async {
    final norm = book.title.trim().toLowerCase();
    if (isBookDownloaded(book.title)) return true;

    downloadingBookTitles.add(norm);
    notifyListeners();

    try {
      BookItem toSave = book;

      // If the book doesn't have paragraphs loaded yet, attempt to find in libraryItems
      if (toSave.paragraphs.isEmpty) {
        final libMatch = libraryItems.firstWhere(
          (b) => b.title.trim().toLowerCase() == norm && b.paragraphs.isNotEmpty,
          orElse: () => book,
        );
        if (libMatch.paragraphs.isNotEmpty) {
          toSave = libMatch;
        }
      }

      // If still empty but currently reading this book, use articleParagraphs
      if (toSave.paragraphs.isEmpty && readerTitle.trim().toLowerCase() == norm && articleParagraphs.isNotEmpty) {
        toSave = BookItem(
          id: book.id,
          title: book.title,
          author: book.author,
          meta: book.meta,
          color: book.color,
          progress: book.progress,
          tag: book.tag,
          paragraphs: List<String>.from(articleParagraphs),
          isFavorite: book.isFavorite,
          lastReadAt: book.lastReadAt,
        );
      }

      downloadedBooks.removeWhere((b) => b.title.trim().toLowerCase() == norm);
      downloadedBooks.insert(0, toSave);

      await _saveOfflineDownloads();
      downloadingBookTitles.remove(norm);
      notifyListeners();

      if (syncEnabled && isLoggedIn) {
        ApiService.pushDownloads([
          {
            'book_title': toSave.title,
            'book_id': toSave.id,
            'book_json': toSave.toJson(),
            'is_removed': false,
            'downloaded_at': DateTime.now().toUtc().toIso8601String(),
          }
        ]);
      }
      return true;
    } catch (_) {
      downloadingBookTitles.remove(norm);
      notifyListeners();
      return false;
    }
  }

  Future<void> removeDownloadedBook(String title) async {
    final norm = title.trim().toLowerCase();
    downloadedBooks.removeWhere((b) => b.title.trim().toLowerCase() == norm);
    await _saveOfflineDownloads();
    notifyListeners();

    if (syncEnabled && isLoggedIn) {
      ApiService.removeDownload(title);
    }
  }

  Future<void> clearAllDownloadedBooks() async {
    final titlesToRemove = downloadedBooks.map((b) => b.title).toList();
    downloadedBooks.clear();
    await _saveOfflineDownloads();
    notifyListeners();

    if (syncEnabled && isLoggedIn) {
      for (var t in titlesToRemove) {
        ApiService.removeDownload(t);
      }
    }
  }

  Future<void> _saveOfflineDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(downloadedBooks.map((b) => b.toJson()).toList());
      await prefs.setString(_userKey('offline_downloaded_books'), jsonStr);
      await prefs.setString('offline_downloaded_books', jsonStr);
    } catch (_) {}
  }

  void openOfflineBook(BookItem book) {
    final norm = book.title.trim().toLowerCase();
    final downloaded = downloadedBooks.firstWhere(
      (b) => b.title.trim().toLowerCase() == norm,
      orElse: () => book,
    );
    openBook(downloaded);
  }

  // Upgrade
  void upgradeNow() {
    isPremium = true;
    purchasedPlanId = selectedPlanId;
    notifyListeners();
  }

  DateTime? _lastLocalSyncToggleTime;

  void setSyncEnabled(bool enabled) {
    if (syncEnabled == enabled) return;
    syncEnabled = enabled;
    _lastLocalSyncToggleTime = DateTime.now();
    notifyListeners(); // 0ms INSTANT UI response for 60fps Switch toggle!

    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('sync_enabled', enabled);
    });

    if (isLoggedIn) {
      ApiService.updateSettings(syncEnabled: enabled);
      if (enabled) {
        // Flush any pending book removals first!
        if (_pendingRemovedBooks.isNotEmpty) {
          final toRemove = List<String>.from(_pendingRemovedBooks);
          for (final bTitle in toRemove) {
            final norm = bTitle.trim().toLowerCase();
            final removedAt = _removedBooks[norm];
            ApiService.removeReadingProgress(bTitle, removedAt: removedAt).then((res) {
              if (res['success'] == true) {
                _pendingRemovedBooks.remove(bTitle);
                _saveRemovedBooks();
              }
            }).catchError((_) {});
          }
        }

        // Last-Write-Wins: Push all local progress with their actual timestamps to cloud first!
        for (final book in continueShelf) {
          final norm = book.title.trim().toLowerCase();
          if (_removedBooks.containsKey(norm)) continue;
          final p = book.progress ?? 0;
          if (p > 0) {
            _pushReadingProgressSafe(book.title, p, lastReadAt: book.lastReadAt ?? DateTime.now());
          }
        }
        // Push all local highlights across all books to cloud!
        final allLocalHighlights = <Map<String, dynamic>>[];
        for (var entry in bookHighlights.entries) {
          for (var h in entry.value) {
            allLocalHighlights.add({
              'book_title': entry.key,
              'paragraph_index': h.paragraphIndex,
              'color': h.color,
              'note': h.note.isNotEmpty ? h.note : null,
            });
          }
        }
        if (allLocalHighlights.isNotEmpty) {
          ApiService.pushHighlights(allLocalHighlights);
        }
        performLiveSync();
      }
    }
  }

  void toggleSync() {
    setSyncEnabled(!syncEnabled);
  }

  // Real Background Delta Sync (Supports force = true on login for initial cloud data hydration)
  Future<void> performLiveSync({bool force = false}) async {
    if (!isLoggedIn || (!syncEnabled && !force)) return;
    try {
      final res = await ApiService.pullSync();
      if (res['success'] == true) {
        bool stateChanged = false;

        // 1. Sync Vocabulary, Learned Status, and Dictionary Cards across devices
        if (res['vocabulary'] != null && res['vocabulary'] is List) {
          final serverVocabList = res['vocabulary'] as List;
          final serverWords = <String>{};

          for (var v in serverVocabList) {
            final word = (v['word'] ?? '').toString().toLowerCase().trim();
            if (word.isNotEmpty) {
              serverWords.add(word);
              final clean = word.replaceAll(RegExp(r"[^a-zA-Z]"), '').trim();
              final isServerMastered = v['is_mastered'] == true || v['is_mastered'] == 1;
              final isMastered = isServerMastered || masteredWords.contains(word) || (clean.isNotEmpty && masteredWords.contains(clean));

              if (isMastered) {
                if (!masteredWords.contains(word)) {
                  masteredWords.add(word);
                  stateChanged = true;
                }
                if (vocabWords.contains(word)) {
                  vocabWords.remove(word);
                  stateChanged = true;
                }
                if (clean.isNotEmpty && vocabWords.contains(clean)) {
                  vocabWords.remove(clean);
                  stateChanged = true;
                }
                if (!isServerMastered && isLoggedIn) {
                  ApiService.recordVocabReview(word, isMastered: true);
                }
              } else {
                if (masteredWords.contains(word)) {
                  masteredWords.remove(word);
                  stateChanged = true;
                }
                if (clean.isNotEmpty && masteredWords.contains(clean)) {
                  masteredWords.remove(clean);
                  stateChanged = true;
                }
                if (!vocabWords.contains(word)) {
                  vocabWords.add(word);
                  stateChanged = true;
                }
              }

              if (v['meaning'] != null) {
                dictionary[word] = DictionaryEntry(
                  word: word,
                  pos: v['pos'] ?? 'word',
                  meaning: v['meaning'] ?? '',
                  example: v['example'] ?? '',
                  synonyms: v['synonyms'] is List ? List<String>.from(v['synonyms']) : const ["term", "expression"],
                  origin: v['origin'] ?? 'English vocabulary',
                );
              }
            }
          }

          // Remove any saved words locally if deleted from server
          final countBefore = vocabWords.length;
          vocabWords.removeWhere((w) => !serverWords.contains(w));
          masteredWords.removeWhere((w) => !serverWords.contains(w));
          if (vocabWords.length != countBefore) {
            stateChanged = true;
          }

          if (stateChanged) {
            _persistVocabWords();
          }
        }

        // 2. Sync Highlights across devices
        if (res['highlights'] != null && res['highlights'] is List) {
          final serverHighlights = res['highlights'] as List;
          final serverKeys = <String>{};

          for (var h in serverHighlights) {
            final bTitle = h['book_title']?.toString();
            final pIdx = h['paragraph_index'] as int?;
            final color = h['color']?.toString() ?? 'yellow';
            final note = h['note']?.toString();
            if (pIdx != null && bTitle != null && bTitle.trim().isNotEmpty) {
              final titleKey = bTitle.trim();
              serverKeys.add('${titleKey.toLowerCase()}:$pIdx');

              bookHighlights.putIfAbsent(titleKey, () => []);
              final existingIdx = bookHighlights[titleKey]!.indexWhere((item) => item.paragraphIndex == pIdx);
              if (existingIdx != -1) {
                if (bookHighlights[titleKey]![existingIdx].color != color ||
                    bookHighlights[titleKey]![existingIdx].note != (note ?? '')) {
                  bookHighlights[titleKey]![existingIdx].color = color;
                  bookHighlights[titleKey]![existingIdx].note = note ?? '';
                  stateChanged = true;
                }
              } else {
                bookHighlights[titleKey]!.add(HighlightItem(
                  paragraphIndex: pIdx,
                  color: color,
                  note: note ?? '',
                  bookTitle: titleKey,
                ));
                stateChanged = true;
              }

              // Update active reader highlights if currently reading this book
              if (titleKey.toLowerCase() == readerTitle.trim().toLowerCase()) {
                final activeIdx = highlights.indexWhere((item) => item.paragraphIndex == pIdx);
                if (activeIdx != -1) {
                  if (highlights[activeIdx].color != color ||
                      highlights[activeIdx].note != (note ?? '')) {
                    highlights[activeIdx].color = color;
                    highlights[activeIdx].note = note ?? '';
                    stateChanged = true;
                  }
                } else {
                  highlights.add(HighlightItem(
                    paragraphIndex: pIdx,
                    color: color,
                    note: note ?? '',
                    bookTitle: titleKey,
                  ));
                  stateChanged = true;
                }
              }
            }
          }

          // If currently reading a book, remove any highlights that were cleared/deleted on another device
          if (readerTitle.isNotEmpty && readerTitle != 'EasyRead Reader') {
            final curNormalized = readerTitle.trim().toLowerCase();
            final countBefore = highlights.length;
            highlights.removeWhere((item) {
              final key = '$curNormalized:${item.paragraphIndex}';
              return !serverKeys.contains(key);
            });
            if (highlights.length != countBefore) {
              stateChanged = true;
              bookHighlights[readerTitle] = List.from(highlights);
            }
          }

          // Also check for any offline highlights created locally that are missing from server, and push them
          final missingOnServer = <Map<String, dynamic>>[];
          for (var entry in bookHighlights.entries) {
            final bName = entry.key.trim();
            for (var h in entry.value) {
              final key = '${bName.toLowerCase()}:${h.paragraphIndex}';
              if (!serverKeys.contains(key)) {
                missingOnServer.add({
                  'book_title': bName,
                  'paragraph_index': h.paragraphIndex,
                  'color': h.color,
                  'note': h.note.isNotEmpty ? h.note : null,
                });
              }
            }
          }
          if (missingOnServer.isNotEmpty) {
            ApiService.pushHighlights(missingOnServer);
          }

          if (stateChanged) {
            _saveBookHighlights();
          }
        }

        // 3. Sync Reading Progress & Continue Shelf across devices (Timestamp / Last-Write-Wins with Tombstones)
        if (res['progress'] != null && res['progress'] is List) {
          final serverProgressList = res['progress'] as List;
          final serverTitles = <String>{};

          // Flush any pending book removals first!
          if (_pendingRemovedBooks.isNotEmpty) {
            final toRemove = List<String>.from(_pendingRemovedBooks);
            for (final bTitle in toRemove) {
              final norm = bTitle.trim().toLowerCase();
              final removedAt = _removedBooks[norm];
              ApiService.removeReadingProgress(bTitle, removedAt: removedAt).then((r) {
                if (r['success'] == true) {
                  _pendingRemovedBooks.remove(bTitle);
                  _saveRemovedBooks();
                }
              }).catchError((_) {});
            }
          }

          for (var p in serverProgressList) {
            final bTitle = p['book_title']?.toString() ?? (p['book'] != null ? p['book']['title']?.toString() : null);
            if (bTitle == null || bTitle.trim().isEmpty) continue;
            final normTitle = bTitle.trim().toLowerCase();
            final prog = (p['progress_percent'] is num) ? (p['progress_percent'] as num).toInt() : int.tryParse(p['progress_percent'].toString()) ?? 0;
            final bool serverIsRemoved = p['is_removed'] == true;

            DateTime? serverTime;
            if (p['last_read_at'] != null) {
              serverTime = DateTime.tryParse(p['last_read_at'].toString())?.toUtc();
            }
            if (serverTime == null && p['updated_at'] != null) {
              serverTime = DateTime.tryParse(p['updated_at'].toString())?.toUtc();
            }

            // Case A: Book was deleted from shelf on another device!
            if (serverIsRemoved) {
              _removedBooks[normTitle] = (serverTime ?? DateTime.now().toUtc()).toIso8601String();
              _pendingRemovedBooks.remove(bTitle);
              final hadBook = continueShelf.any((b) => b.title.trim().toLowerCase() == normTitle);
              if (hadBook) {
                continueShelf.removeWhere((b) => b.title.trim().toLowerCase() == normTitle);
                stateChanged = true;
              }
              for (var b in userLocalBooks) {
                if (b.title.trim().toLowerCase() == normTitle && (b.progress ?? 0) > 0) {
                  b.progress = 0;
                  stateChanged = true;
                }
              }
              for (var b in libraryItems) {
                if (b.title.trim().toLowerCase() == normTitle && (b.progress ?? 0) > 0) {
                  b.progress = 0;
                  stateChanged = true;
                }
              }
              continue; // Do NOT add to serverTitles, skip!
            }

            // Case B: This device deleted this book locally
            if (_removedBooks.containsKey(normTitle)) {
              final localRemovedTime = DateTime.tryParse(_removedBooks[normTitle]!)?.toUtc();
              bool serverIsStale = false;
              if (localRemovedTime != null) {
                if (serverTime == null || !serverTime.isAfter(localRemovedTime.add(const Duration(seconds: 1)))) {
                  serverIsStale = true;
                }
              } else {
                serverIsStale = true;
              }

              if (serverIsStale) {
                // Server has older progress; notify server of our deletion
                ApiService.removeReadingProgress(bTitle, removedAt: _removedBooks[normTitle]);
                final hadBook = continueShelf.any((b) => b.title.trim().toLowerCase() == normTitle);
                if (hadBook) {
                  continueShelf.removeWhere((b) => b.title.trim().toLowerCase() == normTitle);
                  stateChanged = true;
                }
                continue; // Do not add to serverTitles, skip!
              } else {
                // User actively read the book on 2nd device AFTER local deletion
                _removedBooks.remove(normTitle);
                _pendingRemovedBooks.remove(bTitle);
              }
            }

            serverTitles.add(bTitle);

            final shelfIdx = continueShelf.indexWhere((b) => b.title.trim().toLowerCase() == normTitle);

            if (shelfIdx != -1) {
              final localBook = continueShelf[shelfIdx];
              final localProg = localBook.progress ?? 0;
              final localTime = localBook.lastReadAt?.toUtc();

              // Determine whether local or server is newer (Last-Write-Wins with 1000ms drift buffer)
              bool localIsNewer = false;
              bool serverIsNewer = false;

              if (localTime != null && serverTime != null) {
                if (localTime.millisecondsSinceEpoch > serverTime.millisecondsSinceEpoch + 1000) {
                  localIsNewer = true;
                } else if (serverTime.millisecondsSinceEpoch > localTime.millisecondsSinceEpoch + 1000) {
                  serverIsNewer = true;
                }
              } else if (localTime != null && serverTime == null) {
                localIsNewer = true;
              } else if (serverTime != null && localTime == null) {
                serverIsNewer = true;
              }

              if (localIsNewer && !force) {
                // User read further / reset on THIS device while offline or sync was disabled!
                // Push local state to cloud so server and other devices update.
                _pushReadingProgressSafe(bTitle, localProg, lastReadAt: localTime);
              } else if (serverIsNewer || force || (localProg != prog && serverTime == null && localTime == null)) {
                // Server has a newer action (read further or reset on another device): adopt server state!
                localBook.progress = prog;
                localBook.lastReadAt = serverTime;
                stateChanged = true;
              }
            } else if (prog > 0) {
              // Book was read on another device! Look up from library or local books and insert into continueShelf
              BookItem? sourceBook;
              for (var b in libraryItems) {
                if (b.title.trim().toLowerCase() == normTitle) {
                  sourceBook = b;
                  break;
                }
              }
              if (sourceBook == null) {
                for (var b in userLocalBooks) {
                  if (b.title.trim().toLowerCase() == normTitle) {
                    sourceBook = b;
                    break;
                  }
                }
              }
              if (sourceBook == null && p['book'] != null && p['book'] is Map) {
                try {
                  sourceBook = BookItem.fromJson(Map<String, dynamic>.from(p['book']));
                } catch (_) {}
              }

              if (sourceBook != null) {
                sourceBook.progress = prog;
                sourceBook.lastReadAt = serverTime;
                continueShelf.insert(0, sourceBook);
                stateChanged = true;
              }
            }

            // Keep progress consistent across userLocalBooks and libraryItems
            for (var b in userLocalBooks) {
              if (b.title.trim().toLowerCase() == normTitle) {
                final cur = b.progress ?? 0;
                final localTime = b.lastReadAt?.toUtc();
                bool localIsNewer = (!force && localTime != null && serverTime != null && localTime.millisecondsSinceEpoch > serverTime.millisecondsSinceEpoch + 1000);
                if (localIsNewer) {
                  _pushReadingProgressSafe(bTitle, cur, lastReadAt: localTime);
                } else if (prog != cur) {
                  b.progress = prog;
                  b.lastReadAt = serverTime;
                  stateChanged = true;
                }
              }
            }
            for (var b in libraryItems) {
              if (b.title.trim().toLowerCase() == normTitle) {
                final cur = b.progress ?? 0;
                final localTime = b.lastReadAt?.toUtc();
                bool localIsNewer = (!force && localTime != null && serverTime != null && localTime.millisecondsSinceEpoch > serverTime.millisecondsSinceEpoch + 1000);
                if (localIsNewer) {
                  _pushReadingProgressSafe(bTitle, cur, lastReadAt: localTime);
                } else if (prog != cur) {
                  b.progress = prog;
                  b.lastReadAt = serverTime;
                  stateChanged = true;
                }
              }
            }
          }

          // Enforce local tombstones against continueShelf
          if (_removedBooks.isNotEmpty) {
            final before = continueShelf.length;
            continueShelf.removeWhere((b) => _removedBooks.containsKey(b.title.trim().toLowerCase()));
            if (continueShelf.length != before) {
              stateChanged = true;
            }
          }

          if (stateChanged) {
            _saveLocalBooks();
            _saveRemovedBooks();
          }
        }

          // 4. Sync Book Collection assignments across devices
          if (res['collection_books'] != null && res['collection_books'] is List) {
            final colBooks = res['collection_books'] as List;
            bool collectionsChanged = false;
            for (var item in colBooks) {
              final bTitle = item['book_title']?.toString();
              final cTag = item['collection_tag']?.toString();
              if (bTitle != null && cTag != null && bTitle.isNotEmpty && cTag.isNotEmpty) {
                final norm = bTitle.trim().toLowerCase();
                if (bookCollections[norm] != cTag) {
                  bookCollections[norm] = cTag;
                  collectionsChanged = true;
                }
              }
            }
            if (collectionsChanged) {
              _applyBookCollections();
              _saveBookCollections();
              stateChanged = true;
            }
          }

        // 5. Sync Offline Downloads across devices
        if (res['downloaded_books'] != null && res['downloaded_books'] is List) {
          final serverDownloads = res['downloaded_books'] as List;
          final serverDownloadTitles = <String>{};

          for (var d in serverDownloads) {
            final bTitle = d['book_title']?.toString();
            if (bTitle == null || bTitle.trim().isEmpty) continue;
            final norm = bTitle.trim().toLowerCase();
            final bool isRemoved = d['is_removed'] == true;

            if (isRemoved) {
              final hadBook = downloadedBooks.any((b) => b.title.trim().toLowerCase() == norm);
              if (hadBook) {
                downloadedBooks.removeWhere((b) => b.title.trim().toLowerCase() == norm);
                stateChanged = true;
              }
            } else {
              serverDownloadTitles.add(norm);
              final alreadyDownloaded = downloadedBooks.any((b) => b.title.trim().toLowerCase() == norm);
              if (!alreadyDownloaded) {
                BookItem? bookToSave;
                if (d['book_json'] != null && d['book_json'] is Map) {
                  try {
                    bookToSave = BookItem.fromJson(Map<String, dynamic>.from(d['book_json']));
                  } catch (_) {}
                }
                if (bookToSave == null || bookToSave.paragraphs.isEmpty) {
                  for (var b in [...libraryItems, ...continueShelf, ...userLocalBooks]) {
                    if (b.title.trim().toLowerCase() == norm && b.paragraphs.isNotEmpty) {
                      bookToSave = b;
                      break;
                    }
                  }
                }
                if (bookToSave != null) {
                  downloadedBooks.insert(0, bookToSave);
                  stateChanged = true;
                }
              }
            }
          }

          // Push any local offline downloads missing from server ONLY during regular sync, NOT initial force hydration
          if (!force && isLoggedIn) {
            final missingOnServer = <Map<String, dynamic>>[];
            for (var b in downloadedBooks) {
              final norm = b.title.trim().toLowerCase();
              if (!serverDownloadTitles.contains(norm)) {
                missingOnServer.add({
                  'book_title': b.title,
                  'book_id': b.id,
                  'book_json': b.toJson(),
                  'is_removed': false,
                  'downloaded_at': DateTime.now().toUtc().toIso8601String(),
                });
              }
            }
            if (missingOnServer.isNotEmpty) {
              ApiService.pushDownloads(missingOnServer);
            }
          }

          if (stateChanged) {
            _saveOfflineDownloads();
          }
        }

        // 6. Sync User Library Personal Books across devices (Web articles, Pasted text, Imported docs)
        if (res['user_books'] != null && res['user_books'] is List) {
          final serverBooks = res['user_books'] as List;
          final serverBookTitles = <String>{};

          for (var bData in serverBooks) {
            final bTitle = bData['title']?.toString();
            if (bTitle == null || bTitle.trim().isEmpty) continue;
            final norm = normalizeBookTitle(bTitle);
            serverBookTitles.add(norm);

            if (_deletedUserDocTitles.containsKey(norm)) continue;

            final existingIdx = userLocalBooks.indexWhere((b) => normalizeBookTitle(b.title) == norm);
            if (existingIdx == -1) {
              try {
                final newItem = BookItem.fromJson(Map<String, dynamic>.from(bData));
                userLocalBooks.insert(0, newItem);
                retainedLibraryBookTitles.add(norm);
                stateChanged = true;
              } catch (_) {}
            }
          }

          // Push any locally imported books to cloud ONLY during regular sync, NEVER during initial force hydration!
          if (!force && isLoggedIn && userLocalBooks.isNotEmpty) {
            for (var localBook in userLocalBooks) {
              final norm = normalizeBookTitle(localBook.title);
              if (!serverBookTitles.contains(norm) && !_deletedUserDocTitles.containsKey(norm)) {
                ApiService.saveUserBook(localBook);
              }
            }
          }

          if (stateChanged) {
            _deduplicateCollections();
            _saveLocalBooks();
          }
        }

        if (stateChanged) {
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  // Real Cloud Backup (Full Snapshot of Documents, Shelves, Vocabulary, and Highlights)
  bool isBackupInProgress = false;

  Future<Map<String, dynamic>> backupNow() async {
    isBackupInProgress = true;
    notifyListeners();

    // Collect all highlights across all books
    final allHighlights = <Map<String, dynamic>>[];
    for (var entry in bookHighlights.entries) {
      for (var h in entry.value) {
        allHighlights.add({
          'book_title': entry.key,
          'paragraph_index': h.paragraphIndex,
          'color': h.color,
          'note': h.note,
        });
      }
    }
    // Include current reader highlights if not already tracked
    for (var h in highlights) {
      if (!allHighlights.any((item) => item['book_title'] == readerTitle && item['paragraph_index'] == h.paragraphIndex)) {
        allHighlights.add({
          'book_title': readerTitle,
          'paragraph_index': h.paragraphIndex,
          'color': h.color,
          'note': h.note,
        });
      }
    }

    final localTimeNow = formatTimestampLocal(DateTime.now().toIso8601String());
    final payload = {
      'title': 'Cloud Backup ($localTimeNow)',
      'local_books': userLocalBooks.map((b) => b.toJson()).toList(),
      'continue_shelf': continueShelf.map((b) => b.toJson()).toList(),
      'collections': collections.map((c) => c.toJson()).toList(),
      'vocab_words': vocabWords,
      'highlights': allHighlights,
      'book_collections': bookCollections,
      'downloaded_books': downloadedBooks.map((b) => b.toJson()).toList(),
    };

    final res = await ApiService.createBackup(localPayload: payload);
    isBackupInProgress = false;

    if (res['success'] == true) {
      final rawCreatedAt = res['backup']?['created_at'];
      final formattedTime = formatTimestampLocal(rawCreatedAt);
      lastBackupTime = formattedTime;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey('last_backup_time'), formattedTime);
      await prefs.setString('last_backup_time', formattedTime);
    }

    notifyListeners();
    return res;
  }

  // Fetch real list of cloud backups
  Future<List<Map<String, dynamic>>> fetchBackupsList() async {
    return await ApiService.getBackups();
  }

  // Real Point-in-time Restore (Reconstructs all reading materials & progress)
  bool isRestoreInProgress = false;

  Future<Map<String, dynamic>> restoreFromBackup(int backupId) async {
    isRestoreInProgress = true;
    notifyListeners();

    final res = await ApiService.restoreBackup(backupId);
    isRestoreInProgress = false;

    if (res['success'] == true && res['snapshot'] != null) {
      final snapshot = res['snapshot'];

      // 1. Restore User Local Books & Documents
      if (snapshot['local_books'] != null && snapshot['local_books'] is List) {
        userLocalBooks = (snapshot['local_books'] as List)
            .map((b) => BookItem.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }

      // 2. Restore Continue Shelf
      if (snapshot['continue_shelf'] != null && snapshot['continue_shelf'] is List) {
        continueShelf = (snapshot['continue_shelf'] as List)
            .map((b) => BookItem.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      } else if (userLocalBooks.isNotEmpty) {
        continueShelf = [...userLocalBooks];
      }

      // 3. Restore Collections
      if (snapshot['collections'] != null && snapshot['collections'] is List) {
        collections = (snapshot['collections'] as List)
            .map((c) => CollectionItem.fromJson(Map<String, dynamic>.from(c)))
            .toList();
      }

      // 4. Restore Vocabulary Words
      if (snapshot['vocab_words'] != null && snapshot['vocab_words'] is List) {
        vocabWords.clear();
        for (var w in snapshot['vocab_words']) {
          final word = w.toString().toLowerCase().trim();
          final clean = word.replaceAll(RegExp(r"[^a-zA-Z]"), '').trim();
          final isMastered = masteredWords.contains(word) || (clean.isNotEmpty && masteredWords.contains(clean));
          if (word.isNotEmpty && !vocabWords.contains(word) && !isMastered) {
            vocabWords.add(word);
          }
        }
        _persistVocabWords();
      }

      // 5. Restore Highlights
      if (snapshot['highlights'] != null && snapshot['highlights'] is List) {
        bookHighlights.clear();
        highlights.clear();
        for (var h in snapshot['highlights']) {
          final bTitle = h['book_title']?.toString() ?? readerTitle;
          final pIdx = h['paragraph_index'] as int?;
          final color = h['color']?.toString() ?? 'yellow';
          final note = h['note']?.toString();
          if (pIdx != null) {
            bookHighlights.putIfAbsent(bTitle, () => []).add(HighlightItem(
              paragraphIndex: pIdx,
              color: color,
              note: note ?? '',
              bookTitle: bTitle,
            ));
            if (bTitle == readerTitle) {
              highlights.add(HighlightItem(
                paragraphIndex: pIdx,
                color: color,
                note: note ?? '',
                bookTitle: bTitle,
              ));
            }
          }
        }
        await _saveBookHighlights();
      }

      // 6. Restore Book Collections
      if (snapshot['book_collections'] != null && snapshot['book_collections'] is Map) {
        bookCollections = Map<String, String>.from(
          (snapshot['book_collections'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
        );
        _applyBookCollections();
        _saveBookCollections();
      }

      // 7. Restore Downloaded Books
      if (snapshot['downloaded_books'] != null && snapshot['downloaded_books'] is List) {
        downloadedBooks = (snapshot['downloaded_books'] as List)
            .map((b) => BookItem.fromJson(Map<String, dynamic>.from(b)))
            .toList();
        await _saveOfflineDownloads();
      }

      // Reset removed book tombstones so restored books don't get deleted on next sync
      _removedBooks.clear();
      _pendingRemovedBooks.clear();
      await _saveRemovedBooks();

      // Persist restored state locally
      await _saveLocalBooks();
      await fetchDynamicBooks();
      await fetchDynamicCollections();
    }

    notifyListeners();
    return res;
  }

  // Profile: Update Name / Email
  Future<Map<String, dynamic>> updateProfile({String? name, String? email}) async {
    isAuthLoading = true;
    notifyListeners();

    final res = await ApiService.updateProfile(name: name, email: email);
    isAuthLoading = false;

    if (res['success'] == true && res['user'] != null) {
      final user = res['user'];
      currentUser = user;
      currentUserName = user['name'] ?? currentUserName;
      currentUserEmail = user['email'] ?? currentUserEmail;

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user', jsonEncode(user));
      } catch (_) {}
    }

    notifyListeners();
    return res;
  }

  // Profile: Change Password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await ApiService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
