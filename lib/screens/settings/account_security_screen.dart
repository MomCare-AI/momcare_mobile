import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/auth/providers/account_profile_provider.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../theme/app_colors.dart';
import 'change_password_screen.dart';
import 'delete_account_screen.dart';
import 'edit_account_screen.dart';
import 'widgets/setting_row.dart';

/// Real content now that accountProfileProvider exists — Full Name and
/// Email are genuinely session-local, in-memory values (see the provider's
/// own doc comment), not backend-synchronized. Change Password and Delete
/// Account are complete frontend flows with honest "not connected yet"
/// outcomes, matching AuthScreen's own established pattern.
class AccountSecurityScreen extends ConsumerWidget {
  const AccountSecurityScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(accountProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Account & Security',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('Account Information'),
            ClinicalCard(
              child: Column(
                children: [
                  SettingRow(
                    icon: LucideIcons.user,
                    title: 'Full Name',
                    subtitle: profile.fullName.isEmpty
                        ? 'Not set'
                        : profile.fullName,
                    onTap: () => _push(context, const EditAccountScreen()),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  SettingRow(
                    icon: LucideIcons.mail,
                    title: 'Email',
                    subtitle: profile.email.isEmpty ? 'Not set' : profile.email,
                    onTap: () => _push(context, const EditAccountScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Security'),
            ClinicalCard(
              child: SettingRow(
                icon: LucideIcons.lock,
                title: 'Change Password',
                onTap: () => _push(context, const ChangePasswordScreen()),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Danger Zone'),
            ClinicalCard(
              child: _DangerRow(
                onTap: () => _push(context, const DeleteAccountScreen()),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// SettingRow has no destructive/red variant (Phase 1 scope didn't need
/// one), and it isn't in this phase's approved file list to extend — a
/// local row, same shape and accessibility pattern (merged semantics, 48px
/// target), but red-tinted for the one genuinely destructive entry point.
class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(LucideIcons.trash2, size: 22, color: AppColors.high),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Delete Account',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.high,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.high.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      label: 'Delete Account, destructive action',
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: row,
      ),
    );
  }
}
