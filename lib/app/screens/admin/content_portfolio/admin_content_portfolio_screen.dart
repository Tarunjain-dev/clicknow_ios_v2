import 'package:clicknow_version2/app/routes/appRoutes.dart';
import 'package:clicknow_version2/app/screens/admin/content_portfolio/getx/admin_content_portfolio_controller.dart';
import 'package:clicknow_version2/app/screens/admin/widgets/admin_drawer.dart';
import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/scale_utility.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminContentPortfolioScreen extends StatelessWidget {
  const AdminContentPortfolioScreen({super.key});

  static const Color _bgTop = Color(0xff080212);
  static const Color _bgMid = Color(0xff18072D);
  static const Color _panel = Color(0xff15112A);
  static const Color _panelSoft = Color(0xff1E1838);
  static const Color _border = Color(0xff332B5A);
  static const Color _primary = Color(0xffB629FF);
  static const Color _accent = Color(0xff32E6A4);
  static const Color _muted = Color(0xffAFA9D4);

  @override
  Widget build(BuildContext context) {

    final scale = ScalingUtility(context: context)..setCurrentDeviceSize();

    final controller = Get.isRegistered<AdminContentPortfolioController>() ? Get.find<AdminContentPortfolioController>() : Get.put(AdminContentPortfolioController());

    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AdminDrawer(
          scale: scale,
          activeRoute: AppRoutes.adminContentPortfolioRoute,
        ),
        body: Column(
          children: <Widget>[
            _topBar(context, scale, controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: _primary),
                  );
                }
        
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    scale.getScaledWidth(14),
                    scale.getScaledHeight(12),
                    scale.getScaledWidth(14),
                    scale.getScaledHeight(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _heroSummary(scale, controller),
                      SizedBox(height: scale.getScaledHeight(14)),
                      _sectionShell(
                        title: 'Company Story',
                        subtitle: 'Text shown on the customer portfolio page.',
                        icon: Icons.article_outlined,
                        child: Column(
                          children: <Widget>[
                            _textAreaCard(
                              title: 'About ClickNow',
                              hint: 'Write about your company',
                              controller: controller.aboutController,
                              minLines: 4,
                            ),
                            const SizedBox(height: 12),
                            _textAreaCard(
                              title: 'Our Mission',
                              hint: 'Write your mission statement',
                              controller: controller.missionController,
                              minLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _textAreaCard(
                              title: 'Why Choose Us?',
                              hint: 'One point per line',
                              controller: controller.whyChooseController,
                              minLines: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: scale.getScaledHeight(14)),
                      _sectionShell(
                        title: 'Service Media Library',
                        subtitle: 'Upload service-wise customer portfolio photos and videos.',
                        icon: Icons.collections_outlined,
                        child: _serviceMediaGrid(
                          context: context,
                          scale: scale,
                          controller: controller,
                        ),
                      ),
                      SizedBox(height: scale.getScaledHeight(14)),
                      _sectionShell(
                        title: 'Detailed Media Manager',
                        subtitle: 'Edit captions, thumbnails, order, visibility and delete media.',
                        icon: Icons.tune_rounded,
                        child: _mediaManager(context, scale, controller),
                      ),
                      SizedBox(height: scale.getScaledHeight(16)),
                      _stickySaveButton(controller),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(
    BuildContext context,
    ScalingUtility scale,
    AdminContentPortfolioController controller,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        scale.getScaledWidth(10),
        scale.getScaledHeight(60),
        scale.getScaledWidth(12),
        scale.getScaledHeight(10),
      ),
      decoration: BoxDecoration(
        color: Color(0xff6F18A8),
        border: const Border(bottom: BorderSide(color: Color(0xffD9D9D9), width: 1)),
      ),
      child: Row(
        children: <Widget>[
          Builder(
            builder: (context) => IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              splashRadius: 22,
              icon: Icon(
                Icons.menu_rounded,
                color: Colors.white,
                size: scale.getScaledWidth(28),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Content & Portfolio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: scale.getScaledFont(16),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Media & Gallery Management',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: scale.getScaledFont(11),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => FilledButton.icon(
              onPressed: controller.isSaving.value ? null : controller.saveContent,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff4B176F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: controller.isSaving.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroSummary(
    ScalingUtility scale,
    AdminContentPortfolioController controller,
  ) {
    return Obx(() {
      final totalPhotos = controller.photoCountByService.values.fold<int>(0, (sum, value) => sum + value,);
      final totalVideos = controller.videoCountByService.values.fold<int>(0, (sum, value) => sum + value,);
      final visibleMedia = controller.mediaItems.where((item) => item.isVisible).length;
      final hiddenMedia = controller.mediaItems.where((item) => !item.isVisible).length;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(scale.getScaledWidth(16)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Color(0xffF6F4FF),
          border: Border.all(color: const Color(0xffD9D9D9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_mosaic_outlined,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Portfolio Control Room',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Curate the visuals and text customers see before they book.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _metricTile('Services', '${controller.services.length}'),
                _metricTile('Photos', '$totalPhotos'),
                _metricTile('Videos', '$totalVideos'),
                _metricTile('Visible', '$visibleMedia'),
                _metricTile('Hidden', '$hiddenMedia'),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _metricTile(String label, String value) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _sectionShell({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: _primary.withValues(alpha: 0.9)),
                ),
                child: Icon(icon, color: _primary.withValues(alpha: 0.9), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _textAreaCard({
    required String title,
    required String hint,
    required TextEditingController controller,
    required int minLines,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: minLines + 2,
            minLines: minLines,
            style: const TextStyle(color: Colors.black, height: 1.35),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xffD9D9D9)),
              filled: true,
              fillColor: const Color(0xffF6F4FF),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xffD9D9D9)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xffD9D9D9)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serviceMediaGrid({
    required BuildContext context,
    required ScalingUtility scale,
    required AdminContentPortfolioController controller,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 760;
        final cardWidth = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.services
              .map(
                (service) => SizedBox(
                  width: cardWidth,
                  child: _serviceMediaCard(
                    scale: scale,
                    controller: controller,
                    service: service,
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _serviceMediaCard({
    required ScalingUtility scale,
    required AdminContentPortfolioController controller,
    required AdminPortfolioServiceItem service,
  }) {
    return Obx(() {
      final photoLoading = controller.isMediaUploading(service.key, isVideo: false,);
      final videoLoading = controller.isMediaUploading(service.key, isVideo: true,);
      final effectivePhoto = controller.effectivePhotoFor(service.key);
      final effectiveVideo = controller.effectiveVideoFor(service.key);
      final photoIsNetwork = effectivePhoto.startsWith('http');
      final videoIsNetwork = effectiveVideo.startsWith('http');
      final photoCount = controller.photoCountByService[service.key] ?? 0;
      final videoCount = controller.videoCountByService[service.key] ?? 0;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xffF6F4FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffD9D9D9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        service.title,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$photoCount photos | $videoCount videos',
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _statusBadge(
                  photoCount + videoCount > 0 ? 'Live' : 'Default',
                  photoCount + videoCount > 0 ? _accent : _muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _previewPanel(
                    label: 'Cover Photo',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: scale.getScaledHeight(128),
                        width: double.infinity,
                        child: photoIsNetwork
                            ? Image.network(
                                effectivePhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallbackMediaTile(),
                              )
                            : Image.asset(effectivePhoto, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: scale.getScaledWidth(10)),
                Expanded(
                  child: _previewPanel(
                    label: 'Video Preview',
                    child: InkWell(
                      onTap: videoIsNetwork
                          ? () => _openExternalUrl(effectiveVideo)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: scale.getScaledHeight(128),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xff120E25).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffD9D9D9)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              videoIsNetwork ? 'Open video' : 'No video yet',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _primaryActionButton(
                    title: photoLoading ? 'Uploading...' : 'Add Photos',
                    icon: Icons.add_photo_alternate_outlined,
                    loading: photoLoading,
                    onTap: () =>
                        controller.uploadMedia(service.key, isVideo: false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _primaryActionButton(
                    title: videoLoading ? 'Uploading...' : 'Add Video',
                    icon: Icons.video_call_outlined,
                    loading: videoLoading,
                    onTap: () =>
                        controller.uploadMedia(service.key, isVideo: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _previewPanel({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _mediaManager(
    BuildContext context,
    ScalingUtility scale,
    AdminContentPortfolioController controller,
  ) {
    return Obx(() {
      final items = controller.mediaItems;
      if (items.isEmpty) {
        return _emptyMediaState();
      }
      return Column(
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _statusBadge('${items.length} total', _primary),
              _statusBadge(
                '${items.where((item) => item.isVisible).length} visible',
                _accent,
              ),
              _statusBadge(
                '${items.where((item) => !item.isVisible).length} hidden',
                _muted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => _mediaManagerCard(
              context: context,
              scale: scale,
              controller: controller,
              item: item,
            ),
          ),
        ],
      );
    });
  }

  Widget _emptyMediaState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Color(0xffF6F4FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffD9D9D9)),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.photo_library_outlined, color: Colors.black54, size: 40),
          SizedBox(height: 10),
          Text(
            'No media uploaded yet',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Upload photos or videos from the service media library above.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _mediaManagerCard({
    required BuildContext context,
    required ScalingUtility scale,
    required AdminContentPortfolioController controller,
    required AdminPortfolioMediaRecord item,
  }) {
    final previewUrl = item.isVideo && item.thumbnailUrl.isNotEmpty
        ? item.thumbnailUrl
        : item.mediaUrl;
    final visibilityColor = item.isVisible ? _accent : const Color(0xffFFB65C);

    return Container(
      margin: EdgeInsets.only(bottom: scale.getScaledHeight(12)),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _panelSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.isVisible
              ? const Color(0xff334C56)
              : const Color(0xff59432B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 92,
                  height: 82,
                  child: item.isVideo && item.thumbnailUrl.isEmpty
                      ? _videoPlaceholder()
                      : Image.network(
                          previewUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _fallbackMediaTile(),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: <Widget>[
                        _statusBadge(item.mediaType.toUpperCase(), _primary),
                        _statusBadge(
                          item.isVisible ? 'Visible' : 'Hidden',
                          visibilityColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.caption.isEmpty ? 'No caption added' : item.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Service: ${item.serviceId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Display order: ${item.displayOrder}',
                      style: const TextStyle(color: Color(0xff80799F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _toolButton(
                title: 'Edit',
                icon: Icons.edit_outlined,
                onTap: () => _showEditMediaSheet(context, controller, item),
              ),
              _toolButton(
                title: item.isVisible ? 'Hide' : 'Show',
                icon: item.isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onTap: () => controller.toggleMediaVisibility(item),
              ),
              _toolButton(
                title: 'Up',
                icon: Icons.keyboard_arrow_up_rounded,
                onTap: () => controller.moveMedia(item, -1),
              ),
              _toolButton(
                title: 'Down',
                icon: Icons.keyboard_arrow_down_rounded,
                onTap: () => controller.moveMedia(item, 1),
              ),
              _toolButton(
                title: 'Open',
                icon: Icons.open_in_new_rounded,
                onTap: () => _openExternalUrl(item.mediaUrl),
              ),
              _toolButton(
                title: 'Delete',
                icon: Icons.delete_outline_rounded,
                danger: true,
                onTap: () => _confirmDeleteMedia(context, controller, item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _primaryActionButton({
    required String title,
    required IconData icon,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 42,
      child: FilledButton.icon(
        onPressed: loading ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xff4B176F),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: loading
            ? const SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _toolButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? const Color(0xffFF7B8C) : Colors.white;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(title),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(
          color: danger ? const Color(0xffFF7B8C) : const Color(0xff6C61C8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showEditMediaSheet(
    BuildContext parentContext,
    AdminContentPortfolioController controller,
    AdminPortfolioMediaRecord item,
  ) async {
    final captionController = TextEditingController(text: item.caption);
    final thumbnailController = TextEditingController(text: item.thumbnailUrl);
    final orderController = TextEditingController(
      text: item.displayOrder.toString(),
    );
    var serviceId = item.serviceId;
    var isVisible = item.isVisible;
    try {
      await showModalBottomSheet<void>(
        context: parentContext,
        isScrollControlled: true,
        backgroundColor: const Color(0xff18133A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) => SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Media Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Update customer-facing metadata without replacing the file.',
                      style: TextStyle(color: _muted),
                    ),
                    const SizedBox(height: 16),
                    _editField(captionController, 'Caption / Title'),
                    if (item.isVideo) ...<Widget>[
                      const SizedBox(height: 12),
                      _editField(thumbnailController, 'Video Thumbnail URL'),
                    ],
                    const SizedBox(height: 12),
                    _editField(
                      orderController,
                      'Display Order',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: controller.services
                              .any((service) => service.key == serviceId)
                          ? serviceId
                          : controller.services.first.key,
                      dropdownColor: const Color(0xff231C4C),
                      style: const TextStyle(color: Colors.white),
                      decoration: _sheetInputDecoration('Service Category'),
                      items: controller.services
                          .map(
                            (service) => DropdownMenuItem(
                              value: service.key,
                              child: Text(service.title),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => serviceId = value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff120E25),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xff342D5C)),
                      ),
                      child: SwitchListTile(
                        value: isVisible,
                        onChanged: (value) =>
                            setModalState(() => isVisible = value),
                        activeThumbColor: _accent,
                        title: const Text(
                          'Visible to customers',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: const Text(
                          'Hidden media remains saved but is not shown on customer portfolio.',
                          style: TextStyle(color: _muted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xff6C61C8)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await controller.updateMediaMetadata(
                                item: item,
                                caption: captionController.text,
                                thumbnailUrl: thumbnailController.text,
                                displayOrder:
                                    int.tryParse(orderController.text) ??
                                        item.displayOrder,
                                isVisible: isVisible,
                                serviceId: serviceId,
                              );
                              if (context.mounted) Navigator.pop(context);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xff4B176F),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w900),
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
        ),
      );
    } finally {
      captionController.dispose();
      thumbnailController.dispose();
      orderController.dispose();
    }
  }

  Widget _editField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _sheetInputDecoration(label),
    );
  }

  InputDecoration _sheetInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xff120E25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff342D5C)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff342D5C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary),
      ),
    );
  }

  Future<void> _confirmDeleteMedia(
    BuildContext context,
    AdminContentPortfolioController controller,
    AdminPortfolioMediaRecord item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete media item?'),
        content: const Text(
          'Are you sure you want to delete this media item? This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteMedia(item);
    }
  }

  Widget _stickySaveButton(AdminContentPortfolioController controller) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          onPressed: controller.isSaving.value ? null : controller.saveContent,
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: controller.isSaving.value
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.cloud_done_outlined),
          label: Text(
            controller.isSaving.value ? 'Saving Content...' : 'Save All Content',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xff120E25).withValues(alpha: 0.2),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white70,
          size: 34,
        ),
      ),
    );
  }

  Widget _fallbackMediaTile() {
    return Container(
      color: const Color(0xff120E25).withValues(alpha: 0.2),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white70),
      ),
    );
  }

  Future<void> _openExternalUrl(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
