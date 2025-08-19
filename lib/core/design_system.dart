import 'package:flutter/material.dart';

/// Design System for Tulai ALS Enrollment System
/// This file contains reusable design tokens, components, and styling utilities
/// to maintain consistency across the application.

class TulaiColors {
  // Primary colors from your theme
  static const Color primary = Color(0xff0C15A6);
  static const Color secondary = Color(0xff40AD5F);
  static const Color accent = Color.fromARGB(255, 5, 175, 53);

  // Neutral colors
  static const Color textPrimary = Color(0xff2D3748);
  static const Color textSecondary = Color(0xff4A5568);
  static const Color textMuted = Color(0xff718096);

  // Background colors
  static const Color backgroundPrimary = Colors.white;
  static const Color backgroundSecondary = Color(0xffF7FAFC);
  static const Color backgroundMuted = Color(0xffEDF2F7);

  // Status colors
  static const Color success = Color(0xff48BB78);
  static const Color warning = Color(0xffED8936);
  static const Color error = Color(0xffF56565);
  static const Color info = Color(0xff4299E1);

  // Border colors
  static const Color borderLight = Color(0xffE2E8F0);
  static const Color borderMedium = Color(0xffCBD5E0);
  static const Color borderDark = Color(0xffA0AEC0);
}

class TulaiSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class TulaiBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double round = 28.0;
}

class TulaiTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: TulaiColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: TulaiColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: TulaiColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: TulaiColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: TulaiColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: TulaiColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: TulaiColors.textMuted,
    height: 1.3,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: TulaiColors.textPrimary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: TulaiColors.textSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: TulaiColors.textMuted,
  );
}

class TulaiShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}

/// Reusable UI Components
class TulaiCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final BorderRadius? borderRadius;

  const TulaiCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.boxShadow,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? TulaiColors.backgroundPrimary,
        borderRadius:
            borderRadius ?? BorderRadius.circular(TulaiBorderRadius.lg),
        boxShadow: boxShadow ?? TulaiShadows.md,
        border: Border.all(
          color: TulaiColors.borderLight,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius:
                    borderRadius ?? BorderRadius.circular(TulaiBorderRadius.lg),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(TulaiSpacing.lg),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(TulaiSpacing.lg),
                child: child,
              ),
      ),
    );
  }
}

class TulaiButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TulaiButtonStyle style;
  final TulaiButtonSize size;
  final Widget? icon;
  final bool isLoading;

  const TulaiButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style = TulaiButtonStyle.primary,
    this.size = TulaiButtonSize.medium,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(style);
    final buttonSize = _getButtonSize(size);

    return SizedBox(
      height: buttonSize.height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonStyle.backgroundColor,
          foregroundColor: buttonStyle.textColor,
          elevation: buttonStyle.elevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonSize.borderRadius),
            side: buttonStyle.borderSide ?? BorderSide.none,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: buttonSize.horizontalPadding,
            vertical: buttonSize.verticalPadding,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(buttonStyle.textColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: TulaiSpacing.sm),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: buttonSize.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  _ButtonStyleData _getButtonStyle(TulaiButtonStyle style) {
    switch (style) {
      case TulaiButtonStyle.primary:
        return _ButtonStyleData(
          backgroundColor: TulaiColors.primary,
          textColor: Colors.white,
          elevation: 2,
        );
      case TulaiButtonStyle.secondary:
        return _ButtonStyleData(
          backgroundColor: TulaiColors.secondary,
          textColor: Colors.white,
          elevation: 2,
        );
      case TulaiButtonStyle.outline:
        return _ButtonStyleData(
          backgroundColor: Colors.transparent,
          textColor: TulaiColors.primary,
          elevation: 0,
          borderSide: const BorderSide(color: TulaiColors.primary, width: 2),
        );
      case TulaiButtonStyle.ghost:
        return _ButtonStyleData(
          backgroundColor: Colors.transparent,
          textColor: TulaiColors.primary,
          elevation: 0,
        );
    }
  }

  _ButtonSizeData _getButtonSize(TulaiButtonSize size) {
    switch (size) {
      case TulaiButtonSize.small:
        return _ButtonSizeData(
          height: 36,
          fontSize: 14,
          horizontalPadding: 16,
          verticalPadding: 8,
          borderRadius: TulaiBorderRadius.sm,
        );
      case TulaiButtonSize.medium:
        return _ButtonSizeData(
          height: 44,
          fontSize: 16,
          horizontalPadding: 20,
          verticalPadding: 12,
          borderRadius: TulaiBorderRadius.md,
        );
      case TulaiButtonSize.large:
        return _ButtonSizeData(
          height: 52,
          fontSize: 18,
          horizontalPadding: 24,
          verticalPadding: 16,
          borderRadius: TulaiBorderRadius.md,
        );
    }
  }
}

enum TulaiButtonStyle { primary, secondary, outline, ghost }

enum TulaiButtonSize { small, medium, large }

class _ButtonStyleData {
  final Color backgroundColor;
  final Color textColor;
  final double elevation;
  final BorderSide? borderSide;

  _ButtonStyleData({
    required this.backgroundColor,
    required this.textColor,
    required this.elevation,
    this.borderSide,
  });
}

class _ButtonSizeData {
  final double height;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  _ButtonSizeData({
    required this.height,
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
  });
}

class TulaiTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final int? maxLines;

  const TulaiTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: TulaiTextStyles.labelMedium),
          const SizedBox(height: TulaiSpacing.sm),
        ],
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TulaiBorderRadius.md),
            border: Border.all(
              color: errorText != null
                  ? TulaiColors.error
                  : TulaiColors.borderMedium,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TulaiTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TulaiTextStyles.bodyMedium.copyWith(
                color: TulaiColors.textMuted,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TulaiSpacing.md,
                vertical: TulaiSpacing.md,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: TulaiSpacing.xs),
          Text(
            errorText!,
            style: TulaiTextStyles.caption.copyWith(
              color: TulaiColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Utility classes for responsive design
class TulaiBreakpoints {
  static const double mobile = 640;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double widescreen = 1280;
}

class TulaiResponsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < TulaiBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= TulaiBreakpoints.tablet &&
      MediaQuery.of(context).size.width < TulaiBreakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= TulaiBreakpoints.desktop;

  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= TulaiBreakpoints.tablet;

  static T responsive<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
}
