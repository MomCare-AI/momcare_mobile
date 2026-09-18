import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF7F7F9,
      ), // Light background matching the image
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F9),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 32,
                          backgroundImage: AssetImage(
                            'assets/images/onboard/empty_state.png',
                          ), // Placeholder
                          backgroundColor: Colors.black12,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'John Smith',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Edit Profile',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.chevronRight,
                                  size: 14,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Account Settings
                    _buildSettingsItem(
                      icon: LucideIcons.userCog,
                      title: 'Account Settings',
                      showChevron: true,
                    ),
                    const SizedBox(height: 32),

                    // Preferences Section
                    _buildSectionHeader('Preferences'),
                    _buildSettingsItem(
                      icon: LucideIcons.bell,
                      title: 'Notifications',
                      showChevron: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      icon: LucideIcons.palette,
                      title: 'Appearance',
                      showChevron: true,
                    ),
                    const SizedBox(height: 32),

                    // Resources Section
                    _buildSectionHeader('Resources'),
                    _buildSettingsItem(
                      icon: LucideIcons
                          .mail, // using mail as approximation for mailbox
                      title: 'Contact Support',
                      showArrowUpRight: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      icon: LucideIcons.star,
                      title: 'Rate in App Store',
                      showArrowUpRight: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      icon: LucideIcons.twitter,
                      title: 'Follow @MomCare',
                      showArrowUpRight: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsItem(
                      icon: LucideIcons.database,
                      title: 'Data Sources',
                      showChevron: true,
                    ),
                    const SizedBox(height: 32),

                    // Sign Out
                    _buildSettingsItem(
                      icon: LucideIcons.logOut,
                      title: 'Sign Out',
                      showChevron: false,
                    ),

                    const SizedBox(height: 64),

                    // Footer
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'momcare',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black26,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                LucideIcons.sparkles,
                                size: 16,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Version 2.0.3 (571)',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Terms & Privacy',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    bool showChevron = false,
    bool showArrowUpRight = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Colors.black45),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
        if (showChevron)
          const Icon(LucideIcons.chevronRight, size: 20, color: Colors.black26),
        if (showArrowUpRight)
          const Icon(LucideIcons.arrowUpRight, size: 20, color: Colors.black26),
      ],
    );
  }
}
