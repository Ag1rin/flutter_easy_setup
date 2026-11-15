import 'package:path/path.dart' as p;

import '../models/cli_exception.dart';

/// Accepts a Dart package name and rejects path pieces.
void validatePackageName(String name) {
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    throw const CliException(
      'Project name must be a Dart package name, such as my_app.',
    );
  }
}

/// Extra files written after `flutter create`.
Map<String, String> templateFiles(String template) {
  return switch (template) {
    'basic' => const {},
    'state' => {p.join('lib', 'main.dart'): _stateMain},
    'clean' => {
      p.join('lib', 'src', 'domain', '.gitkeep'): '',
      p.join('lib', 'src', 'data', '.gitkeep'): '',
      p.join('lib', 'src', 'presentation', '.gitkeep'): '',
    },
    _ => throw CliException('Unknown template: $template'),
  };
}

const _stateMain = r'''
import 'package:flutter/material.dart';

void main() {
  runApp(const SetupApp());
}

final class SetupApp extends StatelessWidget {
  const SetupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CounterPage(model: CounterModel()),
    );
  }
}

final class CounterModel extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count += 1;
    notifyListeners();
  }
}

final class CounterPage extends StatelessWidget {
  const CounterPage({required this.model, super.key});

  final CounterModel model;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model,
      builder: (context, _) {
        return Scaffold(
          body: Center(child: Text('${model.count}')),
          floatingActionButton: FloatingActionButton(
            onPressed: model.increment,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
''';
