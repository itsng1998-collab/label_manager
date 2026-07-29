// UTF-8, 한국어 주석

class Cooperator {
  static Cooperator? instance;

  final String id;
  final String name;

  const Cooperator({
    required this.id,
    required this.name,
  });

  static void setInstance(Cooperator? cooperator) {
    instance = cooperator;
  }

  @override
  String toString() => 'CooperatorId: $id, Name: $name';
}