import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/auth/providers/account_profile_provider.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../theme/app_colors.dart';

const _confirmPhrase = 'DELETE';

/// Destructive, deliberately hard to trigger by accident: explanation →
/// typed confirmation phrase → a second confirm dialog → action. The action
/// itself only clears the local accountProfileProvider and returns to
/// onboarding (the same mechanism Sign Out already uses) — there is no
/// backend account to actually delete, and nothing here claims otherwise.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _phraseMatches = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      final matches = _confirmController.text.trim() == _confirmPhrase;
      if (matches != _phraseMatches) {
        setState(() => _phraseMatches = matches);
      }
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete your account?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This ends your current MomCare session on this device and '
          'clears the account details you’ve entered here. This can’t '
          'be undone within this preview.',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: AppColors.high,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm != true || !mounted) return;
    // Frontend-only consequence: clears local state, ends the session the
    // same way Sign Out does. No backend account exists to delete, and
    // nothing here implies one was.
    ref.read(accountProfileProvider.notifier).clear();
    if (!mounted) return;
    context.go(OnboardingScreen.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Delete Account',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClinicalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          color: AppColors.high,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a destructive action',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Deleting your account clears the name and email '
                      'you’ve entered on this device and ends your current '
                      'session. Since account sign-in is still a preview, '
                      'there’s no MomCare server record to remove — this '
                      'only affects what’s stored locally right now.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Type $_confirmPhrase to confirm',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _confirmPhrase,
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
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
                    borderSide: const BorderSide(
                      color: AppColors.high,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _DestructiveButton(
                label: 'Delete Account',
                onPressed: _phraseMatches ? _confirmAndDelete : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// PrimaryButton (shared/widgets/) requires a non-null onPressed, so it
/// can't represent a properly disabled state — using it here with a no-op
/// callback would leave the button looking fully active while silently
/// doing nothing, defeating the point of requiring the typed confirmation
/// first. Local widget, same visual language (AppColors.high, same radius/
/// padding/text style as PrimaryButton's isDestructive variant), but with a
/// real disabled state instead of touching the shared component.
class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.high,
          disabledBackgroundColor: AppColors.high.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
