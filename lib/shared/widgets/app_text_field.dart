import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Reusable text input field.
/// Styling inherits from AppTheme.inputDecorationTheme automatically.
/// Never put validation logic here — pass a [validator] from the parent form.
///
/// Usage:
/// ```dart
/// AppTextField(
///   controller: _nameController,
///   label: 'Shop Name',
///   hint: 'e.g. Wood Meniya',
///   validator: Validators.required,
/// )
/// // Multi-line:
/// AppTextField(
///   controller: _storyController,
///   label: 'Your Story',
///   maxLines: 4,
/// )
/// // With prefix icon:
/// AppTextField(
///   controller: _phoneController,
///   label: 'Phone',
///   prefixIcon: Icons.phone_outlined,
///   keyboardType: TextInputType.phone,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? minLines;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label above the field
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction:
              textInputAction ??
              (maxLines > 1 ? TextInputAction.newline : TextInputAction.next),
          maxLines: maxLines,
          minLines: minLines,
          obscureText: obscureText,
          enabled: enabled,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onTap: onTap,
          autofocus: autofocus,
          focusNode: focusNode,
          style: AppTextStyles.body,
          // Decoration inherits from AppTheme.inputDecorationTheme
          // Only override what differs per instance.
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
                : null,
            suffixIcon: suffixIcon,
            // Disabled style
            fillColor: enabled ? AppColors.surface : AppColors.background,
            // Let theme handle border — only set disabledBorder here
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontFamily: 'Sora',
            ),
          ),
        ),
      ],
    );
  }
}

/// Password field variant — includes show/hide toggle built in.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.focusNode,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint ?? '••••••••',
      validator: widget.validator,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      prefixIcon: Icons.lock_outline_rounded,
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
