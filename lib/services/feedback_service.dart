import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../models/foodly_feedback.dart';

class FeedbackService {
  static final _log = Logger('FeedbackService');
  static final CollectionReference<Map<String, dynamic>> _firestore =
      FirebaseFirestore.instance.collection('feedbacks');

  FeedbackService._();

  static Future<void> create(FoodlyFeedback feedback) async {
    final mappedFeedback = feedback.toMap();
    try {
      await _firestore.add(mappedFeedback);
    } catch (e) {
      _log.severe('ERR: create with $mappedFeedback', e);
    }
  }
}
