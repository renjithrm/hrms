// lib/ui/views/today/components/today_skeleton.dart

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../constants/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../tools/ui_helpers.dart';

/// Shimmering placeholder in the Today layout, shown only on the very
/// first load, before anything is cached.
class TodaySkeleton extends StatelessWidget {
  /// Creates the skeleton.
  const TodaySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Skeletonizer.zone(
      enabled: true,
      effect: AppMotion.of(context).canLoop
          ? const ShimmerEffect()
          : const SolidColorEffect(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Palette.deep,
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 24),
            child: const Row(
              children: [
                Bone.circle(size: 40),
                Gap.h12,
                Expanded(child: Bone.text(words: 2)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(words: 3),
                Gap.v12,
                Bone(height: 60, uniRadius: 12),
                Gap.v24,
                Bone.text(words: 2),
                Gap.v12,
                Bone(height: 44, uniRadius: 12),
                Gap.v24,
                Bone.text(words: 1),
                Gap.v12,
                Bone(height: 40, uniRadius: 10),
                Gap.v8,
                Bone(height: 40, uniRadius: 10),
                Gap.v8,
                Bone(height: 40, uniRadius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
