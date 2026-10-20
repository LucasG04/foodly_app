/// What to do with the one-time tip about importing via the share sheet
/// after a dish was saved.
enum ShareTip { show, markSeen, none }

/// Users who already shared a dish into the app (source `share_…`) know the
/// share sheet, so they never get the tip.
ShareTip shareTipAfterSave({required String mealSource, required bool seen}) {
  if (seen) {
    return ShareTip.none;
  }
  return mealSource.startsWith('share') ? ShareTip.markSeen : ShareTip.show;
}
