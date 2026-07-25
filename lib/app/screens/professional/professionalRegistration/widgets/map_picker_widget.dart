import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerWidget extends StatefulWidget {
  const MapPickerWidget({
    super.key,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.isResolvingAddress,
    required this.onLocationChanged,
    required this.onConfirmLocation,
    required this.canConfirmLocation,
    required this.showMap,
    required this.fallbackMessage,
    this.onOpenExpandedMap,
  });

  final double centerLatitude;
  final double centerLongitude;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final bool isResolvingAddress;
  final Future<void> Function(double latitude, double longitude)
  onLocationChanged;
  final VoidCallback onConfirmLocation;
  final bool canConfirmLocation;
  final bool showMap;
  final String fallbackMessage;
  final VoidCallback? onOpenExpandedMap;

  @override
  State<MapPickerWidget> createState() => _MapPickerWidgetState();
}

class _MapPickerWidgetState extends State<MapPickerWidget> {
  GoogleMapController? _mapController;
  LatLng? _lastAnimatedTarget;

  @override
  void didUpdateWidget(covariant MapPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final current = _selectedLatLng;
    if (current == null || _mapController == null) {
      return;
    }
    if (_lastAnimatedTarget != null &&
        _isSamePosition(_lastAnimatedTarget!, current)) {
      return;
    }
    _lastAnimatedTarget = current;
    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(current, 16));
  }

  LatLng? get _selectedLatLng {
    final lat = widget.selectedLatitude;
    final lng = widget.selectedLongitude;
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {

    final markerLocation = _selectedLatLng;

    return SizedBox(
      height: ResponsiveUtility.height(300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (widget.showMap)
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.centerLatitude, widget.centerLongitude),
                  zoom: 16,
                ),
                zoomControlsEnabled: true,
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
                onTap: (point) => widget.onLocationChanged(point.latitude, point.longitude),
                markers: markerLocation == null
                    ? <Marker>{}
                    : <Marker>{
                        Marker(
                          markerId: const MarkerId('selected_location'),
                          position: markerLocation,
                          draggable: true,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                          onDragEnd: (position) => widget.onLocationChanged(
                            position.latitude,
                            position.longitude,
                          ),
                        ),
                      },
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (markerLocation != null) {
                    _lastAnimatedTarget = markerLocation;
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(markerLocation, 16),
                    );
                  }
                },
              )
            else
              Container(
                color: const Color(0xff121731),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.fallbackMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            if (widget.isResolvingAddress)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            if (widget.onOpenExpandedMap != null)
              Positioned(
                top: 12,
                right: 12,
                child: ElevatedButton.icon(
                  onPressed: widget.onOpenExpandedMap,
                  icon: const Icon(Icons.open_in_full),
                  label: const Text("Open Large Map"),
                ),
              ),
            Positioned(
              right: 12,
              bottom: 12,
              child: ElevatedButton.icon(
                onPressed: widget.canConfirmLocation
                    ? widget.onConfirmLocation
                    : null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Confirm Location"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSamePosition(LatLng a, LatLng b) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
  }
}
