import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/auth/providers/account_profile_provider.dart';
import '../../features/medicine_reminders/providers/medicine_reminders_provider.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../theme/app_colors.dart';
import 'account_security_screen.dart';
import 'care_partner_screen.dart';
import 'data_sources_screen.dart';
import 'medicine_reminders_screen.dart';
import 'notifications_screen.dart';
import 'widgets/setting_row.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign out?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You’ll need to sign in again to continue.',
          style: GoogleFonts.inter(),
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
              'Sign Out',
              style: GoogleFonts.inter(
                color: AppColors.high,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    // Mirrors the reality of AuthScreen's own stub: login is just
    // context.go('/home') with no real session behind it, so signing out is
    // the same stub-level action in reverse — no new auth architecture.
    if (confirmed == true && context.mounted) {
      context.go(OnboardingScreen.path);
    }
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
    // Session-local only (accountProfileProvider), no backend — falls back
    // to the same neutral Phase 1 text when nothing's been entered yet.
    final profile = ref.watch(accountProfileProvider);
    final headerName = profile.fullName.isEmpty
        ? 'Your MomCare Account'
        : profile.fullName;
    // Narrow watch — only rebuilds this row when reminders are added or
    // removed, not on every toggle/edit within the list.
    final reminderCount = ref.watch(
      medicineRemindersProvider.select((reminders) => reminders.length),
    );
    // Same narrow-watch shape as reminderCount above — only rebuilds this
    // row when unread count changes, not on every notification read/delete.
    final unreadNotifications = ref.watch(
      notificationsProvider.select(
        (notifications) => notifications.where((n) => !n.isRead).length,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Profile header — not tappable. There's no persisted account
            // (AuthScreen is a frontend-only stub, see its own comments), so
            // this stays a neutral state instead of pretending to know a
            // patient's name.
            ClinicalCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      LucideIcons.user,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      headerName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Account'),
            ClinicalCard(
              child: Column(
                children: [
                  SettingRow(
                    icon: LucideIcons.shieldCheck,
                    title: 'Account & Security',
                    onTap: () => _push(context, const AccountSecurityScreen()),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  SettingRow(
                    icon: LucideIcons.bell,
                    title: 'Notifications',
                    subtitle: unreadNotifications == 0
                        ? null
                        : '$unreadNotifications unread',
                    onTap: () => _push(context, const NotificationsScreen()),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  SettingRow(
                    icon: LucideIcons.pill,
                    title: 'Medicine Reminders',
                    subtitle: reminderCount == 0
                        ? null
                        : '$reminderCount ${reminderCount == 1 ? 'reminder' : 'reminders'}',
                    onTap: () =>
                        _push(context, const MedicineRemindersScreen()),
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  SettingRow(
                    icon: LucideIcons.database,
                    title: 'Data Sources',
                    onTap: () => _push(context, const DataSourcesScreen()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // The one visually distinct MomCare-teal accent card. Built as a
            // local Material + InkWell (not ClinicalCard's own onTap, which
            // is a plain GestureDetector with no ripple) so this one card
            // gets proper press feedback without changing ClinicalCard's
            // shared behavior for every other screen that uses it.
            _AccentCard(onTap: () => _push(context, const CarePartnerScreen())),
            const SizedBox(height: 24),

            _buildSectionHeader('Support'),
            ClinicalCard(
              child: Column(
                children: [
                  // No verified support email exists anywhere in the
                  // project (checked pubspec, docs, api_config — only the
                  // momcare.solutions domain is real, no confirmed mailbox).
                  // An honest unavailable state, not a guessed address.
                  SettingRow(
                    icon: LucideIcons.mail,
                    title: 'Contact Support',
                    subtitle: 'Not set up yet',
                    trailing: SettingRowTrailing.none,
                    enabled: false,
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  // Same treatment — no real store listing exists yet, so no
                  // external-link promise and no fabricated URL.
                  SettingRow(
                    icon: LucideIcons.star,
                    title: 'Rate MomCare',
                    subtitle: 'Not set up yet',
                    trailing: SettingRowTrailing.none,
                    enabled: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ClinicalCard(
              child: SettingRow(
                icon: LucideIcons.logOut,
                title: 'Sign Out',
                // Opens a confirm dialog, not a screen — no chevron.
                trailing: SettingRowTrailing.none,
                onTap: () => _signOut(context),
              ),
            ),
            const SizedBox(height: 48),

            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/momcare_logo.png', height: 28),
                  const SizedBox(height: 12),
                  Text(
                    'MomCare',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Same visual decoration as ClinicalCard (16px radius, AppColors.border
/// outline, matching shadow), rebuilt locally on Material + InkWell so the
/// ripple actually paints — a plain Container-based onTap (what ClinicalCard
/// uses) can't show ink above an opaque background. Settings-screen-only;
/// ClinicalCard itself is untouched.
class _AccentCard extends StatelessWidget {
  const _AccentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Semantics(
            button: true,
            label:
                'Invite your care partner. Keep someone you trust connected '
                'to your pregnancy journey.',
            excludeSemantics: true,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.heartHandshake,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite your care partner',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keep someone you trust connected to your '
                        'pregnancy journey.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
