import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, outline }

enum AppButtonSize { md, lg }

/// Bouton personnalise
/// - Forme pilule (rounded-full)
/// - Variantes: primary (fond noir) et outline (bordure noire)
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool fullWidth;
  final bool isLoading;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.fullWidth = false,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    final double horizontalPadding = widget.size == AppButtonSize.lg ? 32 : 24;
    final double verticalPadding = widget.size == AppButtonSize.lg ? 12 : 10;
    final double fontSize = widget.size == AppButtonSize.lg ? 16 : 14;

    Color backgroundColor;
    Color textColor;
    BoxBorder? border;

    if (widget.variant == AppButtonVariant.primary) {
      backgroundColor = _isPressed
          ? AppColors.neutral900.withValues(alpha: 0.9)
          : AppColors.neutral900;
      textColor = Colors.white;
      border = null;
    } else {
      backgroundColor = _isPressed
          ? AppColors.neutral900.withValues(alpha: 0.05)
          : Colors.transparent;
      textColor = AppColors.neutral900;
      border = Border.all(color: AppColors.neutral900, width: 2);
    }

    if (isDisabled) {
      backgroundColor = backgroundColor.withValues(alpha: 0.5);
    }

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[widget.icon!, const SizedBox(width: 8)],
        if (widget.isLoading)
          SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        else
          Text(
            widget.text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: isDisabled ? textColor.withValues(alpha: 0.5) : textColor,
            ),
          ),
      ],
    );

    Widget button = GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(100),
          border: border,
        ),
        child: Center(child: buttonContent),
      ),
    );

    return button;
  }
}
