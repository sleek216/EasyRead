import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/easy_word_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'library/library_screen.dart';
import 'reader/reader_screen.dart';
import 'vocab/vocab_screen.dart';
import 'profile/profile_screen.dart';
import '../widgets/easy_toast.dart';
import '../sheets/feature_upgrade_sheet.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        context.read<EasyReadProvider>().syncUserLiveState();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. If on any other tab (Reader, Vocab, Profile), back takes you straight to Library
        if (provider.activeTab != 'library') {
          provider.handleBackNavigation();
          return;
        }

        // 2. We are on Library (Home) root: require double-back to exit
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          showEasyToast(context, "Press back again to exit");
          return;
        }

        // Second press within 2 seconds -> close the app cleanly
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: IndexedStack(
          index: _getTabIndex(provider.activeTab),
          children: const [
            LibraryScreen(),
            ReaderScreen(),
            VocabScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.paperSoft,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.only(top: 10, bottom: 20, left: 6, right: 6),
          child: Row(
            children: [
              _buildTabItem(
                icon: Icons.menu_book,
                label: "Library",
                isActive: provider.activeTab == 'library',
                onTap: () => provider.switchTab('library'),
              ),
              _buildTabItem(
                icon: Icons.auto_stories,
                label: "Reading",
                isActive: provider.activeTab == 'reader',
                onTap: () => provider.switchTab('reader'),
              ),
              _buildTabItem(
                icon: Icons.bookmark_border,
                label: "Words",
                isActive: provider.activeTab == 'vocab',
                onTap: () {
                  if (!provider.hasFeature('words_screen')) {
                    showFeatureUpgradeSheet(
                      context: context,
                      featureKey: 'words_screen',
                      featureTitle: "Words & Bookmarks",
                      featureDescription: "Upgrade to access your saved vocabulary flashcards and bookmarked articles.",
                      icon: Icons.bookmark,
                    );
                    return;
                  }
                  provider.switchTab('vocab');
                },
              ),
              _buildTabItem(
                icon: Icons.person_outline,
                label: "Profile",
                isActive: provider.activeTab == 'profile',
                onTap: () => provider.switchTab('profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _getTabIndex(String tab) {
    switch (tab) {
      case 'library':
        return 0;
      case 'reader':
        return 1;
      case 'vocab':
        return 2;
      case 'profile':
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.moss : AppColors.textMute,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.moss : AppColors.textMute,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
