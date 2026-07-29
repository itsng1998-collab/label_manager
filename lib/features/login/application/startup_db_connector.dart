import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/database/db_connection_service.dart';
import 'package:label_manager/database/db_server_connect_info.dart';
import 'package:label_manager/utils/log_context.dart';

typedef StartupDbConnectionState = bool Function();
typedef StartupDbConnect = Future<bool> Function(ServerConnectInfo info);
typedef StartupDbConnectInfoLoader = Future<ServerConnectInfo?> Function();
typedef StartupDbMonitorStarter = void Function(ServerConnectInfo info);

class StartupDbConnector {
  StartupDbConnector({
    StartupDbConnectionState? isConnected,
    StartupDbConnect? connect,
    StartupDbConnectInfoLoader? loadConnectInfo,
    StartupDbMonitorStarter? startMonitor,
  }) : _isConnected = isConnected ?? _defaultIsConnected,
       _connect = connect ?? _defaultConnect,
       _loadConnectInfo =
           loadConnectInfo ?? DbServerConnectInfoHelper.getLastConnectDBInfo,
       _startMonitor = startMonitor ?? _defaultStartMonitor;

  final StartupDbConnectionState _isConnected;
  final StartupDbConnect _connect;
  final StartupDbConnectInfoLoader _loadConnectInfo;
  final StartupDbMonitorStarter _startMonitor;

  ServerConnectInfo? lastConnectInfo;

  bool get isConnected => _isConnected();

  Future<bool> connect() async {
    if (isConnected) {
      debugLog('already connected');
      return true;
    }

    final info = await _loadConnectInfo();
    lastConnectInfo = info;
    if (info == null) {
      debugLog('No previous server connect info found.');
      return false;
    }

    final connected = await _connect(info);
    if (!connected) {
      debugLog('Failed to connect');
      throw Exception('Failed to connect');
    }

    _startMonitor(info);
    debugLog('connected successfully');
    return true;
  }

  static bool _defaultIsConnected() => DbClient.instance.isConnected;

  static Future<bool> _defaultConnect(ServerConnectInfo info) =>
      DbClient.instance.connect(
        ip: info.serverIp,
        port: info.serverPort.toString(),
        databaseName: info.databaseName,
        username: info.userId,
        password: info.password,
        timeoutInSeconds: 30,
      );

  static void _defaultStartMonitor(ServerConnectInfo info) {
    DbConnectionService.instance.attachAndStart(info: info);
  }
}