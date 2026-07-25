import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';

class AddressPreviewCard extends StatelessWidget {
  const AddressPreviewCard({
    super.key,
    required this.formattedAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    this.country = '',
  });

  final String formattedAddress;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final double? latitude;
  final double? longitude;

  @override
  Widget build(BuildContext context) {

    final hasAddress = formattedAddress.trim().isNotEmpty;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Color(0xffFCFBFF),
        borderRadius: BorderRadius.circular(ResponsiveUtility.radius(10)),
        border: Border.all(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Selected Address",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black.withValues(alpha: 0.6),
              fontSize: ResponsiveUtility.fontSize(12),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(8)),
          Text(
            hasAddress ? formattedAddress : "No location selected yet",
            style: TextStyle(
              color: hasAddress ?
              isDark ? Colors.white : Colors.black.withValues(alpha: 0.6) :
              isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6),
              fontSize: ResponsiveUtility.fontSize(12),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: ResponsiveUtility.height(10)),
          Wrap(
            spacing: ResponsiveUtility.width(8),
            runSpacing: ResponsiveUtility.width(8),
            children: [
              _InfoChip(label: "City", value: city),
              _InfoChip(label: "State", value: state),
              _InfoChip(label: "Country", value: country),
              _InfoChip(label: "Pincode", value: pincode),
              _InfoChip(
                label: "Lat",
                value: latitude == null ? "-" : latitude!.toStringAsFixed(6),
              ),
              _InfoChip(
                label: "Lng",
                value: longitude == null ? "-" : longitude!.toStringAsFixed(6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Color(0xff1C1736).withValues(alpha: 0.5) : Color(0xffF6F4FF).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),),
      ),
      child: Text(
        "$label: ${value.trim().isEmpty ? '-' : value}",
        style: TextStyle(color:isDark ? Colors.white54 : Colors.black.withValues(alpha: 0.6), fontSize: ResponsiveUtility.fontSize(12)),
      ),
    );
  }
}
