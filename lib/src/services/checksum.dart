import 'dart:io';

import 'package:crypto/crypto.dart';

/// SHA-256 of [file], as lowercase hex.
Future<String> sha256OfFile(File file) async {
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}

/// SHA-256 of an in-memory byte list, as lowercase hex.
String sha256OfBytes(List<int> bytes) {
  return sha256.convert(bytes).toString();
}
