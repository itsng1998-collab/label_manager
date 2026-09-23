import 'package:flutter/foundation.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/features/item/data/column_content_dao.dart';
import 'package:label_manager/features/item/item_manager_debug_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _legacyItemEditableDefaultRepairMarker =
    'legacy_item_editable_defaults_v1_completed';

Future<int?>? _pendingLegacyItemEditableDefaultRepair;

@visibleForTesting
Future<int?> runLegacyItemEditableDefaultRepair({
  required Future<bool> Function() isCompleted,
  required Future<int> Function() repair,
  required Future<void> Function() markCompleted,
}) async {
  if (await isCompleted()) return null;
  final affected = await repair();
  await markCompleted();
  return affected;
}

Future<int?> ensureLegacyItemEditableDefaultsRepaired() {
  return _pendingLegacyItemEditableDefaultRepair ??=
      _ensureLegacyItemEditableDefaultsRepaired().whenComplete(() {
        _pendingLegacyItemEditableDefaultRepair = null;
      });
}

Future<int?> _ensureLegacyItemEditableDefaultsRepaired() async {
  final preferences = await SharedPreferences.getInstance();
  if (preferences.getBool(_legacyItemEditableDefaultRepairMarker) == true) {
    ItemManagerDebugLog.event(
      'legacyEditableRepair',
      'skipped',
      fields: {'appVersion': appVersion, 'reason': 'completed'},
    );
    return null;
  }

  ItemManagerDebugLog.event(
    'legacyEditableRepair',
    'started',
    fields: {'appVersion': appVersion},
  );
  try {
    final affected = await runLegacyItemEditableDefaultRepair(
      isCompleted: () async => false,
      repair: TColumnContentDAO.normalizeLegacyEditableDefaults,
      markCompleted: () async {
        final saved = await preferences.setBool(
          _legacyItemEditableDefaultRepairMarker,
          true,
        );
        if (!saved) {
          throw StateError('Legacy editable repair marker was not saved.');
        }
      },
    );
    ItemManagerDebugLog.event(
      'legacyEditableRepair',
      'completed',
      fields: {'appVersion': appVersion, 'affected': affected},
    );
    return affected;
  } catch (error) {
    ItemManagerDebugLog.event(
      'legacyEditableRepair',
      'failed',
      fields: {'appVersion': appVersion, 'error': error},
    );
    rethrow;
  }
}