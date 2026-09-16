import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_surface.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../theme/app_colors.dart';
import '../models/exercise.dart';
import '../widgets/video_placeholder.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(exercise.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
      ),
      body: GradientBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            20,
            20,
          ),
          children: [
            const VideoPlaceholder(),
            const SizedBox(height: 20),
            GlassSurface(
              borderRadius: 18,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Placeholder instructions will appear here once reviewed '
                    'content is available.',
                    style: TextStyle(color: AppColors.body, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassSurface(
              borderRadius: 14,
              tint: AppColors.moderate,
              padding: const EdgeInsets.all(14),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.moderate, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is placeholder content, not medical advice. Not '
                      'every exercise is appropriate for every pregnancy — '
                      'always check with your care provider first.',
                      style: TextStyle(color: AppColors.ink, height: 1.4),
                    ),
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
