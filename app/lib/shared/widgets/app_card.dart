import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// SmartTransport GH Premium Card Widget
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final double? elevation;
  final bool showBorder;
  final bool isGlass;
  final Gradient? borderGradient;

  const AppCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.showBorder = false,
    this.isGlass = false,
    this.borderGradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin ?? const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPaddingHorizontal,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isGlass ? AppColors.glassSurface : AppColors.surface),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: showBorder
            ? Border.all(color: AppColors.border, width: 1)
            : (isGlass ? Border.all(color: AppColors.glassBorder, width: 1.5) : null),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: elevation ?? AppSpacing.elevationSmall,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          if (elevation != null && elevation! > 4)
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: elevation! * 2,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
          child: child,
        ),
      ),
    );

    final finalWidget = isGlass
        ? ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: cardContent,
            ),
          )
        : cardContent;

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: finalWidget,
      );
    }

    return finalWidget;
  }
}

/// SmartTransport GH Premium Stat Card
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? trend;
  final bool isPositiveTrend;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.trend,
    this.isPositiveTrend = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.ghanaGold;

    return AppCard(
      backgroundColor: backgroundColor ?? AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: effectiveIconColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
                  size: AppSpacing.iconMedium,
                ),
              ),
              if (trend != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: (isPositiveTrend ? AppColors.success : AppColors.error).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositiveTrend ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 12,
                          color: isPositiveTrend ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            trend!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSmall.copyWith(
                              color: isPositiveTrend ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),

        ],
      ),
    );
  }
}

/// SmartTransport GH List Tile Card
class ListTileCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const ListTileCard({
    Key? key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.leadingIconColor,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = leadingIconColor ?? AppColors.ghanaGold;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: effectiveIconColor.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                leadingIcon,
                color: effectiveIconColor,
                size: AppSpacing.iconMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

