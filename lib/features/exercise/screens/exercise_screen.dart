import 'package:flutter/material.dart';

import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/topic_card.dart';
import '../../../theme/app_colors.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  static const path = '/guest/exercise';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Exercise'),
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
            const Text(
              'Placeholder content — not medical guidance yet.',
              style: TextStyle(color: AppColors.faint, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final exercise in sampleExercises)
              TopicCard(
                title: exercise.title,
                // Feature-internal detail screen — plain Navigator.push, not
                // a separate top-level go_router route.
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailScreen(exercise: exercise),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
