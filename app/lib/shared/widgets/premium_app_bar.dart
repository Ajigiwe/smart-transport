import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Dark premium AppBar with gradient background
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? bottom;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + (bottom != null ? 56.0 : 0.0));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: AppTypography.h3.copyWith(
            color: AppColors.textInverse,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textInverse,
                  size: 20,
                ),
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              )
            : null,
        actions: actions?.map((action) {
          if (action is IconButton) {
            return IconButton(
              icon: action.icon,
              onPressed: action.onPressed,
              style: IconButton.styleFrom(
                foregroundColor: AppColors.textInverse,
              ),
            );
          }
          return action;
        }).toList(),
        bottom: bottom != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: bottom!,
              )
            : null,
      ),
    );
  }
}
