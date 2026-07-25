import 'dart:typed_data';
import 'dart:async';

import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class PortfolioMediaItem {
  const PortfolioMediaItem({
    required this.category,
    required this.mediaPath,
    required this.isVideo,
    required this.isNetwork,
  });

  final String category;
  final String mediaPath;
  final bool isVideo;
  final bool isNetwork;
}

class PortfolioExperienceItem {
  const PortfolioExperienceItem({
    required this.name,
    required this.location,
    required this.message,
    required this.rating,
  });

  final String name;
  final String location;
  final String message;
  final double rating;
}

class CustomerPortfolioController extends GetxController {
  static CustomerPortfolioController get instance {
    if (Get.isRegistered<CustomerPortfolioController>()) {
      return Get.find<CustomerPortfolioController>();
    }
    return Get.put(CustomerPortfolioController());
  }

  final RxInt selectedCategoryIndex = 0.obs;
  final RxInt selectedExperienceIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxString aboutDescription = ''.obs;
  final RxString missionDescription = ''.obs;
  final RxList<String> whyChoosePoints = <String>[].obs;

  final List<String> categories = const [
    'All',
    'Photography & Videography',
    'Music & Live Performance',
    'Professional DJ Service',
    'live Wedding Painter',
    'Professional Anchor Services',
    'Professional Magician Services',
  ];

  final Map<String, String> _serviceKeyByCategory = const <String, String>{
    'Photography & Videography': 'photo_videography',
    'Music & Live Performance': 'music_live_performance',
    'Professional DJ Service': 'professional_dj',
    'live Wedding Painter': 'live_wedding_painter',
    'Professional Anchor Services': 'professional_anchor',
    'Professional Magician Services': 'professional_magician',
  };

  final Map<String, String> _defaultPhotoByService = const <String, String>{
    'photo_videography': AppImages.photographer,
    'music_live_performance': AppImages.musician,
    'professional_dj': AppImages.dj,
    'live_wedding_painter': AppImages.weddingPlanner,
    'professional_anchor': AppImages.anchor,
    'professional_magician': AppImages.magician,
  };

  final RxMap<String, String> _photoUrlByService = <String, String>{}.obs;
  final RxMap<String, String> _videoUrlByService = <String, String>{}.obs;
  final RxList<PortfolioMediaItem> _firestoreMediaItems = <PortfolioMediaItem>[].obs;
  final RxMap<String, String> _serviceNameById = <String, String>{}.obs;
  final Map<String, Future<Uint8List?>> _videoThumbnailFutureByUrl = <String, Future<Uint8List?>>{};
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _portfolioSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _servicesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _mediaSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _reviewsSub;

  static const String defaultDemoVideoUrl = 'https://www.youtube.com/watch?v=3FP42lUN6Lg&list=RD3FP42lUN6Lg&start_radio=1&pp=oAcB';

  final RxList<PortfolioExperienceItem> experiences = <PortfolioExperienceItem>[].obs;

