import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodly/models/foodly_user.dart';

class FoodlyUserService {
  FoodlyUserService._();

  static FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createUserWithId(String userId) {
    final user = new FoodlyUser(id: userId, oldPlans: []);
    return _firestore.collection('users').doc(userId).set(user.toMap());
  }

  static Future<FoodlyUser> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();

    return FoodlyUser.fromMap(doc.id, doc.data());
  }

  static Future<void> addOldPlanIdToUser(String userId, String planId) async {
    final user = await getUserById(userId);

    if (!user.oldPlans.contains(planId)) {
      user.oldPlans.add(planId);
      return _firestore
          .collection('users')
          .doc(userId)
          .update({'oldPlans': user.oldPlans});
    }
  }
}
