import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/hospitals/screens/hospital_discovery_screen.dart';
import '../../theme/app_colors.dart';
import '../../shared/widgets/clinical_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, Ayesha 👋',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '24 weeks + 3 days',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPregnancyJourney() {
    return ClinicalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregnancy Journey',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Week 24',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Simplified timeline visualization
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildJourneyStep('Check', LucideIcons.checkCircle2, true),
              _buildJourneyLine(true),
              _buildJourneyStep('Diet', LucideIcons.checkCircle2, true),
              _buildJourneyLine(true),
              _buildJourneyStep(
                'Today',
                LucideIcons.arrowRightCircle,
                true,
                isActive: true,
              ),
              _buildJourneyLine(false),
              _buildJourneyStep('Scan', LucideIcons.circle, false),
              _buildJourneyLine(false),
              _buildJourneyStep('Birth', LucideIcons.circle, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStep(
    String label,
    IconData icon,
    bool isCompleted, {
    bool isActive = false,
  }) {
    Color iconColor = isActive
        ? AppColors.primary
        : (isCompleted ? AppColors.stable : AppColors.border);
    Color textColor = isActive
        ? AppColors.primary
        : (isCompleted ? AppColors.textPrimary : AppColors.textSecondary);

    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildJourneyLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        alignment: Alignment.topCenter,
        color: isCompleted ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildTodaysCare() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's care",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ClinicalCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.heartPulse,
                      color: AppColors.high,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Vitals',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check status',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ClinicalCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.apple,
                      color: AppColors.stable,
                      size: 28,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nutrition',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Today's plan",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNearbyCare(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Nearby care",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(HospitalDiscoveryScreen.path),
          child: ClinicalCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/images/onboard/empty_state.png',
                      ), // Placeholder for map
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Map Preview',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hospitals near you',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'View nearby hospitals',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                          const Icon(
                            LucideIcons.arrowRight,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEducation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pregnancy education",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ClinicalCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildEducationItem('Safe exercise', true),
              const Divider(height: 1, color: AppColors.border),
              _buildEducationItem('Nutrition this week', false),
              const Divider(height: 1, color: AppColors.border),
              _buildEducationItem('Warning signs', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEducationItem(String title, bool showArrow) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (showArrow)
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textSecondary,
              size: 20,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(),
              const SizedBox(height: 32),
              _buildPregnancyJourney(),
              const SizedBox(height: 32),
              _buildTodaysCare(),
              const SizedBox(height: 32),
              _buildNearbyCare(context),
              const SizedBox(height: 32),
              _buildEducation(),
              const SizedBox(height: 80), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
