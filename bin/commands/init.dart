import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'error.dart';

class Init {
  late final String projectPath;

  late final String projectName;

  Init() {
    projectPath = Directory.current.path;
    projectName = _getProjectName(projectPath);
  }

  Future<int> call() async {
    if (!ask()) {
      return 1;
    }

    var templatePath = await _getTemplatePath();

    stdout.write('Initializing...\n');

    _prepare();

    var entityList = _getEntities(templatePath);
    _createDirectories(templatePath, entityList);
    _createFiles(templatePath, entityList);

    stdout.write('Done.\n'
        'Create something great!\n');

    return 0;
  }

  bool ask() {
    stdout.write('Welcome to Alba!\n\n'
        'This command will init Alba for the current project "$projectName" in path "$projectPath".\n'
        'It will REPLACE lib and tests directories and also add (or replace) files to project root.\n\n'
        'Are you sure? (yes/no): ');
    var answer = stdin.readLineSync();

    return null != answer &&
        ('y' == answer.toLowerCase() || 'yes' == answer.toLowerCase());
  }

  String _getProjectName(String projectPath) {
    YamlMap pubspec;

    try {
      pubspec =
          loadYaml(File(join(projectPath, 'pubspec.yaml')).readAsStringSync());
    } on Exception {
      throw CommandError('No pubspec.yaml file found or is unreadable.\n'
          'This command should be run from the root of your Flutter project.');
    }

    if (!pubspec.containsKey('name') || (pubspec['name'] as String).isEmpty) {
      throw CommandError('There isn\'t a project name on pubspec.yaml file.');
    }

    return pubspec['name'];
  }

  Future<String> _getTemplatePath() async {
    var libPath = (await Isolate.resolvePackageUri(
            Uri(scheme: 'package', path: 'alba/')))!
        .path;

    return '$libPath../template';
  }

  List<FileSystemEntity> _getEntities(String templatePath) =>
      Directory(templatePath)
          .listSync(recursive: true)
          .where((entity) => !basename(entity.path).startsWith('.'))
          .toList();

  void _prepare() {
    if (Directory(join(projectPath, 'lib')).existsSync()) {
      Directory(join(projectPath, 'lib')).deleteSync(recursive: true);
    }
    Directory(join(projectPath, 'lib')).createSync();

    if (Directory(join(projectPath, 'test')).existsSync()) {
      Directory(join(projectPath, 'test')).deleteSync(recursive: true);
    }
    Directory(join(projectPath, 'test')).createSync();
  }

  void _createDirectories(
    String templatePath,
    List<FileSystemEntity> entityList,
  ) {
    for (var entity in entityList) {
      if (entity is Directory) {
        var destinationPath =
            projectPath + entity.path.replaceFirst(templatePath, '');

        if (entity is Directory) {
          Directory(destinationPath).createSync(recursive: true);
        }
      }
    }
  }

  void _createFiles(
    String templatePath,
    List<FileSystemEntity> entityList,
  ) {
    for (var entity in entityList) {
      if (entity is File) {
        var destinationPath = projectPath +
            entity.path
                .replaceFirst(templatePath, '')
                .replaceFirst(RegExp('.tmpl\$'), '');

        var templateContents = entity.readAsStringSync();
        var renderedContents =
            templateContents.replaceAll('{{projectName}}', projectName);

        File(destinationPath)
          ..createSync(recursive: true)
          ..writeAsStringSync(renderedContents);
      }
    }
  }
}
