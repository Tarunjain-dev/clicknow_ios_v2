import 'package:clicknow_version2/app/services/maps_service.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationSearchField extends StatefulWidget {
  const LocationSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSuggestionTap,
    required this.suggestions,
    required this.isSearching,
    required this.onUseCurrentLocation,
    required this.isFetchingCurrentLocation,
    required this.isDark,
    this.hintText = 'Search Location',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<PlaceSuggestion> onSuggestionTap;
  final List<PlaceSuggestion> suggestions;
  final bool isSearching;
  final VoidCallback onUseCurrentLocation;
  final bool isFetchingCurrentLocation;
  final bool isDark;
  final String hintText;

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  static const String _recentSearchesKey = 'clicknow_recent_location_searches';
  static const int _recentLimit = 10;

  final TextEditingController _sheetSearchController = TextEditingController();
  List<String> _recentSearches = <String>[];
  bool _isSheetOpen = false;
  StateSetter? _sheetSetState;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _sheetSetState = null;
    _sheetSearchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LocationSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSheetOpen && _sheetSetState != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetSetState != null) {
          _sheetSetState?.call(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark || HelperFunctions.isDarkMode(context);
    final borderColor = isDark ? const Color(0xff334155) : const Color(0xffD9D9D9);
    final fillColor = isDark
        ? const Color(0xff1E293B)
        : const Color(0xffF6F4FF).withValues(alpha: 0.8);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white60 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.controller,
          builder: (context, value, child) {
            final hasText = value.text.trim().isNotEmpty;
            return Semantics(
              label: 'Search location',
              button: true,
              child: TextField(
                controller: widget.controller,
                readOnly: true,
                onTap: _openSearchSheet,
                style: TextStyle(
                  color: hasText ? textColor : hintColor,
                  fontSize: ResponsiveUtility.fontSize(14),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fillColor,
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: hintColor,
                    fontSize: ResponsiveUtility.fontSize(14),
                  ),
                  prefixIcon: Icon(Icons.search, color: hintColor),
                  suffixIcon: hasText
                      ? IconButton(
                          tooltip: 'Clear search',
                          icon: Icon(Icons.close, color: hintColor),
                          onPressed: () {
                            widget.controller.clear();
                            widget.onChanged('');
                          },
                        )
                      : null,
                  contentPadding: ResponsiveUtility.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xff94A3B8) : Colors.black87,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: ResponsiveUtility.height(8)),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.isFetchingCurrentLocation
                ? null
                : widget.onUseCurrentLocation,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderColor),
              foregroundColor: hintColor,
              backgroundColor: isDark
                  ? const Color(0xff1E293B).withValues(alpha: 0.35)
                  : const Color(0xffF6F4FF).withValues(alpha: 0.35),
              minimumSize: Size.fromHeight(ResponsiveUtility.height(48)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            icon: widget.isFetchingCurrentLocation
                ? SizedBox(
                    width: ResponsiveUtility.width(16),
                    height: ResponsiveUtility.height(16),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: hintColor,
                    ),
                  )
                : const Icon(Icons.location_on_outlined),
            label: Text(
              widget.isFetchingCurrentLocation
                  ? 'Fetching current location...'
                  : 'Use Current Location',
              style: TextStyle(fontSize: ResponsiveUtility.fontSize(14)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSearchSheet() async {
    if (_isSheetOpen) {
      return;
    }
    _isSheetOpen = true;
    _sheetSearchController.text = widget.controller.text;
    widget.onChanged(_sheetSearchController.text);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                _sheetSetState = setSheetState;
                final isDark = widget.isDark || HelperFunctions.isDarkMode(context);
                return _LocationSearchSheet(
                  scrollController: scrollController,
                  searchController: _sheetSearchController,
                  suggestions: widget.suggestions,
                  recentSearches: _recentSearches,
                  isSearching: widget.isSearching,
                  isFetchingCurrentLocation: widget.isFetchingCurrentLocation,
                  isDark: isDark,
                  onChanged: (value) {
                    _syncMainController(value);
                    widget.onChanged(value);
                    setSheetState(() {});
                  },
                  onSuggestionTap: (suggestion) {
                    _saveRecentSearch(suggestion.description);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                    widget.onSuggestionTap(suggestion);
                  },
                  onRecentTap: (recent) {
                    _sheetSearchController.text = recent;
                    _sheetSearchController.selection =
                        TextSelection.collapsed(offset: recent.length);
                    _syncMainController(recent);
                    widget.onChanged(recent);
                    setSheetState(() {});
                  },
                  onDeleteRecent: (recent) async {
                    await _deleteRecentSearch(recent);
                    setSheetState(() {});
                  },
                  onClearRecent: () async {
                    await _clearRecentSearches();
                    setSheetState(() {});
                  },
                  onUseCurrentLocation: () {
                    Navigator.pop(context);
                    widget.onUseCurrentLocation();
                  },
                );
              },
            );
          },
        );
      },
    );
    _sheetSetState = null;
    _isSheetOpen = false;
  }

  void _syncMainController(String value) {
    if (widget.controller.text == value) {
      return;
    }
    widget.controller.text = value;
    widget.controller.selection = TextSelection.collapsed(
      offset: value.length,
    );
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_recentSearchesKey) ?? <String>[];
    if (mounted) {
      setState(() => _recentSearches = values);
    }
  }

  Future<void> _saveRecentSearch(String value) async {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return;
    }
    final next = <String>[
      cleaned,
      ..._recentSearches.where(
        (item) => item.toLowerCase() != cleaned.toLowerCase(),
      ),
    ].take(_recentLimit).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, next);
    if (mounted) {
      setState(() => _recentSearches = next);
    }
  }

  Future<void> _deleteRecentSearch(String value) async {
    final next = _recentSearches
        .where((item) => item.toLowerCase() != value.trim().toLowerCase())
        .toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, next);
    if (mounted) {
      setState(() => _recentSearches = next);
    }
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
    if (mounted) {
      setState(() => _recentSearches = <String>[]);
    }
  }
}

