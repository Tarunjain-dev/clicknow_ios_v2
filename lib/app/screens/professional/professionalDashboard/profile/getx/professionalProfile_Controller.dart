import 'dart:async';

import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/professional/professionalDashboard/profile/models/professional_profile_data.dart';
import 'package:clicknow_version2/app/screens/common/auth/getx/authController.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfessionalProfileController extends GetxController {
  static ProfessionalProfileController get instance {
    if (Get.isRegistered<ProfessionalProfileController>()) {
      return Get.find<ProfessionalProfileController>();
    }
    return Get.put(ProfessionalProfileController());
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isSavingProfessionalInfo = false.obs;
  final RxBool isUploadingProfileImage = false.obs;
  final RxBool isLogoutInProgress = false.obs;
  final RxBool isDeleteRequestInProgress = false.obs;
  final Rx<ProfessionalProfileData> profile = ProfessionalProfileData.empty().obs;

  static const List<String> _generalTeamSizeOptions = <String>[
    '1-5 Members',
    '5-10 Members',
    '10-20 Members',
    '20+ Members',
  ];
  static const List<String> _musicTeamSizeOptions = <String>[
    'Solo',
    'Duo',
    'Band',
  ];

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  String? get _uid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    _listenProfile();
  }

  Future<void> onProfileImageTap() async {
    if (isUploadingProfileImage.value) {
      return;
    }

    final selectedSource = await Get.bottomSheet<ImageSource>(
      Container(
        decoration: const BoxDecoration(
          color: Color(0xFF151233),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Profile Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose image source',
                  style: TextStyle(
                    color: Color(0xFFB7BDE6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.back(result: ImageSource.camera),
                        icon: const Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Camera',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF394078)),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.back(result: ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4B176F),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );

    if (selectedSource == null) {
      return;
    }
    await _pickAndUploadProfileImage(selectedSource);
  }

  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Login Required', 'Please login again.');
      return;
    }

    try {
      isUploadingProfileImage.value = true;
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      final storagePath =
          'professional_profiles/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _firebaseStorage.ref(storagePath);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await ref.getDownloadURL();

      final now = FieldValue.serverTimestamp();
      await _db.collection('professional_profiles').doc(uid).set({
        'profileImageUrl': downloadUrl,
        'basicInfo': <String, dynamic>{
          'profileImageUrl': downloadUrl,
        },
        'updatedAt': now,
      }, SetOptions(merge: true));

      await _db.collection('users').doc(uid).set({
        'profileImageUrl': downloadUrl,
        'updatedAt': now,
      }, SetOptions(merge: true));

      AppSnackbar.success('Updated', 'Profile photo updated successfully.');
    } catch (_) {
      AppSnackbar.error(
        'Upload Failed',
        'Unable to update profile photo right now.',
      );
    } finally {
      isUploadingProfileImage.value = false;
    }
  }

  Future<void> refreshProfile({bool showMessage = false}) async {
    final uid = _uid;
    if (uid == null) {
      isLoading.value = false;
      if (showMessage) {
        AppSnackbar.error('Session Expired', 'Please login again.');
      }
      return;
    }
    isRefreshing.value = true;
    try {
      final snapshot = await _db.collection('professional_profiles').doc(uid).get();
      _applySnapshot(snapshot);
      if (showMessage) {
        AppSnackbar.success('Updated', 'Profile details refreshed.');
      }
    } catch (_) {
      if (showMessage) {
        AppSnackbar.error('Refresh Failed', 'Unable to refresh profile details.');
      }
    } finally {
      isRefreshing.value = false;
      isLoading.value = false;
    }
  }

  Future<bool> logout() async {
    if (isLogoutInProgress.value) {
      return false;
    }
    isLogoutInProgress.value = true;
    try {
      await _auth.signOut();
      AuthController.instance.resetLocalAuthState(keepGuestMode: false);
      Get.offAllNamed(AppRoutes.loginRoute);
      return true;
    } catch (_) {
      AppSnackbar.error('Logout Failed', 'Unable to logout right now.');
      return false;
    } finally {
      isLogoutInProgress.value = false;
    }
  }

  Future<bool> requestDeleteAccount() async {
    if (isDeleteRequestInProgress.value) {
      return false;
    }
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login again.');
      return false;
    }
    isDeleteRequestInProgress.value = true;
    try {
      final existing = await _db
          .collection('account_delete_requests')
          .where('uid', isEqualTo: uid)
          .where('role', isEqualTo: 'professional')
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        AppSnackbar.success(
          'Already Requested',
          'Your delete account request is already pending.',
        );
        return true;
      }

      final now = FieldValue.serverTimestamp();
      await _db.collection('account_delete_requests').add({
        'uid': uid,
        'phoneNumber': profile.value.phoneNumber,
        'fullName': profile.value.fullName,
        'role': 'professional',
        'status': 'pending',
        'requestedAt': now,
      });
      await _db.collection('users').doc(uid).set({
        'deleteRequestStatus': 'pending',
        'updatedAt': now,
      }, SetOptions(merge: true));
      AppSnackbar.success(
        'Delete Requested',
        'Your delete account request has been submitted.',
      );
      return true;
    } catch (_) {
      AppSnackbar.error(
        'Request Failed',
        'Unable to submit delete account request.',
      );
      return false;
    } finally {
      isDeleteRequestInProgress.value = false;
    }
  }

  Future<bool> updateProfessionalInformation({
    required int experienceYears,
    required String teamSize,
    required List<String> workingDays,
    required List<ProfessionalWorkingLocation> workingLocations,
    required List<ProfessionalWorkingLocation> travelPreferenceLocations,
  }) async {
    if (isSavingProfessionalInfo.value) {
      return false;
    }
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login again.');
      return false;
    }

    final safeExperienceYears = experienceYears < 0 ? 0 : experienceYears;
    final safeTeamSize = teamSize.trim();
    final currentServiceType = profile.value.serviceType;
    final validTeamSizes = _teamSizeOptionsForService(currentServiceType);
    final safeWorkingDays = workingDays
        .map((day) => day.trim())
        .where((day) => day.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final safeWorkingLocations = workingLocations
        .where((location) => location.state.trim().isNotEmpty)
        .map((location) => location.normalized())
        .where((location) => location.cities.isNotEmpty)
        .toList(growable: false);

    final safeTravelLocations = travelPreferenceLocations
        .where((location) => location.state.trim().isNotEmpty)
        .map((location) => location.normalized())
        .where((location) => location.cities.isNotEmpty)
        .toList(growable: false);

    if (safeWorkingDays.isEmpty) {
      AppSnackbar.error('Required', 'Please select available working days.');
      return false;
    }
    if (safeWorkingLocations.isEmpty) {
      AppSnackbar.error('Required', 'Please add at least one working location.');
      return false;
    }
    if (safeTeamSize.isEmpty) {
      AppSnackbar.error('Required', 'Please select team size.');
      return false;
    }
    if (validTeamSizes.isNotEmpty && !validTeamSizes.contains(safeTeamSize)) {
      AppSnackbar.error(
        'Invalid Value',
        'Please select a valid team size option.',
      );
      return false;
    }

    isSavingProfessionalInfo.value = true;
    try {
      final profileDoc = _db.collection('professional_profiles').doc(uid);
      final current = await profileDoc.get();
      final currentData = current.data() ?? <String, dynamic>{};
      final currentServices = _asMap(currentData['services']);
      final updatedQuestionnaire = _upsertTeamSizeInQuestionnaire(
        currentServices['questionnaire'],
        safeTeamSize,
        serviceType: currentServiceType,
      );
      final now = FieldValue.serverTimestamp();

      final updatePayload = <String, dynamic>{
        'professional.experienceYears': safeExperienceYears,
        'professional.teamSize': safeTeamSize,
        'professional.workingDays': safeWorkingDays,
        'professional.workingLocations': safeWorkingLocations
            .map((location) => location.toMap())
            .toList(growable: false),
        'professional.secondaryLocations': safeTravelLocations
            .map((location) => location.toMap())
            .toList(growable: false),
        if (updatedQuestionnaire != null)
          'services.questionnaire': updatedQuestionnaire,
        'updatedAt': now,
      };

      try {
        await profileDoc.update(updatePayload);
      } on FirebaseException catch (error) {
        if (error.code != 'not-found') {
          rethrow;
        }
        await profileDoc.set({
          'professional': <String, dynamic>{
            'experienceYears': safeExperienceYears,
            'teamSize': safeTeamSize,
            'workingDays': safeWorkingDays,
            'workingLocations': safeWorkingLocations
                .map((location) => location.toMap())
                .toList(growable: false),
            'secondaryLocations': safeTravelLocations
                .map((location) => location.toMap())
                .toList(growable: false),
          },
          if (updatedQuestionnaire != null)
            'services': <String, dynamic>{
              'questionnaire': updatedQuestionnaire,
            },
          'updatedAt': now,
        }, SetOptions(merge: true));
      }

      await _db.collection('users').doc(uid).set({
        'updatedAt': now,
      }, SetOptions(merge: true));

      AppSnackbar.success(
        'Saved',
        'Professional information updated successfully.',
      );
      return true;
    } catch (_) {
      AppSnackbar.error(
        'Update Failed',
        'Unable to save professional information right now.',
      );
      return false;
    } finally {
      isSavingProfessionalInfo.value = false;
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>>? _upsertTeamSizeInQuestionnaire(
    dynamic questionnaire,
    String teamSize, {
    required String serviceType,
  }) {
    final expectedLabel = _teamSizeQuestionLabelForService(serviceType);
    if (questionnaire is! List) {
      if (teamSize.isEmpty) {
        return null;
      }
      return <Map<String, dynamic>>[
        {
          'id': 'teamSize',
          'question': expectedLabel,
          'answer': teamSize,
          'inputType': 'dropdown',
        },
      ];
    }

    final parsed = questionnaire
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: true);

    var index = -1;
    for (var i = 0; i < parsed.length; i++) {
      final item = parsed[i];
      final id = (item['id'] ?? '').toString().toLowerCase().trim();
      final question = (item['question'] ?? '').toString().toLowerCase().trim();
      if (id.contains('team') || question.contains('team size')) {
        index = i;
        break;
      }
    }

    if (index >= 0) {
      parsed[index] = <String, dynamic>{
        ...parsed[index],
        'id': 'teamSize',
        'question': expectedLabel,
        'answer': teamSize,
        'inputType': 'dropdown',
      };
      return parsed;
    }
    if (teamSize.isEmpty) {
      return parsed;
    }

    parsed.add(<String, dynamic>{
      'id': 'teamSize',
      'question': expectedLabel,
      'answer': teamSize,
      'inputType': 'dropdown',
    });
    return parsed;
  }

  List<String> _teamSizeOptionsForService(String serviceType) {
    if (serviceType.trim().isEmpty) {
      return <String>[
        ..._generalTeamSizeOptions,
        ..._musicTeamSizeOptions,
      ];
    }
    if (_isMusicService(serviceType)) {
      return _musicTeamSizeOptions;
    }
    return _generalTeamSizeOptions;
  }

  bool _isMusicService(String value) {
    final normalized = value.toLowerCase().trim();
    return normalized.contains('music');
  }

  String _teamSizeQuestionLabelForService(String serviceType) {
    if (_isMusicService(serviceType)) {
      return 'What is your team size (solo/duo/band)?';
    }
    return 'What is your team size?';
  }

  void _listenProfile() {
    final uid = _uid;
    if (uid == null) {
      isLoading.value = false;
      return;
    }

    _profileSub = _db.collection('professional_profiles').doc(uid).snapshots().listen(
      (snapshot) {
        isLoading.value = false;
        _applySnapshot(snapshot);
      },
      onError: (_) {
        isLoading.value = false;
        AppSnackbar.error(
          'Fetch Failed',
          'Unable to load professional profile right now.',
        );
      },
    );
  }

  void _applySnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists) {
      return;
    }
    final parsed = ProfessionalProfileData.fromMap(
      uid: snapshot.id,
      map: snapshot.data() ?? <String, dynamic>{},
    );
    profile.value = parsed;
  }

  @override
  void onClose() {
    _profileSub?.cancel();
    super.onClose();
  }
}
