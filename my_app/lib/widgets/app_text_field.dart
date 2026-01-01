import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom styled text field with consistent styling
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      focusNode: focusNode,
      autofocus: autofocus,
      style: GoogleFonts.inter(fontSize: 16.sp, color: const Color(0xFF2D3748)),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: const Color(0xFF718096))
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }
}

/// Password text field with visibility toggle
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const PasswordTextField({
    super.key,
    this.controller,
    this.labelText = 'Password',
    this.hintText = 'Enter your password',
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: Icons.lock_outline,
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: const Color(0xFF718096),
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}

/// Search text field
class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: hintText,
      prefixIcon: Icons.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear, color: Color(0xFF718096)),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
    );
  }
}
