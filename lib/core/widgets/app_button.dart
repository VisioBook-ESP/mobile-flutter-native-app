import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, outline }

enum AppButtonSize { md, lg }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double horizontalPadding = widget.size == AppButtonSize.lg ? 32 : 24;
    final double verticalPadding = widget.size == AppButtonSize.lg ? 14 : 12;
    final double fontSize = widget.size == AppButtonSize.lg ? 16 : 14;

    Color backgroundColor;
    Color textColor;
    BoxBorder? border;

    if (widget.variant == AppButtonVariant.primary) {
      if (isDark) {
        backgroundColor = _isPressed
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.14);
        textColor = Colors.white;
        border = Border.all(color: Colors.white.withValues(alpha: 0.25));
      } else {
        backgroundColor = _isPressed
            ? AppColors.neutral900.withValues(alpha: 0.12)
            : AppColors.neutral900.withValues(alpha: 0.08);
        textColor = AppColors.neutral900;
        border = Border.all(
          color: AppColors.neutral900.withValues(alpha: 0.15),
        );
      }
    } else {
      if (isDark) {
        backgroundColor = _isPressed
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05);
        textColor = Colors.white.withValues(alpha: 0.9);
        border = Border.all(color: Colors.white.withValues(alpha: 0.2));
      } else {
        backgroundColor = _isPressed
            ? AppColors.neutral900.withValues(alpha: 0.06)
            : AppColors.neutral900.withValues(alpha: 0.03);
        textColor = AppColors.neutral900;
        border = Border.all(
          color: AppColors.neutral900.withValues(alpha: 0.12),
        );
      }
    }

    if (isDisabled) {
      backgroundColor = backgroundColor.withValues(alpha: 0.5);
      textColor = textColor.withValues(alpha: 0.4);
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
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
      ],
    );

    return GestureDetector(
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
  }
}
