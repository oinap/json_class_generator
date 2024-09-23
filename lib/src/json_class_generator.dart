import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'dart:convert';
import 'package:analyzer/dart/element/element.dart';
import 'package:json_class_generator_annotations/json_class_generator_annotations.dart';

class JsonClassGenerator extends GeneratorForAnnotation<JsonClass> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    // Extract JSON and generate the main class code
    final fileContent = await buildStep.readAsString(buildStep.inputId);
    final jsonString = extractJsonString(fileContent);
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;

    // Main class name inferred from the element's display name
    final mainClassName =
        '${element.displayName[0].toUpperCase()}${element.displayName.substring(1)}';
    final generatedClasses = <String>[];
    final generatedClassNames =
        <String>{}; // Set to track generated class names

    // Recursively generate classes
    generateClassFromJson(
        mainClassName, jsonMap, generatedClasses, generatedClassNames);

    // Combine all generated classes into the final output
    return generatedClasses.join('\n\n');
  }

  String extractJsonString(String content) {
    final regex = RegExp(r"json = '''(.*?)'''", dotAll: true);
    final match = regex.firstMatch(content);
    return match?.group(1) ?? '{}';
  }

  void generateClassFromJson(String className, Map<String, dynamic> jsonMap,
      List<String> generatedClasses, Set<String> generatedClassNames) {
    // Check if the class has already been generated to prevent duplication
    if (generatedClassNames.contains(className)) {
      return;
    }

    // Mark this class as generated
    generatedClassNames.add(className);

    final buffer = StringBuffer();

    buffer.writeln('class $className {');

    // Generate fields and track nested classes
    jsonMap.forEach((key, value) {
      final type = _getType(
          key, value, className, generatedClasses, generatedClassNames);
      buffer.writeln('  final $type $key;');
    });

    // Generate the constructor
    buffer.write('$className({');
    for (var key in jsonMap.keys) {
      buffer.write('required this.$key,');
    }
    buffer.writeln('});');

    // Generate fromJson method
    buffer.writeln('factory $className.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('  return $className(');
    jsonMap.forEach((key, value) {
      final type = _getType(
          key, value, className, generatedClasses, generatedClassNames);
      if (type.startsWith('Map')) {
        buffer.writeln('    $key: json[\'$key\'],');
      } else if (type == 'String' ||
          type == 'int' ||
          type == 'double' ||
          type == 'bool' ||
          type.startsWith('List')) {
        buffer.writeln('    $key: json[\'$key\'],');
      } else {
        buffer.writeln('    $key: $type.fromJson(json[\'$key\']),');
      }
    });
    buffer.writeln('  );');
    buffer.writeln('}');

    // Generate toJson method
    buffer.writeln('Map<String, dynamic> toJson() => {');
    jsonMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        buffer.writeln('  \'$key\': $key.toJson(),');
      } else {
        buffer.writeln('  \'$key\': $key,');
      }
    });
    buffer.writeln('};');

    buffer.writeln('}');

    // Add the class to the list of generated classes
    generatedClasses.add(buffer.toString());
  }

  String _getType(String key, dynamic value, String parentClassName,
      List<String> generatedClasses, Set<String> generatedClassNames) {
    if (value is String) return 'String';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) return 'List<dynamic>';
    if (value is Map<String, dynamic>) {
      // Generate a nested class for this map
      final nestedClassName = '${key[0].toUpperCase()}${key.substring(1)}';
      generateClassFromJson(
          nestedClassName, value, generatedClasses, generatedClassNames);
      return nestedClassName;
    }
    return 'dynamic';
  }
}

Builder jsonClassBuilder(BuilderOptions options) =>
    LibraryBuilder(JsonClassGenerator(),
        generatedExtension: '.json_class.g.dart', header: '');
