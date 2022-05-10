import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

import '../utils/convert_util.dart';

class LogRecordService {
  static final _log = Logger('LogRecordService');
  static final CollectionReference<Map<String, dynamic>> _firestore =
      FirebaseFirestore.instance.collection('logs');

  static String _currentUserId = '0';
  static String _currentPlanId = '0';
  static List<LogRecord> _logs = [];

  static Timer? _timer;

  LogRecordService._();

  static void startPeriodicLogging() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveLogsToDatabase(),
    );
  }

  static Future<void> saveLog({
    required LogRecord logRecord,
    String? userId,
    String? planId,
  }) async {
    _currentUserId = userId ?? '0';
    _currentPlanId = planId ?? '0';
    _logs.add(logRecord);
  }

  static Future<void> _saveLogsToDatabase() async {
    if (_logs.isEmpty) {
      return;
    }
    final record = await _firestore.doc(_currentUserId).get();
    final logs = _logs;
    _logs = [];

    if (record.exists) {
      await _addLogsToDatabase(logs);
    } else {
      await _createLogs(logs);
    }
  }

  static Future<void> _createLogs(List<LogRecord> logRecords) async {
    final mappedLogRecords =
        logRecords.map((e) => ConvertUtil.logRecordToMap(e)).toList();
    try {
      await _firestore.doc(_currentUserId).set(<String, dynamic>{
        'userId': _currentUserId,
        'planId': _currentPlanId,
        'logs': mappedLogRecords,
      });
    } catch (e) {
      _log.severe('ERR: _createLogs with $mappedLogRecords', e);
    }
  }

  static Future<void> _addLogsToDatabase(List<LogRecord> logRecords) async {
    final mappedLogRecords =
        logRecords.map((e) => ConvertUtil.logRecordToMap(e)).toList();
    try {
      await _firestore.doc(_currentUserId).set(<String, dynamic>{
        'logs': FieldValue.arrayUnion(mappedLogRecords),
      });
    } catch (e) {
      _log.severe(
          'ERR: _addLogToDocument with userId: $_currentUserId, record: $mappedLogRecords',
          e);
    }
  }
}
