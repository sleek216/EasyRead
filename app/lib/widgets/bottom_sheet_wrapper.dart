import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Global guard: prevents opening multiple sheets simultaneously from rapid taps.
bool _sheetOpen = false;

/// Call this before opening a new sheet right after closing another one.
/// This resets the guard so the next sheet can open immediately.
void resetSheetGuard() {
  _sheetOpen = false;
}

void showEasyModalSheet({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool force = false, // bypass guard — use when chaining sheets (pop then open)
}) {
  // Block if a sheet is already open — prevents double/triple sheet stacking from rapid taps
  if (_sheetOpen && !force) return;
  _sheetOpen = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x660C120E),
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.88;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.paperSoft,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 30,
                offset: Offset(0, -10),
              )
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 12,
            left: 22,
            right: 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 28),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Icon(Icons.close, size: 14, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: builder(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    // Reset guard once sheet is fully dismissed
    _sheetOpen = false;
  });
}

