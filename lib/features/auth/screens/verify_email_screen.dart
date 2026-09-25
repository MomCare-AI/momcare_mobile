import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_fields.dart';

/// Second half of registration — the six-digit code emailed after Sign Up.
/// Pushed from _RegisterForm, not a top-level go_router route: it's a step
/// inside the auth flow, not an independent destination.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _resendInFlight = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the code';
    if (trimmed.length != 6 || int.tryParse(trimmed) == null) {
      return 'Enter the 6-digit code';
    }
    return null;
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final succeeded = await ref
        .read(authProvider.notifier)
        .verifyEmail(code: _codeController.text.trim());
    if (!mounted) return;
    if (succeeded) {
      context.go('/home');
      return;
    }
    final message =
        ref.read(authProvider).errorMessage ??
        "That code didn't work. It may be wrong, expired, or already used.";
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resend() async {
    setState(() => _resendInFlight = true);
    final succeeded = await ref
        .read(authProvider.notifier)
        .resendVerification();
    if (!mounted) return;
    setState(() => _resendInFlight = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          succeeded
              ? 'A new code is on its way, if that address has a pending signup.'
              : (ref.read(authProvider).errorMessage ??
                    "Couldn't request a new code. Check your connection and try again."),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVerifying =
        ref.watch(authProvider.select((s) => s.status)) == AuthStatus.verifying;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: AppColors.ink,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check your email',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the 6-digit code we sent to ${widget.email}.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.body,
                    ),
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _codeController,
                    label: 'Verification code',
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    validator: _validateCode,
                  ),
                  const SizedBox(height: 16),
                  AuthPrimaryButton(
                    label: 'Verify',
                    onPressed: _verify,
                    isLoading: isVerifying,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _resendInFlight ? null : _resend,
                      child: Text(
                        _resendInFlight
                            ? 'Sending…'
                            : "Didn't get a code? Resend",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
