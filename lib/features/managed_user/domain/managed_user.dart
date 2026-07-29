import 'package:label_manager/models/user.dart';

class ManagedUser {
  const ManagedUser({
    required this.userId,
    required this.marketId,
    required this.name,
    required this.password,
    required this.grade,
    required this.marketName,
    required this.customerName,
  });

  final String userId;
  final int marketId;
  final String name;
  final String password;
  final UserGrade grade;
  final String marketName;
  final String customerName;

  factory ManagedUser.fromMap(Map<String, dynamic> map) {
    String text(String key) => (map[key] ?? '').toString();
    int number(String key) => int.tryParse(text(key)) ?? 0;
    return ManagedUser(
      userId: text('USER_ID'),
      marketId: number('MARKET_ID'),
      name: text('NAME'),
      password: text('PASSWORD'),
      grade: UserGrade.fromCode(number('GRADE')),
      marketName: text('MARKET_NAME'),
      customerName: text('CUSTOMER_NAME'),
    );
  }
}
