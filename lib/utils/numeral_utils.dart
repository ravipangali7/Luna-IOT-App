/// Utility functions for normalizing between Nepali (Devanagari) and English numerals.
/// Enables bidirectional search functionality.

// Numeral mapping: English -> Nepali
const Map<String, String> _englishToNepali = {
  '0': '०',
  '1': '१',
  '2': '२',
  '3': '३',
  '4': '४',
  '5': '५',
  '6': '६',
  '7': '७',
  '8': '८',
  '9': '९',
};

// Numeral mapping: Nepali -> English
final Map<String, String> _nepaliToEnglish = {
  for (var entry in _englishToNepali.entries) entry.value: entry.key
};

/// Convert Nepali numerals to English numerals in the given text.
///
/// Example:
/// ```dart
/// normalizeToEnglish("६७८९") // Returns "6789"
/// ```
String normalizeToEnglish(String text) {
  if (text.isEmpty) {
    return text;
  }

  return text.split('').map((char) => _nepaliToEnglish[char] ?? char).join();
}

/// Convert English numerals to Nepali numerals in the given text.
///
/// Example:
/// ```dart
/// normalizeToNepali("6789") // Returns "६७८९"
/// ```
String normalizeToNepali(String text) {
  if (text.isEmpty) {
    return text;
  }

  return text.split('').map((char) => _englishToNepali[char] ?? char).join();
}

/// Generate both English and Nepali normalized versions of the input text.
/// This enables bidirectional search - searching with either numeral system
/// will find matches regardless of which system is used in stored data.
///
/// Returns a list containing [original, englishNormalized, nepaliNormalized].
///
/// Example:
/// ```dart
/// normalizeNumeralsBidirectional("6789") // Returns ["6789", "6789", "६७८९"]
/// normalizeNumeralsBidirectional("६७८९") // Returns ["६७८९", "6789", "६७८९"]
/// ```
List<String> normalizeNumeralsBidirectional(String text) {
  if (text.isEmpty) {
    return [text];
  }

  final englishVersion = normalizeToEnglish(text);
  final nepaliVersion = normalizeToNepali(text);

  // Return unique variants
  final variants = <String>{text, englishVersion, nepaliVersion};
  return variants.toList();
}

/// Get all search variants for a given text (original, English normalized, Nepali normalized).
/// Useful for building search queries that match regardless of numeral system used.
///
/// Example:
/// ```dart
/// getSearchVariants("6789") // Returns ["6789", "6789", "६७८९"]
/// getSearchVariants("६७८९") // Returns ["६७८९", "6789", "६७८९"]
/// ```
List<String> getSearchVariants(String text) {
  return normalizeNumeralsBidirectional(text);
}

