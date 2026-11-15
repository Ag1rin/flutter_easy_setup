import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/cli_exception.dart';
import 'https.dart';

/// A streamed HTTP response.
final class ByteResponse {
  /// Creates a response the caller must drain.
  const ByteResponse({
    required this.statusCode,
    required this.body,
    this.contentLength,
    this.location,
  });

  /// HTTP status code.
  final int statusCode;

  /// Response body. Empty when the caller already drained a redirect.
  final Stream<List<int>> body;

  /// `Content-Length` when the server sent one.
  final int? contentLength;

  /// `Location` header for redirects.
  final String? location;
}

/// HTTPS GET client used by downloads.
abstract interface class HttpFetcher {
  /// Sends a GET request. The caller drains [ByteResponse.body].
  Future<ByteResponse> get(Uri uri, {Map<String, String> headers});
}

/// `dart:io` client that refuses non-HTTPS URLs and HTTP downgrades.
final class IoHttpFetcher implements HttpFetcher {
  /// Creates a client that honors proxy environment variables.
  IoHttpFetcher({Map<String, String>? environment})
    : _environment = environment ?? Platform.environment;

  final Map<String, String> _environment;

  @override
  Future<ByteResponse> get(Uri uri, {Map<String, String> headers = const {}}) {
    return _get(requireHttps(uri), headers, 0);
  }

  Future<ByteResponse> _get(
    Uri uri,
    Map<String, String> headers,
    int redirects,
  ) async {
    if (redirects > 5) {
      throw const CliException('Too many redirects.');
    }
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    client.findProxy = (url) => proxyDirective(url, _environment);
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final location = response.headers.value(HttpHeaders.locationHeader);
      final next = nextHttpsRedirect(uri, response.statusCode, location);
      if (next != null) {
        await response.drain<void>();
        client.close();
        return await _get(next, headers, redirects + 1);
      }
      final length = response.contentLength < 0 ? null : response.contentLength;
      final body = response.timeout(const Duration(seconds: 60));
      return ByteResponse(
        statusCode: response.statusCode,
        body: _closeWhenDone(body, client),
        contentLength: length,
        location: location,
      );
    } on CliException {
      client.close(force: true);
      rethrow;
    } catch (error) {
      client.close(force: true);
      throw DownloadException('Request failed for $uri: $error');
    }
  }
}

Stream<List<int>> _closeWhenDone(Stream<List<int>> source, HttpClient client) {
  return source.transform(
    StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) => sink.add(data),
      handleError: (error, stack, sink) {
        client.close(force: true);
        sink.addError(error, stack);
      },
      handleDone: (sink) {
        client.close();
        sink.close();
      },
    ),
  );
}

/// Parses a `sha256sum` file and returns the hash for [fileName].
String? checksumForFile(String sums, String fileName) {
  for (final raw in sums.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) {
      continue;
    }
    final match = RegExp(r'^([a-fA-F0-9]{64})\s+\*?(\S+)$').firstMatch(line);
    if (match != null && match.group(2) == fileName) {
      return match.group(1)!.toLowerCase();
    }
  }
  return null;
}

/// Reads an HTTPS body as UTF-8. Non-200 responses throw.
Future<String> readHttpsText(HttpFetcher fetcher, Uri uri) async {
  final response = await fetcher.get(requireHttps(uri));
  final builder = BytesBuilder(copy: false);
  await for (final chunk in response.body) {
    builder.add(chunk);
  }
  if (response.statusCode != 200) {
    throw DownloadException('HTTP ${response.statusCode} for $uri.');
  }
  return utf8.decode(builder.takeBytes());
}

/// Decodes a JSON body and reports a useful error when it is not JSON.
Object decodeJsonBody(String source, String label) {
  try {
    return jsonDecode(source);
  } on FormatException catch (error) {
    throw CliException('$label is not valid JSON: $error');
  }
}
