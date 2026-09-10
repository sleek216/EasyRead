import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/easy_word_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';
import '../widgets/bottom_sheet_wrapper.dart';
import 'upgrade_sheet.dart';

class NotificationSheetContent extends StatefulWidget {
  const NotificationSheetContent({super.key});

  @override
  State<NotificationSheetContent> createState() => _NotificationSheetContentState();
}

class _NotificationSheetContentState extends State<NotificationSheetContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EasyReadProvider>().fetchNotifications(silent: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final allNotifs = provider.notificationsList;
    final unreadCount = provider.unreadNotificationCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Notifications",
                  style: AppTypography.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.moss,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$unreadCount new",
                      style: AppTypography.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (unreadCount > 0)
              TextButton(
                onPressed: () {
                  provider.markAllNotificationsRead();
                  showEasyToast(context, "Marked all as read");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Mark all read",
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.moss,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Content Area
        if (provider.isLoadingNotifications && allNotifs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.moss),
              ),
            ),
          )
        else if (allNotifs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.paperSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(Icons.notifications_none_outlined, color: AppColors.textMute, size: 22),
                ),
                const SizedBox(height: 12),
                Text(
                  "You're all caught up",
                  style: AppTypography.fraunces(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "No new notifications right now.",
                  style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
                ),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.60,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: allNotifs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final notif = allNotifs[i];
                return _buildNotificationCard(context, provider, notif);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(BuildContext context, EasyReadProvider provider, Map<String, dynamic> notif) {
    final int id = notif['id'] is int ? notif['id'] : int.tryParse(notif['id'].toString()) ?? 0;
    final String type = notif['type']?.toString() ?? 'general';
    final rawTitle = notif['title']?.toString() ?? 'Notification';
    final rawMessage = notif['message']?.toString() ?? '';
    final String timeAgo = notif['time_ago']?.toString() ?? 'Recently';
    final bool isRead = notif['is_read'] == true;
    final dynamic data = notif['data'];

    // Strip any emojis from title and message
    final emojiRegex = RegExp(r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true);
    final String title = rawTitle.replaceAll(emojiRegex, '').trim();
    final String message = rawMessage.replaceAll(emojiRegex, '').trim();

    String typeLabel = 'UPDATE';
    Color tagColor = AppColors.textMute;
    if (type == 'new_book') {
      typeLabel = 'NEW BOOK';
      tagColor = AppColors.moss;
    } else if (type == 'subscription') {
      typeLabel = 'SUBSCRIPTION';
      tagColor = const Color(0xFF4F46E5);
    } else if (type == 'announcement') {
      typeLabel = 'ANNOUNCEMENT';
      tagColor = const Color(0xFFD97706);
    } else if (type == 'suspension') {
      typeLabel = 'SECURITY';
      tagColor = const Color(0xFFDC2626);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isRead && id > 0) {
          provider.markNotificationRead(id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.paperSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.line : AppColors.moss.withValues(alpha: 0.35),
            width: isRead ? 1 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag + Time Ago + Unread dot
            Row(
              children: [
                Text(
                  typeLabel,
                  style: AppTypography.inter(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: AppTypography.inter(
                    fontSize: 10.5,
                    color: AppColors.textMute,
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.moss,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              title,
              style: AppTypography.inter(
                fontSize: 13.5,
                fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: AppTypography.inter(
                  fontSize: 12,
                  color: AppColors.textMute,
                  height: 1.4,
                ),
              ),
            ],

            // Contextual Action Button
            if (type == 'new_book' && data is Map && (data['book_title'] != null || data['book_id'] != null)) ...[
              const SizedBox(height: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (!isRead && id > 0) provider.markNotificationRead(id);
                  Navigator.pop(context);
                  final bookTitle = data['book_title']?.toString();
                  if (bookTitle != null) {
                    final book = provider.libraryItems.firstWhere(
                      (b) => b.title.trim().toLowerCase() == bookTitle.trim().toLowerCase(),
                      orElse: () => provider.libraryItems.isNotEmpty ? provider.libraryItems.first : throw 'Book not found',
                    );
                    provider.openBook(book);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.moss,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Read Book",
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
