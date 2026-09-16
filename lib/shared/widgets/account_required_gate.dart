import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../theme/app_colors.dart';
import 'glass_button.dart';
import 'glass_surface.dart';

/// Shown whenever a guest taps something that genuinely needs an account
/// (joining a hospital, anything personalized). Never fake data, never a
/// silently-dead button — an honest "you need an account for this" state.
Future<void> showAccountRequiredGate(
  BuildContext context, {
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    // Transparent so the frosted GlassSurface below blurs the dimmed
    // barrier behind it, rather than sitting on a flat white sheet.
    backgroundColor: Colors.transparent,
    builder: (context) => _AccountRequiredSheet(message: message),
  );
}

class _AccountRequiredSheet extends StatelessWidget {
  const _AccountRequiredSheet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GlassSurface(
          borderRadius: 28,
          opacity: 0.7,
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.brandWash,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.brand,
                  size: 28,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account required',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.body, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'Create account',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AuthScreen.registerPath);
                  },
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(AuthScreen.loginPath);
                },
                child: const Text('Sign in instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
