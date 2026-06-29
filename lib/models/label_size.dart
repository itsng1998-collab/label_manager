// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:label_manager/core/app.dart';
import 'package:label_manager/database/db_client.dart';
import 'package:label_manager/utils/log_context.dart';
import 'dao.dart';
import 'date_manager.dart';

class LabelSizeCommon {
  final int width;
  final int height;
  final String rtf;

  const LabelSizeCommon({
    required this.width,
    required this.height,
    required this.rtf,
  });

  LabelSizeCommon copyWith({int? width, int? height, String? rtf}) {
    return LabelSizeCommon(
      width: width ?? this.width,
      height: height ?? this.height,
      rtf: rtf ?? this.rtf,
    );
  }

  @override
  String toString() => 'Width: $width, Height: $height, RTF: $rtf';
}

class LabelSizeSetup {
	final bool readOnly;
	final bool useMakeDate;
	final bool useMakeTime;
	final bool useValidDate;
	final bool useValidTime;
	final PrintDateFormat makingDateFormat;
	final PrintTimeFormat makingTimeFormat;
	final PrintDateFormat validDateFormat;
	final PrintTimeFormat validTimeFormat;
	final String strMakeDate;
	final String strMakeTime;
	final String strValidDate;
	final String strValidTime;

	// 저울
	final bool useScale;

  const LabelSizeSetup({
    required this.readOnly,
    required this.useMakeDate,
    required this.useMakeTime,
    required this.useValidDate,
    required this.useValidTime,
    required this.makingDateFormat,
    required this.makingTimeFormat,
    required this.validDateFormat,
    required this.validTimeFormat,
    required this.strMakeDate,
    required this.strMakeTime,
    required this.strValidDate,
    required this.strValidTime,
    required this.useScale,
  });

  @override
  String toString() => 'ReadOnly: $readOnly, '
    'UseMakeDate: $useMakeDate, UseMakeTime: $useMakeTime, '
    'UseValidDate: $useValidDate, UseValidTime: $useValidTime, '
    'MakingDateFormat: $makingDateFormat, MakingTimeFormat: $makingTimeFormat, '
    'ValidDateFormat: $validDateFormat, ValidTimeFormat: $validTimeFormat, '
    'StrMakeDate: $strMakeDate, StrMakeTime: $strMakeTime, '
    'StrValidDate: $strValidDate, StrValidTime: $strValidTime, UseScale: $useScale';
}

class LabelSize {
  static List<LabelSize>? datas;

  final int labelSizeId;
  final int brandId;
  final String labelSizeName;
  final LabelSizeCommon? labelSizeCommon;
  final LabelSizeSetup? labelSizeSetup;

  const LabelSize({
    required this.labelSizeId,
    required this.brandId,
    required this.labelSizeName,
    this.labelSizeCommon,
    this.labelSizeSetup,
  });

  static void setDatas(List<LabelSize>? values) {
    datas = values;
  }

  static LabelSize? replaceCachedFormData(
    int labelSizeId,
    int? width,
    int? height,
    String formData,
  ) {
    final current = datas;
    if (current == null) return null;
    for (var index = 0; index < current.length; index += 1) {
      final labelSize = current[index];
      if (labelSize.labelSizeId != labelSizeId) continue;
      final common = labelSize.labelSizeCommon;
      if (common == null) return labelSize;
      final updated = labelSize.copyWith(
        labelSizeCommon: common.copyWith(
          width: width,
          height: height,
          rtf: formData,
        ),
      );
      final next = [...current];
      next[index] = updated;
      datas = next;
      return updated;
    }
    return null;
  }

  LabelSize copyWith({
    int? labelSizeId,
    int? brandId,
    String? labelSizeName,
    LabelSizeCommon? labelSizeCommon,
    LabelSizeSetup? labelSizeSetup,
  }) {
    return LabelSize(
      labelSizeId: labelSizeId ?? this.labelSizeId,
      brandId: brandId ?? this.brandId,
      labelSizeName: labelSizeName ?? this.labelSizeName,
      labelSizeCommon: labelSizeCommon ?? this.labelSizeCommon,
      labelSizeSetup: labelSizeSetup ?? this.labelSizeSetup,
    );
  }

  factory LabelSize.fromMap(Map<String, dynamic> map) {
    String s(String key) => (map[key] ?? '').toString();

    final labelSizeId = map['LABELSIZE_ID'];
    final brandId = map['BRAND_ID'];
    final labelSizeName = s('LABELSIZE_NAME');

    final labelSizeCommon = LabelSizeCommon(
      width: map['FORM_WIDTH'],
      height: map['FORM_HEIGHT'],
      rtf: s('FORM_DATA'),
    );  

    final labelSizeSetup = LabelSizeSetup(
      readOnly: map['SETUP_READONLY'] != 0,
      useMakeDate: map['SETUP_USE_MAKEDATE'] != 0,
      useMakeTime: map['SETUP_USE_MAKETIME'] != 0,
      useValidDate: map['SETUP_USE_VALIDDATE'] != 0,
      useValidTime: map['SETUP_USE_VALIDTIME'] != 0,
      makingDateFormat: PrintDateFormat.values[map['SETUP_MAKEDATE_TYPE']],
      makingTimeFormat: PrintTimeFormat.values[map['SETUP_MAKETIME_TYPE']],
      validDateFormat: PrintDateFormat.values[map['SETUP_VALIDDATE_TYPE']],
      validTimeFormat: PrintTimeFormat.values[map['SETUP_VALIDTIME_TYPE']],
      strMakeDate: s('USER_MAKEDATE'),
      strMakeTime: s('USER_MAKETIME'),
      strValidDate: s('USER_VALIDDATE'),
      strValidTime: s('USER_VALIDTIME'),
      useScale: map['SETUP_USE_SCALE'] != 0,
    );

    return LabelSize(
      labelSizeId: labelSizeId,
      brandId: brandId,
      labelSizeName: labelSizeName,
      labelSizeCommon: labelSizeCommon,
      labelSizeSetup: labelSizeSetup,
    );
  }

