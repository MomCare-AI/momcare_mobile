import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/vitals/models/vital_reading.dart';
import '../../features/vitals/providers/vitals_provider.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../theme/app_colors.dart';

/// Reads real VitalSource data from the existing vitalsProvider — device vs.
/// manual counts are genuine, not invented. Carries the same sample-data
/// disclosure as VitalsScreen (VitalsRepository returns sample data until a
/// real patient-facing endpoint exists), since this screen surfaces the same
/// underlying data and shouldn't imply it's more real than it is.
class DataSourcesScreen extends ConsumerWidget {
  const DataSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readings = ref.watch(
      vitalsProvider.select((state) => state.readings),
    );
    final deviceCount = readings
        .where((r) => r.source == VitalSource.device)
        .length;
    final manualCount = readings
        .where((r) => r.source == VitalSource.manual)
        .length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Data Sources',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.moderate.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Sample data — not yet connected',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.moderate,
                ),
              ),
            ),
            ClinicalCard(
              child: Column(
                children: [
                  _SourceRow(
                    icon: LucideIcons.smartphone,
                    title: 'Device readings',
                    count: deviceCount,
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  _SourceRow(
                    icon: LucideIcons.pencil,
                    title: 'Manually entered',
                    count: manualCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '$count reading${count == 1 ? '' : 's'}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
