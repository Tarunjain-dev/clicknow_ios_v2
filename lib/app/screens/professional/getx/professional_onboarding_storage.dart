import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfessionalOnboardingStorage {
  ProfessionalOnboardingStorage._();

  static const int totalSteps = 5;
  static const String _baseKey = 'professional_onboarding';
  static const String _anonymousScope = 'anonymous';
  static const int _draftVersion = 1;
  static const String _draftKeySuffix = 'draft_v1';
  static const String _legacyMigratedSuffix = 'legacy_migrated_v1';

  static String _scope({String? uid}) {
    if (uid != null && uid.isNotEmpty) {
      return uid;
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      return currentUid;
    }
    return _anonymousScope;
  }

  static String _stepKey(int stepIndex, {String? uid}) =>
      '${_baseKey}_${_scope(uid: uid)}_step_${stepIndex + 1}';

  static String _onboardingCompletedKey({String? uid}) =>
      '${_baseKey}_${_scope(uid: uid)}_completed';

  static String _draftKey({String? uid}) =>
      '${_baseKey}_${_scope(uid: uid)}_$_draftKeySuffix';

  static String _legacyMigratedKey({String? uid}) =>
      '${_baseKey}_${_scope(uid: uid)}_$_legacyMigratedSuffix';

  static Future<List<bool>> readStepFlags({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    return List<bool>.generate(
      totalSteps,
      (index) => prefs.getBool(_stepKey(index, uid: uid)) ?? false,
    );
  }

  static Future<void> writeStepFlag(
    int stepIndex,
    bool isCompleted, {
    String? uid,
  }) async {
    if (stepIndex < 0 || stepIndex >= totalSteps) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stepKey(stepIndex, uid: uid), isCompleted);
  }

  static Future<bool> readOnboardingCompleted({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompletedKey(uid: uid)) ?? false;
  }

  static Future<void> writeOnboardingCompleted(
    bool isCompleted, {
    String? uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey(uid: uid), isCompleted);
  }

  static Future<Map<String, dynamic>> readDraft({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey(uid: uid));
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, dynamic>{};
      }
      final map = _normalizeMap(decoded);
      final data = map['data'];
      if (data is Map) {
        return _normalizeMap(data);
      }
      return map;
    } catch (_) {
      await prefs.remove(_draftKey(uid: uid));
      return <String, dynamic>{};
    }
  }

  static Future<void> writeDraft(
    Map<String, dynamic> draft, {
    String? uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{'version': _draftVersion, 'data': draft};
    await prefs.setString(_draftKey(uid: uid), jsonEncode(payload));
  }

  static Future<void> clearDraft({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey(uid: uid));
  }

  static Future<void> migrateLegacyDraftIfNeeded({
    String? uid,
    String legacyKey = 'professional_profile_data',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final migratedKey = _legacyMigratedKey(uid: uid);
    if (prefs.getBool(migratedKey) ?? false) {
      return;
    }

    final existingDraft = await readDraft(uid: uid);
    if (existingDraft.isNotEmpty) {
      await prefs.setBool(migratedKey, true);
      return;
    }

    final legacyRaw = GetStorage().read(legacyKey);
    if (legacyRaw is Map) {
      final normalized = _normalizeMap(legacyRaw);
      if (normalized.isNotEmpty) {
        await writeDraft(normalized, uid: uid);
      }
    }

    await prefs.setBool(migratedKey, true);
  }

  static int firstIncompleteStepIndex(List<bool> flags) {
    for (int i = 0; i < flags.length; i++) {
      if (!flags[i]) return i;
    }
    return totalSteps - 1;
  }

  static Future<int> readFirstIncompleteStepIndex({String? uid}) async {
    final flags = await readStepFlags(uid: uid);
    return firstIncompleteStepIndex(flags);
  }

  static Future<void> clearProgress({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < totalSteps; i++) {
      await prefs.remove(_stepKey(i, uid: uid));
    }
    await prefs.remove(_onboardingCompletedKey(uid: uid));
    await prefs.remove(_draftKey(uid: uid));
    await prefs.remove(_legacyMigratedKey(uid: uid));
  }

  static Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> raw) {
    final result = <String, dynamic>{};
    raw.forEach((key, value) {
      result['$key'] = _normalizeValue(value);
    });
    return result;
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      return _normalizeMap(value);
    }
    if (value is List) {
      return value.map(_normalizeValue).toList();
    }
    return value;
  }
}
