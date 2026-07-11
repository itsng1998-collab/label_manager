import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/windows_odbc/odbc_driver.dart';
import 'package:label_manager/database/windows_odbc/odbc_error.dart';

void main() {
  group('[ODBC connection state]', () {
    test('communication SQLSTATE invalidates the connection', () {
      expect(
        odbcErrorInvalidatesConnection(
          OdbcException('communication link failure', sqlState: '08S01'),
        ),
        isTrue,
      );
    });

    test('invalid handle result invalidates the connection', () {
      expect(
        odbcErrorInvalidatesConnection(OdbcException('SQLExecute failed: -2')),
        isTrue,
      );
    });

    test('statement errors keep the connection eligible for reuse', () {
      expect(
        odbcErrorInvalidatesConnection(
          OdbcException('syntax error', sqlState: '42000'),
        ),
        isFalse,
      );
      expect(
        odbcErrorInvalidatesConnection(
          OdbcException('constraint violation', sqlState: '23000'),
        ),
        isFalse,
      );
    });
  });
}
