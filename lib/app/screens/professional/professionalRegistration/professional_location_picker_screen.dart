import 'dart:async';

import 'package:clicknow_version2/app/services/location_service.dart';
import 'package:clicknow_version2/app/services/maps_service.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProfessionalLocationPickerScreen extends StatefulWidget {
  const ProfessionalLocationPickerScreen({
    super.key,
    required this.initialCenterLatitude,
    required this.initialCenterLongitude,
    this.initialSelection,
  });

  final double initialCenterLatitude;
  final double initialCenterLongitude;
  final AddressSelection? initialSelection;

  @override
  State<ProfessionalLocationPickerScreen> createState() =>
      _ProfessionalLocationPickerScreenState();
}

class _ProfessionalLocationPickerScreenState
    extends State<ProfessionalLocationPickerScreen> {
  final MapsService _mapsService = MapsService.instance;
  final LocationService _locationService = LocationService.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;
  Timer? _searchDebounce;

  List<PlaceSuggestion> _suggestions = const <PlaceSuggestion>[];
  bool _isSearching = false;
  bool _isResolvingAddress = false;
  bool _isFetchingCurrentLocation = false;
  int _activeSearchRequestId = 0;
  int _activeResolveRequestId = 0;

  AddressSelection? _selectedAddress;
  LatLng? _selectedMarker;
  late LatLng _cameraTarget;
  double _cameraZoom = 15;

  @override
  void initState() {
    super.initState();
    _cameraTarget = LatLng(
      widget.initialCenterLatitude,
      widget.initialCenterLongitude,
    );

    final initialSelection = widget.initialSelection;
    if (initialSelection != null) {
      _selectedAddress = initialSelection;
      _selectedMarker = LatLng(
        initialSelection.latitude,
        initialSelection.longitude,
      );
      _cameraTarget = _selectedMarker!;
      _cameraZoom = 16;
      _searchController.text = initialSelection.formattedAddress;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _onSearchChanged(String input) {
    _searchDebounce?.cancel();
    final query = input.trim();

    if (query.isEmpty) {
      _activeSearchRequestId++;
      setState(() {
        _suggestions = const <PlaceSuggestion>[];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final requestId = ++_activeSearchRequestId;
      setState(() {
        _isSearching = true;
      });

      try {
        final suggestions = await _mapsService.fetchPlaceSuggestions(query);
        if (!mounted || requestId != _activeSearchRequestId) {
          return;
        }
        if (_searchController.text.trim() != query) {
          return;
        }
        setState(() {
          _suggestions = suggestions;
        });
      } catch (_) {
        if (!mounted || requestId != _activeSearchRequestId) {
          return;
        }
        setState(() {
          _suggestions = const <PlaceSuggestion>[];
        });
        _showMessage('Unable to fetch place suggestions right now.');
      } finally {
        if (mounted &&
            requestId == _activeSearchRequestId &&
            _searchController.text.trim() == query) {
          setState(() {
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<void> _onSuggestionTap(PlaceSuggestion suggestion) async {
    _searchFocusNode.unfocus();
    setState(() {
      _suggestions = const <PlaceSuggestion>[];
      _isSearching = false;
    });

    final requestId = ++_activeResolveRequestId;
    setState(() {
      _isResolvingAddress = true;
    });
    try {
      final details = await _mapsService.getPlaceDetails(suggestion.placeId);
      if (!mounted || requestId != _activeResolveRequestId) {
        return;
      }
      if (details == null) {
        _showMessage('Unable to resolve selected place.');
        return;
      }
      _applySelection(details, animateCamera: true, targetZoom: 16);
    } catch (_) {
      if (!mounted || requestId != _activeResolveRequestId) {
        return;
      }
      _showMessage('Unable to fetch selected place details.');
    } finally {
      if (mounted && requestId == _activeResolveRequestId) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  Future<void> _resolveFromCoordinates({
    required double latitude,
    required double longitude,
    bool animateCamera = false,
  }) async {
    final requestId = ++_activeResolveRequestId;
    setState(() {
      _isResolvingAddress = true;
    });

    try {
      final reverseResult = await _mapsService.reverseGeocode(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted || requestId != _activeResolveRequestId) {
        return;
      }

      final selection =
          reverseResult ??
          AddressSelection(
            formattedAddress:
                'Pinned location (${latitude.toStringAsFixed(6)}, '
                '${longitude.toStringAsFixed(6)})',
            state: '',
            city: '',
            pincode: '',
            latitude: latitude,
            longitude: longitude,
          );

      _applySelection(selection, animateCamera: animateCamera);
    } catch (_) {
      if (!mounted || requestId != _activeResolveRequestId) {
        return;
      }
      _showMessage('Unable to resolve address for selected map point.');
    } finally {
      if (mounted && requestId == _activeResolveRequestId) {
        setState(() {
          _isResolvingAddress = false;
        });
      }
    }
  }

  void _applySelection(
    AddressSelection selection, {
    bool animateCamera = false,
    double? targetZoom,
  }) {
    final marker = LatLng(selection.latitude, selection.longitude);
    final zoom = targetZoom ?? _cameraZoom;

    setState(() {
      _selectedAddress = selection;
      _selectedMarker = marker;
      _cameraTarget = marker;
      _cameraZoom = zoom;
      _searchController.text = selection.formattedAddress;
      _suggestions = const <PlaceSuggestion>[];
      _isSearching = false;
    });

    if (animateCamera && _mapController != null) {
      unawaited(
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(marker, zoom)),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isFetchingCurrentLocation) {
      return;
    }
    setState(() {
      _isFetchingCurrentLocation = true;
    });

    try {
      final permission = await _locationService.ensurePermission();
      if (permission == LocationPermissionState.serviceDisabled) {
        _showMessage('Please enable location services and try again.');
        return;
      }
      if (permission == LocationPermissionState.denied) {
        _showMessage(
          'Location permission is required to fetch current location.',
        );
        return;
      }
      if (permission == LocationPermissionState.deniedForever) {
        _showMessage('Enable location permission from app settings.');
        return;
      }

      final coordinate = await _locationService.getCurrentLocation();
      if (coordinate == null) {
        _showMessage('Unable to fetch current location coordinates.');
        return;
      }

      await _resolveFromCoordinates(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        animateCamera: true,
      );
    } on TimeoutException {
      _showMessage('Current location lookup timed out. Please try again.');
    } catch (_) {
      _showMessage('Unable to fetch your current location right now.');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingCurrentLocation = false;
        });
      }
    }
  }

  void _pinCurrentCameraCenter() {
    _searchFocusNode.unfocus();
    setState(() {
      _suggestions = const <PlaceSuggestion>[];
      _isSearching = false;
    });
    unawaited(
      _resolveFromCoordinates(
        latitude: _cameraTarget.latitude,
        longitude: _cameraTarget.longitude,
      ),
    );
  }

  void _onSaveLocation() {
    final selected = _selectedAddress;
    if (selected == null) {
      _showMessage('Please select a location first.');
      return;
    }
    Navigator.of(context).pop(selected);
  }

  String _coordinateText() {
    final marker = _selectedMarker;
    final lat = (marker?.latitude ?? _cameraTarget.latitude).toStringAsFixed(6);
    final lng = (marker?.longitude ?? _cameraTarget.longitude).toStringAsFixed(
      6,
    );
    return 'Lat: $lat, Lng: $lng, Zoom: ${_cameraZoom.toStringAsFixed(1)}';
  }

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    if (!_mapsService.isApiKeyConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Location')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Google Maps API key is missing.\n'
              'Please set ApiConstants.googleMapsApiKey.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.primaryColor : Color(0xff751097),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text('Select Location', style: TextStyle(fontSize: ResponsiveUtility.fontSize(18), color: Colors.white, fontWeight: FontWeight.bold),),
        actions: [
          TextButton.icon(
            onPressed: _selectedAddress == null || _isResolvingAddress ? null : _onSaveLocation,
            icon: Icon(Icons.save, color: Colors.white, size: 16,),
            label: Text('Save', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: ResponsiveUtility.fontSize(16)),),
          ),
          SizedBox(width: ResponsiveUtility.width(4)),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _cameraTarget,
              zoom: _cameraZoom,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            onCameraMove: (position) {
              _cameraTarget = position.target;
              _cameraZoom = position.zoom;
            },
            onTap: (point) {
              _searchFocusNode.unfocus();
              setState(() {
                _suggestions = const <PlaceSuggestion>[];
                _isSearching = false;
              });
              unawaited(
                _resolveFromCoordinates(
                  latitude: point.latitude,
                  longitude: point.longitude,
                ),
              );
            },
            markers: _selectedMarker == null
                ? const <Marker>{}
                : <Marker>{
                    Marker(
                      markerId: const MarkerId('selected_location'),
                      position: _selectedMarker!,
                      draggable: true,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                      onDragEnd: (position) {
                        unawaited(
                          _resolveFromCoordinates(
                            latitude: position.latitude,
                            longitude: position.longitude,
                          ),
                        );
                      },
                    ),
                  },
            onMapCreated: (controller) {
              _mapController = controller;
              if (_selectedMarker != null) {
                unawaited(
                  controller.moveCamera(
                    CameraUpdate.newLatLngZoom(_selectedMarker!, _cameraZoom),
                  ),
                );
              }
            },
          ),

          /// -- Ignore pointer
          IgnorePointer(
            child: Center(
              child: Container(
                padding: ResponsiveUtility.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_location_alt_outlined,
                  color: Colors.white70,
                  size: 26,
                ),
              ),
            ),
          ),

          /// -- Search Bar
          Positioned(
            left: ResponsiveUtility.width(12),
            right: ResponsiveUtility.width(12),
            top: ResponsiveUtility.height(12),
            child: Column(
              children: [
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search place',
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),),
                      suffixIcon: _searchController.text.trim().isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              icon: Icon(Icons.close),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black26,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            suggestion.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _onSuggestionTap(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          /// -- Bottom address box
          Positioned(
            left: ResponsiveUtility.width(12),
            right: ResponsiveUtility.width(12),
            bottom: ResponsiveUtility.height(12),
            child: Material(
              color: isDark ? Color(0xff11162A).withValues(alpha: 0.95) : Color(0xffFCFBFF),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: ResponsiveUtility.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAddress?.formattedAddress ?? 'Tap on the map, search a place, or pin the current center.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6)),
                    ),
                    SizedBox(height: ResponsiveUtility.height(6),),
                    Text(
                      _coordinateText(),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6)),
                    ),
                    SizedBox(height: ResponsiveUtility.height(10)),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isResolvingAddress ? null : _pinCurrentCameraCenter,
                            icon: Icon(Icons.center_focus_strong),
                            label: Text('Pin Center'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                              side: BorderSide(color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6)),
                            ),
                          ),
                        ),
                        SizedBox(width: ResponsiveUtility.width(8)),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isResolvingAddress || _isFetchingCurrentLocation ? null : _useCurrentLocation,
                            icon: _isFetchingCurrentLocation
                                ? SizedBox(
                                    width: ResponsiveUtility.width(16),
                                    height: ResponsiveUtility.height(16),
                                    child: CircularProgressIndicator(strokeWidth: 2,),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(
                              _isFetchingCurrentLocation
                                  ? 'Locating...'
                                  : 'Current',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                              side: BorderSide(color: isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveUtility.height(8)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedAddress == null || _isResolvingAddress ? null : _onSaveLocation,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Save Location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isResolvingAddress)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: ResponsiveUtility.symmetric(vertical: 6),
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