class _LocationSearchSheet extends StatelessWidget {
  const _LocationSearchSheet({
    required this.scrollController,
    required this.searchController,
    required this.suggestions,
    required this.recentSearches,
    required this.isSearching,
    required this.isFetchingCurrentLocation,
    required this.isDark,
    required this.onChanged,
    required this.onSuggestionTap,
    required this.onRecentTap,
    required this.onDeleteRecent,
    required this.onClearRecent,
    required this.onUseCurrentLocation,
  });

  final ScrollController scrollController;
  final TextEditingController searchController;
  final List<PlaceSuggestion> suggestions;
  final List<String> recentSearches;
  final bool isSearching;
  final bool isFetchingCurrentLocation;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final ValueChanged<PlaceSuggestion> onSuggestionTap;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onDeleteRecent;
  final VoidCallback onClearRecent;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final background = isDark ? const Color(0xff0F172A) : Colors.white;
    final surface = isDark ? const Color(0xff1E293B) : Colors.white;
    final border = isDark ? const Color(0xff334155) : const Color(0xffE5E7EB);
    final primaryText = isDark ? Colors.white : const Color(0xff111827);
    final secondaryText = isDark ? Colors.white70 : const Color(0xff6B7280);
    final query = searchController.text.trim();

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          ResponsiveUtility.width(16),
          ResponsiveUtility.height(10),
          ResponsiveUtility.width(16),
          ResponsiveUtility.height(24),
        ),
        children: [
          Center(
            child: Container(
              width: ResponsiveUtility.width(42),
              height: ResponsiveUtility.height(4),
              decoration: BoxDecoration(
                color: secondaryText.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(14)),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: primaryText),
                tooltip: 'Back',
              ),
              Expanded(
                child: Text(
                  'Select Location',
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.w700,
                    fontSize: ResponsiveUtility.fontSize(18),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtility.height(10)),
          TextField(
            controller: searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: TextStyle(color: primaryText),
            decoration: InputDecoration(
              hintText: 'Search location, landmark, building...',
              hintStyle: TextStyle(color: secondaryText),
              prefixIcon: Icon(Icons.search, color: secondaryText),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, color: secondaryText),
                      onPressed: () {
                        searchController.clear();
                        onChanged('');
                      },
                    ),
              filled: true,
              fillColor: surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white70 : const Color(0xff111827),
                ),
              ),
            ),
            onChanged: onChanged,
          ),
          SizedBox(height: ResponsiveUtility.height(12)),
          _CurrentLocationCard(
            isDark: isDark,
            isLoading: isFetchingCurrentLocation,
            onTap: onUseCurrentLocation,
          ),
          SizedBox(height: ResponsiveUtility.height(18)),
          if (query.isEmpty) ...[
            _SectionHeader(
              title: 'Recent Searches',
              actionLabel: recentSearches.isEmpty ? '' : 'Clear All',
              onAction: onClearRecent,
              isDark: isDark,
            ),
            if (recentSearches.isEmpty)
              _EmptyState(
                icon: Icons.history_rounded,
                title: 'No recent searches',
                subtitle: 'Your latest searched locations will appear here.',
                isDark: isDark,
              )
            else
              ...recentSearches.map(
                (item) => _RecentSearchTile(
                  label: item,
                  isDark: isDark,
                  onTap: () => onRecentTap(item),
                  onDelete: () => onDeleteRecent(item),
                ),
              ),
          ] else ...[
            _SectionHeader(title: 'Search Results', isDark: isDark),
            if (isSearching)
              ...List.generate(5, (index) => _SkeletonResultTile(isDark: isDark))
            else if (suggestions.isEmpty)
              _EmptyState(
                icon: Icons.location_off_outlined,
                title: 'No locations found',
                subtitle: 'Try searching with another keyword',
                isDark: isDark,
              )
            else
              ...suggestions.map(
                (suggestion) => _PlaceSuggestionTile(
                  suggestion: suggestion,
                  isDark: isDark,
                  onTap: () => onSuggestionTap(suggestion),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard({
    required this.isDark,
    required this.isLoading,
    required this.onTap,
  });

  final bool isDark;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: ResponsiveUtility.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xff334155) : const Color(0xffE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            isLoading
                ? SizedBox(
                    width: ResponsiveUtility.width(22),
                    height: ResponsiveUtility.height(22),
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    color: isDark ? Colors.white : const Color(0xff111827),
                  ),
            SizedBox(width: ResponsiveUtility.width(12)),
            Expanded(
              child: Text(
                isLoading ? 'Fetching current location...' : 'Use Current Location',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xff111827),
                  fontWeight: FontWeight.w700,
                  fontSize: ResponsiveUtility.fontSize(14),
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? Colors.white54 : Colors.black38,
              size: ResponsiveUtility.width(14),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceSuggestionTile extends StatelessWidget {
  const _PlaceSuggestionTile({
    required this.suggestion,
    required this.isDark,
    required this.onTap,
  });

  final PlaceSuggestion suggestion;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = suggestion.title.trim().isEmpty
        ? suggestion.description
        : suggestion.title;
    final subtitle = suggestion.secondaryText.trim().isEmpty
        ? suggestion.description
        : suggestion.secondaryText;
    return _ResultCard(
      isDark: isDark,
      onTap: onTap,
      leading: Icons.location_on_outlined,
      title: title,
      subtitle: subtitle,
      trailing: Icons.north_west_rounded,
    );
  }
}

class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({
    required this.label,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      isDark: isDark,
      onTap: onTap,
      leading: Icons.history_rounded,
      title: label,
      subtitle: 'Recent search',
      trailingWidget: IconButton(
        tooltip: 'Remove recent search',
        onPressed: onDelete,
        icon: Icon(
          Icons.close,
          size: ResponsiveUtility.width(18),
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.isDark,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingWidget,
  });

  final bool isDark;
  final VoidCallback onTap;
  final IconData leading;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xff1E293B) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xff111827);
    final secondaryText = isDark ? Colors.white70 : const Color(0xff6B7280);
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtility.height(10)),
      child: Material(
        color: surface,
        elevation: isDark ? 0 : 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: ResponsiveUtility.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(leading, color: secondaryText, size: ResponsiveUtility.width(22)),
                SizedBox(width: ResponsiveUtility.width(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryText,
                          fontWeight: FontWeight.w700,
                          fontSize: ResponsiveUtility.fontSize(14),
                        ),
                      ),
                      SizedBox(height: ResponsiveUtility.height(3)),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: ResponsiveUtility.fontSize(12),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                trailingWidget ??
                    Icon(
                      trailing ?? Icons.chevron_right_rounded,
                      color: secondaryText,
                      size: ResponsiveUtility.width(18),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.isDark,
    this.actionLabel = '',
    this.onAction,
  });

  final String title;
  final bool isDark;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveUtility.height(10)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xff111827),
                fontWeight: FontWeight.w800,
                fontSize: ResponsiveUtility.fontSize(15),
              ),
            ),
          ),
          if (actionLabel.isNotEmpty)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }
}

