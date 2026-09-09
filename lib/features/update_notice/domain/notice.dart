import 'package:label_manager/core/user.dart';

class Notice {
  const Notice({required this.message, required this.state});

  final String message;
  final int state;

  factory Notice.fromMap(Map<String, dynamic> map) => Notice(
    message: (map['UN_MSG'] ?? '').toString(),
    state: int.tryParse((map['UN_STATE'] ?? '0').toString()) ?? 0,
  );
}

class NoticeTargetUser {
  const NoticeTargetUser({
    required this.userId,
    required this.customerId,
    required this.customerName,
    required this.marketId,
    required this.marketName,
  });

  final String userId;
  final int customerId;
  final String customerName;
  final int marketId;
  final String marketName;

  factory NoticeTargetUser.fromMap(Map<String, dynamic> map) {
    int number(String key) => int.tryParse((map[key] ?? '').toString()) ?? 0;
    return NoticeTargetUser(
      userId: (map['USER_ID'] ?? '').toString(),
      customerId: number('CUSTOMER_ID'),
      customerName: (map['CUSTOMER_NAME'] ?? '').toString(),
      marketId: number('MARKET_ID'),
      marketName: (map['MARKET_NAME'] ?? '').toString(),
    );
  }
}

List<NoticeTargetUser> filterNoticeTargetUsers(
  List<NoticeTargetUser> users, {
  int? customerId,
  int? marketId,
}) => users
    .where(
      (user) =>
          (customerId == null || user.customerId == customerId) &&
          (marketId == null || user.marketId == marketId),
    )
    .toList(growable: false);

int findNoticeTargetUserIndex(
  List<NoticeTargetUser> users,
  String query, {
  int startAfter = -1,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty || users.isEmpty) return -1;
  for (var offset = 1; offset <= users.length; offset += 1) {
    final index = (startAfter + offset) % users.length;
    if (users[index].userId.toLowerCase().contains(normalizedQuery)) {
      return index;
    }
  }
  return -1;
}

enum UpdateNoticeSaveTarget {
  selectedUsers,
  allCooperators,
  currentCooperator,
  currentUser,
}

UpdateNoticeSaveTarget resolveUpdateNoticeSaveTarget({
  required UserGrade grade,
  required bool selectUsers,
  required bool allCooperators,
}) {
  if (grade != UserGrade.SYSTEM_ADMIN_USER &&
      grade != UserGrade.COOP_ADMIN_USER) {
    return UpdateNoticeSaveTarget.currentUser;
  }
  if (selectUsers) return UpdateNoticeSaveTarget.selectedUsers;
  if (grade == UserGrade.SYSTEM_ADMIN_USER && allCooperators) {
    return UpdateNoticeSaveTarget.allCooperators;
  }
  return UpdateNoticeSaveTarget.currentCooperator;
}

class UpdateNoticeSaveRequest {
  const UpdateNoticeSaveRequest({
    required this.target,
    required this.message,
    required this.selectedUserIds,
    required this.dontShowAgain,
  });

  final UpdateNoticeSaveTarget target;
  final String? message;
  final List<String> selectedUserIds;
  final bool dontShowAgain;
}
