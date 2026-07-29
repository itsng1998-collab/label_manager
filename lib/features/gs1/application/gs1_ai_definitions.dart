import 'package:label_manager/features/gs1/domain/gs1_ai_definition.dart';

class Gs1AiDefinitions {
  const Gs1AiDefinitions._();

  static Map<String, Gs1AiDefinition> values = const {};

  static void set(Iterable<Gs1AiDefinition> definitions) {
    values = Map.unmodifiable({
      for (final definition in definitions) definition.code: definition,
    });
  }
}
