import 'dart:async';
import 'package:clicknow_version2/app/services/service_catalog_paths.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/app_snackbar.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AvailabilityScheduleScreen extends StatefulWidget {
  const AvailabilityScheduleScreen({super.key});

  @override
  State<AvailabilityScheduleScreen> createState() => _AvailabilityScheduleScreenState();
}

class _AvailabilityScheduleScreenState extends State<AvailabilityScheduleScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  final Set<String> _bookedDateKeys = <String>{};
  final Set<String> _savedUnavailableDateKeys = <String>{};
  final Set<String> _draftUnavailableDateKeys = <String>{};
  final Map<String, Set<String>> _bookedBySource = <String, Set<String>>{};

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _bookingSubs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasLocalChanges = false;
  bool _isProfileLoaded = false;
  final Set<String> _pendingBookingSources = <String>{};

  String? get _uid => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _bindProfileAvailability();
    _bindBookedDates();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    for (final sub in _bookingSubs) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    /// -- Scaling utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    return Container(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color: isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              /// -- Header section
              _header(scale,isDark),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xffB629FF),),
                      )
                    : ListView(
                        padding: ResponsiveUtility.only(bottom: 16, top: 12, right: 14, left: 14),
                        children: [
                          _calendarCard(scale, isDark),
                          SizedBox(height: ResponsiveUtility.height(10)),
                          _legendCard(scale, isDark),
                          SizedBox(height: scale.getScaledHeight(10)),
                          SizedBox(
                            height: ResponsiveUtility.height(44),
                            child: ElevatedButton(
                              onPressed: _isSaving || !_hasLocalChanges ? null : _saveAvailability,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                                foregroundColor: isDark ? Color(0xff4A176F) : Colors.white,
                                disabledBackgroundColor: isDark ? Colors.white.withValues(alpha: 0.42) : Colors.black.withValues(alpha: 0.2),
                                disabledForegroundColor: isDark ? Color(0xff4A176F).withValues(alpha: 0.5) :  Colors.black.withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isSaving
                                  ? SizedBox(
                                      height: ResponsiveUtility.height(20),
                                      width: ResponsiveUtility.fontSize(20),
                                      child: const CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xff4A176F),),
                                    )
                                  : Text(
                                      _hasLocalChanges ? 'Save Availability' : 'No Changes',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: ResponsiveUtility.fontSize(18),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(ScalingUtility scale, bool isDark) {
    return Container(
      padding: ResponsiveUtility.only(bottom: 10, top: 8, right: 12, left: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9), width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              'Availability & Schedule',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: ResponsiveUtility.fontSize(18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendarCard(ScalingUtility scale, bool isDark) {

    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month,);
    final firstWeekDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final leading = firstWeekDay % 7;
    const weekLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Container(
      padding: ResponsiveUtility.only(bottom: 12, top: 10, right: 12, left: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1A1436) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _monthNavButton(
                scale: scale,
                isDark: isDark,
                icon: Icons.chevron_left_rounded,
                onTap: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                      1,
                    );
                  });
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthLabel(_focusedMonth.month)} ${_focusedMonth.year}',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtility.fontSize(16),
                    ),
                  ),
                ),
              ),
              _monthNavButton(
                scale: scale,
                isDark: isDark,
                icon: Icons.chevron_right_rounded,
                onTap: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtility.height(8)),
          Row(
            children: weekLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                          fontSize: ResponsiveUtility.fontSize(16),
                        ),
                      ),
                    ),
                  ),
                ).toList(growable: false),
          ),
          SizedBox(height: ResponsiveUtility.height(8)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leading + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < leading) {
                return const SizedBox.shrink();
              }
              final day = index - leading + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
              final key = _toDateKey(date);
              final isBooked = _bookedDateKeys.contains(key);
              final isUnavailable = _draftUnavailableDateKeys.contains(key);

              Color bgColor = isDark ? Color(0xff3C3B60) : Color(0xffDFDFDF).withValues(alpha: 0.1);
              Color borderColor = isDark ? Color(0xff8087A9) : Color(0xff848484).withValues(alpha: 0.2);
              if (isBooked) {
                bgColor = isDark ? Color(0xff1457B9) : Color(0xffA6C3FF).withValues(alpha: 0.3);
                borderColor = isDark ? Color(0xff1B78FF) : Color(0xff0066FF);
              } else if (isUnavailable) {
                bgColor = isDark ? Color(0xff7F2138) : Color(0xffFD9196).withValues(alpha: 0.3);
                borderColor = isDark ? Color(0xffE03452) : Color(0xffFF0005);
              }

              return InkWell(
                onTap: isBooked ? null : () => _toggleUnavailable(key),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: ResponsiveUtility.fontSize(18),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _monthNavButton({
    required ScalingUtility scale,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: ResponsiveUtility.height(28),
        width: ResponsiveUtility.width(28),
        decoration: BoxDecoration(
          color: isDark ? Color(0xff2A2D53) : Color(0xffE9E9E9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white : Colors.black, size: 18),
      ),
    );
  }

  Widget _legendCard(ScalingUtility scale, bool isDark) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.only(bottom: 12, top: 10, right: 12, left: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1A1436) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xff2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: scale.getScaledFont(16),
            ),
          ),
          SizedBox(height: scale.getScaledHeight(10)),
          _legendRow(scale, isDark ? Color(0xff1457B9) : Color(0xffA6C3FF), 'Booked Dates', isDark),
          SizedBox(height: scale.getScaledHeight(8)),
          _legendRow(scale, isDark ? Color(0xff7F2138) : Color(0xffFD9196), 'Unavailable (Marked by you)', isDark),
          SizedBox(height: scale.getScaledHeight(8)),
          _legendRow(scale, isDark ? Color(0xff3C3B60) : Color(0xffDFDFDF), 'Available', isDark),
        ],
      ),
    );
  }

  Widget _legendRow(ScalingUtility scale, Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          height: ResponsiveUtility.height(24),
          width: ResponsiveUtility.width(24),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 1.0)),
          ),
        ),
        SizedBox(width: ResponsiveUtility.width(8)),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.9),
            fontSize: ResponsiveUtility.fontSize(14),
          ),
        ),
      ],
    );
  }

  void _bindProfileAvailability() {
    final uid = _uid;
    if (uid == null) {
      setState(() {
        _isProfileLoaded = true;
      });
      _syncLoadingState();
      return;
    }

    _profileSub = _db
        .collection('professional_profiles')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data() ?? <String, dynamic>{};
            final availability = _asMap(data['availability']);
            final nestedUnavailable = _readDateKeys(availability['unavailableDates']);
            final legacyUnavailable =
                _readDateKeys(data['availability.unavailableDates']);
            final unavailable = availability.containsKey('unavailableDates')
                ? nestedUnavailable
                : legacyUnavailable;
            if (!mounted) return;
            setState(() {
              _savedUnavailableDateKeys
                ..clear()
                ..addAll(unavailable);
              if (!_hasLocalChanges) {
                _draftUnavailableDateKeys
                  ..clear()
                  ..addAll(unavailable);
              }
              _isProfileLoaded = true;
            });
            _syncLoadingState();
          },
          onError: (_) {
            if (!mounted) return;
            setState(() {
              _isProfileLoaded = true;
            });
            _syncLoadingState();
            AppSnackbar.error(
              'Fetch Failed',
              'Unable to load your saved availability.',
            );
          },
        );
  }

  void _bindBookedDates() {
    final uid = _uid;
    if (uid == null) {
      _syncLoadingState(bookingsReady: true);
      return;
    }

    final sourceQueries = <String, Query<Map<String, dynamic>>>{
      'professionalId': _db
          .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
          .where('professionalId', isEqualTo: uid),
      'assignedProfessionalId': _db
          .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
          .where('assignedProfessionalId', isEqualTo: uid),
      'assignedToProfessionalId': _db
          .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
          .where('assignedToProfessionalId', isEqualTo: uid),
      'professional.uid': _db
          .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
          .where('professional.uid', isEqualTo: uid),
      'assignment.professionalId': _db
          .collection(ServiceCatalogPaths.customerBookingRequestsCollection)
          .where('assignment.professionalId', isEqualTo: uid),
    };

    _pendingBookingSources
      ..clear()
      ..addAll(sourceQueries.keys);

    for (final entry in sourceQueries.entries) {
      final source = entry.key;
      final query = entry.value;
      final sub = query.snapshots().listen(
        (snapshot) {
          final bookedKeys = <String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            if (_isDeliveryCompleted(data)) {
              continue;
            }
            final eventDate = _asDateTime(data['eventDate']);
            if (eventDate == null) {
              continue;
            }
            bookedKeys.add(_toDateKey(eventDate));
          }
          _bookedBySource[source] = bookedKeys;
          _pendingBookingSources.remove(source);
          _rebuildBookedDates();
          _syncLoadingState();
        },
        onError: (_) {
          _bookedBySource.remove(source);
          _pendingBookingSources.remove(source);
          _rebuildBookedDates();
          _syncLoadingState();
        },
      );
      _bookingSubs.add(sub);
    }
  }

  void _rebuildBookedDates() {
    if (!mounted) return;
    final merged = <String>{};
    for (final keys in _bookedBySource.values) {
      merged.addAll(keys);
    }
    setState(() {
      _bookedDateKeys
        ..clear()
        ..addAll(merged);
    });
  }

  void _syncLoadingState({bool? bookingsReady}) {
    final ready = bookingsReady ?? _pendingBookingSources.isEmpty;
    if (!mounted) return;
    setState(() {
      _isLoading = !(_isProfileLoaded && ready);
    });
  }

  void _toggleUnavailable(String key) {
    setState(() {
      if (_draftUnavailableDateKeys.contains(key)) {
        _draftUnavailableDateKeys.remove(key);
      } else {
        _draftUnavailableDateKeys.add(key);
      }
      _hasLocalChanges = !_setEquals(
        _draftUnavailableDateKeys,
        _savedUnavailableDateKeys,
      );
    });
  }

  Future<void> _saveAvailability() async {
    final uid = _uid;
    if (uid == null) {
      AppSnackbar.error('Session Expired', 'Please login again.');
      return;
    }
    if (_isSaving || !_hasLocalChanges) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final unavailable = _draftUnavailableDateKeys.toList(growable: false)
        ..sort();
      final now = FieldValue.serverTimestamp();
      await _db.collection('professional_profiles').doc(uid).set({
        'availability': {
          'unavailableDates': unavailable,
          'updatedAt': now,
        },
        'updatedAt': now,
      }, SetOptions(merge: true));

      await _db.collection('users').doc(uid).set({
        'professionalUnavailableDates': unavailable,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _savedUnavailableDateKeys
          ..clear()
          ..addAll(unavailable);
        _hasLocalChanges = false;
      });
      AppSnackbar.success('Saved', 'Availability updated successfully.');
    } catch (_) {
      AppSnackbar.error(
        'Save Failed',
        'Unable to save availability right now. Please retry.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isDeliveryCompleted(Map<String, dynamic> data) {
    final status = (data['bookingStatus'] ?? '')
        .toString()
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_');
    final stage = (data['bookingStage'] ?? '')
        .toString()
        .toLowerCase()
        .trim()
        .replaceAll(' ', '_');
    final canceled = (data['isCanceled'] as bool?) ?? false;
    if (canceled) {
      return true;
    }
    const completedStatuses = <String>{
      'completed',
      'delivered',
      'canceled',
      'cancelled',
    };
    const completedStages = <String>{
      'completed',
      'delivered',
      'event_date',
      'canceled',
      'cancelled',
    };
    return completedStatuses.contains(status) || completedStages.contains(stage);
  }

  Set<String> _readDateKeys(dynamic raw) {
    if (raw is! List) {
      return <String>{};
    }
    final keys = <String>{};
    for (final item in raw) {
      final date = _asDateTime(item);
      if (date != null) {
        keys.add(_toDateKey(date));
        continue;
      }
      final text = item.toString().trim();
      if (text.isNotEmpty) {
        keys.add(text);
      }
    }
    return keys;
  }

  DateTime? _asDateTime(dynamic raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }

  String _toDateKey(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    return _dateKeyFormat.format(date);
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

  bool _setEquals(Set<String> left, Set<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final value in left) {
      if (!right.contains(value)) {
        return false;
      }
    }
    return true;
  }

  String _monthLabel(int month) {
    const months = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final safeIndex = month < 1
        ? 0
        : month > 12
            ? 11
            : month - 1;
    return months[safeIndex];
  }
}
