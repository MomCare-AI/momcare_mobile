import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';
import 'home/home_screen.dart';
import '../features/vitals/screens/vitals_screen.dart';
import 'food_scan/food_scan_screen.dart';
import 'chat/chat_screen.dart';
import 'settings/settings_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  static const path = '/home';

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const VitalsScreen(),
    const ChatScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const FoodScanScreen(),
                fullscreenDialog: true,
              ),
            );
          },
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 4),
          ),
          child: const Icon(LucideIcons.plus, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const labels = ['Home', 'Vitals', 'Chat', 'Settings'];

  static const icons = [
    LucideIcons.home,
    LucideIcons.heartPulse,
    LucideIcons.messageCircle,
    LucideIcons.settings,
  ];

  Widget _buildTabItem(int index) {
    final isSelected = index == selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icons[index],
                color: isSelected ? AppColors.primary : Colors.black26,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.black26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 20,
      shadowColor: Colors.black26,
      shape: const CircularNotchedRectangle(),
      notchMargin: 12,
      child: SizedBox(
        height: 70, // Tall enough for icon + text
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTabItem(0),
            _buildTabItem(1),
            const Expanded(child: SizedBox()), // Empty space for FAB
            _buildTabItem(2),
            _buildTabItem(3),
          ],
        ),
      ),
    );
  }
}
