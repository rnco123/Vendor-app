import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';

const Color kVendorAmber = Color(0xFFF7B500);

PreferredSizeWidget vendorSetupAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppColors.background,
    surfaceTintColor: AppColors.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleSpacing: 0,
    automaticallyImplyLeading: false,
    shape: const Border(
      bottom: BorderSide(color: AppColors.divider, width: 1),
    ),
    leading: IconButton(
      onPressed: () => Navigator.maybePop(context),
      icon: Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.cardBackground,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.textPrimary,
          size: 10,
        ),
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class VendorSetupHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const VendorSetupHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class VendorLabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const VendorLabeledField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          cursorColor: AppColors.primary,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: vendorInputDecoration(hint),
          validator: validator ??
              (v) => (v == null || v.trim().isEmpty)
                  ? 'This field is required'
                  : null,
        ),
      ],
    );
  }
}

InputDecoration vendorInputDecoration(String hint) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    filled: true,
    fillColor: AppColors.inputBackground,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    border: border(AppColors.divider),
    enabledBorder: border(AppColors.divider),
    focusedBorder: border(AppColors.primary, 1.5),
    errorBorder: border(AppColors.error),
    focusedErrorBorder: border(AppColors.error, 1.5),
    errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
  );
}

class VendorPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color color;
  final Color textColor;

  const VendorPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.color = AppColors.primary,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withAlpha(153),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

void showVendorSnack(BuildContext context, String message,
    {bool success = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
