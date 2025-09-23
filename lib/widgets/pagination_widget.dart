import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Function(int)? onPageChanged;
  final Function(int)? onPageSizeChanged;

  const PaginationWidget({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.isLoading = false,
    this.onPrevious,
    this.onNext,
    this.onPageChanged,
    this.onPageSizeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show pagination if there are items to paginate
    if (totalCount <= 25) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          // Pagination info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Showing ${((currentPage - 1) * 25) + 1} to ${(currentPage * 25).clamp(0, totalCount)} of $totalCount',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous button
                    IconButton(
                      onPressed: isLoading || !hasPreviousPage
                          ? null
                          : onPrevious,
                      icon: const Icon(Icons.chevron_left, size: 20),
                      tooltip: 'Previous page',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),

                    // Page numbers
                    ..._buildPageNumbers(),

                    // Next button
                    IconButton(
                      onPressed: isLoading || !hasNextPage ? null : onNext,
                      icon: const Icon(Icons.chevron_right, size: 20),
                      tooltip: 'Next page',
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pageNumbers = [];

    // Limit to maximum 3 page numbers to prevent overflow
    int maxPages = 3;
    int startPage = (currentPage - 1).clamp(1, totalPages);
    int endPage = (currentPage + 1).clamp(1, totalPages);

    // Adjust range if we have too many pages
    if (totalPages > maxPages) {
      if (currentPage <= 2) {
        startPage = 1;
        endPage = maxPages;
      } else if (currentPage >= totalPages - 1) {
        startPage = totalPages - maxPages + 1;
        endPage = totalPages;
      }
    }

    // Add first page if not in range
    if (startPage > 1) {
      pageNumbers.add(_buildPageButton(1));
      if (startPage > 2) {
        pageNumbers.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('...', style: TextStyle(fontSize: 10)),
          ),
        );
      }
    }

    // Add page numbers in range
    for (int i = startPage; i <= endPage; i++) {
      pageNumbers.add(_buildPageButton(i));
    }

    // Add ellipsis and last page if needed
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageNumbers.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('...', style: TextStyle(fontSize: 10)),
          ),
        );
      }
      pageNumbers.add(_buildPageButton(totalPages));
    }

    return pageNumbers;
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == currentPage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      child: Material(
        color: isCurrentPage ? Get.theme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: isLoading || isCurrentPage
              ? null
              : () => onPageChanged?.call(page),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            child: Text(
              '$page',
              style: TextStyle(
                color: isCurrentPage ? Colors.white : Colors.black87,
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Simplified pagination widget for bottom sheets or smaller spaces
class CompactPaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const CompactPaginationWidget({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.isLoading = false,
    this.onPrevious,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show pagination if there are items to paginate
    if (totalCount <= 25) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $currentPage of $totalPages ($totalCount items)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          Row(
            children: [
              IconButton(
                onPressed: isLoading || !hasPreviousPage ? null : onPrevious,
                icon: const Icon(Icons.chevron_left, size: 20),
                tooltip: 'Previous page',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              IconButton(
                onPressed: isLoading || !hasNextPage ? null : onNext,
                icon: const Icon(Icons.chevron_right, size: 20),
                tooltip: 'Next page',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
