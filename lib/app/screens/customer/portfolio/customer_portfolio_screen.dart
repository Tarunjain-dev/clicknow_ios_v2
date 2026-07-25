import 'dart:typed_data';
import 'package:clicknow_version2/app/screens/customer/portfolio/getx/customer_portfolio_controller.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_constants/appImages.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomerPortfolioScreen extends StatelessWidget {
  const CustomerPortfolioScreen({super.key});

  @override
  Widget build(BuildContext context) {

    /// -- Scaling utility instance
    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    /// -- Customer portfolio controller instance
    final controller = CustomerPortfolioController.instance;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Container(
      height: double.maxFinite,
      width: double.maxFinite,
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.primaryGradient : null,
        color:  isDark ? null : Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveUtility.only(left: 14, top: 14,right: 14, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Portfolio',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(18),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(3)),
                Text(
                  'Showcasing excellence in event services',
                  style: TextStyle(
                    color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(10)),
                _aboutCard(scale, controller, isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                _missionCard(scale, controller, isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                _whyChooseCard(scale, controller, isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                Text(
                  'Our Client Experiences',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(6)),
                _experienceSlider(scale, controller, isDark),
                SizedBox(height: ResponsiveUtility.height(6)),
                _experienceIndicators(scale, controller, isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                Text(
                  'Media Gallery',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                ),
                SizedBox(height: ResponsiveUtility.height(6)),
                _categoryTabs(scale, controller, isDark),
                SizedBox(height: ResponsiveUtility.height(10)),
                _mediaGrid(scale, controller),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aboutCard(
    ScalingUtility scale,
    CustomerPortfolioController controller,
    bool isDark
  ) {
    return Obx(() {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF101430).withValues(alpha: 0.92) : Color(0xFFFCFBFF).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Color(0xFF2A3363) : Color(0xffD9D9D9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: ResponsiveUtility.only(left: 12, top: 10, right: 12, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About ClickNow',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveUtility.fontSize(14),
                    ),
                  ),
                  SizedBox(height: ResponsiveUtility.height(6)),
                  Text(
                    controller.aboutDescription.value,
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                      height: 1.35,
                      fontSize: ResponsiveUtility.fontSize(12),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: isDark ? Color(0xFF2A3363).withValues(alpha: 0.7) : Color(0xffD9D9D9),
              height: 1,
            ),
            Padding(
              padding: ResponsiveUtility.symmetric(vertical: 10, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _StatTile(value: '500+', label: 'Events'),
                  _StatTile(value: '500+', label: 'Professionals'),
                  _StatTile(value: '500+', label: 'Ratings'),
                  _StatTile(value: '20+', label: 'Cities'),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _missionCard(
    ScalingUtility scale,
    CustomerPortfolioController controller,
    bool isDark,
  ) {
    return Obx(() {
      return _simpleInfoCard(
        scale: scale,
        title: 'Our Mission',
        content: controller.missionDescription.value,
        isDark: isDark
      );
    });
  }

  Widget _whyChooseCard(
    ScalingUtility scale,
    CustomerPortfolioController controller,
    bool isDark
  ) {
    return Obx(() {
      final points = controller.whyChoosePoints;
      final content = points.isEmpty
          ? '-'
          : points.map((item) => '- $item').join('\n');
      return _simpleInfoCard(
        scale: scale,
        title: 'Why Choose Us?',
        content: content,
        isDark: isDark
      );
    });
  }

  Widget _simpleInfoCard({
    required ScalingUtility scale,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtility.only(left: 12, top: 10, right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF101430).withValues(alpha: 0.92) : Color(0xFFFCFBFF).withValues(alpha: 1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Color(0xFF2A3363) : Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.black,
              fontWeight: FontWeight.w600,
              fontSize: ResponsiveUtility.fontSize(14),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(4)),
          Text(
            content,
            style: TextStyle(
              color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
              height: 1.35,
              fontSize: ResponsiveUtility.fontSize(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _experienceSlider(
    ScalingUtility scale,
    CustomerPortfolioController controller,
    bool isDark,
  ) {
    return Obx(() {
      final experiences = controller.experiences;
      return SizedBox(
        height: ResponsiveUtility.height(118),
        child: PageView.builder(
          itemCount: experiences.length,
          onPageChanged: controller.onExperiencePageChanged,
          itemBuilder: (_, index) {
            final item = experiences[index];
            return Container(
            padding: ResponsiveUtility.all(10),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF101430).withValues(alpha: 0.95) : Color(0xFFFCFBFF).withValues(alpha: 1.0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Color(0xFF2A3363) : Color(0xFFD9D9D9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: ResponsiveUtility.width(38),
                      height: ResponsiveUtility.height(38),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF5C86A), width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(AppImages.avtar2, fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(width: ResponsiveUtility.width(8)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.black,
                              fontSize: ResponsiveUtility.fontSize(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            item.location,
                            style: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.65),
                              fontSize: ResponsiveUtility.fontSize(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.black,
                        fontSize: ResponsiveUtility.fontSize(12),
                      ),
                    ),
                    Icon(
                      Icons.star,
                      color: isDark ? Color(0xFFFFC400) : Colors.orange,
                      size: 16,
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtility.height(8)),
                Expanded(
                  child: Text(
                    '" ${item.message} "',
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.78) : Colors.black.withValues(alpha: 0.78),
                      fontSize: ResponsiveUtility.fontSize(12.5),
                      height: 1.35,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            );
          },
        ),
      );
    });
  }

  Widget _experienceIndicators(
    ScalingUtility scale,
    CustomerPortfolioController controller,
    bool isDark,
  ) {
    return Obx(
      () {
        final selectedExperienceIndex = controller.selectedExperienceIndex.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            controller.experiences.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.symmetric(horizontal: scale.getScaledWidth(2)),
              width: selectedExperienceIndex == index ? scale.getScaledWidth(22) : scale.getScaledWidth(7),
              height: scale.getScaledHeight(7),
              decoration: BoxDecoration(
                color: selectedExperienceIndex == index
                    ? const Color(0xFFD100FF)
                    : isDark ? Colors.white54 : Colors.black26,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _categoryTabs(
    ScalingUtility scale,
    CustomerPortfolioController controller,
    bool isDark,
  ) {
    return SizedBox(
      height: ResponsiveUtility.height(36),
      child: Obx(
        () {
          final selectedCategoryIndex = controller.selectedCategoryIndex.value;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.categories.length,
            separatorBuilder: (context, separatorIndex) => SizedBox(width: ResponsiveUtility.width(8)),
            itemBuilder: (context, index) {
              final isSelected = selectedCategoryIndex == index;
              return GestureDetector(
                onTap: () => controller.onCategorySelected(index),
                child: Container(
                  padding: ResponsiveUtility.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? isDark ? Color(0xFF5D10D8) : Color(0xff700095)
                        : isDark ? Color(0xFF1C1E28) : Color(0xffE3E3E3).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    controller.categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : isDark ? Colors.white : Colors.black45,
                      fontWeight: FontWeight.w600,
                      fontSize: scale.getScaledFont(10),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _mediaGrid(ScalingUtility scale, CustomerPortfolioController controller) {
    return Obx(() {
      final items = controller.filteredMedia;
      return GridView.builder(
        itemCount: items.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: scale.getScaledWidth(10),
          mainAxisSpacing: scale.getScaledHeight(10),
          childAspectRatio: 0.94,
        ),
        itemBuilder: (_, index) {
          final item = items[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.isVideo
                ? FutureBuilder<Uint8List?>(
                    future: controller.videoThumbnailFor(item.mediaPath),
                    builder: (context, snapshot) {
                      final bytes = snapshot.data;
                      return InkWell(
                        onTap: () => _openMedia(item.mediaPath),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (bytes != null && bytes.isNotEmpty)
                              Image.memory(bytes, fit: BoxFit.cover)
                            else
                              Container(
                                decoration: BoxDecoration(
                                    color: Color(0xFF1E2230).withValues(alpha: 1),
                                    image: DecorationImage(image: AssetImage(AppImages.authImage), fit: BoxFit.contain)
                                ),
                                child: Icon(
                                  Icons.videocam_rounded,
                                  color: Colors.white.withValues(alpha: 0.45),
                                  size: scale.getScaledWidth(38),
                                ),
                              ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(scale.getScaledWidth(8)),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.32),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: scale.getScaledWidth(30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : item.isNetwork
                    ? Image.network(
                        item.mediaPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _brokenMediaTile(scale),
                      )
                    : Image.asset(
                        item.mediaPath,
                        fit: BoxFit.cover,
                      ),
          );
        },
      );
    });
  }

  Widget _brokenMediaTile(ScalingUtility scale) {
    return Container(
      color: const Color(0xFF1E2230),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white.withValues(alpha: 0.7),
          size: scale.getScaledWidth(28),
        ),
      ),
    );
  }

  Future<void> _openMedia(String path) async {
    final uri = Uri.tryParse(path.trim());
    if (uri == null) {
      return;
    }
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.black,
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveUtility.fontSize(16),
          ),
        ),
        SizedBox(height: ResponsiveUtility.height(2)),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white.withValues(alpha: 0.82) : Colors.black.withValues(alpha: 0.82),
            fontWeight: FontWeight.w500,
            fontSize: ResponsiveUtility.fontSize(12),
          ),
        ),
      ],
    );
  }
}
