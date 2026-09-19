import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/care_partner/providers/care_partner_provider.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';

/// A complete frontend preview of inviting a care partner — real local
/// invitation-code generation, real clipboard copy, real confirm-before-
/// cancel flow. What it deliberately isn't: a second account. There's no
/// real invitee anywhere, so nothing here shows delivery status, acceptance,
/// "last seen," or any other state implying someone received or acted on
/// this — only what this device's own local state actually is.
class CarePartnerScreen extends ConsumerWidget {
  const CarePartnerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(carePartnerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Care Partner',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: state.hasActiveInvitation
              ? _InvitationReady(code: state.invitationCode!)
              : const _EmptyState(),
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.heartHandshake, size: 40, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Invite a care partner',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'A care partner is someone you trust — a partner, a family '
          'member, or anyone close to you — who can support you '
          'through your pregnancy journey.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Invite care partner',
          onPressed: () =>
              ref.read(carePartnerProvider.notifier).createInvitation(),
        ),
      ],
    );
  }
}

class _InvitationReady extends ConsumerWidget {
  const _InvitationReady({required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invitation copied')));
  }

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel invitation?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This invitation code will no longer work. You can create a new '
          'one anytime.',
          style: GoogleFonts.inter(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Keep it',
              style: GoogleFonts.inter(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Cancel invitation',
              style: GoogleFonts.inter(
                color: AppColors.high,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    ref.read(carePartnerProvider.notifier).cancelInvitation();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitation removed from this preview.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.checkCircle2, size: 40, color: AppColors.primary),
        const SizedBox(height: 16),
        Text(
          'Invitation ready',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Share this code with the person you’d like to invite. This '
          'invitation is only stored on this device for this preview — '
          'it hasn’t been sent to MomCare’s servers.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          label: 'Invitation code $code',
          child: ClinicalCard(
            child: Center(
              child: Text(
                code,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Copy invitation',
          onPressed: () => _copy(context),
        ),
        const SizedBox(height: 24),
        Center(
          child: Semantics(
            button: true,
            label: 'Cancel invitation, destructive action',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => _confirmCancel(context, ref),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(
                  'Cancel invitation',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.high,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
