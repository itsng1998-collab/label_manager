// ignore_for_file: constant_identifier_names

enum UserGrade {
  SYSTEM_ADMIN_USER(0),
  COOP_ADMIN_USER(1),
  MANAGER_USER(2),
  CLIENT_USER(3);

  final int code;
  const UserGrade(this.code);

  static UserGrade fromCode(int code) =>
      UserGrade.values.firstWhere((grade) => grade.code == code);

  String get label {
    switch (this) {
      case UserGrade.SYSTEM_ADMIN_USER:
        return '시스템 관리자';
      case UserGrade.COOP_ADMIN_USER:
        return '협력업체 관리자';
      case UserGrade.MANAGER_USER:
        return '책임자';
      case UserGrade.CLIENT_USER:
        return '일반 사용자';
    }
  }
}

class User {
  static const String SYSTEM = 'SYSTEM';
  static User? instance;

  final String userId;
  final int marketId;
  final String name;
  final String pwd;
  final UserGrade grade;
  final String marketName;
  final String customerName;

  const User({
    required this.userId,
    required this.marketId,
    required this.name,
    required this.pwd,
    required this.grade,
    required this.marketName,
    required this.customerName,
  });

  static void setInstance(User? user) {
    instance = user;
  }

  bool get canEditItemDetails => grade != UserGrade.CLIENT_USER;

  bool get canManageItemStructure => canEditItemDetails;

  bool get canAccessCommonLabelManagement => grade != UserGrade.CLIENT_USER;

  bool get canEdit => canEditItemDetails;

  @override
  String toString() =>
      '$userId ($name), MarketId: $marketId, Grade: $grade, Market: $marketName, Customer: $customerName';
}
