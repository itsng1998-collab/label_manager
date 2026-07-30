import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/database/windows_odbc/odbc_driver.dart';
import 'package:label_manager/database/windows_odbc/odbc_error.dart';

void main() {
  group('[ODBC connection state]', () {
    test('tries SQL Server ODBC Driver 18 before Driver 17', () {
      expect(
        odbcSqlServerDriverNames(),
        const <String>[
          '{ODBC Driver 18 for SQL Server}',
          '{ODBC Driver 17 for SQL Server}',
        ],
      );
    });

    test('falls back only when the requested ODBC driver is missing', () {
      expect(
        odbcErrorAllowsDriverFallback(
          OdbcException('driver not found', sqlState: 'IM002'),
        ),
        isTrue,
      );
      expect(
        odbcErrorAllowsDriverFallback(
          OdbcException('login failed', sqlState: '28000'),
        ),
        isFalse,
      );
    });

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
