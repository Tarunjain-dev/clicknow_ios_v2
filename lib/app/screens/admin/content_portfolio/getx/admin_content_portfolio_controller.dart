import 'dart:async';
import 'dart:io';

import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AdminPortfolioServiceItem {
  const AdminPortfolioServiceItem({
    required this.key,
    required this.title,
    required this.defaultPhotoAsset,
  });

  final String key;
  final String title;
  final String defaultPhotoAsset;
}

class AdminPortfolioMediaRecord {
  const AdminPortfolioMediaRecord({
    required this.id,
    required this.serviceId,
    required this.mediaType,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.displayOrder,
    required this.isVisible,
    required this.storagePath,
  });

  final String id;
  final String serviceId;
  final String mediaType;
  final String mediaUrl;
  final String thumbnailUrl;
  final String caption;
  final int displayOrder;
  final bool isVisible;
  final String storagePath;

  bool get isVideo => mediaType == 'video';

  factory AdminPortfolioMediaRecord.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AdminPortfolioMediaRecord(
      id: doc.id,
      serviceId: (data['serviceId'] ?? '').toString().trim(),
      mediaType: (data['mediaType'] ?? 'image').toString().trim(),
      mediaUrl: (data['mediaUrl'] ?? '').toString().trim(),
      thumbnailUrl: (data['thumbnailUrl'] ?? '').toString().trim(),
      caption: (data['caption'] ?? data['title'] ?? '').toString().trim(),
      displayOrder: data['displayOrder'] is int
          ? data['displayOrder'] as int
          : int.tryParse('${data['displayOrder']}') ?? 0,
      isVisible: data['isVisible'] != false,
      storagePath: (data['storagePath'] ?? '').toString().trim(),
    );
  }
}

