// UTF-8, 한국어 주석
// ignore_for_file: constant_identifier_names

import 'package:label_manager/features/date_setup/domain/date_manager.dart';

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

  LabelSizeSetup copyWith({bool? useScale}) => LabelSizeSetup(
    readOnly: readOnly,
    useMakeDate: useMakeDate,
    useMakeTime: useMakeTime,
    useValidDate: useValidDate,
    useValidTime: useValidTime,
    makingDateFormat: makingDateFormat,
    makingTimeFormat: makingTimeFormat,
    validDateFormat: validDateFormat,
    validTimeFormat: validTimeFormat,
    strMakeDate: strMakeDate,
    strMakeTime: strMakeTime,
    strValidDate: strValidDate,
    strValidTime: strValidTime,
    useScale: useScale ?? this.useScale,
  );

  LabelSizeSetup copyWithDateSetup(LabelSizeDateSetupUpdate update) =>
      LabelSizeSetup(
        readOnly: readOnly,
        useMakeDate: update.useMakeDate,
        useMakeTime: update.useMakeTime,
        useValidDate: update.useValidDate,
        useValidTime: update.useValidTime,
        makingDateFormat: update.makingDateFormat,
        makingTimeFormat: update.makingTimeFormat,
        validDateFormat: update.validDateFormat,
        validTimeFormat: update.validTimeFormat,
        strMakeDate: update.strMakeDate,
        strMakeTime: update.strMakeTime,
        strValidDate: update.strValidDate,
        strValidTime: update.strValidTime,
        useScale: useScale,
      );

  @override
  String toString() =>
      'ReadOnly: $readOnly, '
      'UseMakeDate: $useMakeDate, UseMakeTime: $useMakeTime, '
      'UseValidDate: $useValidDate, UseValidTime: $useValidTime, '
      'MakingDateFormat: $makingDateFormat, MakingTimeFormat: $makingTimeFormat, '
      'ValidDateFormat: $validDateFormat, ValidTimeFormat: $validTimeFormat, '
      'StrMakeDate: $strMakeDate, StrMakeTime: $strMakeTime, '
      'StrValidDate: $strValidDate, StrValidTime: $strValidTime, UseScale: $useScale';
}

class LabelSizeDateSetupUpdate {
  const LabelSizeDateSetupUpdate({
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
  });

  factory LabelSizeDateSetupUpdate.fromSetup(LabelSizeSetup setup) =>
      LabelSizeDateSetupUpdate(
        useMakeDate: setup.useMakeDate,
        useMakeTime: setup.useMakeTime,
        useValidDate: setup.useValidDate,
        useValidTime: setup.useValidTime,
        makingDateFormat: setup.makingDateFormat,
        makingTimeFormat: setup.makingTimeFormat,
        validDateFormat: setup.validDateFormat,
        validTimeFormat: setup.validTimeFormat,
        strMakeDate: setup.strMakeDate,
        strMakeTime: setup.strMakeTime,
        strValidDate: setup.strValidDate,
        strValidTime: setup.strValidTime,
      );

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

  Map<String, dynamic> toParams() => {
    'useMakeDate': useMakeDate ? 1 : 0,
    'useMakeTime': useMakeTime ? 1 : 0,
    'useValidDate': useValidDate ? 1 : 0,
    'useValidTime': useValidTime ? 1 : 0,
    'makeDateType': makingDateFormat.index,
    'makeTimeType': makingTimeFormat.index,
    'validDateType': validDateFormat.index,
    'validTimeType': validTimeFormat.index,
    'userMakeDate': strMakeDate,
    'userMakeTime': strMakeTime,
    'userValidDate': strValidDate,
    'userValidTime': strValidTime,
  };
}

class LabelSize {
  static List<LabelSize>? datas;

  final int labelSizeId;
  final int brandId;
  final String labelSizeName;
  final LabelSizeCommon? labelSizeCommon;
  final LabelSizeSetup? labelSizeSetup;
  final bool hasInvalidDateSetupValues;

  const LabelSize({
    required this.labelSizeId,
    required this.brandId,
    required this.labelSizeName,
    this.labelSizeCommon,
    this.labelSizeSetup,
    this.hasInvalidDateSetupValues = false,
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

  static LabelSize replaceCachedDateSetup(LabelSize updated) {
    final current = datas;
    if (current == null) return updated;
    final index = current.indexWhere(
      (value) => value.labelSizeId == updated.labelSizeId,
    );
    if (index < 0) return updated;
    final next = [...current];
    next[index] = updated;
    datas = next;
    return updated;
  }

  LabelSize copyWith({
    int? labelSizeId,
    int? brandId,
    String? labelSizeName,
    LabelSizeCommon? labelSizeCommon,
    LabelSizeSetup? labelSizeSetup,
    bool? hasInvalidDateSetupValues,
  }) {
    return LabelSize(
      labelSizeId: labelSizeId ?? this.labelSizeId,
      brandId: brandId ?? this.brandId,
      labelSizeName: labelSizeName ?? this.labelSizeName,
      labelSizeCommon: labelSizeCommon ?? this.labelSizeCommon,
      labelSizeSetup: labelSizeSetup ?? this.labelSizeSetup,
      hasInvalidDateSetupValues:
          hasInvalidDateSetupValues ?? this.hasInvalidDateSetupValues,
    );
  }

  @override
  String toString() =>
      'LabelSizeId: $labelSizeId, BrandId: $brandId, LabelSizeName: $labelSizeName';
}

class LabelSizeOrderUpdate {
  const LabelSizeOrderUpdate({
    required this.labelSizeId,
    required this.labelSizeOrder,
  });

  final int labelSizeId;
  final int labelSizeOrder;
}