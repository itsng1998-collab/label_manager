abstract class DbDriver {
  bool get isConnected;

  Future<bool> connect({
    required String ip,
    required String port,
    required String databaseName,
    required String username,
    required String password,
    int timeoutInSeconds = 15,
  });

  Future<Object> getData(String sql);

  Future<Object> writeData(String sql);

  Future<Object> getDataWithParams(String sql, Map<String, dynamic> params);

  Future<Object> writeDataWithParams(String sql, Map<String, dynamic> params);

  Future<bool> disconnect();
}
