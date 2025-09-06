import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:luna_iot/models/search_filter_model.dart';
import '../app/app_theme.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final String title;
  final List<FilterOption> filterOptions;
  final String searchQuery;
  final Map<String, dynamic> currentFilters;
  final Function(String) onSearchChanged;
  final Function(String, String?) onFilterChanged;
  final VoidCallback onClearAll;
  final VoidCallback onApply;

  const SearchFilterBottomSheet({
    super.key,
    required this.title,
    required this.filterOptions,
    required this.searchQuery,
    required this.currentFilters,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClearAll,
    required this.onApply,
  });

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late Map<String, dynamic> _tempFilters;
  late String _tempSearchQuery;
  late TextEditingController _searchController; // Add this

  @override
  void initState() {
    super.initState();
    // Initialize temporary state with current values
    _tempFilters = Map.from(widget.currentFilters);
    _tempSearchQuery = widget.searchQuery;
    _searchController = TextEditingController(
      text: widget.searchQuery,
    ); // Initialize controller here
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose the controller
    super.dispose();
  }

  void _updateTempFilter(String key, String? value) {
    setState(() {
      if (value == null) {
        _tempFilters.remove(key);
      } else {
        _tempFilters[key] = value;
      }
    });
  }

  void _updateTempSearch(String query) {
    setState(() {
      _tempSearchQuery = query;
    });
  }

  void _clearAllTemp() {
    setState(() {
      _tempFilters.clear();
      _tempSearchQuery = '';
      _searchController.clear(); // Clear the controller text
    });
  }

  void _applyFilters() {
    // Apply the temporary filters to the actual controller
    widget.onSearchChanged(_tempSearchQuery);
    _tempFilters.forEach((key, value) {
      widget.onFilterChanged(key, value);
    });
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.titleColor,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllTemp,
                  child: Text(
                    'Clear All',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController, // Use the stored controller
              onChanged: _updateTempSearch,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Filters
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.filterOptions.length,
              itemBuilder: (context, index) {
                final filter = widget.filterOptions[index];
                return _buildFilterSection(filter);
              },
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(FilterOption filter) {
    // Get the current selected value for this filter from temporary state
    final currentValue = _tempFilters[filter.key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          filter.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.titleColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            // All option
            FilterChip(
              selected: currentValue == null,
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
              label: Text(
                'All',
                style: TextStyle(
                  color: currentValue == null
                      ? AppTheme.primaryColor
                      : AppTheme.subTitleColor,
                  fontWeight: currentValue == null
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  _updateTempFilter(filter.key, null);
                }
              },
              side: BorderSide(
                color: currentValue == null
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                width: currentValue == null ? 2 : 1,
              ),
            ),
            // Value options
            ...filter.values.map((value) {
              final isSelected = currentValue == value;
              return FilterChip(
                selected: isSelected,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
                label: Text(
                  value,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.subTitleColor,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                onSelected: (selected) {
                  if (selected) {
                    _updateTempFilter(filter.key, value);
                  }
                },
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
