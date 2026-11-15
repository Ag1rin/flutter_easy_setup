import 'dart:io';

import '../models/cli_exception.dart';
import 'checksum.dart';
import 'http_fetcher.dart';
import 'https.dart';
import 'release_index.dart';

/// Pauses between download attempts.
abstract interface class Sleeper {
  /// Waits for [duration].
  Future<void> sleep(Duration duration);
}

/// [Sleeper] that does not wait. Tests use this.
final class NoopSleeper implements Sleeper {
  /// Creates a sleeper that returns immediately.
  const NoopSleeper();

  @override
  Future<void> sleep(Duration duration) async {}
}

/// [Sleeper] that uses the real clock.
final class SystemSleeper implements Sleeper {
  /// Creates a real sleeper.
  const SystemSleeper();

  @override
  Future<void> sleep(Duration duration) => Future<void>.delayed(duration);
}

/// Streams an archive to disk, resumes when the server allows it, and checks
/// SHA-256 before returning.
final class ArchiveDownloader {
  /// Creates a downloader.
  const ArchiveDownloader({
    required this.fetcher,
    this.sleeper = const SystemSleeper(),
    this.maxAttempts = 3,
  });

  /// HTTP client.
  final HttpFetcher fetcher;

  /// Wait between attempts.
  final Sleeper sleeper;

  /// How many times a network failure is tried.
  final int maxAttempts;

  /// Downloads [url] to [destination] and returns that file.
  Future<File> download({
    required Uri url,
    required File destination,
    required String expectedSha256,
    void Function(int received, int? total)? onProgress,
  }) async {
    requireHttps(url);
    if (!isSha256Hex(expectedSha256)) {
      throw const CliException('Expected SHA-256 is not 64 hex characters.');
    }
    final expected = expectedSha256.toLowerCase();
    if (destination.existsSync() && await _matches(destination, expected)) {
      return destination;
    }
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _transfer(url, destination, onProgress);
        if (!await _matches(destination, expected)) {
          final actual = await sha256OfFile(destination);
          await _delete(destination);
          throw DownloadException(
            'SHA-256 mismatch. Expected $expected, got $actual.',
          );
        }
        return destination;
      } on DownloadException {
        rethrow;
      } catch (error) {
        lastError = error;
        if (attempt == maxAttempts) {
          break;
        }
        await sleeper.sleep(Duration(milliseconds: 200 << (attempt - 1)));
      }
    }
    throw DownloadException('Download failed: $lastError');
  }

  Future<void> _transfer(
    Uri url,
    File destination,
    void Function(int received, int? total)? onProgress,
  ) async {
    final existing = destination.existsSync() ? destination.lengthSync() : 0;
    final headers = <String, String>{
      if (existing > 0) 'Range': 'bytes=$existing-',
    };
    final response = await fetcher.get(url, headers: headers);
    if (response.statusCode == 416 && existing > 0) {
      await _drain(response.body);
      return;
    }
    final append = response.statusCode == 206;
    if (response.statusCode != 200 && !append) {
      await _drain(response.body);
      throw DownloadException(
        'Download failed with HTTP ${response.statusCode} for $url.',
      );
    }
    if (!append && existing > 0) {
      await _delete(destination);
    }
    final total = _total(response.contentLength, existing, append);
    var received = append ? existing : 0;
    final sink = destination.openWrite(
      mode: append ? FileMode.append : FileMode.write,
    );
    try {
      await for (final chunk in response.body) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  Future<bool> _matches(File file, String expected) async {
    if (!file.existsSync() || file.lengthSync() == 0) {
      return false;
    }
    return await sha256OfFile(file) == expected;
  }
}

int? _total(int? contentLength, int existing, bool append) {
  if (contentLength == null) {
    return null;
  }
  return append ? existing + contentLength : contentLength;
}

Future<void> _drain(Stream<List<int>> body) async {
  await body.drain<void>();
}

Future<void> _delete(File file) async {
  if (file.existsSync()) {
    await file.delete();
  }
}
