import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.prefixIcon,
    this.prefixFixedText,
    this.focusNode,
    this.onFieldSubmitted,
    this.onChanged,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.inputFormatters,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputAction textInputAction;
  final Widget? prefixIcon;
  final String? prefixFixedText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool enableSuggestions;
  final bool autocorrect;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    _bindFocusNode(widget.focusNode);
  }

  @override
  void didUpdateWidget(covariant AuthTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _unbindFocusNode(oldWidget.focusNode);
      _bindFocusNode(widget.focusNode);
    }
  }

  @override
  void dispose() {
    _unbindFocusNode(widget.focusNode);
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) {
      return;
    }
    setState(() => _isFocused = widget.focusNode?.hasFocus ?? false);
  }

  void _bindFocusNode(FocusNode? node) {
    node?.addListener(_handleFocusChange);
    _isFocused = node?.hasFocus ?? false;
  }

  void _unbindFocusNode(FocusNode? node) {
    node?.removeListener(_handleFocusChange);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: _isFocused ? AppColors.primaryDark : AppColors.textPrimary,
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          enableSuggestions: widget.enableSuggestions,
          autocorrect: widget.autocorrect,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          scrollPadding: const EdgeInsets.only(bottom: 120),
          cursorColor: AppColors.primaryDark,
          style: const TextStyle(fontSize: 17, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: widget.hintText,
            fillColor: _isFocused ? Colors.white : AppColors.inputFill,
            prefixIcon: widget.prefixFixedText != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 18, right: 8),
                    child: Text(
                      widget.prefixFixedText!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  )
                : widget.prefixIcon,
            prefixIconConstraints:
                widget.prefixFixedText != null ? const BoxConstraints(minWidth: 0, minHeight: 0) : null,
            counterText: widget.maxLength != null ? '' : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    splashRadius: 20,
                    icon: Icon(
                      _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
