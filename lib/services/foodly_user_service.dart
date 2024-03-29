import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/foodly_user.dart';

class FoodlyUserService {
  FoodlyUserService._();

  static final log = Logger('FoodlyUserService');
  static final CollectionReference<FoodlyUser> _firestore =
      FirebaseFirestore.instance.collection('users').withConverter<FoodlyUser>(
            fromFirestore: (snapshot, _) =>
                FoodlyUser.fromMap(snapshot.id, snapshot.data()!),
            toFirestore: (model, _) => model.toMap(),
          );

  static Future<FoodlyUser> createUserWithId(String userId) async {
    log.finer('Call createUserWithId with $userId');
    final user = FoodlyUser(id: userId, plans: []);
    await _firestore.doc(userId).set(user);
    return user;
  }

  static Future<FoodlyUser?> getUserById(String userId) async {
    log.finer('Call getUserById with $userId');
    final doc = await _firestore.doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> addPlanIdToUser(String userId, String? planId) async {
    log.finer('Call addOldPlanIdToUser with UserId: $userId | PlanId: $planId');
    final user = await getUserById(userId);

    if (user != null && user.plans != null && !user.plans!.contains(planId)) {
      user.plans!.add(planId);
      return _firestore
          .doc(userId)
          .update(<String, List<String?>>{'oldPlans': user.plans ?? []});
    }
    log.finest(
        'Call addOldPlanIdToUser with UserId: $userId | PlanId: $planId | $user');
  }

  static Future<void> removePlanFromUser(String userId, String planId) async {
    log.finer('Call removePlanFromUser with UserId: $userId | PlanId: $planId');
    final user = await getUserById(userId);

    if (user != null && user.plans != null && user.plans!.contains(planId)) {
      user.plans!.remove(planId);
      return _firestore
          .doc(userId)
          .update(<String, List<String?>>{'oldPlans': user.plans ?? []});
    }
    log.finest(
        'Call removePlanFromUser with UserId: $userId | PlanId: $planId | $user');
  }

  static Future<void> deleteUserById(String userId) {
    log.finer('Call deleteUserById with $userId');
    return _firestore.doc(userId).delete();
  }

  static Future<void> setPremiumGiftedMessageShown(String userId) async {
    log.finer('Call setPremiumGiftedMessageShown');
    final user = await getUserById(userId);
    if (user != null) {
      user.premiumGiftedMessageShown = true;
      await _firestore.doc(user.id).update(user.toMap());
    }
  }

  static Future<void> resetPremiumGifted(String userId) async {
    log.finer('Call resetPremiumGifted');
    final user = await getUserById(userId);
    if (user != null) {
      user.isPremiumGifted = false;
      user.premiumGiftedAt = null;
      user.premiumGiftedMessageShown = false;
      await _firestore.doc(user.id).update(user.toMap());
    }
  }
}
