import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_models.dart';
import '../providers/easy_word_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/easy_toast.dart';

class UpgradeSheetContent extends StatefulWidget {
  const UpgradeSheetContent({super.key});

  @override
  State<UpgradeSheetContent> createState() => _UpgradeSheetContentState();
}

class _UpgradeSheetContentState extends State<UpgradeSheetContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<EasyReadProvider>().fetchDynamicPlans();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EasyReadProvider>();
    final allPlans = provider.plans;
    final PlanItem freePlan = allPlans.firstWhere(
      (p) => p.id.toLowerCase() == 'free' || p.label.toLowerCase().contains('free'),
      orElse: () => PlanItem(id: 'free', label: 'Free Tier', price: 'Free', sub: 'Forever', badge: 'Starter'),
    );
    final paidPlans = allPlans.where((p) => p.id.toLowerCase() != 'free' && !p.label.toLowerCase().contains('free')).toList();

    final selectedPlan = allPlans.firstWhere(
      (p) => p.id == provider.selectedPlanId,
      orElse: () => paidPlans.isNotEmpty ? paidPlans.first : freePlan,
    );

    final isSelectedPlanFree = selectedPlan.id.toLowerCase() == 'free' || selectedPlan.label.toLowerCase().contains('free');
    final isUserCurrentlyFree = !provider.isPremium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, AppColors.goldSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "EasyRead Plus & Plans",
            textAlign: TextAlign.center,
            style: AppTypography.fraunces(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            "Unlock the full reading & learning companion.",
            textAlign: TextAlign.center,
            style: AppTypography.inter(fontSize: 12, color: AppColors.textMute),
          ),
          if (selectedPlan.features.isNotEmpty)
            ...selectedPlan.features.map((feat) => _buildFeature(feat, ""))
          else ...[
            _buildFeature(
              "Unlimited AI reading assistant",
              "Free plan includes 10 Simplify/Summarize uses — Plus removes the cap and unlocks Explain & Translate",
            ),
            _buildFeature(
              "Unlimited vocabulary",
              "Free plan saves up to 30 words — Plus removes the limit",
            ),
            _buildFeature(
              "Offline downloads",
              "Read your whole library without a connection",
            ),
            _buildFeature(
              "Cross-device sync",
              "Library, notes & progress everywhere",
            ),
          ],
          const SizedBox(height: 16),

          // 1. Official Free Tier Card (Controlled from Admin Studio)
          GestureDetector(
            onTap: () {
                provider.selectPlan(freePlan.id);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelectedPlanFree ? const Color(0x14B8873B) : Colors.white,
                  border: Border.all(
                    color: isSelectedPlanFree ? AppColors.gold : AppColors.line,
                    width: isSelectedPlanFree ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.paperSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Icons.spa_outlined, color: AppColors.moss, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                freePlan.label,
                                style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isUserCurrentlyFree ? AppColors.moss.withValues(alpha: 0.12) : AppColors.paperSoft,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: isUserCurrentlyFree ? AppColors.moss : AppColors.line),
                                ),
                                child: Text(
                                  isUserCurrentlyFree ? "CURRENT PLAN" : (freePlan.badge ?? "STARTER"),
                                  style: AppTypography.inter(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: isUserCurrentlyFree ? AppColors.moss : AppColors.textMute,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "All reading & AI features free · Words & Sync locked",
                            style: AppTypography.inter(fontSize: 9.5, color: AppColors.textMute),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          freePlan.price,
                          style: AppTypography.fraunces(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          freePlan.sub,
                          style: AppTypography.inter(fontSize: 9, color: AppColors.textMute),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.line)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "UPGRADE TO PLUS PACKAGES",
                  style: AppTypography.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMute,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.line)),
            ],
          ),
          const SizedBox(height: 12),

          // 2. Paid Plans 2x2 Grid (Monthly, 3 Months, 6 Months, Yearly)
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: paidPlans.map((p) {
              final isSel = p.id == provider.selectedPlanId;
              return GestureDetector(
                onTap: () {
                  provider.selectPlan(p.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0x14B8873B) : Colors.white,
                    border: Border.all(
                      color: isSel ? AppColors.gold : AppColors.line,
                      width: isSel ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      if (p.badge != null)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.moss,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              p.badge!,
                              style: AppTypography.inter(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.label,
                            style: AppTypography.inter(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            p.price,
                            style: AppTypography.fraunces(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            p.sub,
                            style: AppTypography.inter(fontSize: 9.5, color: AppColors.textMute),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: (isSelectedPlanFree && isUserCurrentlyFree) ? AppColors.paperSoft : AppColors.ink,
              foregroundColor: (isSelectedPlanFree && isUserCurrentlyFree) ? AppColors.textDark : AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: (isSelectedPlanFree && isUserCurrentlyFree) ? const BorderSide(color: AppColors.line) : BorderSide.none,
              ),
              elevation: 0,
            ),
            onPressed: provider.isPurchaseInProgress
                ? null
                : (isSelectedPlanFree && isUserCurrentlyFree)
                    ? () => Navigator.of(context).pop()
                    : () async {
                        final success = await provider.purchaseSelectedPlan();
                        if (context.mounted) {
                          if (success) {
                            Navigator.of(context).pop();
                            showEasyToast(context, isSelectedPlanFree ? "Switched to Free Tier" : "Welcome to EasyRead Plus — ${selectedPlan.price} plan ✦");
                          } else {
                            showEasyToast(context, "Action cancelled");
                          }
                        }
                      },
            child: provider.isPurchaseInProgress
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    (isSelectedPlanFree && isUserCurrentlyFree)
                        ? "You Are on Free Tier (Active)"
                        : isSelectedPlanFree
                            ? "Switch to Free Tier"
                            : (provider.isPremium && provider.selectedPlanId == provider.purchasedPlanId)
                                ? "Current Active Plan"
                                : provider.isPremium
                                    ? "Change Plan — ${selectedPlan.price}"
                                    : "Upgrade — ${selectedPlan.price}${selectedPlan.id == 'monthly' ? '/month' : ''}",
                    style: AppTypography.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: (isSelectedPlanFree && isUserCurrentlyFree) ? AppColors.textDark : AppColors.paper,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            "Cancel anytime via App Store / Google Play account settings",
            textAlign: TextAlign.center,
            style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute),
          ),
          const SizedBox(height: 10),

          // Store Policy Mandatory Links (Apple StoreKit & Google Play Billing)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () async {
                  showEasyToast(context, "Checking previous purchases...");
                  final restored = await provider.restorePurchases();
                  if (context.mounted) {
                    if (restored) {
                      Navigator.of(context).pop();
                      showEasyToast(context, "Purchases restored! EasyRead Plus activated ✦");
                    } else {
                      showEasyToast(context, "No active subscription found to restore.");
                    }
                  }
                },
                child: Text(
                  "Restore Purchases",
                  style: AppTypography.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.moss),
                ),
              ),
              Text("  ·  ", style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute)),
              GestureDetector(
                onTap: () => showEasyToast(context, "EasyRead Terms of Use (EULA)"),
                child: Text(
                  "Terms of Use (EULA)",
                  style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute, decoration: TextDecoration.underline),
                ),
              ),
              Text("  ·  ", style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute)),
              GestureDetector(
                onTap: () => showEasyToast(context, "EasyRead Privacy Policy"),
                child: Text(
                  "Privacy Policy",
                  style: AppTypography.inter(fontSize: 10.5, color: AppColors.textMute, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
  }

  Widget _buildFeature(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Color(0x264B6B4A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: AppColors.moss),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.inter(fontSize: 12.5, fontWeight: FontWeight.w700)),
                if (desc.isNotEmpty)
                  Text(desc, style: AppTypography.inter(fontSize: 11, color: AppColors.textMute)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
