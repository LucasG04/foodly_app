import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import 'app_review_service.dart';
import 'plan_service.dart';
import 'settings_service.dart';
import 'version_service.dart';

/// One-time readback migration of legacy Hive boxes into Isar.
///
/// The app previously stored settings, version, app-review and plan state in
/// Hive. Those boxes were never migrated when the storage layer moved to Isar,
/// so this service reads the old boxes once on launch, writes their values into
/// the new Isar-backed services and then deletes the Hive boxes from disk.
///
/// Idempotency is achieved without any extra Isar schema/flag: a box is only
/// migrated while it still [Hive.boxExists] on disk, and it is deleted right
/// after a successful migration. Once the legacy files are gone, [migrate] is a
/// no-op. This temporary service (and the Hive dependencies) can be removed
/// once all users have launched a build containing it.
class HiveMigrationService {
  HiveMigrationService._();

  static final _log = Logger('HiveMigrationService');

  // Legacy Hive box names. Note: the version box name was misspelled as
  // 'verison' in the original implementation and must be matched exactly.
  static const _settingsBoxName = 'settings';
  static const _versionBoxName = 'verison';
  static const _reviewBoxName = 'reviewevents';
  static const _planBoxName = 'plan';

  /// Runs the migration for every legacy box that still exists on disk. Never
  /// throws: each box is migrated independently and any failure is logged so it
  /// neither blocks the other boxes nor app startup.
  static Future<void> migrate() async {
    try {
      await Hive.initFlutter();
    } catch (e, s) {
      _log.severe('Failed to initialize Hive for migration', e, s);
      return;
    }

    await _migrateSettings();
    await _migrateVersion();
    await _migrateReview();
    await _migratePlan();
  }

  static Future<void> _migrateSettings() async {
    await _migrateBox(_settingsBoxName, (box) async {
      await SettingsService.restore(
        firstUsage: box.get('firstUsage') as bool?,
        multipleMealsPerTime: box.get('multipleMealsPerTime') as bool?,
        showSuggestions: box.get('showSuggestions') as bool?,
        removeBoughtImmediately: box.get('removeBoughtImmediately') as bool?,
        primaryColor: box.get('primaryColor') as int?,
        shoppingListSort: box.get('shoppingListSort') as int?,
        productGroupOrder:
            (box.get('productGroupOrder') as List<dynamic>?)?.cast<String>(),
        activeMealTypes:
            (box.get('activeMealTypes') as List<dynamic>?)?.cast<int>(),
        useDevApi: box.get('useDevApi') as bool?,
      );
    });
  }

  static Future<void> _migrateVersion() async {
    await _migrateBox(_versionBoxName, (box) async {
      await VersionService.restore(
        lastCheckedVersion: box.get('lastCheckedVersion') as String?,
        lastCheckedForUpdate: box.get('lastCheckedForUpdate') as DateTime?,
      );
    });
  }

  static Future<void> _migrateReview() async {
    await _migrateBox(_reviewBoxName, (box) async {
      await AppReviewService.restore(
        planMeal: box.get('planMeal') as int?,
        groceryBought: box.get('groceryBought') as int?,
        mealCreated: box.get('mealCreated') as int?,
        lastRequest: box.get('lastRequest') as DateTime?,
        hasRated: box.get('hasRated') as bool?,
      );
    });
  }

  static Future<void> _migratePlan() async {
    await _migrateBox(_planBoxName, (box) async {
      await PlanService.restore(
        lastLockedCheck: box.get('lastLockedCheck') as int?,
      );
    });
  }

  /// Opens [name] if it still exists on disk, runs [migrateData], then deletes
  /// the box from disk so the migration self-disables on the next launch.
  /// Any error is caught and logged so a single box cannot block the others.
  static Future<void> _migrateBox(
    String name,
    Future<void> Function(Box<dynamic> box) migrateData,
  ) async {
    try {
      if (!await Hive.boxExists(name)) {
        return;
      }

      _log.fine('Migrating legacy Hive box "$name"');
      final box = await Hive.openBox<dynamic>(name);
      await migrateData(box);
      await box.deleteFromDisk();
      _log.fine('Migrated and removed legacy Hive box "$name"');
    } catch (e, s) {
      _log.severe('Failed to migrate legacy Hive box "$name"', e, s);
    }
  }
}
