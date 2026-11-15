import 'en.dart';
import 'fa.dart';

/// Looks up user-facing text for `en` or `fa`.
final class Messages {
  /// Creates a catalog for [language].
  Messages(this.language) {
    if (language != 'en' && language != 'fa') {
      throw ArgumentError.value(language, 'language', 'must be en or fa');
    }
  }

  /// `en` or `fa`.
  final String language;

  /// Returns the template for [key], with `{name}` placeholders replaced.
  String text(String key, [Map<String, String> values = const {}]) {
    final template =
        (language == 'fa' ? faMessages[key] : null) ?? enMessages[key];
    if (template == null) {
      throw StateError('Missing message: $key');
    }
    var resolved = template;
    for (final entry in values.entries) {
      resolved = resolved.replaceAll('{${entry.key}}', entry.value);
    }
    return resolved;
  }
}

/// True when English and Persian define the same keys.
bool messageCatalogsMatch() {
  final english = enMessages.keys.toSet();
  final persian = faMessages.keys.toSet();
  return english.length == persian.length && english.containsAll(persian);
}
