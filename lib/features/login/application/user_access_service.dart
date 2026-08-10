import 'package:label_manager/core/admin_connect_session.dart';
import 'package:label_manager/core/user.dart';
import 'package:label_manager/features/login/data/user_access_dao.dart';
import 'package:label_manager/features/login/data/user_access_local_store.dart';
import 'package:label_manager/features/login/domain/user_access_serial.dart';

typedef UserAccessDataLoader = Future<String?> Function(String userId);
typedef UserAccessDataSaver = Future<String> Function(
  String userId,
  String userName,
);
typedef UserAccessLocalReader = Future<String> Function();
typedef UserAccessLocalWriter = Future<void> Function(String value);
typedef UserAccessSerialPrompt = Future<bool> Function(
  String temporaryNumber,
);

bool userAccessAuthorizationRequired(LoginAuthenticationMode mode) =>
    mode != LoginAuthenticationMode.masterKey;

class UserAccessService {
  UserAccessService({
    UserAccessDataLoader? loadAccessData,
    UserAccessDataSaver? saveAccessData,
    UserAccessLocalReader? readLocalValue,
    UserAccessLocalWriter? writeLocalValue,
    DateTime Function()? now,
  }) : _loadAccessData = loadAccessData ?? UserAccessDAO.selectAccessData,
       _saveAccessData =
           saveAccessData ??
           ((userId, userName) => UserAccessDAO.saveAccess(
             userId: userId,
             userName: userName,
           )),
       _readLocalValue = readLocalValue ?? UserAccessLocalStore.read,
       _writeLocalValue = writeLocalValue ?? UserAccessLocalStore.write,
       _now = now ?? DateTime.now;

  final UserAccessDataLoader _loadAccessData;
  final UserAccessDataSaver _saveAccessData;
  final UserAccessLocalReader _readLocalValue;
  final UserAccessLocalWriter _writeLocalValue;
  final DateTime Function() _now;

  Future<bool> authorize({
    required User user,
    required UserAccessSerialPrompt promptSerial,
  }) async {
    final accessData = await _loadAccessData(user.userId);
    final localValue = await _readLocalValue();
    if (accessData != null &&
        userAccessLocalValue(accessData) == localValue) {
      return true;
    }

    if (accessData == null && localValue.isEmpty) {
      await _saveAndStore(user);
      return true;
    }

    final temporaryNumber = userAccessTemporaryNumber(_now());
    if (!await promptSerial(temporaryNumber)) return false;
    await _saveAndStore(user);
    return true;
  }

  Future<void> _saveAndStore(User user) async {
    final accessData = await _saveAccessData(user.userId, user.name);
    await _writeLocalValue(userAccessLocalValue(accessData));
  }
}