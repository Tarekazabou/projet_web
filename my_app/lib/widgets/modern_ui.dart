import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_theme.dart';

/// Modern glass-morphism card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.boxShadow,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? EdgeInsets.zero,
        padding: padding ?? EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.radiusMd),
          border: border ?? Border.all(color: Colors.grey.shade100),
          boxShadow: boxShadow ?? AppTheme.cardShadow,
        ),
        child: child,
      ),
    );
  }
}

/// Animated gradient card with hover effect
class GradientCard extends StatefulWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? borderRadius;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  State<GradientCard> createState() => _GradientCardState();
}

class _GradientCardState extends State<GradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: widget.margin ?? EdgeInsets.zero,
              padding: widget.padding ?? EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: widget.gradient,
                borderRadius:
                    BorderRadius.circular(widget.borderRadius ?? AppTheme.radiusLg),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Modern stat card with icon
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24.r),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern circular progress indicator
class CircularProgressCard extends StatelessWidget {
  final double progress;
  final String label;
  final String value;
  final Color color;
  final double size;

  const CircularProgressCard({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
    required this.color,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size.w,
          height: size.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size.w,
                height: size.w,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 6.w,
                  backgroundColor: color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Modern icon button with background
class ModernIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;

  const ModernIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.backgroundColor,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.textSecondary,
          size: size ?? 22.r,
        ),
      ),
    );
  }
}

/// Modern section header
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? emoji;
  final String? actionText;
  final VoidCallback? onActionTap;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.emoji,
    this.actionText,
    this.onActionTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (emoji != null) ...[
                      SizedBox(width: 8.w),
                      Text(
                        emoji!,
                        style: TextStyle(fontSize: 18.sp),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Row(
                children: [
                  Text(
                    actionText!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14.r,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Modern chip/tag
class ModernChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback? onTap;

  const ModernChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(
            color: isSelected ? chipColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16.r,
                color: isSelected ? Colors.white : chipColor,
              ),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class ModernEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onActionTap;

  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.description,
    this.actionText,
    this.onAction,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final desc = description ?? subtitle;
    final action = onAction ?? onActionTap;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48.r,
                color: AppTheme.primary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (desc != null) ...[
              SizedBox(height: 8.h),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppTheme.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading effect
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(widget.borderRadius ?? AppTheme.radiusSm),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
