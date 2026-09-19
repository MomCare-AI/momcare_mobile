import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../theme/app_colors.dart';

/// What the trailing indicator communicates about what happens on tap —
/// deliberately three states, not a bool, so a row that neither navigates
/// nor leaves the app (e.g. one that opens a dialog, or one that's simply
/// not wired up to anything yet) doesn't have to fake a chevron it doesn't
/// mean.
enum SettingRowTrailing {
  /// Pushes another screen within the app.
  chevron,

  /// Leaves the app (a browser, mail client, app store, etc).
  external,

  /// Opens a dialog, or isn't a real destination at all — no promise about
  /// where tapping leads.
  none,
}

/// One row inside a settings group: icon, title, optional supporting text,
/// and a trailing indicator matching [SettingRowTrailing]. The whole row is
/// exposed to assistive tech as a single control — [Semantics] with
/// `excludeSemantics: true` drops the title/subtitle/icon's own separate
/// semantics nodes so a screen reader announces one coherent label instead
/// of several disconnected stops.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing = SettingRowTrailing.chevron,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final SettingRowTrailing trailing;
  final VoidCallback? onTap;

  /// False dims the row and drops interactivity entirely — for a row that
  /// honestly isn't wired to anything yet (e.g. no verified destination
  /// exists), rather than pretending it's tappable.
  final bool enabled;

  static const double minTapHeight = 48;

  String get _semanticLabel {
    final parts = [title, if (subtitle != null) subtitle!];
    if (trailing == SettingRowTrailing.external) {
      parts.add('opens outside the app');
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final contentColor = enabled ? AppColors.primary : AppColors.textSecondary;
    final titleColor = enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: minTapHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: contentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != SettingRowTrailing.none)
              Icon(
                trailing == SettingRowTrailing.external
                    ? LucideIcons.arrowUpRight
                    : LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );

    final tappable = enabled && onTap != null;

    return Semantics(
      button: tappable,
      label: _semanticLabel,
      excludeSemantics: true,
      onTap: tappable ? onTap : null,
      child: InkWell(
        onTap: tappable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: row,
      ),
    );
  }
}
