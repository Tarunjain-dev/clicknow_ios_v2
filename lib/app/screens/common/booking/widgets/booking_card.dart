import 'package:flutter/material.dart';

enum UserRole { customer, professional, admin }

class BookingCardData {
  const BookingCardData({
    required this.serviceName,
    required this.dateTimeLabel,
    required this.priceLabel,
    required this.professionalName,
    required this.statusLabel,
    required this.statusColor,
  });

  final String serviceName;
  final String dateTimeLabel;
  final String priceLabel;
  final String professionalName;
  final String statusLabel;
  final Color statusColor;
}

class BookingCard extends StatelessWidget {
  const BookingCard({
    required this.booking,
    required this.role,
    super.key,
    this.onTap,
  });

  final BookingCardData booking;
  final UserRole role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141337).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2C2F63)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: booking.statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: booking.statusColor),
                    ),
                    child: Text(
                      booking.statusLabel,
                      style: TextStyle(
                        color: booking.statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                booking.dateTimeLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                booking.professionalName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                booking.priceLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