class _SkeletonResultTile extends StatelessWidget {
  const _SkeletonResultTile({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xff1E293B) : const Color(0xffF3F4F6);
    final highlight = isDark ? const Color(0xff334155) : const Color(0xffE5E7EB);
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveUtility.height(10)),
      padding: ResponsiveUtility.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _SkeletonBox(width: 24, height: 24, color: highlight, radius: 12),
          SizedBox(width: ResponsiveUtility.width(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBox(width: double.infinity, height: 12, color: highlight),
                SizedBox(height: ResponsiveUtility.height(8)),
                _SkeletonBox(width: 180, height: 10, color: highlight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 8,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width == double.infinity ? double.infinity : ResponsiveUtility.width(width),
      height: ResponsiveUtility.height(height),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveUtility.symmetric(vertical: 30, horizontal: 12),
      child: Column(
        children: [
          Icon(
            icon,
            size: ResponsiveUtility.width(42),
            color: isDark ? Colors.white54 : Colors.black38,
          ),
          SizedBox(height: ResponsiveUtility.height(10)),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xff111827),
              fontWeight: FontWeight.w800,
              fontSize: ResponsiveUtility.fontSize(15),
            ),
          ),
          SizedBox(height: ResponsiveUtility.height(4)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xff6B7280),
              fontSize: ResponsiveUtility.fontSize(12),
            ),
          ),
        ],
      ),
    );
  }
}
