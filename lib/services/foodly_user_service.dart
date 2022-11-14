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
    final user = FoodlyUser(id: userId, oldPlans: []);
    await _firestore.doc(userId).set(user);
    return user;
  }

  static Future<FoodlyUser?> getUserById(String userId) async {
    log.finer('Call getUserById with $userId');
    final doc = await _firestore.doc(userId).get();
    return doc.exists ? doc.data() : null;
  }

  static Future<void> addOldPlanIdToUser(String userId, String? planId) async {
    log.finer('Call addOldPlanIdToUser with UserId: $userId | PlanId: $planId');
    final user = await getUserById(userId);

    if (user != null &&
        user.oldPlans != null &&
        !user.oldPlans!.contains(planId)) {
      user.oldPlans!.add(planId);
      return _firestore
          .doc(userId)
          .update(<String, List<String?>>{'oldPlans': user.oldPlans ?? []});
    }
    log.finest(
        'Call addOldPlanIdToUser with UserId: $userId | PlanId: $planId | ${user.toString()} | oldPlans dont contain planId');
  }

  static Future<void> deleteUserById(String userId) {
    log.finer('Call deleteUserById with $userId');
    return _firestore.doc(userId).delete();
  }

  static Future<void> subscribeToPremium(
    String userId,
    DateTime expiresAt,
  ) async {
    log.finer('Call subscribeToPremium with $userId and $expiresAt');
    final user = await getUserById(userId);
    if (user == null) {
      log.severe('#subscribeToPremium User $userId not found');
      return;
    }
    user.isPremium = true;
    user.premiumExpiresAt = expiresAt;
    return _firestore.doc(userId).update(user.toMap());
  }
}
