import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'glass_surface.dart';

/// A plain titled card, reused as-is across nutrition/exercise/pregnancy
/// education list screens — genuinely identical in all three, not
/// speculative reuse.
class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassSurface(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: onTap != null
              ? const Icon(Icons.chevron_right, color: AppColors.faint)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}
