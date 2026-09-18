import 'package:flutter/material.dart';

import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/topic_card.dart';
import '../../../theme/app_colors.dart';
import '../models/education_topic.dart';

class PregnancyEducationScreen extends StatelessWidget {
  const PregnancyEducationScreen({super.key});

  static const path = '/guest/education';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pregnancy Education'),
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
            for (final topic in sampleEducationTopics)
              TopicCard(title: topic.title),
          ],
        ),
      ),
    );
  }
}
