import 'dart:io';

import 'package:flutter_easy_setup/src/app.dart';
import 'package:flutter_easy_setup/src/models/cli_exception.dart';

/// Entry point for the `fes` executable.
Future<void> main(List<String> arguments) async {
  final app = FesApp.production();
  try {
    exit(await app.run(arguments));
  } on CliException catch (error, stack) {
    app.logger.error(error, stack);
    stderr.writeln(error.message);
    exit(error.exitCode);
  } on FormatException catch (error, stack) {
    app.logger.error(error, stack);
    stderr.writeln(error.message);
    exit(1);
  } catch (error, stack) {
    app.logger.error(error, stack);
    stderr.writeln(error);
    exit(2);
  }
}
