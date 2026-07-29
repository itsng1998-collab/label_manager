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

  factory Cooperator.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();

    return Cooperator(
      id: s('COOP_ID'),
      name: s('NAME'),
    );
  }

  @override
  String toString() => 'CooperatorId: $id, Name: $name';
}
