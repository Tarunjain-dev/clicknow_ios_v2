import 'dart:async';

import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class ServicePricingPlan {
  const ServicePricingPlan({
    required this.key,
    required this.label,
    required this.price,
    this.descriptionPoints = const <String>[],
  });

  final String key;
  final String label;
  final int price;
  final List<String> descriptionPoints;

  ServicePricingPlan copyWith({
    String? key,
    String? label,
    int? price,
    List<String>? descriptionPoints,
  }) {
    return ServicePricingPlan(
      key: key ?? this.key,
      label: label ?? this.label,
      price: price ?? this.price,
      descriptionPoints: descriptionPoints ?? this.descriptionPoints,
    );
  }
}

class ServiceEventTypeModel {
  const ServiceEventTypeModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.pricingPlans,
  });

  final String id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, ServicePricingPlan> pricingPlans;

  ServicePricingPlan get basicPlan =>
      pricingPlans['basic'] ??
      const ServicePricingPlan(key: 'basic', label: 'Default Plan', price: 0);

  ServicePricingPlan get normalPlan =>
      pricingPlans['normal'] ??
      const ServicePricingPlan(key: 'normal', label: 'Normal Plan', price: 0);

  ServicePricingPlan get professionalPlan =>
      pricingPlans['professional'] ??
      const ServicePricingPlan(
        key: 'professional',
        label: 'Professional Plan',
        price: 0,
      );
}

class AdminServiceModel {
  const AdminServiceModel({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.events,
  });

  final String id;
  final String name;
  final int sortOrder;
  final List<ServiceEventTypeModel> events;

  int get activeEventCount => events.where((event) => event.isActive).length;
  bool get isActive => activeEventCount > 0;
}

class AdminServicesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxDouble gstPercent = 18.0.obs;
  final RxList<AdminServiceModel> services = <AdminServiceModel>[].obs;
  final RxSet<String> expandedServiceIds = <String>{}.obs;
  final RxMap<String, bool> busyByKey = <String, bool>{}.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _servicesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _settingsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _eventTypeSubs =
      <String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>{};

  final Map<String, _ServiceMeta> _serviceMetaById = <String, _ServiceMeta>{};
  final Map<String, List<ServiceEventTypeModel>> _eventsByServiceId =
      <String, List<ServiceEventTypeModel>>{};

  int get totalEventTypes =>
      services.fold(0, (sum, service) => sum + service.events.length);
  int get activeEventTypes =>
      services.fold(0, (sum, service) => sum + service.activeEventCount);

  bool isExpanded(String serviceId) => expandedServiceIds.contains(serviceId);
  bool isBusy(String key) => busyByKey[key] == true;

  @override
  void onInit() {
    super.onInit();
    _ensureSeedDataIfNeeded();
    _listenSettings();
    _listenServices();
  }

  void toggleExpanded(String serviceId) {
    final next = <String>{};
    if (!expandedServiceIds.contains(serviceId)) {
      next.add(serviceId);
    }
    expandedServiceIds
      ..clear()
      ..addAll(next);
    expandedServiceIds.refresh();
  }

  Future<bool> addEventType({
    required AdminServiceModel service,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.error('Required', 'Please enter event type name.');
      return false;
    }
    final duplicate = service.events.any(
      (event) => event.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      AppSnackbar.error(
        'Already Exists',
        'This event type already exists for ${service.name}.',
      );
      return false;
    }

    return _runBusy(
      'add_${service.id}',
      action: () async {
        final now = FieldValue.serverTimestamp();
        await _db
            .collection(ServiceCatalogPaths.servicesCollection)
            .doc(service.id)
            .collection(ServiceCatalogPaths.eventTypesSubcollection)
            .add({
              'name': trimmed,
              'isActive': true,
              'createdAt': now,
              'updatedAt': now,
              'pricingPlans': _defaultPricingPlans(),
            });

        _syncServiceSummaryBestEffort(service.id);
        AppSnackbar.success(
          'Event Type Added',
          '$trimmed has been added successfully.',
        );
      },
    );
  }

  Future<bool> updateEventTypeName({
    required String serviceId,
    required String eventId,
    required String nextName,
    required List<ServiceEventTypeModel> existingEvents,
  }) async {
    final trimmed = nextName.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.error('Required', 'Please enter event type name.');
      return false;
    }

    final duplicate = existingEvents.any(
      (event) =>
          event.id != eventId &&
          event.name.toLowerCase() == trimmed.toLowerCase(),
    );
    if (duplicate) {
      AppSnackbar.error(
        'Already Exists',
        'This event type name already exists in this service.',
      );
      return false;
    }

    return _runBusy(
      'edit_$eventId',
      action: () async {
        await _db
            .collection(ServiceCatalogPaths.servicesCollection)
            .doc(serviceId)
            .collection(ServiceCatalogPaths.eventTypesSubcollection)
            .doc(eventId)
            .set({
              'name': trimmed,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        _syncServiceSummaryBestEffort(serviceId);
        AppSnackbar.success(
          'Event Type Updated',
          'Event type has been updated successfully.',
        );
      },
    );
  }

  Future<void> toggleEventTypeActive({
    required String serviceId,
    required ServiceEventTypeModel event,
  }) async {
    await _runBusy(
      'toggle_${event.id}',
      action: () async {
        await _db
            .collection(ServiceCatalogPaths.servicesCollection)
            .doc(serviceId)
            .collection(ServiceCatalogPaths.eventTypesSubcollection)
            .doc(event.id)
            .set({
              'isActive': !event.isActive,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        _syncServiceSummaryBestEffort(serviceId);
      },
    );
  }

  Future<bool> deleteEventType({
    required String serviceId,
    required ServiceEventTypeModel event,
  }) async {
    return _runBusy(
      'delete_${event.id}',
      action: () async {
        await _db
            .collection(ServiceCatalogPaths.servicesCollection)
            .doc(serviceId)
            .collection(ServiceCatalogPaths.eventTypesSubcollection)
            .doc(event.id)
            .delete();

        _syncServiceSummaryBestEffort(serviceId);
        AppSnackbar.success(
          'Deleted',
          '${event.name} has been deleted successfully.',
        );
      },
    );
  }

  Future<bool> saveEventPricing({
    required String serviceId,
    required String eventId,
    required String defaultLabel,
    required int defaultPrice,
    required List<String> defaultDescriptionPoints,
    required String normalLabel,
    required int normalPrice,
    required List<String> normalDescriptionPoints,
    required String professionalLabel,
    required int professionalPrice,
    required List<String> professionalDescriptionPoints,
  }) async {
    if (defaultPrice < 0 || normalPrice < 0 || professionalPrice < 0) {
      AppSnackbar.error('Invalid Amount', 'Pricing cannot be negative.');
      return false;
    }
    final basicLabel = _cleanPlanLabel(defaultLabel, 'Default Plan');
    final standardLabel = _cleanPlanLabel(normalLabel, 'Normal Plan');
    final proLabel = _cleanPlanLabel(professionalLabel, 'Professional Plan');
    final basicPoints = _cleanPlanDescriptionPoints(defaultDescriptionPoints);
    final standardPoints = _cleanPlanDescriptionPoints(normalDescriptionPoints);
    final proPoints = _cleanPlanDescriptionPoints(
      professionalDescriptionPoints,
    );

    return _runBusy(
      'pricing_$eventId',
      action: () async {
        await _db
            .collection(ServiceCatalogPaths.servicesCollection)
            .doc(serviceId)
            .collection(ServiceCatalogPaths.eventTypesSubcollection)
            .doc(eventId)
            .set({
              'pricingPlans': {
                'basic': {
                  'label': basicLabel,
                  'price': defaultPrice,
                  'descriptionPoints': basicPoints,
                },
                'normal': {
                  'label': standardLabel,
                  'price': normalPrice,
                  'descriptionPoints': standardPoints,
                },
                'professional': {
                  'label': proLabel,
                  'price': professionalPrice,
                  'descriptionPoints': proPoints,
                },
              },
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        AppSnackbar.success(
          'Pricing Updated',
          'Event pricing has been updated successfully.',
        );
      },
    );
  }

  Future<bool> saveGstPercent(double value) async {
    final clamped = value.clamp(0.0, 100.0).toDouble();
    return _runBusy(
      'gst',
      action: () async {
        await _db
            .collection(ServiceCatalogPaths.appSettingsCollection)
            .doc(ServiceCatalogPaths.serviceSettingsDoc)
            .set({
              'gstPercent': clamped,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        gstPercent.value = clamped;
        AppSnackbar.success('GST Updated', 'GST percentage saved successfully.');
      },
    );
  }

  Future<void> _listenSettings() async {
    _settingsSub = _db
        .collection(ServiceCatalogPaths.appSettingsCollection)
        .doc(ServiceCatalogPaths.serviceSettingsDoc)
        .snapshots()
        .listen((snapshot) {
          final data = snapshot.data() ?? <String, dynamic>{};
          gstPercent.value = _asDouble(data['gstPercent'], fallback: 18.0);
        });
  }

  Future<void> _listenServices() async {
    _servicesSub = _db
        .collection(ServiceCatalogPaths.servicesCollection)
        .snapshots()
        .listen(
          (snapshot) {
            final docs = snapshot.docs
                .map(_ServiceMeta.fromDoc)
                .where((meta) => meta.isActive)
                .toList(growable: false);

            final ids = docs.map((service) => service.id).toSet();
            _serviceMetaById
              ..clear()
              ..addEntries(docs.map((meta) => MapEntry(meta.id, meta)));

            final staleServiceIds = _eventTypeSubs.keys
                .where((id) => !ids.contains(id))
                .toList(growable: false);
            for (final staleId in staleServiceIds) {
              _eventTypeSubs.remove(staleId)?.cancel();
              _eventsByServiceId.remove(staleId);
            }

            for (final service in docs) {
              _eventTypeSubs.putIfAbsent(
                service.id,
                () => _listenEventTypes(service.id),
              );
            }

            expandedServiceIds.removeWhere((id) => !ids.contains(id));
            expandedServiceIds.refresh();
            _rebuildServices();
            isLoading.value = false;
          },
          onError: (_) {
            isLoading.value = false;
            AppSnackbar.error(
              'Fetch Failed',
              'Unable to load service management data.',
            );
          },
        );
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> _listenEventTypes(
    String serviceId,
  ) {
    return _db
        .collection(ServiceCatalogPaths.servicesCollection)
        .doc(serviceId)
        .collection(ServiceCatalogPaths.eventTypesSubcollection)
        .snapshots()
        .listen((snapshot) {
          final events = snapshot.docs.map(_serviceEventFromDoc).toList(
            growable: false,
          )..sort((a, b) {
              final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final right =
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final compare = left.compareTo(right);
              if (compare != 0) {
                return compare;
              }
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

          _eventsByServiceId[serviceId] = events;
          _rebuildServices();
        });
  }

  void _rebuildServices() {
    final items = _serviceMetaById.values
        .map(
          (meta) => AdminServiceModel(
            id: meta.id,
            name: meta.name,
            sortOrder: meta.sortOrder,
            events: _eventsByServiceId[meta.id] ?? const <ServiceEventTypeModel>[],
          ),
        )
        .toList(growable: false)
      ..sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) {
          return orderCompare;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    services.assignAll(items);
  }

  Future<void> _ensureSeedDataIfNeeded() async {
    try {
      final settingsRef = _db
          .collection(ServiceCatalogPaths.appSettingsCollection)
          .doc(ServiceCatalogPaths.serviceSettingsDoc);

      final existing = await _db
          .collection(ServiceCatalogPaths.servicesCollection)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        final settings = await settingsRef.get();
        if (!settings.exists) {
          await settingsRef.set({
            'gstPercent': 18.0,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return;
      }

      final now = FieldValue.serverTimestamp();
      final batch = _db.batch();
      for (final seed in _seedServices) {
        final serviceRef = _db
            .collection(ServiceCatalogPaths.servicesCollection)
            .doc(seed.id);
        final activeNames = seed.events
            .where((event) => event.isActive)
            .map((event) => event.name)
            .toList(growable: false);

        batch.set(serviceRef, {
          'name': seed.name,
          'isActive': true,
          'sortOrder': seed.sortOrder,
          'eventTypeCount': seed.events.length,
          'activeEventTypeCount': activeNames.length,
          'activeEventTypeNames': activeNames,
          'updatedAt': now,
          'createdAt': now,
        }, SetOptions(merge: true));

        for (final event in seed.events) {
          final eventRef = serviceRef
              .collection(ServiceCatalogPaths.eventTypesSubcollection)
              .doc();
          batch.set(eventRef, {
            'name': event.name,
            'isActive': event.isActive,
            'pricingPlans': _defaultPricingPlans(),
            'updatedAt': now,
            'createdAt': now,
          }, SetOptions(merge: true));
        }
      }

      batch.set(settingsRef, {
        'gstPercent': 18.0,
        'updatedAt': now,
        'createdAt': now,
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (_) {}
  }

  Future<void> _syncServiceSummary(String serviceId) async {
    final events = await _db
        .collection(ServiceCatalogPaths.servicesCollection)
        .doc(serviceId)
        .collection(ServiceCatalogPaths.eventTypesSubcollection)
        .get();

    final eventDocs = events.docs;
    final activeNames = eventDocs
        .where((doc) => (doc.data()['isActive'] as bool?) ?? true)
        .map((doc) => (doc.data()['name'] as String? ?? '').trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    await _db.collection(ServiceCatalogPaths.servicesCollection).doc(serviceId).set({
      'eventTypeCount': eventDocs.length,
      'activeEventTypeCount': activeNames.length,
      'activeEventTypeNames': activeNames,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> _runBusy(
    String key, {
    required Future<void> Function() action,
  }) async {
    if (busyByKey[key] == true) {
      return false;
    }
    busyByKey[key] = true;
    try {
      await action().timeout(const Duration(seconds: 20));
      return true;
    } on TimeoutException {
      AppSnackbar.error(
        'Request Timeout',
        'Action is taking longer than expected. Please check and retry.',
      );
      return false;
    } catch (_) {
      AppSnackbar.error('Action Failed', 'Something went wrong. Please retry.');
      return false;
    } finally {
      busyByKey.remove(key);
    }
  }

  void _syncServiceSummaryBestEffort(String serviceId) {
    unawaited(
      _syncServiceSummary(serviceId).timeout(const Duration(seconds: 12)).catchError(
        (_) {},
      ),
    );
  }

  @override
  void onClose() {
    _servicesSub?.cancel();
    _settingsSub?.cancel();
    for (final sub in _eventTypeSubs.values) {
      sub.cancel();
    }
    super.onClose();
  }
}

class _ServiceMeta {
  const _ServiceMeta({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;

  static _ServiceMeta fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return _ServiceMeta(
      id: doc.id,
      name: (data['name'] as String? ?? '').trim(),
      sortOrder: _asInt(data['sortOrder'], fallback: 999),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }
}

ServiceEventTypeModel _serviceEventFromDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
  final plansRaw = data['pricingPlans'];
  final pricingPlans = <String, ServicePricingPlan>{};
  if (plansRaw is Map) {
    final plans = Map<String, dynamic>.from(plansRaw);
    pricingPlans['basic'] = _parsePlan(
      plans['basic'],
      key: 'basic',
      fallbackLabel: 'Default Plan',
      fallbackPrice: 2500,
    );
    pricingPlans['normal'] = _parsePlan(
      plans['normal'],
      key: 'normal',
      fallbackLabel: 'Normal Plan',
      fallbackPrice: 5000,
    );
    pricingPlans['professional'] = _parsePlan(
      plans['professional'],
      key: 'professional',
      fallbackLabel: 'Professional Plan',
      fallbackPrice: 10000,
    );
  }

  pricingPlans.putIfAbsent(
    'basic',
    () => const ServicePricingPlan(
      key: 'basic',
      label: 'Default Plan',
      price: 2500,
    ),
  );
  pricingPlans.putIfAbsent(
    'normal',
    () => const ServicePricingPlan(
      key: 'normal',
      label: 'Normal Plan',
      price: 5000,
    ),
  );
  pricingPlans.putIfAbsent(
    'professional',
    () => const ServicePricingPlan(
      key: 'professional',
      label: 'Professional Plan',
      price: 10000,
    ),
  );

  return ServiceEventTypeModel(
    id: doc.id,
    name: (data['name'] as String? ?? '').trim(),
    isActive: (data['isActive'] as bool?) ?? true,
    createdAt: _asDateTime(data['createdAt']),
    updatedAt: _asDateTime(data['updatedAt']),
    pricingPlans: pricingPlans,
  );
}

class _SeedService {
  const _SeedService({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.events,
  });

  final String id;
  final String name;
  final int sortOrder;
  final List<_SeedEventType> events;
}

class _SeedEventType {
  const _SeedEventType({
    required this.name,
    required this.isActive,
  });

  final String name;
  final bool isActive;
}

Map<String, dynamic> _defaultPricingPlans() {
  return const <String, dynamic>{
    'basic': {
      'label': 'Default Plan',
      'price': 2500,
      'descriptionPoints': <String>[],
    },
    'normal': {
      'label': 'Normal Plan',
      'price': 5000,
      'descriptionPoints': <String>[],
    },
    'professional': {
      'label': 'Professional Plan',
      'price': 10000,
      'descriptionPoints': <String>[],
    },
  };
}

ServicePricingPlan _parsePlan(
  dynamic value, {
  required String key,
  required String fallbackLabel,
  required int fallbackPrice,
}) {
  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    return ServicePricingPlan(
      key: key,
      label: (map['label'] as String?)?.trim().isNotEmpty == true
          ? (map['label'] as String).trim()
          : fallbackLabel,
      price: _asInt(map['price'], fallback: fallbackPrice),
      descriptionPoints: _readPlanDescriptionPoints(map['descriptionPoints']),
    );
  }
  return ServicePricingPlan(
    key: key,
    label: fallbackLabel,
    price: fallbackPrice,
  );
}

String _cleanPlanLabel(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

List<String> _cleanPlanDescriptionPoints(Iterable<String> values) {
  return values
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .take(4)
      .toList(growable: false);
}

List<String> _readPlanDescriptionPoints(dynamic raw) {
  if (raw is List) {
    return _cleanPlanDescriptionPoints(raw.map((item) => item.toString()));
  }
  if (raw is String) {
    return _cleanPlanDescriptionPoints(raw.split('\n'));
  }
  return const <String>[];
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim()) ?? fallback;
  }
  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

const List<_SeedService> _seedServices = <_SeedService>[
  _SeedService(
    id: 'photo_videography',
    name: 'Photo and Videography Services',
    sortOrder: 1,
    events: <_SeedEventType>[
      _SeedEventType(name: 'Family events', isActive: true),
      _SeedEventType(name: 'Pre-wedding', isActive: true),
      _SeedEventType(name: 'Corporate Events', isActive: true),
      _SeedEventType(name: 'Private Parties', isActive: true),
      _SeedEventType(name: 'Product shoots', isActive: true),
      _SeedEventType(name: 'Fashion shoots', isActive: true),
      _SeedEventType(name: 'Real Estate', isActive: true),
      _SeedEventType(name: 'Makeup shoots', isActive: true),
      _SeedEventType(name: 'Weddings', isActive: true),
      _SeedEventType(name: 'Mobile Shoots', isActive: true),
    ],
  ),
  _SeedService(
    id: 'music_live_performance',
    name: 'Music & Live Performance Services',
    sortOrder: 2,
    events: <_SeedEventType>[
      _SeedEventType(name: 'Wedding Sangeet', isActive: true),
      _SeedEventType(name: 'Corporate Event', isActive: true),
      _SeedEventType(name: 'Private Party', isActive: true),
      _SeedEventType(name: 'Live Concert', isActive: true),
      _SeedEventType(name: 'Religious Event', isActive: true),
      _SeedEventType(name: 'College Fest', isActive: true),
      _SeedEventType(name: 'Cocktail Night', isActive: false),
    ],
  ),
  _SeedService(
    id: 'professional_dj',
    name: 'Professional DJ Services',
    sortOrder: 3,
    events: <_SeedEventType>[
      _SeedEventType(name: 'Wedding DJ', isActive: true),
      _SeedEventType(name: 'Club DJ', isActive: true),
      _SeedEventType(name: 'Corporate DJ', isActive: true),
      _SeedEventType(name: 'Festival DJ', isActive: true),
      _SeedEventType(name: 'Private Party DJ', isActive: true),
      _SeedEventType(name: 'House Party DJ', isActive: false),
    ],
  ),
  _SeedService(
    id: 'live_wedding_painter',
    name: 'Live Wedding Painter Services',
    sortOrder: 4,
    events: <_SeedEventType>[
      _SeedEventType(name: 'Live Couple Portrait', isActive: true),
      _SeedEventType(name: 'Ceremony Live Painting', isActive: true),
      _SeedEventType(name: 'Reception Live Painting', isActive: true),
      _SeedEventType(name: 'Family Live Portrait', isActive: false),
    ],
  ),
  _SeedService(
    id: 'professional_anchor',
    name: 'Professional Anchor Services',
    sortOrder: 5,
    events: <_SeedEventType>[
      _SeedEventType(name: 'Wedding Hosting', isActive: true),
      _SeedEventType(name: 'Corporate Hosting', isActive: true),
      _SeedEventType(name: 'Award Show', isActive: true),
      _SeedEventType(name: 'Product Launch', isActive: true),
      _SeedEventType(name: 'Private Event', isActive: true),
      _SeedEventType(name: 'Live Show', isActive: false),
    ],
  ),
  _SeedService(
    id: 'professional_magician',
    name: 'Professional Magician Services',
    sortOrder: 6,
    events: <_SeedEventType>[
      _SeedEventType(name: 'Stage Magic', isActive: true),
      _SeedEventType(name: 'Close-Up Magic', isActive: true),
      _SeedEventType(name: 'Kids Magic Show', isActive: true),
      _SeedEventType(name: 'Corporate Magic Show', isActive: true),
      _SeedEventType(name: 'Wedding Magic Show', isActive: false),
    ],
  ),
];
