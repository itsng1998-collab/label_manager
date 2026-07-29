import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/scale_output/data/db_scale_connect_info.dart';

void main() {
  test('windows debug uses application support path instead of cwd', () {
    expect(
      DbScaleConnectInfoHelper.desktopDbBaseDirPath(
        isWindows: true,
        isReleaseMode: false,
        applicationSupportPath: r'C:/Users/test/AppData/Roaming/label_manager',
        windowsAppDataPath: r'C:/Users/test/AppData/Roaming',
      ),
      r'C:/Users/test/AppData/Roaming/label_manager',
    );
  });

  test('windows release prefers appdata vendor path when available', () {
    expect(
      DbScaleConnectInfoHelper.desktopDbBaseDirPath(
        isWindows: true,
        isReleaseMode: true,
        applicationSupportPath: r'C:/Users/test/AppData/Roaming/label_manager',
        windowsAppDataPath: r'C:/Users/test/AppData/Roaming',
      ),
      p.join(r'C:/Users/test/AppData/Roaming', 'com.itsng', 'label_manager'),
    );
  });

  test('desktop non-windows uses application support path', () {
    expect(
      DbScaleConnectInfoHelper.desktopDbBaseDirPath(
        isWindows: false,
        isReleaseMode: false,
        applicationSupportPath: '/home/test/.local/share/label_manager',
      ),
      '/home/test/.local/share/label_manager',
    );
  });
}