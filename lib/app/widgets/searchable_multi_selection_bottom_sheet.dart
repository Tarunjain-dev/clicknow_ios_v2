import 'package:clicknow_version2/app/utils/device_constants/appColors.dart';
import 'package:clicknow_version2/app/utils/device_utils/helperFunctions.dart';
import 'package:clicknow_version2/app/utils/device_utils/responsive_Utility.dart';
import 'package:flutter/material.dart';

class SearchableMultiSelectionBottomSheet {
  SearchableMultiSelectionBottomSheet._();

  static Future<List<String>?> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    List<String> initialValues = const <String>[],
    String? searchHint,
  }) async {
    if (options.isEmpty) {
      return null;
    }
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchableMultiSelectionSheet(
        title: title,
        options: options,
        initialValues: initialValues,
        searchHint: searchHint,
      ),
    );
  }
}

class _SearchableMultiSelectionSheet extends StatefulWidget {
  const _SearchableMultiSelectionSheet({
    required this.title,
    required this.options,
    required this.initialValues,
    this.searchHint,
  });

  final String title;
  final List<String> options;
  final List<String> initialValues;
  final String? searchHint;

  @override
  State<_SearchableMultiSelectionSheet> createState() => _SearchableMultiSelectionSheetState();
}

class _SearchableMultiSelectionSheetState extends State<_SearchableMultiSelectionSheet> {
  late final TextEditingController _searchController;
  late final ScrollController _listController;
  late final Set<String> _selected;
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _listController = ScrollController();
    _selected = widget.initialValues.where((value) => widget.options.contains(value)).toSet();
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
      _filtered = widget.options.where((option) => option.toLowerCase().contains(query)).toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {

    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    /// -- Dark mode instance
    final isDark = HelperFunctions.isDarkMode(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: 0.82,
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
                            separatorBuilder: (context, index) =>
                              Divider(
                              color: isDark ? Color(0xff1E2939) : Color(0xffD9D9D9),
                              height: 1,
                              indent: ResponsiveUtility.width(14),
                              endIndent: ResponsiveUtility.width(14),
                            ),
                            itemBuilder: (context, index) {
                              final item = _filtered[index];
                              final selected = _selected.contains(item);
                              return CheckboxListTile(
                                value: selected,
                                onChanged: (_) {
                                  setState(() {
                                    if (selected) {
                                      _selected.remove(item);
                                    } else {
                                      _selected.add(item);
                                    }
                                  });
                                },
                                dense: true,
                                contentPadding: ResponsiveUtility.symmetric(horizontal: 8),
                                activeColor: const Color(0xFFB33CF1),
                                checkColor: Colors.white,
                                title: Padding(
                                  padding: ResponsiveUtility.only(left: 8),
                                  child: Text(
                                    item,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black.withValues(alpha: 0.6)),
                                  ),
                                ),
                                controlAffinity: ListTileControlAffinity.trailing,
                              );
                            },
                          ),
                        ),
                ),
                Container(
                  padding: ResponsiveUtility.only(left: 12,top: 10 ,right: 12, bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: isDark ? Color(0xFF2A3363) : Color(0xffD9D9D9))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black,
                            side: BorderSide(color: Color(0xFF3B4272)),
                          ),
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: ResponsiveUtility.width(10)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context,).pop(_selected.toList(growable: false)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : AppColors.primaryColor,
                            foregroundColor: isDark ? Color(0xFF4B176F) : Colors.white,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
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
