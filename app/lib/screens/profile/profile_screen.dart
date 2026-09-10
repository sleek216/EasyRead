import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/easy_word_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_top_bar.dart';
import '../../widgets/bottom_sheet_wrapper.dart';
import '../../widgets/easy_toast.dart';
import '../../sheets/upgrade_sheet.dart';
import '../../sheets/feature_upgrade_sheet.dart';
import '../auth/forgot_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _downloadsExpanded = false;
  bool _syncExpanded = false;
  bool _devicesExpanded = false;
  bool _accountExpanded = false;
  String _lastTab = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentTab = context.watch<EasyReadProvider>().activeTab;
    if (currentTab != 'profile' || (_lastTab != 'profile' && currentTab == 'profile')) {
      _downloadsExpanded = false;
      _syncExpanded = false;
      _devicesExpanded = false;
      _accountExpanded = false;
    }
    _lastTab = currentTab;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CustomAppTopBar(title: "Profile"),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.gold, AppColors.moss],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            provider.currentUserName.isNotEmpty
                                ? provider.currentUserName.substring(0, provider.currentUserName.length >= 2 ? 2 : 1).toUpperCase()
                                : "ER",
                            style: AppTypography.fraunces(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.currentUserName,
                                style: AppTypography.fraunces(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                provider.currentUserEmail,
                                style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Plan Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: provider.isPremium
                            ? const LinearGradient(colors: [Color(0xFF16241D), Color(0xFF2C4433)])
                            : null,
                        color: provider.isPremium ? null : AppColors.ink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CURRENT PLAN",
                                style: AppTypography.inter(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0x8CEFE6D0),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                provider.planDisplayName,
                                style: AppTypography.fraunces(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.paper,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                provider.isPremium
                                    ? (provider.currentUser?['subscription_expires_at'] != null
                                        ? "Renews / Expires: ${provider.currentUser!['subscription_expires_at'].toString().split('T').first}"
                                        : "Unlimited access · Auto-renewing")
                                    : "30 saved words · 10 AI uses/day",
                                style: AppTypography.inter(fontSize: 10.5, color: const Color(0x99EFE6D0)),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldSoft,
                              foregroundColor: AppColors.ink,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              elevation: 0,
                            ),
                            onPressed: () {
                              showEasyModalSheet(
                                context: context,
                                builder: (ctx) => const UpgradeSheetContent(),
                              );
                            },
                            child: Text(
                              provider.isPremium ? "Change Plan" : "Upgrade",
                              style: AppTypography.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 0: Offline Downloads (Dropdown Accordion matching the other 3)
                    _ExpandableSectionCard(
                      icon: Icons.download_rounded,
                      title: "Offline Downloads",
                      isExpanded: _downloadsExpanded,
                      onExpansionChanged: (val) {
                        setState(() => _downloadsExpanded = val);
                      },
                      children: [
                        if (provider.downloadedBooks.isEmpty) ...[
                          _buildSettingRow(
                            icon: Icons.cloud_download_outlined,
                            title: "No offline books",
                            subtitle: "Download books to read without internet connection",
                            isLast: true,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.paper,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Text(
                                "0 books",
                                style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ] else ...[
                          _buildSettingRow(
                            icon: Icons.storage_rounded,
                            title: "${provider.downloadedBooks.length} ${provider.downloadedBooks.length == 1 ? 'Book' : 'Books'} Saved",
                            subtitle: "Storage: ${provider.totalOfflineStorageSize} · 100% offline",
                            trailing: GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (dCtx) => AlertDialog(
                                    backgroundColor: AppColors.paper,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Text("Clear All Downloads?", style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w700)),
                                    content: Text("This will remove all downloaded books from your device.", style: AppTypography.inter(fontSize: 12.5, color: AppColors.textDark)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dCtx, false),
                                        child: Text("Cancel", style: AppTypography.inter(fontSize: 12, color: AppColors.textMute)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.plum,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => Navigator.pop(dCtx, true),
                                        child: Text("Clear All", style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  await provider.clearAllDownloadedBooks();
                                  if (context.mounted) {
                                    showEasyToast(context, "All offline downloads cleared");
                                  }
                                }
                              },
                              child: Text(
                                "Clear all",
                                style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.plum),
                              ),
                            ),
                          ),
                          ...provider.downloadedBooks.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final book = entry.value;
                            final isLast = idx == provider.downloadedBooks.length - 1;

                            return Container(
                              decoration: BoxDecoration(
                                border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.line, width: 0.7)),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    child: const Icon(Icons.menu_book_rounded, size: 15, color: AppColors.moss),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          "${book.author ?? 'Library Book'} · ${provider.getBookStorageSize(book)}",
                                          style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => provider.openOfflineBook(book),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.paper,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.line),
                                      ),
                                      child: Text(
                                        "Read",
                                        style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () async {
                                      await provider.removeDownloadedBook(book.title);
                                      if (context.mounted) {
                                        showEasyToast(context, 'Removed "${book.title}" from downloads');
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textMute),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),

                    // SECTION 1: Sync & Backup (Dropdown Accordion)
                    _ExpandableSectionCard(
                      icon: Icons.cloud_sync_outlined,
                      title: "Sync & Backup",
                      isExpanded: _syncExpanded,
                      onExpansionChanged: (val) {
                        setState(() => _syncExpanded = val);
                      },
                      children: [
                        _buildSettingRow(
                          icon: Icons.sync,
                          title: "Cross-device sync",
                          subtitle: provider.hasFeature('cloud_sync')
                              ? (provider.syncEnabled ? "Syncing across your devices" : "Turned off")
                              : "Plus feature · Tap to unlock",
                          trailing: Switch.adaptive(
                            value: provider.hasFeature('cloud_sync') && provider.syncEnabled,
                            activeTrackColor: AppColors.moss,
                            onChanged: (val) {
                              if (val && !provider.hasFeature('cloud_sync')) {
                                showFeatureUpgradeSheet(
                                  context: context,
                                  featureKey: 'cloud_sync',
                                  featureTitle: "Cross-Device Sync",
                                  featureDescription: "Keep your entire library, vocabulary cards, and reading progress synchronized across all your phones and tablets.",
                                  icon: Icons.sync,
                                );
                                return;
                              }
                              provider.setSyncEnabled(val);
                              showEasyToast(
                                context,
                                val
                                    ? "Cross-device sync turned on"
                                    : "Cross-device sync turned off",
                              );
                            },
                          ),
                        ),
                        _buildSettingRow(
                          icon: Icons.cloud_upload_outlined,
                          title: "Back up now",
                          subtitle: provider.lastBackupTime != null
                              ? "Last backup: ${provider.lastBackupTime}"
                              : "Last backup: never",
                          trailing: provider.isBackupInProgress
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.moss),
                                )
                              : GestureDetector(
                                  onTap: () async {
                                    final allowed = await provider.checkFeatureAccess('cloud_sync');
                                    if (!context.mounted) return;
                                    if (!allowed) {
                                      showFeatureUpgradeSheet(
                                        context: context,
                                        featureKey: 'cloud_sync',
                                        featureTitle: "Cloud Backup & Multi-Device Sync",
                                        featureDescription: "Back up your entire reading history, vocabulary cards, and book progress to the cloud to access anywhere.",
                                        icon: Icons.cloud_sync_outlined,
                                      );
                                      return;
                                    }
                                    showEasyToast(context, "Backing up your library & documents...");
                                    final res = await provider.backupNow();
                                    if (context.mounted) {
                                      if (res['success'] == true) {
                                        showEasyToast(context, "Cloud backup created successfully");
                                      } else {
                                        showEasyToast(context, res['message']?.toString() ?? "Failed to create backup");
                                      }
                                    }
                                  },
                                  child: Text(
                                    "Back up",
                                    style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.moss),
                                  ),
                                ),
                        ),
                        _buildSettingRow(
                          icon: Icons.history,
                          title: "Restore from backup",
                          subtitle: "Bring back a previous library state",
                          isLast: true,
                          trailing: GestureDetector(
                            onTap: () async {
                              final allowed = await provider.checkFeatureAccess('cloud_sync');
                              if (!context.mounted) return;
                              if (!allowed) {
                                showFeatureUpgradeSheet(
                                  context: context,
                                  featureKey: 'cloud_sync',
                                  featureTitle: "Cloud Backup & Multi-Device Sync",
                                  featureDescription: "Restore previous library states, saved words, and reading progress across all your devices.",
                                  icon: Icons.history,
                                );
                                return;
                              }
                              _showRestoreBackupsSheet(context, provider);
                            },
                            child: Text(
                              "Restore",
                              style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.moss),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // SECTION 2: Connected Devices (Live Dynamic Accordion)
                    _ConnectedDevicesAccordion(
                      isExpanded: _devicesExpanded,
                      onExpansionChanged: (val) {
                        setState(() => _devicesExpanded = val);
                      },
                    ),

                    // SECTION 3: Account & Privacy (Dropdown Accordion)
                    _ExpandableSectionCard(
                      icon: Icons.shield_outlined,
                      title: "Account & Privacy",
                      isExpanded: _accountExpanded,
                      onExpansionChanged: (val) {
                        setState(() => _accountExpanded = val);
                      },
                      children: [
                        _buildActionRow(
                          Icons.mail_outline,
                          "Email address",
                          () => _showEmailEditSheet(context, provider),
                          actionText: "Edit",
                        ),
                        _buildActionRow(
                          Icons.lock_outline,
                          "Password",
                          () => _showPasswordEditSheet(context, provider),
                          actionText: "Edit",
                        ),
                        _buildActionRow(
                          Icons.privacy_tip_outlined,
                          "Privacy & data",
                          () => _showPrivacyDataSheet(context, provider),
                          actionText: "View",
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Sign out
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x33A13B3B)),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        await provider.logout();
                        if (context.mounted) {
                          showEasyToast(context, "Logged out successfully");
                        }
                      },
                      child: Text(
                        "Sign out",
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA13B3B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Apple Store Compliance 5.1.1: Delete Account
                    Center(
                      child: TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.paper,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              title: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDE8E8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Delete Account?",
                                    style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                                  ),
                                ],
                              ),
                              content: Text(
                                "Are you sure you want to delete your account? All your reading progress, highlights, and vocabulary will be permanently removed. This action cannot be undone.",
                                style: AppTypography.inter(fontSize: 13, color: AppColors.textDark, height: 1.45),
                              ),
                              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text("Cancel", style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMute)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD32F2F),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    elevation: 0,
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    showEasyToast(context, "Deleting account and wiping data...");
                                    final res = await ApiService.deleteAccount();
                                    await provider.logout();
                                    if (context.mounted) {
                                      if (res['success'] == true) {
                                        showEasyToast(context, "Account deleted & personal data permanently erased");
                                      } else {
                                        showEasyToast(context, res['message']?.toString() ?? "Account deleted");
                                      }
                                    }
                                  },
                                  child: Text("Delete Account", style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          "Delete Account",
                          style: AppTypography.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMute,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Edit Email Bottom Sheet
  void _showEmailEditSheet(BuildContext context, EasyReadProvider provider) {
    final emailController = TextEditingController(text: provider.currentUserEmail);
    final nameController = TextEditingController(text: provider.currentUserName);
    bool isLoading = false;

    showEasyModalSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Account Details",
                style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                "Update your display name and login email address.",
                style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
              ),
              const SizedBox(height: 16),
              
              Text("NAME", style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: AppTypography.inter(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: "Enter your name",
                  filled: true,
                  fillColor: AppColors.paperSoft,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.moss, width: 1.5)),
                ),
              ),
              const SizedBox(height: 14),

              Text("EMAIL ADDRESS", style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.inter(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: "Enter new email",
                  filled: true,
                  fillColor: AppColors.paperSoft,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.moss, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moss,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isLoading ? null : () async {
                  final newName = nameController.text.trim();
                  final newEmail = emailController.text.trim();
                  if (newEmail.isEmpty || !newEmail.contains('@')) {
                    showEasyToast(context, "Please enter a valid email address");
                    return;
                  }

                  setState(() => isLoading = true);
                  final res = await provider.updateProfile(name: newName, email: newEmail);
                  setState(() => isLoading = false);

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    if (res['success'] == true) {
                      showEasyToast(context, "Profile updated successfully");
                    } else {
                      showEasyToast(context, res['message'] ?? "Failed to update profile");
                    }
                  }
                },
                child: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text("Save Changes", style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Change Password Bottom Sheet
  void _showPasswordEditSheet(BuildContext context, EasyReadProvider provider) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showEasyModalSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Change Password",
                style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                "Enter your current password and choose a new one.",
                style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("CURRENT PASSWORD", style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            initialEmail: provider.currentUserEmail,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Text(
                        "Forgot password?",
                        style: AppTypography.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.moss),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: currentPassController,
                obscureText: obscureCurrent,
                style: AppTypography.inter(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: "Current password",
                  filled: true,
                  fillColor: AppColors.paperSoft,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMute),
                    onPressed: () => setState(() => obscureCurrent = !obscureCurrent),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.moss, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              Text("NEW PASSWORD", style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: newPassController,
                obscureText: obscureNew,
                style: AppTypography.inter(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: "Minimum 6 characters",
                  filled: true,
                  fillColor: AppColors.paperSoft,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMute),
                    onPressed: () => setState(() => obscureNew = !obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.moss, width: 1.5)),
                ),
              ),
              const SizedBox(height: 12),

              Text("CONFIRM NEW PASSWORD", style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              TextField(
                controller: confirmPassController,
                obscureText: obscureConfirm,
                style: AppTypography.inter(fontSize: 13, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: "Re-enter new password",
                  filled: true,
                  fillColor: AppColors.paperSoft,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.textMute),
                    onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.moss, width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.moss,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isLoading ? null : () async {
                  final currentPass = currentPassController.text.trim();
                  final newPass = newPassController.text.trim();
                  final confirmPass = confirmPassController.text.trim();

                  if (currentPass.isEmpty) {
                    showEasyToast(context, "Please enter your current password");
                    return;
                  }
                  if (newPass.length < 6) {
                    showEasyToast(context, "New password must be at least 6 characters");
                    return;
                  }
                  if (newPass != confirmPass) {
                    showEasyToast(context, "New passwords do not match");
                    return;
                  }

                  setState(() => isLoading = true);
                  final res = await provider.changePassword(
                    currentPassword: currentPass,
                    newPassword: newPass,
                  );
                  setState(() => isLoading = false);

                  if (context.mounted) {
                    if (res['success'] == true) {
                      Navigator.pop(ctx);
                      showEasyToast(context, "Password changed successfully");
                    } else {
                      showEasyToast(context, res['message'] ?? "Failed to change password");
                    }
                  }
                },
                child: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text("Update Password", style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Privacy & Data Bottom Sheet (Dynamic from Admin Backend)
  void _showPrivacyDataSheet(BuildContext context, EasyReadProvider provider) {
    const defaultPolicy =
        "EasyRead values your reading privacy.\n\n• Private AI Processing: Passages sent to AI for simplify, summarize, explain, or translation are processed securely and never retained to train public models.\n\n• Local & Encrypted Sync: Your vocabulary words, reading highlights, and book progress are stored securely on your device and encrypted during sync.\n\n• No Data Selling: We do not sell your reading habits, vocabulary, or personal data to any third parties.";

    showEasyModalSheet(
      context: context,
      builder: (ctx) => FutureBuilder<String?>(
        future: ApiService.getPrivacyPolicy(),
        initialData: defaultPolicy,
        builder: (context, snapshot) {
          final policyText = (snapshot.data != null && snapshot.data!.isNotEmpty)
              ? snapshot.data!
              : defaultPolicy;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Privacy & Policy",
                  style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  "EasyRead is built with reading privacy and data security at its core.",
                  style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                ),
                const SizedBox(height: 16),

                Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.paperSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      policyText,
                      style: AppTypography.inter(
                        fontSize: 12.5,
                        color: AppColors.textDark,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.moss,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Done", style: AppTypography.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.line, width: 0.7)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(icon, size: 15, color: AppColors.textDark),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(subtitle, style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, VoidCallback onTap, {String actionText = "View", bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.line, width: 0.7)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          splashColor: AppColors.gold.withValues(alpha: 0.12),
          highlightColor: AppColors.moss.withValues(alpha: 0.06),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.textDark),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(label, style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                Text(
                  actionText,
                  style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.moss),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Expandable Accordion Card Widget for Settings Categories
class _ExpandableSectionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool? isExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  const _ExpandableSectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.isExpanded,
    this.onExpansionChanged,
  });

  @override
  State<_ExpandableSectionCard> createState() => _ExpandableSectionCardState();
}

class _ExpandableSectionCardState extends State<_ExpandableSectionCard> {
  late bool _isExpanded;

  bool get _isCurrentlyExpanded => widget.isExpanded ?? _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded ?? widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant _ExpandableSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != null && widget.isExpanded != _isExpanded) {
      _isExpanded = widget.isExpanded!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpandedNow = _isCurrentlyExpanded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.paperSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          // Clickable Dropdown Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final next = !isExpandedNow;
                setState(() => _isExpanded = next);
                widget.onExpansionChanged?.call(next);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.moss.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(widget.icon, size: 16, color: AppColors.moss),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTypography.fraunces(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpandedNow ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: AppColors.textMute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Animated Dropdown Sub-Items
          AnimatedCrossFade(
            firstChild: Container(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.line, width: 0.8)),
              ),
              child: Column(children: widget.children),
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpandedNow ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _ConnectedDevicesAccordion extends StatefulWidget {
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;

  const _ConnectedDevicesAccordion({
    required this.isExpanded,
    required this.onExpansionChanged,
  });

  @override
  State<_ConnectedDevicesAccordion> createState() => _ConnectedDevicesAccordionState();
}

class _ConnectedDevicesAccordionState extends State<_ConnectedDevicesAccordion> {
  List<Map<String, dynamic>>? _devices;
  bool _isLoading = false;
  int? _revokingDeviceId;
  bool _isLoggingOutOthers = false;

  @override
  void didUpdateWidget(covariant _ConnectedDevicesAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _loadDevices();
    }
  }

  Future<void> _loadDevices() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final provider = context.read<EasyReadProvider>();
    await provider.refreshConnectedDevices();
    if (mounted) {
      setState(() {
        _devices = provider.connectedDevices;
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeDevice(int id, String name) async {
    if (_revokingDeviceId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Log out this device?", style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text(
          "Are you sure you want to disconnect \"$name\"? This session will be immediately signed out.",
          style: AppTypography.inter(fontSize: 13, color: AppColors.textMute),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: AppTypography.inter(color: AppColors.textMute, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Log Out", style: AppTypography.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _revokingDeviceId = id);
    final res = await ApiService.revokeDevice(id);
    if (mounted) {
      setState(() => _revokingDeviceId = null);
      if (res['success'] == true) {
        showEasyToast(context, 'Disconnected "$name"');
      } else {
        showEasyToast(context, res['message'] ?? 'Failed to disconnect');
      }
      context.read<EasyReadProvider>().refreshConnectedDevices();
    }
  }

  Future<void> _logoutAllOthers() async {
    if (_isLoggingOutOthers) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Log out all other sessions?", style: AppTypography.fraunces(fontSize: 18, fontWeight: FontWeight.w600)),
        content: Text(
          "All other active devices will be signed out immediately and required to log in again.",
          style: AppTypography.inter(fontSize: 13, color: AppColors.textMute),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: AppTypography.inter(color: AppColors.textMute, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Log Out All", style: AppTypography.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOutOthers = true);
    final res = await ApiService.logoutOtherDevices();
    if (mounted) {
      setState(() => _isLoggingOutOthers = false);
      if (res['success'] == true) {
        showEasyToast(context, 'Logged out of all other sessions');
      } else {
        showEasyToast(context, res['message'] ?? 'Failed to log out other sessions');
      }
      context.read<EasyReadProvider>().refreshConnectedDevices();
    }
  }

  IconData _getDeviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ipad') || lower.contains('tablet')) return Icons.tablet_mac;
    if (lower.contains('mac') || lower.contains('pc') || lower.contains('windows') || lower.contains('laptop') || lower.contains('desktop')) {
      return Icons.laptop_mac;
    }
    if (lower.contains('iphone') || lower.contains('phone') || lower.contains('android') || lower.contains('xiaomi') || lower.contains('samsung')) {
      return Icons.phone_android;
    }
    return Icons.devices;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final devices = provider.connectedDevices.isNotEmpty ? provider.connectedDevices : (_devices ?? []);
    final otherDevicesCount = devices.where((d) => d['is_current'] != true).length;

    return _ExpandableSectionCard(
      icon: Icons.devices_outlined,
      title: "Connected Devices",
      isExpanded: widget.isExpanded,
      initiallyExpanded: false,
      onExpansionChanged: (isExpanded) {
        widget.onExpansionChanged(isExpanded);
        if (isExpanded) {
          _loadDevices();
        }
      },
      children: [
        if (_isLoading) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.moss),
              ),
            ),
          ),
        ] else if (devices.isEmpty) ...[
          _buildStaticDeviceRow("This Device", "Active now · Main session", true, isLast: true),
        ] else ...[
          ...devices.asMap().entries.map((entry) {
            final idx = entry.key;
            final dev = entry.value;
            final isCurrent = dev['is_current'] == true;
            final devId = int.tryParse(dev['id']?.toString() ?? '0') ?? 0;
            final isLast = (idx == devices.length - 1) && otherDevicesCount == 0;
            final name = dev['name']?.toString() ?? 'Mobile Device';
            final isOnline = dev['is_online'] == true || isCurrent;
            final sub = isCurrent
                ? "Active now · This device"
                : (isOnline ? "Active now · Other session" : "Last active: ${dev['last_active'] ?? 'Recently'}");
            final isRevokingThis = _revokingDeviceId == devId;

            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.line, width: 0.7)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.moss.withValues(alpha: 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isCurrent ? AppColors.moss.withValues(alpha: 0.3) : AppColors.line),
                    ),
                    child: Icon(
                      _getDeviceIcon(name),
                      size: 16,
                      color: isCurrent ? AppColors.moss : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.moss.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "THIS DEVICE",
                                  style: AppTypography.inter(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.moss,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: isOnline ? AppColors.moss : AppColors.textMute.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(sub, style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isCurrent && devId > 0) ...[
                    GestureDetector(
                      onTap: isRevokingThis ? null : () => _revokeDevice(devId, name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: isRevokingThis
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFFD32F2F)),
                              )
                            : Text(
                                "Log out",
                                style: AppTypography.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD32F2F),
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (otherDevicesCount > 0) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isLoggingOutOthers ? null : _logoutAllOthers,
                  icon: _isLoggingOutOthers
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD32F2F)),
                        )
                      : const Icon(Icons.logout_rounded, size: 14, color: Color(0xFFD32F2F)),
                  label: Text(
                    _isLoggingOutOthers ? "Logging out other sessions..." : "Log out of all other sessions ($otherDevicesCount)",
                    style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFD32F2F)),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFDE8E8).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildStaticDeviceRow(String name, String sub, bool isActive, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.line, width: 0.7)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(Icons.devices, size: 15, color: AppColors.textDark),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Row(
                children: [
                  if (isActive) ...[
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.moss,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  Text(sub, style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showRestoreBackupsSheet(BuildContext context, EasyReadProvider provider) {
  showEasyModalSheet(
    context: context,
    builder: (ctx) => _RestoreBackupsModal(provider: provider),
  );
}

class _RestoreBackupsModal extends StatefulWidget {
  final EasyReadProvider provider;
  const _RestoreBackupsModal({required this.provider});

  @override
  State<_RestoreBackupsModal> createState() => _RestoreBackupsModalState();
}

class _SnapshotDateTime {
  final String dateText;
  final String timeText;
  final String relativeText;
  final String fullFormatted;

  const _SnapshotDateTime({
    required this.dateText,
    required this.timeText,
    required this.relativeText,
    required this.fullFormatted,
  });
}

class _RestoreBackupsModalState extends State<_RestoreBackupsModal> {
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;
  int? _restoringId;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final list = await widget.provider.fetchBackupsList();
    if (mounted) {
      setState(() {
        _backups = list;
        _isLoading = false;
      });
    }
  }

  _SnapshotDateTime _parseSnapshotDateTime(dynamic rawTime, dynamic rawTitle, int id) {
    DateTime? dt;
    if (rawTime != null) {
      try {
        dt = DateTime.parse(rawTime.toString()).toLocal();
      } catch (_) {}
    }

    const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

    if (dt != null) {
      final now = DateTime.now();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final yesterday = now.subtract(const Duration(days: 1));
      final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? "PM" : "AM";
      final minuteStr = dt.minute.toString().padLeft(2, '0');
      final timeText = "$hour12:$minuteStr $ampm";

      String dateText;
      if (isToday) {
        dateText = "Today";
      } else if (isYesterday) {
        dateText = "Yesterday";
      } else {
        dateText = "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}";
      }

      final diff = now.difference(dt);
      String relativeText = "";
      if (diff.inSeconds < 60) {
        relativeText = "Just now";
      } else if (diff.inMinutes < 60) {
        relativeText = "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24 && isToday) {
        relativeText = "${diff.inHours}h ago";
      } else if (isYesterday) {
        relativeText = "Yesterday";
      } else if (diff.inDays < 30) {
        relativeText = "${diff.inDays}d ago";
      } else {
        relativeText = "${dt.day} ${months[dt.month - 1]}";
      }

      final fullFormatted = isToday
          ? "Today at $timeText"
          : (isYesterday ? "Yesterday at $timeText" : "$dateText at $timeText");

      return _SnapshotDateTime(
        dateText: dateText,
        timeText: timeText,
        relativeText: relativeText,
        fullFormatted: fullFormatted,
      );
    }

    // Fallback if raw timestamp is missing
    final titleStr = rawTitle?.toString() ?? '';
    if (titleStr.contains('(') && titleStr.contains(')')) {
      final inside = titleStr.substring(titleStr.indexOf('(') + 1, titleStr.lastIndexOf(')')).trim();
      if (inside.contains(' at ')) {
        final parts = inside.split(' at ');
        return _SnapshotDateTime(
          dateText: parts[0].trim(),
          timeText: parts.length > 1 ? parts[1].trim() : '',
          relativeText: '',
          fullFormatted: inside,
        );
      } else if (inside.contains(', ')) {
        final parts = inside.split(', ');
        return _SnapshotDateTime(
          dateText: parts[0].trim(),
          timeText: parts.length > 1 ? parts[1].trim() : '',
          relativeText: '',
          fullFormatted: inside,
        );
      }
      return _SnapshotDateTime(
        dateText: inside,
        timeText: '',
        relativeText: '',
        fullFormatted: inside,
      );
    }

    return _SnapshotDateTime(
      dateText: "Snapshot #$id",
      timeText: '',
      relativeText: '',
      fullFormatted: "Snapshot #$id",
    );
  }

  Future<void> _handleRestore(int id, _SnapshotDateTime timeInfo, int itemCount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.moss.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.restore_rounded, color: AppColors.moss, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Restore Snapshot?",
                style: AppTypography.fraunces(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This will restore your library, imported documents, highlights, and vocabulary to this saved restore point:",
              style: AppTypography.inter(fontSize: 12.5, color: AppColors.textDark, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 15, color: AppColors.moss),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          timeInfo.timeText.isNotEmpty
                              ? "${timeInfo.dateText} · ${timeInfo.timeText}"
                              : timeInfo.dateText,
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 15, color: AppColors.textMute),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "$itemCount items (Library, Highlights, Words)",
                          style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Any progress made after this snapshot will be replaced with this snapshot state.",
              style: AppTypography.inter(fontSize: 11, color: AppColors.textMute, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              "Cancel",
              style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMute),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.moss,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              "Yes, Restore",
              style: AppTypography.inter(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _restoringId = id);
    final res = await widget.provider.restoreFromBackup(id);

    if (mounted) {
      setState(() => _restoringId = null);
      Navigator.pop(context);
      if (res['success'] == true) {
        showEasyToast(context, "Library and documents restored successfully!");
      } else {
        showEasyToast(context, res['message']?.toString() ?? "Failed to restore backup");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20, color: AppColors.moss),
                const SizedBox(width: 8),
                Text(
                  "Cloud Restore Points",
                  style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                setState(() => _isLoading = true);
                _loadBackups();
              },
              child: const Icon(Icons.refresh, size: 18, color: AppColors.textMute),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          "Select a snapshot to restore your library & reading progress",
          style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
        ),
        const SizedBox(height: 16),
        if (_isLoading) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.moss),
              ),
            ),
          ),
        ] else if (_backups.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.paperSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(Icons.cloud_off_outlined, color: AppColors.textMute, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  "No cloud backups found yet",
                  style: AppTypography.fraunces(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tap 'Back up' in your profile to create your first cloud restore point.",
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(fontSize: 11.5, color: AppColors.textMute),
                ),
              ],
            ),
          ),
        ] else ...[
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.52,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _backups.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final item = _backups[idx];
                final id = item['id'] as int;
                final createdAtRaw = item['created_at'];
                final timeInfo = _parseSnapshotDateTime(createdAtRaw, item['title'], id);
                final itemCount = item['item_count'] ?? 1;
                final isRestoringThis = _restoringId == id;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.line,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Status Icon Box
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.paperSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.line,
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.cloud_done_rounded,
                          size: 19,
                          color: AppColors.moss,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Snapshot Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Line 1: Date and Time clearly displayed in Ink
                            Row(
                              children: [
                                Text(
                                  timeInfo.dateText,
                                  style: AppTypography.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if (timeInfo.timeText.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                    child: Container(
                                      width: 3.5,
                                      height: 3.5,
                                      decoration: const BoxDecoration(
                                        color: AppColors.textMute,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeInfo.timeText,
                                    style: AppTypography.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            // Line 2: Item count & Relative time
                            Row(
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 11.5,
                                  color: AppColors.textMute,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    "$itemCount items",
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark.withValues(alpha: 0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (timeInfo.relativeText.isNotEmpty) ...[
                                  const Text(
                                    " · ",
                                    style: TextStyle(fontSize: 11, color: AppColors.textMute),
                                  ),
                                  Text(
                                    timeInfo.relativeText,
                                    style: AppTypography.inter(
                                      fontSize: 10.5,
                                      color: AppColors.textMute,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Restore Button (Creamy with Dark Ink text matching app UX)
                      isRestoringThis
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.moss),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppColors.paperSoft,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.line, width: 1.0),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => _handleRestore(id, timeInfo, itemCount),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                                    child: Text(
                                      "Restore",
                                      style: AppTypography.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

