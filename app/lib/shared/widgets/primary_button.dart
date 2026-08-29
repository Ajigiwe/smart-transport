import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'animated_widgets.dart';
import 'animated_loader.dart';

/// SmartTransport GH Primary Button
class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.backgroundColor,
    this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _pressAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _pressAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? AppColors.ghanaGold;
    final fg = widget.textColor ?? AppColors.primaryDark;

    return ScaleTransition(
      scale: _pressAnimation,
      child: GestureDetector(
        onTapDown: widget.onPressed != null && !widget.isLoading
            ? (_) => _pressController.forward()
            : null,
        onTapUp: widget.onPressed != null && !widget.isLoading
            ? (_) => _pressController.reverse()
            : null,
        onTapCancel: () => _pressController.reverse(),
        child: SizedBox(
          width: widget.isExpanded ? double.infinity : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              gradient: widget.backgroundColor == null
                  ? AppColors.accentGradient
                  : LinearGradient(
                      colors: [
                        bg,
                        Color.lerp(bg, Colors.white, 0.15)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: bg.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: MaterialButton(
              onPressed:
                  widget.isLoading ? null : widget.onPressed,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.buttonPaddingHorizontal,
                vertical: AppSpacing.buttonPaddingVertical,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMedium),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              child: widget.isLoading
                  ? AnimatedLoader(
                      size: 22,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 18, color: fg),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.text,
                          style: AppTypography.buttonMedium.copyWith(
                            color: fg,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

}

/// SmartTransport GH Secondary Button
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isExpanded;
  final IconData? icon;

  const SecondaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isExpanded = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onPressed,
      child: SizedBox(
        width: isExpanded ? double.infinity : null,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.ghanaGreen,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.buttonPaddingHorizontal,
              vertical: AppSpacing.buttonPaddingVertical,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMedium),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconSmall),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                text,
                style: AppTypography.buttonMedium.copyWith(
                  color: AppColors.ghanaGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// SmartTransport GH Icon Button
class IconButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  const IconButtonWidget({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onPressed,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: color ?? AppColors.textPrimary,
        iconSize: size ?? AppSpacing.iconMedium,
      ),
    );
  }
}
