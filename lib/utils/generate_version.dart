// lib/utils/generate_version.dart
// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'package:yaml/yaml.dart';

void main() {
  // 1) pubspec.yaml 읽기
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    stderr.writeln('Error: pubspec.yaml 파일을 찾을 수 없습니다.');
    exit(1);
  }

  final pubspecContent = pubspecFile.readAsStringSync();

  // 2) YAML 파싱
  final pubspec = loadYaml(pubspecContent) as YamlMap;
  final version = pubspec['version'] as String?;
  
  if (version == null) {
    stderr.writeln('Error: pubspec.yaml에 version이 정의되어 있지 않습니다.');
    exit(1);
  }

  // 3) version.txt 쓰기
  final outFile = File('version.txt');
  outFile.writeAsStringSync(version);
  stdout.writeln('Generated version.txt: $version');
}
