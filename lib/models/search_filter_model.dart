class SearchFilterOptions {
  final String searchQuery;
  final Map<String, dynamic> filters;
  final String sortBy;
  final bool ascending;

  SearchFilterOptions({
    this.searchQuery = '',
    this.filters = const {},
    this.sortBy = '',
    this.ascending = true,
  });

  SearchFilterOptions copyWith({
    String? searchQuery,
    Map<String, dynamic>? filters,
    String? sortBy,
    bool? ascending,
  }) {
    return SearchFilterOptions(
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}

class FilterOption {
  final String key;
  final String label;
  final List<String> values;
  final String? selectedValue;

  FilterOption({
    required this.key,
    required this.label,
    required this.values,
    this.selectedValue,
  });

  FilterOption copyWith({String? selectedValue}) {
    return FilterOption(
      key: key,
      label: label,
      values: values,
      selectedValue: selectedValue ?? this.selectedValue,
    );
  }
}
