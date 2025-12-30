import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Primary button with loading state
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor ?? Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20.r),
                  SizedBox(width: 8.w),
                ],
                Text(text),
              ],
            ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Secondary outlined button
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final Color? borderColor;
  final Color? foregroundColor;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.borderColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = borderColor ?? Theme.of(context).colorScheme.primary;

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor ?? color,
        side: BorderSide(color: color, width: 2),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20.h,
              width: 20.w,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20.r),
                  SizedBox(width: 8.w),
                ],
                Text(text),
              ],
            ),
    );

    if (isExpanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Icon button with optional label
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.backgroundColor,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
              size: size ?? 24.r,
            ),
            if (label != null) ...[
              SizedBox(height: 4.h),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Floating action button with extended label
class AppFloatingButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AppFloatingButton({
    super.key,
    required this.icon,
    this.label,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        icon: Icon(icon),
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      child: Icon(icon),
    );
  }
}
