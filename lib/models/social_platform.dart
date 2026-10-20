import 'package:flutter/widgets.dart';
import 'package:simple_icons/simple_icons.dart';

import 'meal_generation_event.dart';

/// Where a social recipe import comes from. Instagram and TikTok run the same
/// import flow and share one free quota; only these details differ. Find a
/// link's platform with `BasicUtils.socialPlatformOf`.
enum SocialPlatform {
  instagram('Instagram', SimpleIcons.instagram, MealGenerationSource.instagram),
  tiktok('TikTok', SimpleIcons.tiktok, MealGenerationSource.tiktok);

  const SocialPlatform(this.label, this.icon, this.source);

  /// The brand name, the same in every language.
  final String label;
  final IconData icon;
  final MealGenerationSource source;
}
