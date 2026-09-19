import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';

/// Same "not connected yet" honesty pattern as AuthScreen's private
/// _showNotConnected (used there for Forgot Password) — replicated locally
/// since that function isn't exported, matching its exact tone rather than
/// inventing new wording.
void _showNotConnected(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'OK',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateCurrent(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your current password';
    }
    return null;
  }

  // Matches AuthScreen's registration rule (minLength: 8) — same convention,
  // not a new one.
  String? _validateNew(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm your new password';
    }
    if (value != _newController.text) {
      return 'Passwords don’t match';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // No real backend to authenticate or change a password against — this
    // never creates or stores a local password either. Same honesty as
    // AuthScreen's own forgot-password flow: nothing happened.
    _showNotConnected(
      context,
      'Password changing isn’t connected yet',
      'This will update your password once the backend supports it. No '
          'password was changed, and no request was sent.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Change Password',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PasswordField(
                  controller: _currentController,
                  label: 'Current Password',
                  obscureText: _obscureCurrent,
                  onToggleObscure: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: _validateCurrent,
                ),
                const SizedBox(height: 16),
                _PasswordField(
                  controller: _newController,
                  label: 'New Password',
                  obscureText: _obscureNew,
                  onToggleObscure: () =>
                      setState(() => _obscureNew = !_obscureNew),
                  validator: _validateNew,
                ),
                const SizedBox(height: 16),
                _PasswordField(
                  controller: _confirmController,
                  label: 'Confirm New Password',
                  obscureText: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: _validateConfirm,
                ),
                const SizedBox(height: 32),
                PrimaryButton(label: 'Change Password', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleObscure,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleObscure;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.high, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.high, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? LucideIcons.eye : LucideIcons.eyeOff,
            color: AppColors.textSecondary,
          ),
          tooltip: obscureText ? 'Show password' : 'Hide password',
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
