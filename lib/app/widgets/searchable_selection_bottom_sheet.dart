import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';

class SearchableSelectionBottomSheet {
  SearchableSelectionBottomSheet._();

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    String? initialValue,
    String? searchHint,
    String Function(String)? displayMapper,
  }) async {
    if (options.isEmpty) {
      return null;
    }
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchableSelectionSheet(
        title: title,
        options: options,
        initialValue: initialValue,
        searchHint: searchHint,
        displayMapper: displayMapper,
      ),
    );
  }
}

class _SearchableSelectionSheet extends StatefulWidget {
  const _SearchableSelectionSheet({
    required this.title,
    required this.options,
    required this.displayMapper,
    this.initialValue,
    this.searchHint,
  });

  final String title;
  final List<String> options;
  final String? initialValue;
  final String? searchHint;
  final String Function(String)? displayMapper;

  @override
  State<_SearchableSelectionSheet> createState() =>
      _SearchableSelectionSheetState();
}

class _SearchableSelectionSheetState extends State<_SearchableSelectionSheet> {
  late final TextEditingController _searchController;
  late final ScrollController _listController;
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _listController = ScrollController();
    _filtered = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _filtered = widget.options
          .where((option) {
            final label = _label(option).toLowerCase();
            return label.contains(query);
          })
          .toList(growable: false);
    });
  }

  String _label(String option) {
    return widget.displayMapper?.call(option) ?? option;
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final selectedValue = (widget.initialValue ?? '').trim();

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: 0.76,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF161235) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: ResponsiveUtility.only(top: 10, right: 12, left: 12, bottom: 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveUtility.fontSize(16),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Color(0xFF8F96C4) : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: isDark ? Color(0xFF2A3363) : Color(0xffD9D9D9), height: 1),
                Padding(
                  padding: ResponsiveUtility.only(bottom: 10, left: 12, right: 12, top: 10),
                  child: TextField(
                    controller: _searchController,
                    cursorColor: isDark ? Colors.white : Colors.black,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6)),
                    decoration: InputDecoration(
                      hintText: widget.searchHint ?? 'Search ${widget.title.toLowerCase()}',
                      hintStyle: TextStyle(color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white : Colors.black,),
                      filled: true,
                      fillColor: isDark ? Color(0xFF211E56) : Color(0xffF6F4FF).withValues(alpha: 0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF5663D8)),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No results found',
                            style: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.6),
                              fontSize: ResponsiveUtility.fontSize(14),
                            ),
                          ),
                        )
                      : Scrollbar(
                          controller: _listController,
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _listController,
                            physics: const BouncingScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            itemCount: _filtered.length,
                            separatorBuilder: (context, index) => Divider(
                              color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                              height: 1,
                              indent: ResponsiveUtility.width(14),
                              endIndent: ResponsiveUtility.width(14),
                            ),
                            itemBuilder: (context, index) {
                              final item = _filtered[index];
                              final isSelected = selectedValue.isNotEmpty && item == selectedValue;
                              return ListTile(
                                title: Text(
                                  _label(item),
                                  style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6),
                                      fontSize: ResponsiveUtility.fontSize(14),
                                  ),
                                ),
                                trailing: isSelected ? Icon(Icons.check, color: Color(0xFFB33CF1),) : null,
                                onTap: () => Navigator.of(context).pop(item),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
