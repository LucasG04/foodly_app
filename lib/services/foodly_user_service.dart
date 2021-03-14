import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/foodly_user.dart';

class FoodlyUserService {
  static final log = Logger('FoodlyUserService');

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FoodlyUserService._();

  static Future<FoodlyUser> createUserWithId(String userId) async {
    log.finer('Call createUserWithId with $userId');
    final user = new FoodlyUser(id: userId, oldPlans: []);
    await _firestore.collection('users').doc(userId).set(user.toMap());
    return user;
  }

  static Future<FoodlyUser> getUserById(String userId) async {
    log.finer('Call getUserById with $userId');
    final doc = await _firestore.collection('users').doc(userId).get();
    return FoodlyUser.fromMap(doc.id, doc.data());
  }

  static Future<void> addOldPlanIdToUser(String userId, String planId) async {
    log.finer('Call addOldPlanIdToUser with UserId: $userId | PlanId: $planId');
    final user = await getUserById(userId);

    if (!user.oldPlans.contains(planId)) {
      user.oldPlans.add(planId);
      return _firestore
          .collection('users')
          .doc(userId)
          .update({'oldPlans': user.oldPlans});
    }
    log.finest(
        'Call addOldPlanIdToUser with UserId: $userId | PlanId: $planId | ${user.toMap()} | oldPlans dont contain planId');
  }
}