  static const List<PortfolioExperienceItem> _defaultExperiences = <PortfolioExperienceItem>[
    PortfolioExperienceItem(
      name: 'Tarun Jain',
      location: 'Indore, Madhya Pradesh',
      message: 'Our company portfolio showcases real projects and successful events, giving you confidence that your special moments are in experienced hands.',
      rating: 3.4,
    ),
    PortfolioExperienceItem(
      name: 'Ritika Sharma',
      location: 'Bhopal, Madhya Pradesh',
      message: 'The service quality and response time were excellent. The team handled our event smoothly and professionally.',
      rating: 4.6,
    ),
    PortfolioExperienceItem(
      name: 'Aman Verma',
      location: 'Pune, Maharashtra',
      message: 'From planning to execution, everything was very organized. We loved the final output and support.',
      rating: 4.2,
    ),
    PortfolioExperienceItem(
      name: 'Neha Gupta',
      location: 'Mumbai, Maharashtra',
      message: 'Great platform for finding reliable professionals quickly. Booking and coordination were very easy.',
      rating: 4.7,
    ),
    PortfolioExperienceItem(
      name: 'Priyansh Raj',
      location: 'Jaipur, Rajasthan',
      message: 'Truly memorable experience. The team understood our expectations and delivered beyond them.',
      rating: 4.5,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _applyDefaultContent();
    experiences.assignAll(_defaultExperiences);
    _listenPortfolioContent();
    _listenPortfolioServices();
    _listenPortfolioMedia();
    _listenTopReviews();
  }

  Future<Uint8List?> videoThumbnailFor(String videoUrl) {
    final key = videoUrl.trim();
    if (key.isEmpty) {
      return Future<Uint8List?>.value();
    }
    final youtubeThumbnail = youtubeThumbnailUrl(key);
    if (youtubeThumbnail.isNotEmpty) {
      return Future<Uint8List?>.value();
    }
    return _videoThumbnailFutureByUrl.putIfAbsent(
      key,
      () => VideoThumbnail.thumbnailData(
        video: key,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 640,
        quality: 100,
      ),
    );
  }

  String thumbnailSourceFor(String videoUrl) {
    final key = videoUrl.trim();
    if (key.isEmpty) {
      return '';
    }
    final youtube = youtubeThumbnailUrl(key);
    if (youtube.isNotEmpty) {
      return youtube;
    }
    final drive = driveThumbnailUrl(key);
    if (drive.isNotEmpty) {
      return drive;
    }
    return key;
  }

  bool isYouTubeUrl(String videoUrl) {
    final url = videoUrl.trim().toLowerCase();
    return url.contains('youtube.com/watch') ||
        url.contains('youtu.be/') ||
        url.contains('youtube.com/shorts/');
  }

  String? youtubeVideoId(String videoUrl) {
    final url = videoUrl.trim();
    if (url.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }
    if (uri.host.contains('youtu.be')) {
      final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return segment.isEmpty ? null : segment;
    }
    final videoId = uri.queryParameters['v'];
    if (videoId != null && videoId.trim().isNotEmpty) {
      return videoId.trim();
    }
    if (uri.pathSegments.contains('shorts')) {
      final index = uri.pathSegments.indexOf('shorts');
      if (index >= 0 && index + 1 < uri.pathSegments.length) {
        final segment = uri.pathSegments[index + 1].trim();
        return segment.isEmpty ? null : segment;
      }
    }
    return null;
  }

  String youtubeThumbnailUrl(String videoUrl) {
    final videoId = youtubeVideoId(videoUrl);
    if (videoId == null || videoId.isEmpty) {
      return '';
    }
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  String driveFileId(String videoUrl) {
    final uri = Uri.tryParse(videoUrl.trim());
    if (uri == null) {
      return '';
    }
    final matches = <String?>[
      uri.queryParameters['id'],
      _matchFirst(uri.path, RegExp(r'/file/d/([^/]+)')),
      _matchFirst(uri.path, RegExp(r'/d/([^/]+)')),
    ];
    for (final value in matches) {
      final candidate = (value ?? '').trim();
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }

  String driveThumbnailUrl(String videoUrl) {
    final fileId = driveFileId(videoUrl);
    if (fileId.isEmpty) {
      return '';
    }
    return 'https://drive.google.com/thumbnail?id=$fileId';
  }

  String playableVideoUrl(String videoUrl) {
    final key = videoUrl.trim();
    if (key.isEmpty) {
      return key;
    }
    if (isYouTubeUrl(key)) {
      return key;
    }
    final driveId = driveFileId(key);
    if (driveId.isNotEmpty) {
      return 'https://drive.google.com/uc?export=download&id=$driveId';
    }
    return key;
  }

  List<PortfolioMediaItem> get mediaItems {
    if (_firestoreMediaItems.isNotEmpty) {
      return _firestoreMediaItems.toList(growable: false);
    }
    final items = <PortfolioMediaItem>[];
    for (final category in categories) {
      if (category == 'All') {
        continue;
      }
      final rawServiceKey = _serviceKeyByCategory[category];
      if (rawServiceKey == null) {
        continue;
      }
      final serviceKey = _normalizeServiceKey(rawServiceKey);
      final photo = (_photoUrlByService[serviceKey] ?? '').trim();
      final video = (_videoUrlByService[serviceKey] ?? '').trim();

      final effectivePhoto = photo.isNotEmpty
          ? photo
          : (_defaultPhotoByService[serviceKey] ?? AppImages.photographer);
      final effectiveVideo = video.isNotEmpty ? video : defaultDemoVideoUrl;

      items.add(
        PortfolioMediaItem(
          category: category,
          mediaPath: effectivePhoto,
          isVideo: false,
          isNetwork: effectivePhoto.startsWith('http'),
        ),
      );
      items.add(
        PortfolioMediaItem(
          category: category,
          mediaPath: effectiveVideo,
          isVideo: true,
          isNetwork: effectiveVideo.startsWith('http'),
        ),
      );
    }
    return items;
  }

  void onCategorySelected(int index) {
    selectedCategoryIndex.value = index;
  }

  void onExperiencePageChanged(int index) {
    selectedExperienceIndex.value = index;
  }

  List<PortfolioMediaItem> get filteredMedia {
    final selected = categories[selectedCategoryIndex.value];
    if (selected == 'All') {
      return mediaItems;
    }
    return mediaItems
        .where((item) => item.category == selected)
        .toList(growable: false);
  }

  void _listenPortfolioContent() {
    _portfolioSub = _db
        .collection(ServiceCatalogPaths.portfolioContentCollection)
        .doc(ServiceCatalogPaths.portfolioSettingsDoc)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data();
            if (data == null || data.isEmpty) {
              _applyDefaultContent();
              isLoading.value = false;
              return;
            }
            _hydrateFromFirestore(data);
            isLoading.value = false;
          },
          onError: (_) {
            _applyDefaultContent();
            isLoading.value = false;
          },
        );
  }

  void _listenPortfolioServices() {
    _servicesSub = _db
        .collection(ServiceCatalogPaths.portfolioServicesCollection)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final names = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        names[(data['id'] ?? doc.id).toString()] =
            (data['serviceName'] ?? doc.id).toString();
      }
      _serviceNameById.assignAll(names);
    });
  }

  void _listenPortfolioMedia() {
    _mediaSub = _db
        .collection(ServiceCatalogPaths.portfolioMediaCollection)
        .where('isVisible', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final photos = <String, String>{};
      final videos = <String, String>{};
      final allItems = <PortfolioMediaItem>[];
      final sortedDocs = snapshot.docs.toList()
        ..sort((a, b) {
          final left = _asInt(a.data()['displayOrder']);
          final right = _asInt(b.data()['displayOrder']);
          return left.compareTo(right);
        });
      for (final doc in sortedDocs) {
        final data = doc.data();
        final serviceId = _normalizeServiceKey(
          (data['serviceId'] ?? '').toString().trim(),
        );
        final mediaType = (data['mediaType'] ?? '').toString().trim();
        final mediaUrl = (data['mediaUrl'] ?? '').toString().trim();
        if (serviceId.isEmpty || mediaUrl.isEmpty) continue;
        final category = _categoryForServiceId(serviceId);
        if (mediaType == 'video') {
          videos.putIfAbsent(serviceId, () => mediaUrl);
          allItems.add(
            PortfolioMediaItem(
              category: category,
              mediaPath: mediaUrl,
              isVideo: true,
              isNetwork: mediaUrl.startsWith('http'),
            ),
          );
        } else {
          photos.putIfAbsent(serviceId, () => mediaUrl);
          allItems.add(
            PortfolioMediaItem(
              category: category,
              mediaPath: mediaUrl,
              isVideo: false,
              isNetwork: mediaUrl.startsWith('http'),
            ),
          );
        }
      }
      _photoUrlByService.assignAll(photos);
      _videoUrlByService.assignAll(videos);
      _firestoreMediaItems.assignAll(allItems);
    });
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

  void _listenTopReviews() {
    _reviewsSub?.cancel();
    _reviewsSub = _db
        .collection(ServiceCatalogPaths.reviewsCollection)
        .orderBy('rating', descending: true)
        .limit(20)
        .snapshots()
        .listen(
          (snapshot) {
            final items = snapshot.docs
                .where((doc) => doc.data()['visible'] != false)
                .map((doc) {
                  final data = doc.data();
                  return PortfolioExperienceItem(
                    name: (data['customerName'] ?? 'Customer').toString().trim(),
                    location: (data['location'] ?? 'India').toString().trim(),
                    message: (data['comment'] ?? '').toString().trim(),
                    rating: _asDouble(data['rating']),
                  );
                })
                .where((item) => item.message.isNotEmpty && item.rating > 0)
                .take(5)
                .toList(growable: false);
            experiences.assignAll(items.isEmpty ? _defaultExperiences : items);
            if (selectedExperienceIndex.value >= experiences.length) {
              selectedExperienceIndex.value = 0;
            }
          },
          onError: (_) => experiences.assignAll(_defaultExperiences),
        );
  }

  String _categoryForServiceId(String serviceId) {
    for (final entry in _serviceKeyByCategory.entries) {
      if (entry.value == serviceId) {
        return entry.key;
      }
    }
    final customName = (_serviceNameById[serviceId] ?? '').trim();
    return customName.isEmpty ? serviceId : customName;
  }

  void _hydrateFromFirestore(Map<String, dynamic> data) {
    aboutDescription.value =
        (data['aboutUsDescription'] ?? data['aboutDescription'] ?? _defaultAboutDescription).toString().trim();
    missionDescription.value =
        (data['missionDescription'] ?? _defaultMissionDescription)
            .toString()
            .trim();

    final points = _stringList(data['whyChooseUsPoints'] ?? data['whyChoosePoints']);
    if (points.isEmpty) {
      whyChoosePoints.assignAll(_defaultWhyChoosePoints);
    } else {
      whyChoosePoints.assignAll(points);
    }

    final media = _asMap(data['media']);
    final photos = <String, String>{};
    final videos = <String, String>{};

    for (final serviceKey in _defaultPhotoByService.keys) {
      final entry = _asMap(media[serviceKey] ?? media[_legacyServiceKey(serviceKey)]);
      final photo = (entry['photoUrl'] ?? '').toString().trim();
      final video = (entry['videoUrl'] ?? '').toString().trim();
      if (photo.isNotEmpty) {
        photos[serviceKey] = photo;
      }
      if (video.isNotEmpty) {
        videos[serviceKey] = video;
      }
    }

    _photoUrlByService.assignAll(photos);
    _videoUrlByService.assignAll(videos);
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

  void _applyDefaultContent() {
    aboutDescription.value = _defaultAboutDescription;
    missionDescription.value = _defaultMissionDescription;
    whyChoosePoints.assignAll(_defaultWhyChoosePoints);
    _photoUrlByService.clear();
    _videoUrlByService.clear();
    _firestoreMediaItems.clear();
    _videoThumbnailFutureByUrl.clear();
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

  List<String> _stringList(dynamic value) {
    if (value is! List) {
      return <String>[];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  void onClose() {
    _portfolioSub?.cancel();
    _servicesSub?.cancel();
    _mediaSub?.cancel();
    _reviewsSub?.cancel();
    super.onClose();
  }

  static const String _defaultAboutDescription =
      "We are India's premier event services platform, dedicated to making your special moments truly unforgettable. With years of experience and a team of talented professionals, we bring excellence to every event.";
  static const String _defaultMissionDescription =
      'To provide seamless, professional event services that exceed expectations and create lasting memories for our clients.';
  static const List<String> _defaultWhyChoosePoints = <String>[
    'Verified and experienced professionals',
    'Transparent pricing with no hidden costs',
    '24/7 customer support',
    'Quality guaranteed on every service',
  ];
}

String? _matchFirst(String input, RegExp pattern) {
  final match = pattern.firstMatch(input);
  if (match == null || match.groupCount < 1) {
    return null;
  }
  return match.group(1);
}

double _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