  @override
  String toString() =>
    'LabelSizeId: $labelSizeId, BrandId: $brandId, LabelSizeName: $labelSizeName';
}

class LabelSizeDAO extends DAO {
  static const String SelectSql = '''
    SELECT
      RICH_LABELSIZE_ID AS LABELSIZE_ID,
      RICH_BRAND_ID AS BRAND_ID,
      COALESCE(CONVERT(NVARCHAR(50), RICH_LABELSIZE_NAME COLLATE ${DAO.CP949}), N'') AS LABELSIZE_NAME,
      RICH_FORM_WIDTH AS FORM_WIDTH,
      RICH_FORM_HEIGHT AS FORM_HEIGHT,
      RICH_FORM_DATA AS FORM_DATA,
      RICH_SETUP_READONLY AS SETUP_READONLY,
      RICH_SETUP_USE_MAKEDATE AS SETUP_USE_MAKEDATE,
      RICH_SETUP_USE_MAKETIME AS SETUP_USE_MAKETIME,
      RICH_SETUP_USE_VALIDDATE AS SETUP_USE_VALIDDATE,
      RICH_SETUP_USE_VALIDTIME AS SETUP_USE_VALIDTIME,
      RICH_SETUP_MAKEDATE_TYPE AS SETUP_MAKEDATE_TYPE,
      RICH_SETUP_MAKETIME_TYPE AS SETUP_MAKETIME_TYPE,
      RICH_SETUP_VALIDDATE_TYPE AS SETUP_VALIDDATE_TYPE,
      RICH_SETUP_VALIDTIME_TYPE AS SETUP_VALIDTIME_TYPE,
      COALESCE(CONVERT(NVARCHAR(50), RICH_USER_MAKEDATE COLLATE ${DAO.CP949}), N'') AS USER_MAKEDATE,
      COALESCE(CONVERT(NVARCHAR(50), RICH_USER_MAKETIME COLLATE ${DAO.CP949}), N'') AS USER_MAKETIME,
      COALESCE(CONVERT(NVARCHAR(50), RICH_USER_VALIDDATE COLLATE ${DAO.CP949}), N'') AS USER_VALIDDATE,
      COALESCE(CONVERT(NVARCHAR(50), RICH_USER_VALIDTIME COLLATE ${DAO.CP949}), N'') AS USER_VALIDTIME,
      RICH_SETUP_USE_SCALE AS SETUP_USE_SCALE
    FROM BM_RICH_LABELSIZE_FORM
  ''';

  static const String UpdateFormDataSql = '''
    UPDATE BM_RICH_LABELSIZE_FORM SET RICH_FORM_WIDTH=@width,RICH_FORM_HEIGHT=@height,RICH_FORM_DATA=@formData
  ''';

  // WHERE 절: Brand ID로 조회 (Integer)
  static const String WhereSqlBrandId = '''
	  WHERE RICH_BRAND_ID=@brandId
  ''';

  static const String WhereSqlLabelSizeId = '''
	  WHERE RICH_LABELSIZE_ID=@labelSizeId
  ''';

  static const String OrderSqlByLabelSize = '''
	  ORDER BY RICH_LABELSIZE_ORDER ASC
  ''';

  static Future<List<LabelSize>?> getByBrandIdByLabelSizeOrder(int brandId) async {
    debugLog('$START, brandId:$brandId');

    try {
      final res = await DbClient.instance.getDataWithParams(
        '$SelectSql $WhereSqlBrandId $OrderSqlByLabelSize',
        { 'brandId': brandId }
      );

      final labelSizes = DAO.mapRows(res, LabelSize.fromMap);

      debugLog(END);
      return labelSizes;
    }
    catch (e) {
      debugLog('$END, $e');
      throw Exception('${runtimeLogTag()} $e');
    }
  }

  static Future<void> setByLabelSizeId(
    int labelSizeId,
    int width,
    int height,
    String formData,
  ) async {
    debugLog('$START, labelSizeId:$labelSizeId, width:$width, height:$height');

    try {
      final res = await DbClient.instance.writeDataWithParams(
        '$UpdateFormDataSql $WhereSqlLabelSizeId',
        {'width': width, 'height': height, 'formData': formData, 'labelSizeId': labelSizeId},
      );

      debugLog('$END - Result: $res');
    } catch (e) {
      debugLog('$END, $e');
      rethrow;
    }
  }
}
