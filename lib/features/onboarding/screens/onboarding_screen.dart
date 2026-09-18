import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/screens/auth_screen.dart';
import '../../guest/screens/guest_home_screen.dart';
import '../widgets/auto_scrolling_row.dart';
import '../widgets/dashed_tag.dart';
import '../../../shared/widgets/particle_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const path = '/onboarding';

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // Top Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                "Let's make",
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              Text(
                                "your days",
                                style: GoogleFonts.playfairDisplay(
                                  color: Colors.pink, // Pink italic text as requested
                                  fontSize: 52,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                  height: 1.1,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              Text(
                                "healthier",
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w700,
                                  height: 1.0,
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "No Rushing. Only your feelings.",
                                style: GoogleFonts.inter(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Middle Section (Auto-Scrolling Tags)
                        Column(
                          children: [
                            const AutoScrollingRow(
                              scrollLeft: true,
                              speed: 30.0,
                              children: [
                                DashedTag(label: 'Habits', backgroundColor: Color(0xFFD0E9F9)),
                                DashedTag(label: '🍏', isEmoji: true),
                                DashedTag(label: 'Track meals mindfully'),
                                DashedTag(label: 'Rest', isEmoji: false),
                                DashedTag(label: '💧', isEmoji: true),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const AutoScrollingRow(
                              scrollLeft: false, // Scrolls right
                              speed: 25.0,
                              children: [
                                DashedTag(label: 'Build healthy habits'),
                                DashedTag(label: '🥦', isEmoji: true),
                                DashedTag(label: 'Support', backgroundColor: Color(0xFFD0E9F9)),
                                DashedTag(label: '🧘‍♀️', isEmoji: true),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const AutoScrollingRow(
                              scrollLeft: true,
                              speed: 35.0,
                              children: [
                                DashedTag(label: 'Nutrition', backgroundColor: Color(0xFFD0E9F9)),
                                DashedTag(label: '🥗', isEmoji: true),
                                DashedTag(label: 'Increase meals nutrition'),
                                DashedTag(label: '🥑', isEmoji: true),
                              ],
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Bottom Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 64,
                                child: ParticleButton(
                                  onPressed: () => context.go(AuthScreen.registerPath),
                                  animationDuration: const Duration(milliseconds: 800),
                                  particleColor: Colors.pink,
                                  particleCount: 60,
                                  child: ElevatedButton(
                                    onPressed: null, // Disabled so ParticleButton handles the tap
                                    style: ButtonStyle(
                                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                                        return Colors.black; // The outer detector handles tap visual changes if needed, but we just disintegrate
                                      }),
                                      foregroundColor: WidgetStateProperty.all(Colors.white),
                                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                      ),
                                      elevation: WidgetStateProperty.all(0),
                                    ),
                                    child: Text(
                                      'Get Started',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => context.go(AuthScreen.loginPath),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  'I Already Have an Account',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go(GuestHomeScreen.path),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black54,
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Try as Guest',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
