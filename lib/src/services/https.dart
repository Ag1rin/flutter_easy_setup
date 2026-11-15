import '../models/cli_exception.dart';

/// Checks that a URL is HTTPS and has no embedded credentials.
Uri requireHttps(Uri uri) {
  if (uri.scheme != 'https') {
    throw CliException('Only HTTPS URLs are allowed: $uri');
  }
  if (uri.userInfo.isNotEmpty) {
    throw const CliException('URLs with embedded credentials are not allowed.');
  }
  if (uri.host.isEmpty) {
    throw CliException('URL is missing a host: $uri');
  }
  return uri;
}

/// Returns the next HTTPS URL for a redirect, or null when [status] is not
/// a redirect.
Uri? nextHttpsRedirect(Uri current, int status, String? location) {
  const redirectCodes = {301, 302, 303, 307, 308};
  if (!redirectCodes.contains(status)) {
    return null;
  }
  if (location == null || location.trim().isEmpty) {
    throw const CliException('Redirect is missing a Location header.');
  }
  return requireHttps(current.resolve(location.trim()));
}

/// Builds a `HttpClient.findProxy` result from proxy environment variables.
String proxyDirective(Uri uri, Map<String, String> environment) {
  final https = _first(environment, const ['HTTPS_PROXY', 'https_proxy']);
  final http = _first(environment, const ['HTTP_PROXY', 'http_proxy']);
  final raw = uri.scheme == 'https' ? (https ?? http) : http;
  if (raw == null || raw.trim().isEmpty) {
    return 'DIRECT';
  }
  var value = raw.trim();
  if (!value.contains('://')) {
    value = 'http://$value';
  }
  final parsed = Uri.tryParse(value);
  if (parsed == null || parsed.host.isEmpty) {
    throw const CliException('Proxy URL is invalid.');
  }
  final port = parsed.hasPort ? parsed.port : 8080;
  return 'PROXY ${parsed.host}:$port';
}

String? _first(Map<String, String> environment, List<String> keys) {
  for (final key in keys) {
    final value = environment[key];
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

/// Removes one trailing slash from a storage base URL.
String trimTrailingSlash(String value) {
  return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}

/// Validates a Flutter storage or pub host base URL.
String validateBaseUrl(String value) {
  final trimmed = trimTrailingSlash(value.trim());
  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    throw CliException('Invalid URL: $value');
  }
  requireHttps(uri);
  if (uri.path != '' && uri.path != '/') {
    throw CliException('Base URL must not include a path: $value');
  }
  if (uri.query.isNotEmpty || uri.fragment.isNotEmpty) {
    throw const CliException('Base URL must not include a query or fragment.');
  }
  return trimmed;
}
