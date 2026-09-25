import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ai_usage.dart';
import '../utils/ai_usage_period.dart';

/// Reads free-plan AI usage from the `aiUsage/{userId}` document.
///
/// The backend atomically increments the document; the client only reads it.
/// The weekly window is identified by [AiUsagePeriod.currentPeriodKey].
class AiUsageService {
  AiUsageService._();

  static final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection('aiUsage');

  /// Live usage for [userId], normalized to the current window.
  static Stream<AiUsage> streamUsage(String userId, AiLimits limits) {
    return _collection.doc(userId).snapshots().map(
          (snap) => AiUsage.fromDoc(
            snap.data(),
            currentPeriodKey: AiUsagePeriod.currentPeriodKey(),
            limits: limits,
          ),
        );
  }
}
