import 'dart:io';

import 'package:flutter_easy_setup/src/models/cpu_arch.dart';
import 'package:flutter_easy_setup/src/services/checksum.dart';
import 'package:flutter_easy_setup/src/services/downloader.dart';
import 'package:flutter_easy_setup/src/services/http_fetcher.dart';
import 'package:flutter_easy_setup/src/services/release_index.dart';
import 'package:test/test.dart';

void main() {
  test('selects the current stable archive for the requested arch', () {
    final index = ReleaseIndex.parse(_fixture);
    final x64 = index.select(channel: 'stable', arch: CpuArch.x64);
    final arm = index.select(channel: 'stable', arch: CpuArch.arm64);
    expect(x64.version, '3.24.0');
    expect(x64.archive, contains('flutter_windows_3.24.0'));
    expect(arm.archive, contains('arm64'));
    expect(x64.sha256, isNot(arm.sha256));
    final url = x64.downloadUri('https://storage.googleapis.com');
    expect(url.scheme, 'https');
    expect(url.path, contains('flutter_windows_3.24.0-stable.zip'));
  });

  test('selects an older version and the beta channel', () {
    final index = ReleaseIndex.parse(_fixture);
    final older = index.select(
      channel: 'stable',
      arch: CpuArch.x64,
      version: '3.22.0',
    );
    expect(older.hash, 'ccc');
    final beta = index.select(channel: 'beta', arch: CpuArch.x64);
    expect(beta.version, '3.25.0-0.1.pre');
  });

  test('rejects a missing archive, a bad channel, and a bad version', () {
    final index = ReleaseIndex.parse(_fixture);
    expect(
      () => index.select(
        channel: 'stable',
        arch: CpuArch.arm64,
        version: '3.22.0',
      ),
      throwsA(isA<Exception>()),
    );
    expect(() => normalizeChannel('dev'), throwsA(isA<Exception>()));
    expect(
      () => validateFlutterVersion('../3.24.0'),
      throwsA(isA<Exception>()),
    );
  });

  test('downloads, resumes, retries, and rejects a bad checksum', () async {
    final bytes = List<int>.generate(8, (index) => index + 1);
    final hash = sha256OfBytes(bytes);
    final dir = await Directory.systemTemp.createTemp('fes-dl-');
    final file = File('${dir.path}${Platform.pathSeparator}sdk.zip');
    await file.writeAsBytes(bytes.take(3).toList());
    final fetcher = _FakeFetcher(bytes);
    final downloader = ArchiveDownloader(
      fetcher: fetcher,
      sleeper: const NoopSleeper(),
    );
    await downloader.download(
      url: Uri.parse('https://example.com/sdk.zip'),
      destination: file,
      expectedSha256: hash,
    );
    expect(await file.readAsBytes(), bytes);
    expect(fetcher.calls, 1);

    final flaky = _FakeFetcher(bytes, failTimes: 1);
    final second = File('${dir.path}${Platform.pathSeparator}retry.zip');
    await ArchiveDownloader(
      fetcher: flaky,
      sleeper: const NoopSleeper(),
    ).download(
      url: Uri.parse('https://example.com/retry.zip'),
      destination: second,
      expectedSha256: hash,
    );
    expect(flaky.calls, 2);

    final bad = File('${dir.path}${Platform.pathSeparator}bad.zip');
    await expectLater(
      ArchiveDownloader(
        fetcher: _FakeFetcher(bytes),
        sleeper: const NoopSleeper(),
      ).download(
        url: Uri.parse('https://example.com/bad.zip'),
        destination: bad,
        expectedSha256: 'ab' * 32,
      ),
      throwsA(isA<Exception>()),
    );
    expect(bad.existsSync(), isFalse);
    await dir.delete(recursive: true);
  });
}

class _FakeFetcher implements HttpFetcher {
  _FakeFetcher(this.bytes, {this.failTimes = 0});

  final List<int> bytes;
  final int failTimes;
  var calls = 0;

  @override
  Future<ByteResponse> get(
    Uri uri, {
    Map<String, String> headers = const {},
  }) async {
    calls += 1;
    if (calls <= failTimes) {
      throw const SocketException('offline');
    }
    final range = headers['Range'];
    if (range == null) {
      return ByteResponse(
        statusCode: 200,
        body: Stream<List<int>>.value(bytes),
        contentLength: bytes.length,
      );
    }
    final start = int.parse(
      range.substring(range.indexOf('=') + 1, range.indexOf('-')),
    );
    final slice = bytes.sublist(start);
    return ByteResponse(
      statusCode: 206,
      body: Stream<List<int>>.value(slice),
      contentLength: slice.length,
    );
  }
}

const _fixture = '''
{
  "current_release": {"stable": "aaa", "beta": "bbb"},
  "releases": [
    {
      "hash": "aaa",
      "channel": "stable",
      "version": "3.24.0",
      "dart_sdk_arch": "x64",
      "archive": "stable/windows/flutter_windows_3.24.0-stable.zip",
      "sha256": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "release_date": "2024-08-01T00:00:00Z"
    },
    {
      "hash": "aaa",
      "channel": "stable",
      "version": "3.24.0",
      "dart_sdk_arch": "arm64",
      "archive": "stable/macos/flutter_macos_arm64_3.24.0-stable.zip",
      "sha256": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      "release_date": "2024-08-01T00:00:00Z"
    },
    {
      "hash": "ccc",
      "channel": "stable",
      "version": "3.22.0",
      "dart_sdk_arch": "x64",
      "archive": "stable/windows/flutter_windows_3.22.0-stable.zip",
      "sha256": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
      "release_date": "2024-01-01T00:00:00Z"
    },
    {
      "hash": "bbb",
      "channel": "beta",
      "version": "3.25.0-0.1.pre",
      "dart_sdk_arch": "x64",
      "archive": "beta/windows/flutter_windows_3.25.0-0.1.pre-beta.zip",
      "sha256": "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
      "release_date": "2024-09-01T00:00:00Z"
    },
    {
      "hash": "eee",
      "channel": "stable",
      "version": "3.16.0",
      "dart_sdk_arch": "x64",
      "archive": "../secret.zip",
      "sha256": "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
    }
  ]
}
''';
