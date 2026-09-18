import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/primary_button.dart';

class FoodScanScreen extends StatefulWidget {
  const FoodScanScreen({super.key});

  @override
  State<FoodScanScreen> createState() => _FoodScanScreenState();
}

class _FoodScanScreenState extends State<FoodScanScreen> {
  int _step = 0; // 0: Camera, 1: Processing, 2: Results

  void _capturePhoto() {
    setState(() => _step = 1);

    // Simulate AI processing steps
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _step = 2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _step == 0 ? Colors.black : AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildCameraView();
      case 1:
        return _buildProcessingView();
      case 2:
        return _buildResultsView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Fake Camera Viewfinder
        Positioned.fill(
          child: Container(
            color: Colors.black,
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    'FOOD AREA',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Close Button
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: const Icon(LucideIcons.x, color: Colors.white, size: 32),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        // Instructions
        Positioned(
          bottom: 140,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Center your meal',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        // Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Gallery',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                ),
              ),
              GestureDetector(
                onTap: _capturePhoto,
                child: Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Capture',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analyzing your meal',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            _buildChecklistItem('Detecting food', true),
            const SizedBox(height: 16),
            _buildChecklistItem('Identifying portions', true),
            const SizedBox(height: 16),
            _buildChecklistItem('Estimating nutrition', false),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String label, bool isComplete) {
    return Row(
      children: [
        Icon(
          isComplete ? LucideIcons.checkCircle2 : LucideIcons.circle,
          color: isComplete ? AppColors.stable : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: isComplete ? FontWeight.w600 : FontWeight.w500,
            color: isComplete ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimated nutrition',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClinicalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your meal',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text('🍚 Rice', style: GoogleFonts.inter(fontSize: 15)),
                const SizedBox(height: 4),
                Text('🥗 Salad', style: GoogleFonts.inter(fontSize: 15)),
                const SizedBox(height: 4),
                Text('🍗 Chicken', style: GoogleFonts.inter(fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ClinicalCard(
            child: Column(
              children: [
                _buildNutritionRow('Calories', '540 kcal', isHighlight: true),
                const Divider(height: 32, color: AppColors.border),
                _buildNutritionRow('Protein', '31 g'),
                const SizedBox(height: 12),
                _buildNutritionRow('Carbohydrates', '64 g'),
                const SizedBox(height: 12),
                _buildNutritionRow('Fat', '18 g'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI-generated estimate. Actual values may vary depending on ingredients and portion size.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.primary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Save to Diary',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isHighlight ? 16 : 15,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
            color: isHighlight
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isHighlight ? 16 : 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
