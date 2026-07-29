import 'package:flutter/material.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_server_connect_info.dart';
import 'package:label_manager/features/login/application/startup_db_connector.dart';
import 'package:label_manager/utils/log_context.dart';
import 'package:label_manager/widgets/snackbar.dart';

class StartupDbHelper {
  StartupDbHelper({StartupDbConnector? connector})
    : _connector = connector ?? StartupDbConnector();

  final StartupDbConnector _connector;

  ServerConnectInfo? get lastConnectInfo => _connector.lastConnectInfo;

  Future<bool> connectToServerDB(BuildContext context) async {
    debugLog(START);
    if (_connector.isConnected) return true;

    var errorSnackBarShown = false;
    try {
      showSnackBar(
        context,
        '서버 데이터베이스에 접속 중 입니다...',
        type: SnackBarType.inProgress,
      );
      return await _connector.connect();
    } catch (error) {
      debugLog('Exception during DB connect: $error');

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        showSnackBar(
          context,
          '서버 접속에 실패하였습니다!!\n인터넷 연결상태를 먼저 확인해주시고 02)3274-1776으로 전화주세요!',
          type: SnackBarType.error,
        );
        errorSnackBarShown = true;
      }
      return false;
    } finally {
      if (!errorSnackBarShown && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      debugLog(END);
    }
  }
}