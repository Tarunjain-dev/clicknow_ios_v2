import 'package:clicknow_version2/app/screens/customer/home/services/widgets/customer_service_detail_template.dart';
import 'package:flutter/material.dart';

class ProfessionalDjServiceScreen extends StatelessWidget {
  const ProfessionalDjServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomerServiceDetailScreen(
      config: CustomerServiceDetailConfigs.dj,
    );
  }
}