class AdminContentPortfolioController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxMap<String, bool> mediaUploadLoadingByKey = <String, bool>{}.obs;

  final TextEditingController aboutController = TextEditingController();
  final TextEditingController missionController = TextEditingController();
  final TextEditingController whyChooseController = TextEditingController();

  final RxMap<String, String> photoUrlByService = <String, String>{}.obs;
  final RxMap<String, String> videoUrlByService = <String, String>{}.obs;
  final RxMap<String, int> photoCountByService = <String, int>{}.obs;
  final RxMap<String, int> videoCountByService = <String, int>{}.obs;
  final RxList<AdminPortfolioMediaRecord> mediaItems =
      <AdminPortfolioMediaRecord>[].obs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _mediaSub;

  static const String defaultDemoVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  final List<AdminPortfolioServiceItem> services =
      const <AdminPortfolioServiceItem>[
        AdminPortfolioServiceItem(
          key: 'photo_videography',
          title: 'Photo & Videography',
          defaultPhotoAsset: AppImages.photographer,
        ),
        AdminPortfolioServiceItem(
          key: 'music_live_performance',
          title: 'Music & Live Performance',
          defaultPhotoAsset: AppImages.musician,
        ),
        AdminPortfolioServiceItem(
          key: 'professional_dj',
          title: 'Professional DJ',
          defaultPhotoAsset: AppImages.dj,
        ),
        AdminPortfolioServiceItem(
          key: 'live_wedding_painter',
          title: 'Live Wedding Painter',
          defaultPhotoAsset: AppImages.weddingPlanner,
        ),
        AdminPortfolioServiceItem(
          key: 'professional_anchor',
          title: 'Professional Anchor',
          defaultPhotoAsset: AppImages.anchor,
        ),
        AdminPortfolioServiceItem(
          key: 'professional_magician',
          title: 'Professional Magician',
          defaultPhotoAsset: AppImages.magician,
        ),
      ];

  @override
  void onInit() {
    super.onInit();
    unawaited(_seedPortfolioServices());
    loadPortfolioContent();
    _listenMediaCounts();
  }

  bool isMediaUploading(String serviceKey, {required bool isVideo}) {
    final key = _mediaKey(serviceKey, isVideo: isVideo);
    return mediaUploadLoadingByKey[key] == true;
  }

  String effectivePhotoFor(String serviceKey) {
    final uploaded = (photoUrlByService[serviceKey] ?? '').trim();
    if (uploaded.isNotEmpty) {
      return uploaded;
    }
    final service = _serviceByKey(serviceKey);
    return service?.defaultPhotoAsset ?? AppImages.photographer;
  }

  String effectiveVideoFor(String serviceKey) {
    final uploaded = (videoUrlByService[serviceKey] ?? '').trim();
    if (uploaded.isNotEmpty) {
      return uploaded;
    }
    return defaultDemoVideoUrl;
  }

  void _listenMediaCounts() {
    _mediaSub?.cancel();
    _mediaSub = _db
        .collection(ServiceCatalogPaths.portfolioMediaCollection)
        .snapshots()
        .listen((snapshot) {
      final photoCounts = <String, int>{};
      final videoCounts = <String, int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final serviceId = _normalizeServiceKey(
          (data['serviceId'] ?? '').toString().trim(),
        );
        final mediaType = (data['mediaType'] ?? '').toString().trim();
        if (serviceId.isEmpty) continue;
        if (mediaType == 'video') {
          videoCounts[serviceId] = (videoCounts[serviceId] ?? 0) + 1;
        } else {
          photoCounts[serviceId] = (photoCounts[serviceId] ?? 0) + 1;
        }
      }
      photoCountByService.assignAll(photoCounts);
      videoCountByService.assignAll(videoCounts);
      final records = snapshot.docs
          .map(AdminPortfolioMediaRecord.fromDoc)
          .where((item) => item.mediaUrl.isNotEmpty)
          .toList(growable: true)
        ..sort((a, b) {
          final serviceCompare = _serviceTitle(
            _normalizeServiceKey(a.serviceId),
          ).compareTo(_serviceTitle(_normalizeServiceKey(b.serviceId)));
          if (serviceCompare != 0) return serviceCompare;
          return a.displayOrder.compareTo(b.displayOrder);
        });
      mediaItems.assignAll(records);
    });
  }

  Future<void> loadPortfolioContent() async {
    isLoading.value = true;
    try {
      final ref = _db
          .collection(ServiceCatalogPaths.portfolioContentCollection)
          .doc(ServiceCatalogPaths.portfolioSettingsDoc);
      final snapshot = await ref.get();
      Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
      if (!snapshot.exists) {
        data = _defaultPayload();
        await ref.set(data, SetOptions(merge: true));
      }
      _hydrate(data);
    } catch (_) {
      _hydrate(_defaultPayload());
      AppSnackbar.error(
        'Load Failed',
        'Unable to load portfolio content. Showing defaults.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveContent() async {
    await _persistPortfolioContent(showSuccess: true);
  }

  Future<void> uploadMedia(
    String serviceKey, {
    required bool isVideo,
  }) async {
    final normalizedServiceKey = _normalizeServiceKey(serviceKey);
    final key = _mediaKey(normalizedServiceKey, isVideo: isVideo);
    if (mediaUploadLoadingByKey[key] == true) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: !isVideo,
      type: FileType.custom,
      allowedExtensions: isVideo
          ? const <String>['mp4', 'mov', 'avi', 'mkv']
          : const <String>['png', 'jpg', 'jpeg', 'webp'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    if (!isVideo && result.files.length > 50) {
      AppSnackbar.error(
        'Upload Limit',
        'You can add maximum 50 photos at once.',
      );
      return;
    }

    mediaUploadLoadingByKey[key] = true;
    try {
      var uploadedCount = 0;
      var nextOrder = await _nextMediaOrder(
        normalizedServiceKey,
        isVideo ? 'video' : 'image',
      );
      for (final file in result.files) {
        final maxBytes = isVideo ? 100 * 1024 * 1024 : 10 * 1024 * 1024;
        if (file.size <= 0 || file.size > maxBytes) {
          AppSnackbar.error(
            'Invalid File',
            '${file.name} exceeds the allowed ${isVideo ? "100 MB" : "10 MB"} limit.',
          );
          continue;
        }
        final extension =
            (file.extension ?? (isVideo ? 'mp4' : 'jpg')).toLowerCase();
        final pathSegment = isVideo ? 'videos' : 'images';
        final storagePath =
            'portfolio/$normalizedServiceKey/$pathSegment/${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(RegExp(r"\\s+"), "_")}';

        final ref = _storage.ref(storagePath);
        UploadTask task;
        if (file.bytes != null) {
          task = ref.putData(
            file.bytes!,
            SettableMetadata(
              contentType: isVideo ? 'video/$extension' : 'image/$extension',
            ),
          );
        } else if (file.path != null) {
          task = ref.putFile(
            File(file.path!),
            SettableMetadata(
              contentType: isVideo ? 'video/$extension' : 'image/$extension',
            ),
          );
        } else {
          continue;
        }

        final snapshot = await task;
        final url = await snapshot.ref.getDownloadURL();
        final mediaDoc =
            _db.collection(ServiceCatalogPaths.portfolioMediaCollection).doc();
        await mediaDoc.set(<String, dynamic>{
          'id': mediaDoc.id,
          'serviceId': normalizedServiceKey,
          'mediaType': isVideo ? 'video' : 'image',
          'mediaUrl': url,
          'thumbnailUrl': isVideo ? '' : url,
          'caption': '',
          'storagePath': storagePath,
          'displayOrder': nextOrder++,
          'isVisible': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (isVideo) {
          videoUrlByService[normalizedServiceKey] = url;
        } else {
          photoUrlByService[normalizedServiceKey] = url;
        }
        uploadedCount++;
        if (isVideo) {
          break;
        }
      }

      await _persistPortfolioContent(showSuccess: false);
      AppSnackbar.success(
        'Upload Complete',
        '$uploadedCount ${isVideo ? "video" : "media file(s)"} added to ${_serviceTitle(normalizedServiceKey)}.',
      );
    } catch (_) {
      AppSnackbar.error(
        'Upload Failed',
        'Unable to upload ${isVideo ? "video" : "photo"} right now.',
      );
    } finally {
      mediaUploadLoadingByKey.remove(key);
    }
  }

  Future<void> clearMedia(
    String serviceKey, {
    required bool isVideo,
  }) async {
    if (isVideo) {
      videoUrlByService.remove(serviceKey);
    } else {
      photoUrlByService.remove(serviceKey);
    }
    await _persistPortfolioContent(showSuccess: false);
    AppSnackbar.success(
      'Cleared',
      '${isVideo ? "Video" : "Photo"} reset for ${_serviceTitle(serviceKey)}.',
    );
  }

  Future<void> updateMediaMetadata({
    required AdminPortfolioMediaRecord item,
    required String caption,
    required String thumbnailUrl,
    required int displayOrder,
    required bool isVisible,
    required String serviceId,
  }) async {
    await _db
        .collection(ServiceCatalogPaths.portfolioMediaCollection)
        .doc(item.id)
        .set(<String, dynamic>{
          'caption': caption.trim(),
          'thumbnailUrl': thumbnailUrl.trim(),
          'displayOrder': displayOrder,
          'isVisible': isVisible,
          'serviceId': _normalizeServiceKey(serviceId),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    AppSnackbar.success('Saved', 'Media details updated.');
  }

  Future<void> toggleMediaVisibility(AdminPortfolioMediaRecord item) async {
    await _db
        .collection(ServiceCatalogPaths.portfolioMediaCollection)
        .doc(item.id)
        .set(<String, dynamic>{
          'isVisible': !item.isVisible,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> moveMedia(AdminPortfolioMediaRecord item, int delta) async {
    final nextOrder = (item.displayOrder + delta).clamp(1, 999999);
    await _db
        .collection(ServiceCatalogPaths.portfolioMediaCollection)
        .doc(item.id)
        .set(<String, dynamic>{
          'displayOrder': nextOrder,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> deleteMedia(AdminPortfolioMediaRecord item) async {
    await _db
        .collection(ServiceCatalogPaths.portfolioMediaCollection)
        .doc(item.id)
        .delete();
    if (item.storagePath.isNotEmpty) {
      try {
        await _storage.ref(item.storagePath).delete();
      } catch (_) {
        AppSnackbar.error(
          'Storage Warning',
          'Media record was deleted, but the storage file could not be removed.',
        );
        return;
      }
    }
    AppSnackbar.success('Deleted', 'Portfolio media item removed.');
  }

  Future<void> _persistPortfolioContent({required bool showSuccess}) async {
    if (isSaving.value) {
      return;
    }
    isSaving.value = true;
    try {
      final ref = _db
          .collection(ServiceCatalogPaths.portfolioContentCollection)
          .doc(ServiceCatalogPaths.portfolioSettingsDoc);
      await ref.set(_payloadFromState(), SetOptions(merge: true));
      if (showSuccess) {
        AppSnackbar.success(
          'Saved',
          'Portfolio content has been updated successfully.',
        );
      }
    } catch (_) {
      AppSnackbar.error(
        'Save Failed',
        'Unable to save portfolio content right now.',
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _seedPortfolioServices() async {
    final batch = _db.batch();
    for (var index = 0; index < services.length; index++) {
      final service = services[index];
      final ref = _db
          .collection(ServiceCatalogPaths.portfolioServicesCollection)
          .doc(service.key);
      batch.set(ref, <String, dynamic>{
        'id': service.key,
        'serviceName': service.title,
        'serviceIcon': '',
        'shortDescription': 'Portfolio media for ${service.title}',
        'displayOrder': index + 1,
        'isVisible': true,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    const legacyMap = <String, String>{
      'photography': 'photo_videography',
      'musician': 'music_live_performance',
      'dj': 'professional_dj',
      'wedding_planner': 'live_wedding_painter',
      'anchor': 'professional_anchor',
      'magician': 'professional_magician',
    };
    for (final entry in legacyMap.entries) {
      final ref = _db
          .collection(ServiceCatalogPaths.portfolioServicesCollection)
          .doc(entry.key);
      batch.set(ref, <String, dynamic>{
        'id': entry.key,
        'canonicalId': entry.value,
        'isVisible': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<int> _nextMediaOrder(String serviceKey, String mediaType) async {
    final snapshot = await _db
        .collection(ServiceCatalogPaths.portfolioMediaCollection)
        .where('serviceId', isEqualTo: serviceKey)
        .where('mediaType', isEqualTo: mediaType)
        .get();
    var maxOrder = 0;
    for (final doc in snapshot.docs) {
      final raw = doc.data()['displayOrder'];
      final order = raw is int ? raw : int.tryParse('$raw') ?? 0;
      if (order > maxOrder) {
        maxOrder = order;
      }
    }
    return maxOrder + 1;
  }

  void _hydrate(Map<String, dynamic> data) {
    aboutController.text =
        (data['aboutUsDescription'] ?? data['aboutDescription'] ?? _defaultPayload()['aboutUsDescription'])
            .toString();
    missionController.text =
        (data['missionDescription'] ?? _defaultPayload()['missionDescription'])
            .toString();

    final points = _parseWhyChoosePoints(data['whyChooseUsPoints'] ?? data['whyChoosePoints']);
    whyChooseController.text = points.join('\n');

    final media = _asMap(data['media']);
    final photoMap = <String, String>{};
    final videoMap = <String, String>{};

    for (final service in services) {
      final serviceMedia = _asMap(
        media[service.key] ?? media[_legacyServiceKey(service.key)],
      );
      final photo = (serviceMedia['photoUrl'] ?? '').toString().trim();
      final video = (serviceMedia['videoUrl'] ?? '').toString().trim();
      if (photo.isNotEmpty) {
        photoMap[service.key] = photo;
      }
      if (video.isNotEmpty) {
        videoMap[service.key] = video;
      }
    }
    photoUrlByService.assignAll(photoMap);
    videoUrlByService.assignAll(videoMap);
  }

  Map<String, dynamic> _payloadFromState() {
    final whyPoints = whyChooseController.text
        .split('\n')
        .map((line) => line.replaceFirst(RegExp(r'^[-*]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    final mediaPayload = <String, dynamic>{};
    for (final service in services) {
      mediaPayload[service.key] = <String, dynamic>{
        'photoUrl': (photoUrlByService[service.key] ?? '').trim(),
        'videoUrl': (videoUrlByService[service.key] ?? '').trim(),
      };
    }

    return <String, dynamic>{
      'aboutUsTitle': 'About ClickNow',
      'aboutUsDescription': aboutController.text.trim(),
      'missionTitle': 'Our Mission',
      'missionDescription': missionController.text.trim(),
      'whyChooseUsTitle': 'Why Choose Us',
      'whyChooseUsPoints': whyPoints,
      'statistics': const <String, int>{
        'events': 500,
        'professionals': 500,
        'ratings': 500,
        'cities': 20,
      },
      'media': mediaPayload,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _defaultPayload() {
    return <String, dynamic>{
      'aboutUsTitle': 'About ClickNow',
      'aboutUsDescription':
          "We are India's premier event services platform, dedicated to making your special moments truly unforgettable. With years of experience and a team of talented professionals, we bring excellence to every event.",
      'missionTitle': 'Our Mission',
      'missionDescription':
          'To provide seamless, professional event services that exceed expectations and create lasting memories for our clients.',
      'whyChooseUsTitle': 'Why Choose Us',
      'whyChooseUsPoints': const <String>[
        'Verified and experienced professionals',
        'Transparent pricing with no hidden costs',
        '24/7 customer support',
        'Quality guaranteed on every service',
      ],
      'media': {
        for (final service in services)
          service.key: <String, dynamic>{
            'photoUrl': '',
            'videoUrl': defaultDemoVideoUrl,
          },
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String _mediaKey(String serviceKey, {required bool isVideo}) {
    return '$serviceKey|${isVideo ? "video" : "photo"}';
  }

  String _serviceTitle(String serviceKey) {
    return _serviceByKey(serviceKey)?.title ?? serviceKey;
  }

  AdminPortfolioServiceItem? _serviceByKey(String serviceKey) {
    final normalized = _normalizeServiceKey(serviceKey);
    for (final item in services) {
      if (item.key == normalized) {
        return item;
      }
    }
    return null;
  }

  String _normalizeServiceKey(String value) {
    const legacyMap = <String, String>{
      'photography': 'photo_videography',
      'musician': 'music_live_performance',
      'dj': 'professional_dj',
      'wedding_planner': 'live_wedding_painter',
      'anchor': 'professional_anchor',
      'magician': 'professional_magician',
    };
    return legacyMap[value.trim()] ?? value.trim();
  }

  String _legacyServiceKey(String value) {
    const reverse = <String, String>{
      'photo_videography': 'photography',
      'music_live_performance': 'musician',
      'professional_dj': 'dj',
      'live_wedding_painter': 'wedding_planner',
      'professional_anchor': 'anchor',
      'professional_magician': 'magician',
    };
    return reverse[value.trim()] ?? value.trim();
  }

  List<String> _parseWhyChoosePoints(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[
      'Verified and experienced professionals',
      'Transparent pricing with no hidden costs',
      '24/7 customer support',
      'Quality guaranteed on every service',
    ];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val));
    }
    return <String, dynamic>{};
  }

  @override
  void onClose() {
    aboutController.dispose();
    missionController.dispose();
    whyChooseController.dispose();
    _mediaSub?.cancel();
    super.onClose();
  }
}
