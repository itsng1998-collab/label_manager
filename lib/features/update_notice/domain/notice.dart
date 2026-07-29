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
  const NoticeTargetUser({required this.userId, required this.customerName});

  final String userId;
  final String customerName;

  factory NoticeTargetUser.fromMap(Map<String, dynamic> map) =>
      NoticeTargetUser(
        userId: (map['USER_ID'] ?? '').toString(),
        customerName: (map['CUSTOMER_NAME'] ?? '').toString(),
      );
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
