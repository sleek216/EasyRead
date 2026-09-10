import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/bottom_sheet_wrapper.dart';
import 'upgrade_sheet.dart';

class FeatureUpgradeSheetContent extends StatelessWidget {
  final String featureKey;
  final String featureTitle;
  final String featureDescription;
  final IconData icon;

  const FeatureUpgradeSheetContent({
    super.key,
    required this.featureKey,
    required this.featureTitle,
    required this.featureDescription,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC28B38), Color(0xFFE5C07B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC28B38).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFC28B38).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFFC28B38)),
                  const SizedBox(width: 4),
                  Text(
                    "PLUS VIP FEATURE",
                    style: AppTypography.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFC28B38),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          featureTitle,
          textAlign: TextAlign.center,
          style: AppTypography.fraunces(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            featureDescription,
            textAlign: TextAlign.center,
            style: AppTypography.inter(fontSize: 13, color: AppColors.textMute, height: 1.4),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paperSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.moss, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Included in EasyRead Plus. Cancel anytime.",
                  style: AppTypography.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Reset the guard explicitly so the next sheet can open immediately
            // (the guard's whenComplete fires async, after the animation)
            resetSheetGuard();
            showEasyModalSheet(
              context: context,
              builder: (ctx) => const UpgradeSheetContent(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.moss,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(
            "View Plans & Upgrade",
            style: AppTypography.inter(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Maybe later",
            style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
          ),
        ),
      ],
    );
  }
}

void showFeatureUpgradeSheet({
  required BuildContext context,
  required String featureKey,
  required String featureTitle,
  required String featureDescription,
  required IconData icon,
}) {
  showEasyModalSheet(
    context: context,
    builder: (ctx) => FeatureUpgradeSheetContent(
      featureKey: featureKey,
      featureTitle: featureTitle,
      featureDescription: featureDescription,
      icon: icon,
    ),
  );
}
