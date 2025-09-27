class PaginationInfo {
  final int count;
  final String? next;
  final String? previous;
  final int currentPage;
  final int totalPages;
  final int pageSize;

  PaginationInfo({
    required this.count,
    this.next,
    this.previous,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    final count = json['count'] ?? json['total_items'] ?? 0;
    final next =
        json['next'] ??
        (json['has_next'] == true ? '?page=${json['next_page']}' : null);
    final previous =
        json['previous'] ??
        (json['has_previous'] == true
            ? '?page=${json['previous_page']}'
            : null);
    final currentPage = json['current_page'] ?? 1;
    final totalPages = json['total_pages'] ?? 1;
    final pageSize = json['page_size'] ?? 10;

    print(
      'PaginationInfo.fromJson - Count: $count, Next: $next, Previous: $previous, CurrentPage: $currentPage, TotalPages: $totalPages, PageSize: $pageSize',
    );

    return PaginationInfo(
      count: count,
      next: next,
      previous: previous,
      currentPage: currentPage,
      totalPages: totalPages,
      pageSize: pageSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'next': next,
      'previous': previous,
      'current_page': currentPage,
      'total_pages': totalPages,
      'page_size': pageSize,
    };
  }

  bool get hasNext => next != null;
  bool get hasPrevious => previous != null;
}

class PaginatedResponse<T> {
  final bool success;
  final String message;
  final List<T> data;
  final PaginationInfo pagination;

  PaginatedResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    // Handle different response formats
    List<T> data = [];

    if (json['data'] != null) {
      if (json['data'] is List) {
        data = (json['data'] as List<dynamic>)
            .map((item) => fromJsonT(item as Map<String, dynamic>))
            .toList();
      } else if (json['data'] is Map<String, dynamic>) {
        final dataMap = json['data'] as Map<String, dynamic>;

        // Check if data contains a 'vehicles' or 'devices' key (nested structure)
        if (dataMap.containsKey('vehicles') && dataMap['vehicles'] is List) {
          data = (dataMap['vehicles'] as List<dynamic>)
              .map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList();
        } else if (dataMap.containsKey('devices') &&
            dataMap['devices'] is List) {
          data = (dataMap['devices'] as List<dynamic>)
              .map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList();
        } else {
          // Single object format
          data = [fromJsonT(dataMap)];
        }
      }
    }

    // Get pagination data or create default
    Map<String, dynamic> paginationData = {};

    // Check for pagination data in different locations
    if (json['pagination'] != null) {
      paginationData = json['pagination'] as Map<String, dynamic>;
      print('Pagination data from backend (root): $paginationData');
    } else if (json['data'] != null && json['data']['pagination'] != null) {
      paginationData = json['data']['pagination'] as Map<String, dynamic>;
      print('Pagination data from backend (data.pagination): $paginationData');
    } else {
      print('No pagination data found in backend response');
    }

    // If pagination data is empty, check if we have pagination info in the response
    if (paginationData.isEmpty) {
      // Check if pagination info is in the main response
      if (json.containsKey('count') || json.containsKey('total_pages')) {
        paginationData = {
          'count': json['count'] ?? data.length,
          'current_page': json['current_page'] ?? 1,
          'total_pages': json['total_pages'] ?? 1,
          'page_size': json['page_size'] ?? 25,
          'next': json['next'],
          'previous': json['previous'],
        };
        print('Found pagination data in main response: $paginationData');
      } else {
        print('No pagination data from backend, creating fallback pagination');
        // For client-side pagination, we need to know the total count
        // This is a fallback - ideally the backend should provide this
        final totalCount = data.length; // This will be the page size for now
        final totalPages = (totalCount / 25)
            .ceil(); // Assuming 25 items per page

        paginationData = {
          'count': totalCount,
          'current_page': 1,
          'total_pages': totalPages,
          'page_size': 25,
          'next': totalPages > 1 ? '?page=2' : null,
          'previous': null,
        };
        print('Created fallback pagination: $paginationData');
      }
    }

    print('Creating PaginatedResponse with pagination data: $paginationData');

    return PaginatedResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: data,
      pagination: PaginationInfo.fromJson(paginationData),
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'success': success,
      'message': message,
      'data': data.map((item) => toJsonT(item)).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
