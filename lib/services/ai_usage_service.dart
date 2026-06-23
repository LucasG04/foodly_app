import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/ai_usage.dart';
import '../utils/ai_usage_period.dart';

/// Tracks free-plan AI usage in a dedicated `ai_usage/{userId}` document.
///
/// The weekly window is identified by [AiUsagePeriod.currentPeriodKey]; when the
/// stored `periodKey` no longer matches the current one the counts reset by
/// construction — no scheduler or mutate-on-read needed.
class AiUsageService {
  AiUsageService._();

  static final _log = Logger('AiUsageService');
  static final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('aiUsage');

  /// Live usage for [userId], normalized to the current window.
  static Stream<AiUsage> streamUsage(String userId) {
    return _collection.doc(userId).snapshots().map(
          (snap) => AiUsage.fromDoc(
            snap.data(),
            currentPeriodKey: AiUsagePeriod.currentPeriodKey(),
          ),
        );
  }

  static Future<void> incrementKcal(String userId) =>
      _increment(userId, 'kcalUsed');

  static Future<void> incrementText(String userId) =>
      _increment(userId, 'textUsed');

  static Future<void> incrementInstagram(String userId) =>
      _increment(userId, 'instagramUsed');

  static Future<void> _increment(String userId, String field) async {
    final docRef = _collection.doc(userId);
    final periodKey = AiUsagePeriod.currentPeriodKey();
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists || snap.data()?['periodKey'] != periodKey) {
          tx.set(docRef, <String, dynamic>{
            'periodKey': periodKey,
            'kcalUsed': field == 'kcalUsed' ? 1 : 0,
            'textUsed': field == 'textUsed' ? 1 : 0,
            'instagramUsed': field == 'instagramUsed' ? 1 : 0,
          });
        } else {
          tx.update(docRef, <String, dynamic>{
            field: FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      _log.severe('ERR in _increment for field $field', e);
    }
  }
}
