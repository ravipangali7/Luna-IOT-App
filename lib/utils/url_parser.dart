class UrlParser {
  /// Extract VTID from a scanned URL or direct VTID string
  /// Supports formats like:
  /// - https://app.mylunago.com/vehicle-tag/alert/VTID83
  /// - http://app.mylunago.com/vehicle-tag/alert/VTID83
  /// - app.mylunago.com/vehicle-tag/alert/VTID83
  /// - /vehicle-tag/alert/VTID83
  /// - VTID83 (direct VTID)
  static String? extractVtidFromUrl(String scannedValue) {
    if (scannedValue.isEmpty) {
      return null;
    }

    // Trim whitespace
    scannedValue = scannedValue.trim();

    // Check if it's a direct VTID (starts with VTID)
    if (scannedValue.toUpperCase().startsWith('VTID')) {
      return scannedValue.toUpperCase();
    }

    try {
      // Try to parse as URL
      Uri? uri;
      
      // Add protocol if missing
      if (!scannedValue.startsWith('http://') && !scannedValue.startsWith('https://')) {
        scannedValue = 'https://$scannedValue';
      }
      
      uri = Uri.tryParse(scannedValue);
      
      if (uri == null) {
        return null;
      }

      // Extract path segments
      final pathSegments = uri.pathSegments;
      
      // Look for VTID in path segments
      // Common pattern: /vehicle-tag/alert/VTID83
      for (int i = 0; i < pathSegments.length; i++) {
        final segment = pathSegments[i];
        if (segment.toUpperCase().startsWith('VTID')) {
          return segment.toUpperCase();
        }
      }

      // If no VTID found in path, check last segment
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.toUpperCase().startsWith('VTID')) {
          return lastSegment.toUpperCase();
        }
      }

      return null;
    } catch (e) {
      // If parsing fails, try to extract VTID directly from string
      final regex = RegExp(r'VTID\d+', caseSensitive: false);
      final match = regex.firstMatch(scannedValue);
      if (match != null) {
        return match.group(0)?.toUpperCase();
      }
      
      return null;
    }
  }
}

