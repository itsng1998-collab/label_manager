import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/db_server_connect_info.dart';
import 'package:label_manager/features/login/application/startup_db_connector.dart';

void main() {
  const info = ServerConnectInfo(
    serverIp: '127.0.0.1',
    databaseName: 'LABEL',
    serverPort: 1433,
    userId: 'user',
    password: 'password',
    serverName: 'server',
    customerType: CustomerType.CUST_TYPE_NORMAL,
  );

  test('already connected skips info load and monitor start', () async {
    var loadCalled = false;
    var connectCalled = false;
    var monitorCalled = false;
    final connector = StartupDbConnector(
      isConnected: () => true,
      loadConnectInfo: () async {
        loadCalled = true;
        return info;
      },
      connect: (_) async {
        connectCalled = true;
        return true;
      },
      startMonitor: (_) => monitorCalled = true,
    );

    expect(await connector.connect(), isTrue);
    expect(loadCalled, isFalse);
    expect(connectCalled, isFalse);
    expect(monitorCalled, isFalse);
  });

  test('missing connect info stops before DB connect', () async {
    var connectCalled = false;
    final connector = StartupDbConnector(
      isConnected: () => false,
      loadConnectInfo: () async => null,
      connect: (_) async {
        connectCalled = true;
        return true;
      },
      startMonitor: (_) {},
    );

    expect(await connector.connect(), isFalse);
    expect(connector.lastConnectInfo, isNull);
    expect(connectCalled, isFalse);
  });

  test('successful connect starts monitor with loaded info', () async {
    ServerConnectInfo? connectedWith;
    ServerConnectInfo? monitoredWith;
    final connector = StartupDbConnector(
      isConnected: () => false,
      loadConnectInfo: () async => info,
      connect: (value) async {
        connectedWith = value;
        return true;
      },
      startMonitor: (value) => monitoredWith = value,
    );

    expect(await connector.connect(), isTrue);
    expect(connector.lastConnectInfo, same(info));
    expect(connectedWith, same(info));
    expect(monitoredWith, same(info));
  });

  test('failed connect throws and does not start monitor', () async {
    var monitorCalled = false;
    final connector = StartupDbConnector(
      isConnected: () => false,
      loadConnectInfo: () async => info,
      connect: (_) async => false,
      startMonitor: (_) => monitorCalled = true,
    );

    await expectLater(connector.connect(), throwsException);
    expect(monitorCalled, isFalse);
  });
}