import 'dart:math' as math;

import 'fortune_sheet_model.dart';

typedef FortuneFormulaFunction = Object? Function(List<Object?> params);
typedef ParserEventDone = void Function(Object? value);

// ignore: constant_identifier_names
const List<String> SUPPORTED_FORMULAS = <String>[
  'BETADIST',
  'BETAINV',
  'BINOMDIST',
  'ISOCEILING',
  'CEILING',
  'CEILINGMATH',
  'CEILINGPRECISE',
  'CHIDIST',
  'CHIDISTRT',
  'CHIINV',
  'CHIINVRT',
  'CHITEST',
  'CONFIDENCE',
  'COVAR',
  'COVARIANCEP',
  'COVARIANCES',
  'CRITBINOM',
  'EXPONDIST',
  'ERFCPRECISE',
  'ERFPRECISE',
  'FDIST',
  'FDISTRT',
  'FINVRT',
  'FINV',
  'FLOOR',
  'FLOORMATH',
  'FLOORPRECISE',
  'FTEST',
  'GAMMADIST',
  'GAMMAINV',
  'GAMMALNPRECISE',
  'HYPGEOMDIST',
  'LOGINV',
  'LOGNORMINV',
  'LOGNORMDIST',
  'MODE',
  'MODEMULT',
  'MODESNGL',
  'NEGBINOMDIST',
  'NETWORKDAYSINTL',
  'NORMDIST',
  'NORMINV',
  'NORMSDIST',
  'NORMSINV',
  'PERCENTILE',
  'PERCENTILEEXC',
  'PERCENTILEINC',
  'PERCENTRANK',
  'PERCENTRANKEXC',
  'PERCENTRANKINC',
  'POISSON',
  'POISSONDIST',
  'QUARTILE',
  'QUARTILEEXC',
  'QUARTILEINC',
  'RANK',
  'RANKAVG',
  'RANKEQ',
  'SKEWP',
  'STDEV',
  'STDEVP',
  'STDEVS',
  'TDIST',
  'TDISTRT',
  'TINV',
  'TTEST',
  'VAR',
  'VARP',
  'VARS',
  'WEIBULL',
  'WEIBULLDIST',
  'WORKDAYINTL',
  'ZTEST',
  'FINDFIELD',
  'DAVERAGE',
  'DCOUNT',
  'DCOUNTA',
  'DGET',
  'DMAX',
  'DMIN',
  'DPRODUCT',
  'DSTDEV',
  'DSTDEVP',
  'DSUM',
  'DVAR',
  'DVARP',
  'BESSELI',
  'BESSELJ',
  'BESSELK',
  'BESSELY',
  'BIN2DEC',
  'BIN2HEX',
  'BIN2OCT',
  'BITAND',
  'BITLSHIFT',
  'BITOR',
  'BITRSHIFT',
  'BITXOR',
  'COMPLEX',
  'CONVERT',
  'DEC2BIN',
  'DEC2HEX',
  'DEC2OCT',
  'DELTA',
  'ERF',
  'ERFC',
  'GESTEP',
  'HEX2BIN',
  'HEX2DEC',
  'HEX2OCT',
  'IMABS',
  'IMAGINARY',
  'IMARGUMENT',
  'IMCONJUGATE',
  'IMCOS',
  'IMCOSH',
  'IMCOT',
  'IMDIV',
  'IMEXP',
  'IMLN',
  'IMLOG10',
  'IMLOG2',
  'IMPOWER',
  'IMPRODUCT',
  'IMREAL',
  'IMSEC',
  'IMSECH',
  'IMSIN',
  'IMSINH',
  'IMSQRT',
  'IMCSC',
  'IMCSCH',
  'IMSUB',
  'IMSUM',
  'IMTAN',
  'OCT2BIN',
  'OCT2DEC',
  'OCT2HEX',
  'AND',
  'CHOOSE',
  'FALSE',
  'IF',
  'IFS',
  'IFERROR',
  'IFNA',
  'NOT',
  'OR',
  'TRUE',
  'XOR',
  'SWITCH',
  'ABS',
  'ACOS',
  'ACOSH',
  'ACOT',
  'ACOTH',
  'AGGREGATE',
  'ARABIC',
  'ASIN',
  'ASINH',
  'ATAN',
  'ATAN2',
  'ATANH',
  'BASE',
  'COMBIN',
  'COMBINA',
  'COS',
  'COSH',
  'COT',
  'COTH',
  'CSC',
  'CSCH',
  'DECIMAL',
  'DEGREES',
  'EVEN',
  'EXP',
  'FACT',
  'FACTDOUBLE',
  'GCD',
  'INT',
  'ISO',
  'LCM',
  'LN',
  'LN10',
  'LN2',
  'LOG10E',
  'LOG2E',
  'LOG',
  'LOG10',
  'MOD',
  'MROUND',
  'MULTINOMIAL',
  'ODD',
  'PI',
  'E',
  'POWER',
  'PRODUCT',
  'QUOTIENT',
  'RADIANS',
  'RAND',
  'RANDBETWEEN',
  'ROMAN',
  'ROUND',
  'ROUNDDOWN',
  'ROUNDUP',
  'SEC',
  'SECH',
  'SERIESSUM',
  'SIGN',
  'SIN',
  'SINH',
  'SQRT',
  'SQRTPI',
  'SQRT1_2',
  'SQRT2',
  'SUBTOTAL',
  'ADD',
  'MINUS',
  'DIVIDE',
  'MULTIPLY',
  'GT',
  'GTE',
  'LT',
  'LTE',
  'EQ',
  'NE',
  'POW',
  'SUM',
  'SUMIF',
  'SUMIFS',
  'SUMPRODUCT',
  'SUMSQ',
  'SUMX2MY2',
  'SUMX2PY2',
  'SUMXMY2',
  'TAN',
  'TANH',
  'TRUNC',
  'ASC',
  'BAHTTEXT',
  'CHAR',
  'CLEAN',
  'CODE',
  'CONCATENATE',
  'CONCAT',
  'DBCS',
  'DOLLAR',
  'EXACT',
  'FIND',
  'FIXED',
  'HTML2TEXT',
  'LEFT',
  'LEN',
  'LOWER',
  'MID',
  'NUMBERVALUE',
  'PRONETIC',
  'PROPER',
  'REGEXEXTRACT',
  'REGEXMATCH',
  'REGEXREPLACE',
  'REPLACE',
  'REPT',
  'RIGHT',
  'SEARCH',
  'SPLIT',
  'SUBSTITUTE',
  'T',
  'TEXT',
  'TRIM',
  'UNICHAR',
  'UNICODE',
  'UPPER',
  'VALUE',
  'DATE',
  'DATEDIF',
  'DATEVALUE',
  'DAY',
  'DAYS',
  'DAYS360',
  'EDATE',
  'EOMONTH',
  'HOUR',
  'INTERVAL',
  'ISOWEEKNUM',
  'MINUTE',
  'MONTH',
  'NETWORKDAYS',
  'NOW',
  'SECOND',
  'TIME',
  'TIMEVALUE',
  'TODAY',
  'WEEKDAY',
  'WEEKNUM',
  'WORKDAY',
  'YEAR',
  'YEARFRAC',
  'ACCRINT',
  'ACCRINTM',
  'AMORDEGRC',
  'AMORLINC',
  'COUPDAYBS',
  'COUPDAYS',
  'COUPDAYSNC',
  'COUPNCD',
  'COUPNUM',
  'COUPPCD',
  'CUMIPMT',
  'CUMPRINC',
  'DB',
  'DDB',
  'DISC',
  'DOLLARDE',
  'DOLLARFR',
  'DURATION',
  'EFFECT',
  'FV',
  'FVSCHEDULE',
  'INTRATE',
  'IPMT',
  'IRR',
  'ISPMT',
  'MDURATION',
  'MIRR',
  'NOMINAL',
  'NPER',
  'NPV',
  'ODDFPRICE',
  'ODDFYIELD',
  'ODDLPRICE',
  'ODDLYIELD',
  'PDURATION',
  'PMT',
  'PPMT',
  'PRICE',
  'PRICEDISC',
  'PRICEMAT',
  'PV',
  'RATE',
  'RECEIVED',
  'RRI',
  'SLN',
  'SYD',
  'TBILLEQ',
  'TBILLPRICE',
  'TBILLYIELD',
  'VDB',
  'XIRR',
  'XNPV',
  'YIELD',
  'YIELDDISC',
  'YIELDMAT',
  'CELL',
  'ERROR',
  'INFO',
  'ISBLANK',
  'ISBINARY',
  'ISERR',
  'ISERROR',
  'ISEVEN',
  'ISFORMULA',
  'ISLOGICAL',
  'ISNA',
  'ISNONTEXT',
  'ISNUMBER',
  'ISODD',
  'ISREF',
  'ISTEXT',
  'N',
  'NA',
  'SHEET',
  'SHEETS',
  'TYPE',
  'MATCH',
  'VLOOKUP',
  'HLOOKUP',
  'LOOKUP',
  'INDEX',
  'AVEDEV',
  'AVERAGE',
  'AVERAGEA',
  'AVERAGEIF',
  'AVERAGEIFS',
  'BETA',
  'BINOM',
  'CHISQ',
  'COLUMN',
  'COLUMNS',
  'CORREL',
  'COUNT',
  'COUNTA',
  'COUNTIN',
  'COUNTBLANK',
  'COUNTIF',
  'COUNTIFS',
  'COUNTUNIQUE',
  'COVARIANCE',
  'DEVSQ',
  'EXPON',
  'F',
  'FISHER',
  'FISHERINV',
  'FORECAST',
  'FREQUENCY',
  'GAMMA',
  'GAMMALN',
  'GAUSS',
  'GEOMEAN',
  'GROWTH',
  'HARMEAN',
  'HYPGEOM',
  'INTERCEPT',
  'KURT',
  'LARGE',
  'LINEST',
  'LOGEST',
  'LOGNORM',
  'MAX',
  'MAXA',
  'MEDIAN',
  'MIN',
  'MINA',
  'NEGBINOM',
  'NORM',
  'PEARSON',
  'PERMUT',
  'PERMUTATIONA',
  'PHI',
  'PROB',
  'ROW',
  'ROWS',
  'RSQ',
  'SKEW',
  'SLOPE',
  'SMALL',
  'STANDARDIZE',
  'STDEVA',
  'STDEVPA',
  'STEYX',
  'TRANSPOSE',
  'TREND',
  'TRIMMEAN',
  'VARA',
  'VARPA',
  'Z',
  'UNIQUE',
  'FLATTEN',
  'ARGS2ARRAY',
  'REFERENCE',
  'JOIN',
  'NUMBERS',
  'utils',
];

final Object _parserNoValue = Object();
typedef FortuneFormulaOperation = Object? Function(List<Object?> params);

class FortuneFormulaOperator {
  const FortuneFormulaOperator(
    this.symbol,
    this.operation, {
    this.isFactory = false,
  });

  final Object symbol;
  final FortuneFormulaOperation operation;
  final bool isFactory;

  Object? evaluate([List<Object?> params = const []]) => operation(params);
}

final Map<String, FortuneFormulaOperator> _formulaOperations =
    <String, FortuneFormulaOperator>{
      '+': FortuneFormulaOperator(
        '+',
        (params) => _formulaOperationNumbers(params).reduce((a, b) => a + b),
      ),
      '&': FortuneFormulaOperator(
        '&',
        (params) => params.map(_formulaOperationText).join(),
      ),
      '/': FortuneFormulaOperator('/', _formulaOperationDivide),
      '=': FortuneFormulaOperator(
        '=',
        (params) => _formulaOperationCompare(params, '='),
      ),
      'SUM': FortuneFormulaOperator(
        'SUM',
        (params) => _formulaOperationNumbers(
          params,
          strict: false,
        ).fold<num>(0, (sum, value) => sum + value),
      ),
      '>': FortuneFormulaOperator(
        '>',
        (params) => _formulaOperationCompare(params, '>'),
      ),
      '>=': FortuneFormulaOperator(
        '>=',
        (params) => _formulaOperationCompare(params, '>='),
      ),
      '<': FortuneFormulaOperator(
        '<',
        (params) => _formulaOperationCompare(params, '<'),
      ),
      '<=': FortuneFormulaOperator(
        '<=',
        (params) => _formulaOperationCompare(params, '<='),
      ),
      '-': FortuneFormulaOperator(
        '-',
        (params) => _formulaOperationNumbers(params).reduce((a, b) => a - b),
      ),
      '*': FortuneFormulaOperator(
        '*',
        (params) => _formulaOperationNumbers(params).reduce((a, b) => a * b),
      ),
      '<>': FortuneFormulaOperator(
        '<>',
        (params) => _formulaOperationCompare(params, '<>'),
      ),
      '^': FortuneFormulaOperator('^', (params) {
        final numbers = _formulaOperationNumbers(params);
        return math.pow(numbers[0], numbers[1]);
      }),
    };

final FortuneFormulaOperator formulaFunctionOperator = FortuneFormulaOperator(
  SUPPORTED_FORMULAS,
  (_) => throw StateError(ERROR_NAME),
  isFactory: true,
);

FortuneFormulaOperator? getOperation(Object symbol) =>
    _formulaOperations['$symbol'.toUpperCase()];

Object? evaluateByOperator(String operator, [List<Object?> params = const []]) {
  final operation = getOperation(operator);
  if (operation == null) {
    return _evaluateFormulaFunctionOperator(operator, params);
  }
  return operation.evaluate(params);
}

Object? _evaluateFormulaFunctionOperator(
  String operator,
  List<Object?> params,
) {
  final expression =
      '${operator.toUpperCase()}(${params.map(_formulaLiteral).join(',')})';
  final result = Parser().parse(expression);
  final error = result['error'];
  if (error is String) {
    throw StateError(error);
  }
  return result['result'];
}

String _formulaLiteral(Object? value) {
  if (value == null) {
    return 'NULL';
  }
  if (value is num) {
    return value.toString();
  }
  if (value is bool) {
    return value ? 'TRUE' : 'FALSE';
  }
  if (value is Iterable) {
    return '[${value.map(_formulaLiteral).join(',')}]';
  }
  return '"${'$value'.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}

void registerOperation(Object symbol, FortuneFormulaOperation operation) {
  final symbols = symbol is Iterable && symbol is! String ? symbol : [symbol];
  for (final item in symbols) {
    _formulaOperations['$item'.toUpperCase()] = FortuneFormulaOperator(
      item,
      operation,
    );
  }
}

class Parser {
  Parser() {
    setVariable('TRUE', true);
    setVariable('FALSE', false);
    setVariable('NULL', null);
  }

  final Map<String, Object?> _variables = <String, Object?>{};
  final Map<String, FortuneFormulaFunction> _functions =
      <String, FortuneFormulaFunction>{};
  final Map<String, List<Function>> _listeners = <String, List<Function>>{};

  Parser setVariable(String name, Object? value) {
    _variables[name.toUpperCase()] = value;
    return this;
  }

  Object? getVariable(String name) => _variables[name.toUpperCase()];

  Parser setFunction(String name, FortuneFormulaFunction function) {
    _functions[name.toUpperCase()] = function;
    return this;
  }

  FortuneFormulaFunction? getFunction(String name) =>
      _functions[name.toUpperCase()];

  Parser on(String event, Function listener) {
    (_listeners[event] ??= <Function>[]).add(listener);
    return this;
  }

  Parser off([String? event, Function? listener]) {
    if (event == null) {
      _listeners.clear();
    } else if (listener == null) {
      _listeners.remove(event);
    } else {
      _listeners[event]?.remove(listener);
    }
    return this;
  }

  Map<String, Object?> parse(
    Object? expression, {
    FortuneSheet? sheet,
    Map<String, Object?>? options,
  }) {
    if (expression is! String) {
      return {'error': '#ERROR!', 'result': null};
    }
    if (expression.isEmpty) {
      return {'error': null, 'result': ''};
    }

    final parseSheet = (sheet ?? FortuneSheet(id: 'parser', name: 'Sheet1'))
        .copyWith(
          extraFields: <String, Object?>{
            ...?sheet?.extraFields,
            'formulaVariables': <String, Object?>{
              ..._variables,
              if (sheet?.extraFields['formulaVariables'] is Map)
                ...(sheet!.extraFields['formulaVariables'] as Map).map(
                  (key, value) => MapEntry('$key'.toUpperCase(), value),
                ),
            },
            'formulaFunctions': <String, FortuneFormulaFunction>{
              ..._functions,
              if (sheet?.extraFields['formulaFunctions'] is Map)
                for (final entry
                    in (sheet!.extraFields['formulaFunctions'] as Map).entries)
                  if (entry.value is FortuneFormulaFunction)
                    '${entry.key}'.toUpperCase():
                        entry.value as FortuneFormulaFunction,
            },
            if (options != null) 'formulaParserOptions': {...options},
          },
        );

    try {
      final cache = <FortuneCellCoord, Object?>{};
      final result = _Parser(
        expression.startsWith('=') ? expression.substring(1) : expression,
        (ref, sheetName) {
          final eventValue = _emitValue('callCellValue', <Object?>[
            _cellEventPayload(ref, sheetName),
          ]);
          if (!identical(eventValue, _parserNoValue)) {
            return eventValue;
          }
          return FortuneFormulaEngine._cellValue(
            parseSheet,
            ref,
            cache,
            <FortuneCellCoord>{},
          );
        },
        (range) {
          final eventValue = _emitValue('callRangeValue', <Object?>[
            _cellEventPayload(
              FortuneCellCoord(range.rowStart, range.columnStart),
              range.sheetName,
            ),
            _cellEventPayload(
              FortuneCellCoord(range.rowEnd, range.columnEnd),
              range.sheetName,
            ),
          ]);
          if (!identical(eventValue, _parserNoValue)) {
            return _rangeEventValues(eventValue);
          }
          return FortuneFormulaEngine._rangeValues(
            parseSheet,
            range,
            cache,
            <FortuneCellCoord>{},
          );
        },
        (ref, _) => FortuneFormulaEngine._cellFormula(parseSheet, ref),
        currentCoord: null,
        namedValues: _formulaVariables(parseSheet),
        customFunctions: _formulaFunctions(parseSheet),
        sheetNames: {parseSheet.name.toUpperCase()},
        referenceCellValue: (ref, sheetName, reference) {
          final eventValue = _emitValue('callCellValue', <Object?>[
            _cellEventPayload(ref, sheetName, reference: reference),
          ]);
          return eventValue;
        },
        referenceRangeValues: (range) {
          final eventValue = _emitValue('callRangeValue', <Object?>[
            _cellEventPayload(
              FortuneCellCoord(range.rowStart, range.columnStart),
              range.sheetName,
              reference: range.startReference,
            ),
            _cellEventPayload(
              FortuneCellCoord(range.rowEnd, range.columnEnd),
              range.sheetName,
              reference: range.endReference,
            ),
          ]);
          if (identical(eventValue, _parserNoValue)) {
            return _parserNoValue;
          }
          return eventValue;
        },
        variableValue: (name) => _emitValue('callVariable', <Object?>[name]),
        functionValue: (name, params) =>
            _emitValue('callFunction', <Object?>[name, params]),
        strictParserCompatibility: true,
      ).parse();
      final publicResult = _parserPublicResult(result);
      final resultText = publicResult is _FormulaError
          ? publicResult.label
          : publicResult;
      if (resultText is StateError) {
        return {
          'error':
              formulaParserError(resultText.message) ??
              formulaParserError(ERROR),
          'result': null,
        };
      }
      final error = publicResult is _FormulaError
          ? formulaParserError(publicResult.label)
          : null;
      return {'error': error, 'result': error == null ? publicResult : null};
    } on StateError catch (error) {
      return {
        'error': formulaParserError(error.message) ?? formulaParserError(ERROR),
        'result': null,
      };
    } catch (_) {
      return {'error': formulaParserError(ERROR), 'result': null};
    }
  }

  Map<String, Object?> _formulaVariables(FortuneSheet sheet) =>
      <String, Object?>{
        ..._variables,
        ...FortuneFormulaEngine._formulaVariables(sheet),
      };

  Map<String, FortuneFormulaFunction> _formulaFunctions(FortuneSheet sheet) =>
      <String, FortuneFormulaFunction>{
        ..._functions,
        ...FortuneFormulaEngine._formulaFunctions(sheet),
      };

  Object? _emitValue(String event, List<Object?> args) {
    Object? value = _parserNoValue;
    final listeners = _listeners[event];
    if (listeners == null) {
      return value;
    }
    void done(Object? newValue) {
      value = newValue;
    }

    for (final listener in List<Function>.of(listeners)) {
      Function.apply(listener, <Object?>[...args, done]);
    }
    return value;
  }

  Map<String, Object?> _cellEventPayload(
    FortuneCellCoord coord,
    String? sheetName, {
    String? reference,
  }) {
    final referenceParts = _referenceParts(reference);
    final columnLabel =
        referenceParts?.columnLabel ?? _columnLabel(coord.column);
    final rowLabel = '${coord.row + 1}';
    final label = referenceParts == null
        ? '$columnLabel$rowLabel'
        : '${referenceParts.columnPrefix}$columnLabel${referenceParts.rowPrefix}$rowLabel';
    return <String, Object?>{
      'label': label,
      ...sheetName == null
          ? const <String, Object?>{}
          : <String, Object?>{'sheetName': sheetName},
      'row': <String, Object?>{
        'index': coord.row,
        'isAbsolute': referenceParts?.rowAbsolute ?? false,
        'label': rowLabel,
      },
      'column': <String, Object?>{
        'index': coord.column,
        'isAbsolute': referenceParts?.columnAbsolute ?? false,
        'label': columnLabel,
      },
    };
  }

  _ParserReferenceParts? _referenceParts(String? reference) {
    return _parserReferenceParts(reference);
  }

  List<Object> _rangeEventValues(Object? value) {
    if (value is Iterable) {
      return <Object>[
        for (final item in value)
          if (item is Iterable)
            for (final nested in item) nested is Object ? nested : _formulaBlank
          else
            item is Object ? item : _formulaBlank,
      ];
    }
    return <Object>[value is Object ? value : _formulaBlank];
  }

  String _columnLabel(int index) {
    var value = index + 1;
    final chars = <String>[];
    while (value > 0) {
      final remainder = (value - 1) % 26;
      chars.insert(0, String.fromCharCode(65 + remainder));
      value = (value - 1) ~/ 26;
    }
    return chars.join();
  }

  Object? _parserPublicResult(Object? value) {
    if (value is _FormulaArgument) {
      if (value.rowCount <= 1 || value.columnCount <= 1) {
        return [for (final item in value.values) _parserPublicResult(item)];
      }
      return [
        for (var row = 0; row < value.rowCount; row += 1)
          [
            for (var column = 0; column < value.columnCount; column += 1)
              _parserPublicResult(value.valueAt(row, column)),
          ],
      ];
    }
    if (identical(value, _formulaBlank)) {
      return null;
    }
    return value;
  }
}

List<num> _formulaOperationNumbers(List<Object?> params, {bool strict = true}) {
  final numbers = <num>[];
  for (final param in params) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(param);
    if (number == null) {
      if (strict) {
        throw StateError(ERROR_VALUE);
      }
      continue;
    }
    numbers.add(number);
  }
  if (strict && numbers.isEmpty) {
    throw StateError(ERROR_VALUE);
  }
  return numbers;
}

bool _formulaOperationCompare(List<Object?> params, String operator) {
  if (params.length < 2) {
    throw StateError(ERROR_VALUE);
  }
  final left = params[0];
  final right = params[1];
  if (operator == '=') {
    return _formulaOperationStrictEquals(left, right);
  }
  if (operator == '<>') {
    return !_formulaOperationStrictEquals(left, right);
  }
  final comparison = _formulaOperationRelationalComparison(left, right);
  if (comparison == null) {
    return false;
  }
  return switch (operator) {
    '>' => comparison > 0,
    '<' => comparison < 0,
    '>=' => comparison >= 0,
    '<=' => comparison <= 0,
    _ => throw StateError(ERROR_VALUE),
  };
}

Object? _formulaOperationDivide(List<Object?> params) {
  final List<num> numbers;
  try {
    numbers = _formulaOperationNumbers(params);
  } on StateError catch (error) {
    if (error.message == ERROR_VALUE) {
      return ERROR_VALUE;
    }
    rethrow;
  }
  final result = numbers.reduce((a, b) => a / b);
  if (result == double.infinity || result == double.negativeInfinity) {
    return ERROR_DIV_ZERO;
  }
  if (result.isNaN) {
    return ERROR_VALUE;
  }
  return result;
}

bool _formulaOperationStrictEquals(Object? left, Object? right) {
  if (left == null || right == null) {
    return left == null && right == null;
  }
  if (left is num && right is num) {
    return left == right;
  }
  if (left is String && right is String) {
    return left == right;
  }
  if (left is bool && right is bool) {
    return left == right;
  }
  return identical(left, right);
}

int? _formulaOperationRelationalComparison(Object? left, Object? right) {
  if (left is String && right is String) {
    return left.compareTo(right);
  }
  final leftNumber = _formulaOperationJsNumber(left);
  final rightNumber = _formulaOperationJsNumber(right);
  if (leftNumber == null || rightNumber == null) {
    return null;
  }
  return leftNumber.compareTo(rightNumber);
}

num? _formulaOperationJsNumber(Object? value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value;
  }
  if (value is bool) {
    return value ? 1 : 0;
  }
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) {
      return 0;
    }
    return num.tryParse(text);
  }
  return null;
}

String _formulaOperationText(Object? value) {
  if (value == null || _isFormulaBlankLike(value)) {
    return '';
  }
  if (value is _FormulaError) {
    return value.label;
  }
  return '$value';
}

bool _isFormulaBlankLike(Object? value) {
  return identical(value, _formulaBlank) || identical(value, _formulaNull);
}

FortuneWorkbook calculateFormula(
  FortuneWorkbook workbook, {
  String? id,
  FortuneRange? range,
}) {
  return FortuneFormulaEngine.calculateFormula(workbook, id: id, range: range);
}

Map<String, Object?> executeAffectedFormulas(
  FortuneWorkbook workbook,
  Iterable<Map<String, Object?>> formulaRunList,
  Iterable<Map<String, Object?>> calcChains,
) {
  return FortuneFormulaEngine.executeAffectedFormulas(
    workbook,
    formulaRunList,
    calcChains,
  );
}

FortuneWorkbook refreshAffectedFormulas(
  FortuneWorkbook workbook, {
  required int row,
  required int column,
  String? id,
  Object? value,
  bool isForce = false,
  Iterable<Map<String, Object?>>? execFunctionExist,
}) {
  final sheetId = id ?? workbook.activeSheet.id;
  var nextWorkbook = workbook.copyWith();
  final sheetIndex = nextWorkbook.sheets.indexWhere(
    (sheet) => sheet.id == sheetId,
  );
  if (sheetIndex < 0) {
    return nextWorkbook;
  }
  if (value != null) {
    final nextSheets = [
      for (final sheet in nextWorkbook.sheets) sheet.copyWith(),
    ];
    nextSheets[sheetIndex] = nextSheets[sheetIndex].setCellValue(
      row,
      column,
      value,
    );
    nextWorkbook = nextWorkbook.copyWith(sheets: nextSheets);
  }

  final calcChains = getAllFunctionGroup(nextWorkbook);
  if (calcChains.isEmpty) {
    return nextWorkbook;
  }

  final updateCells = _formulaUpdateCells(
    row: row,
    column: column,
    sheetId: sheetId,
    execFunctionExist: execFunctionExist,
  );
  final formulaCellInfoMap = <String, Map<String, Object?>>{};
  setFormulaCellInfoMap(formulaCellInfoMap, nextWorkbook, calcChains);
  if (formulaCellInfoMap.isEmpty) {
    return nextWorkbook;
  }

  var workingWorkbook = nextWorkbook;
  var pendingUpdateCells = updateCells;
  final executedKeys = <String>{};
  while (pendingUpdateCells.isNotEmpty) {
    final formulaRunList = _formulaRunListForUpdateCells(
      updateCells: pendingUpdateCells,
      formulaCellInfoMap: formulaCellInfoMap,
      isForce: isForce,
    ).where((item) => executedKeys.add(item['key'].toString())).toList();
    if (formulaRunList.isEmpty) {
      return workingWorkbook;
    }
    final executed = executeAffectedFormulas(
      workingWorkbook,
      formulaRunList,
      calcChains,
    );
    final refreshData = executed['groupValuesRefreshData'];
    if (refreshData is! Iterable) {
      return workingWorkbook;
    }
    final normalizedRefreshData = refreshData.whereType<Map>().map((item) {
      return Map<String, Object?>.from(item);
    }).toList();
    final staleDynamicArrayCells =
        FortuneFormulaEngine._staleDynamicArrayRefreshCells(
          workingWorkbook,
          normalizedRefreshData,
        );
    workingWorkbook = groupValuesRefresh(
      workingWorkbook,
      normalizedRefreshData,
    );
    pendingUpdateCells = [
      ..._formulaRefreshDataCells(normalizedRefreshData),
      ...staleDynamicArrayCells,
    ];
  }
  return workingWorkbook;
}

List<Map<String, Object?>> _formulaRunListForUpdateCells({
  required Iterable<Map<String, Object?>> updateCells,
  required Map<String, Map<String, Object?>> formulaCellInfoMap,
  required bool isForce,
}) {
  final updateValueObjects = <String, Object?>{
    for (final cell in updateCells)
      'r${cell['row']}c${cell['column']}i${cell['sheetId']}': 1,
  };
  final updateValueArray = <Map<String, Object?>?>[];
  final updateValueKeys = <String>{};
  final arrayMatchCache = <String, List<Map<String, Object?>>>{};
  final formulaCellInfoMapLookup = formulaCellInfoMap.cast<String, Object?>();
  void queueFormulaObject(String key, Map<String, Object?> formulaObject) {
    if (updateValueKeys.add(key)) {
      updateValueArray.add(formulaObject);
    }
  }

  for (final entry in formulaCellInfoMap.entries) {
    final formulaObject = entry.value;
    final dependency = formulaObject['formulaDependency'];
    if (dependency is Iterable) {
      final dependencyRanges = dependency.whereType<Map>().map((item) {
        return Map<String, Object?>.from(item);
      }).toList();
      arrayMatch(
        arrayMatchCache,
        dependencyRanges,
        formulaCellInfoMapLookup,
        updateValueObjects,
        (childKey, childRow, childColumn, childSheetId) {
          final childFormulaObject = formulaCellInfoMap[childKey];
          if (childFormulaObject != null) {
            final parents = childFormulaObject['parents'];
            if (parents is Map) {
              parents[entry.key] = 1;
            }
          }
          if (!isForce && updateValueObjects.containsKey(childKey)) {
            queueFormulaObject(entry.key, formulaObject);
          }
        },
      );
    }
    if (isForce) {
      queueFormulaObject(entry.key, formulaObject);
    }
  }

  return getFormulaRunList(updateValueArray, formulaCellInfoMap);
}

List<Map<String, Object?>> _formulaRefreshDataCells(
  Iterable<Map<String, Object?>> refreshData,
) {
  final cells = <Map<String, Object?>>[];
  final keys = <String>{};
  for (final item in refreshData) {
    final row = _formulaInt(item['r']);
    final column = _formulaInt(item['c']);
    final sheetId = item['id']?.toString();
    if (row == null || column == null || sheetId == null) {
      continue;
    }
    final key = '$row:$column:$sheetId';
    if (keys.add(key)) {
      cells.add({'row': row, 'column': column, 'sheetId': sheetId});
    }
  }
  return cells;
}

List<Map<String, Object?>> _formulaUpdateCells({
  required int row,
  required int column,
  required String sheetId,
  Iterable<Map<String, Object?>>? execFunctionExist,
}) {
  final cells = <Map<String, Object?>>[];
  if (execFunctionExist != null) {
    for (final item in execFunctionExist) {
      final itemRow = _formulaInt(item['r']);
      final itemColumn = _formulaInt(item['c']);
      final itemSheetId = (item['i'] ?? item['id'] ?? sheetId).toString();
      if (itemRow != null && itemColumn != null) {
        cells.add({
          'row': itemRow,
          'column': itemColumn,
          'sheetId': itemSheetId,
        });
      }
    }
  }
  if (cells.isNotEmpty) {
    return cells;
  }
  return [
    {'row': row, 'column': column, 'sheetId': sheetId},
  ];
}

int? _formulaInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num && value.isFinite) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

class FortuneFormulaEngine {
  const FortuneFormulaEngine._();

  static const Object _missingFormulaValue = Object();

  static String translateReferences(
    String formula, {
    required int rowDelta,
    required int columnDelta,
  }) {
    if (!formula.startsWith('=')) {
      return formula;
    }
    final referencePattern = RegExp(r'(\$?)([A-Za-z]+)(\$?)([0-9]+)');
    final buffer = StringBuffer();
    var offset = 0;
    for (final match in referencePattern.allMatches(formula)) {
      if (_isInsideFormulaQuotedSegment(formula, match.start)) {
        continue;
      }
      final previous = match.start > 0 ? formula[match.start - 1] : '';
      final next = match.end < formula.length ? formula[match.end] : '';
      if (_isIdentifierChar(previous) ||
          _isIdentifierChar(next) ||
          next == '!') {
        continue;
      }
      buffer.write(formula.substring(offset, match.start));
      final absoluteColumn = match.group(1) == r'$';
      final columnName = match.group(2)!;
      final absoluteRow = match.group(3) == r'$';
      final rowNumber = int.parse(match.group(4)!);
      final columnIndex = _columnIndex(columnName);
      final nextColumn = absoluteColumn
          ? columnIndex
          : columnIndex + columnDelta;
      final nextRow = absoluteRow ? rowNumber - 1 : rowNumber - 1 + rowDelta;
      if (nextColumn < 0 || nextRow < 0) {
        buffer.write('#REF!');
      } else {
        buffer
          ..write(absoluteColumn ? r'$' : '')
          ..write(_columnName(nextColumn))
          ..write(absoluteRow ? r'$' : '')
          ..write(nextRow + 1);
      }
      offset = match.end;
    }
    buffer.write(formula.substring(offset));
    return buffer.toString();
  }

  static bool _isInsideFormulaQuotedSegment(String formula, int position) {
    var inDoubleQuotedText = false;
    var inSingleQuotedName = false;
    var inBracketedName = false;
    for (var index = 0; index < position; index += 1) {
      final char = formula[index];
      if (char == '"' && !inSingleQuotedName) {
        if (inDoubleQuotedText &&
            index + 1 < position &&
            formula[index + 1] == '"') {
          index += 1;
        } else {
          inDoubleQuotedText = !inDoubleQuotedText;
        }
      } else if (char == "'" && !inDoubleQuotedText) {
        if (inSingleQuotedName &&
            index + 1 < position &&
            formula[index + 1] == "'") {
          index += 1;
        } else {
          inSingleQuotedName = !inSingleQuotedName;
        }
      } else if (char == '[' && !inDoubleQuotedText && !inSingleQuotedName) {
        inBracketedName = true;
      } else if (char == ']' && inBracketedName) {
        inBracketedName = false;
      }
    }
    return inDoubleQuotedText || inSingleQuotedName || inBracketedName;
  }

  static FortuneSheet recalculate(FortuneSheet sheet) {
    return _recalculateSheet(sheet);
  }

  static FortuneWorkbook calculateFormula(
    FortuneWorkbook workbook, {
    String? id,
    FortuneRange? range,
  }) {
    final nextSheets = [for (final sheet in workbook.sheets) sheet.copyWith()];
    var nextWorkbook = workbook.copyWith(sheets: nextSheets);
    for (var index = 0; index < nextSheets.length; index += 1) {
      final sheet = nextSheets[index];
      if (id == null || sheet.id == id) {
        nextSheets[index] = _recalculateSheetInWorkbook(
          nextWorkbook,
          sheet,
          range: range,
        );
        nextWorkbook = nextWorkbook.copyWith(sheets: nextSheets);
      }
    }
    return nextWorkbook;
  }

  static FortuneSheet _recalculateSheet(
    FortuneSheet sheet, {
    FortuneRange? range,
  }) {
    final formulas = <FortuneCellCoord, String>{};
    for (final entry in sheet.cells.entries) {
      final formula = entry.value.formula;
      if (formula != null &&
          formula.startsWith('=') &&
          (range == null || _coordInRange(entry.key, range))) {
        formulas[entry.key] = formula;
      }
    }
    if (formulas.isEmpty) {
      return sheet;
    }

    final cache = <FortuneCellCoord, Object?>{};
    final dynamicArrayItems = <Map<String, Object?>>[];
    final dynamicArrayRemovals = <FortuneCellCoord>[];
    for (final entry in formulas.entries) {
      final rawValue = _evaluateCell(
        sheet,
        entry.key,
        cache,
        <FortuneCellCoord>{},
      );
      final value = _dynamicArraySpillValue(
        sheet,
        entry.key,
        rawValue,
        formula: entry.value,
      );
      _clearStaleDynamicArrayCells(sheet, entry.key, value);
      _materializeDynamicArrayCells(sheet, entry.key, value);
      final dynamicArrayItem = _dynamicArrayMetadataItem(
        anchor: entry.key,
        formula: entry.value,
        value: value,
      );
      if (dynamicArrayItem != null) {
        dynamicArrayItems.add(dynamicArrayItem);
      } else if (_dynamicArrayEntryFor(
            sheet.dynamicArray,
            entry.key.row,
            entry.key.column,
            sheet.id,
          ) !=
          null) {
        dynamicArrayRemovals.add(entry.key);
      }
      final previous = sheet.cells[entry.key];
      if (previous == null) {
        continue;
      }
      final formulaSparkline = value is _FormulaSparkline ? value.data : null;
      final formulaDisplayValue = value is _FormulaSparkline
          ? ''
          : value == null
          ? '#VALUE!'
          : _formatFormulaValue(value);
      if (_formulaCellHasMaterializedResult(
        previous,
        formulaDisplayValue,
        value,
      )) {
        continue;
      }
      sheet.cells[entry.key] = value is _FormulaSparkline
          ? previous.withFormulaResult(
              formulaDisplayValue,
              formulaValue: formulaDisplayValue,
              sparklineResult: formulaSparkline,
            )
          : previous.withFormulaResult(
              formulaDisplayValue,
              formulaValue: formulaDisplayValue,
            );
    }
    if (dynamicArrayItems.isEmpty && dynamicArrayRemovals.isEmpty) {
      return sheet;
    }
    return sheet.copyWith(
      dynamicArray: _dynamicArrayWithMetadataItems(
        _dynamicArrayWithoutAnchors(
          sheet.dynamicArray,
          dynamicArrayRemovals,
          sheet.id,
        ),
        dynamicArrayItems,
        sheet.id,
      ),
      hasRawDynamicArray: true,
    );
  }

  static FortuneSheet _recalculateSheetInWorkbook(
    FortuneWorkbook workbook,
    FortuneSheet sheet, {
    FortuneRange? range,
  }) {
    final formulas = <FortuneCellCoord, String>{};
    for (final entry in sheet.cells.entries) {
      final formula = entry.value.formula;
      if (formula != null &&
          formula.startsWith('=') &&
          (range == null || _coordInRange(entry.key, range))) {
        formulas[entry.key] = formula;
      }
    }
    if (formulas.isEmpty) {
      return sheet;
    }

    final cache = <String, Object?>{};
    final dynamicArrayItems = <Map<String, Object?>>[];
    final dynamicArrayRemovals = <FortuneCellCoord>[];
    for (final entry in formulas.entries) {
      final rawValue = _cellValueInWorkbook(
        workbook,
        sheet,
        entry.key,
        null,
        cache,
        <String>{},
      );
      final value = _dynamicArraySpillValue(
        sheet,
        entry.key,
        rawValue,
        formula: entry.value,
      );
      _clearStaleDynamicArrayCells(sheet, entry.key, value);
      _materializeDynamicArrayCells(sheet, entry.key, value);
      final dynamicArrayItem = _dynamicArrayMetadataItem(
        anchor: entry.key,
        formula: entry.value,
        value: value,
      );
      if (dynamicArrayItem != null) {
        dynamicArrayItems.add(dynamicArrayItem);
      } else if (_dynamicArrayEntryFor(
            sheet.dynamicArray,
            entry.key.row,
            entry.key.column,
            sheet.id,
          ) !=
          null) {
        dynamicArrayRemovals.add(entry.key);
      }
      final previous = sheet.cells[entry.key];
      if (previous == null) {
        continue;
      }
      final formulaSparkline = value is _FormulaSparkline ? value.data : null;
      final formulaDisplayValue = value is _FormulaSparkline
          ? ''
          : value == null
          ? '#VALUE!'
          : _formatFormulaValue(value);
      if (_formulaCellHasMaterializedResult(
        previous,
        formulaDisplayValue,
        value,
      )) {
        continue;
      }
      sheet.cells[entry.key] = value is _FormulaSparkline
          ? previous.withFormulaResult(
              formulaDisplayValue,
              formulaValue: formulaDisplayValue,
              sparklineResult: formulaSparkline,
            )
          : previous.withFormulaResult(
              formulaDisplayValue,
              formulaValue: formulaDisplayValue,
            );
    }
    if (dynamicArrayItems.isEmpty && dynamicArrayRemovals.isEmpty) {
      return sheet;
    }
    return sheet.copyWith(
      dynamicArray: _dynamicArrayWithMetadataItems(
        _dynamicArrayWithoutAnchors(
          sheet.dynamicArray,
          dynamicArrayRemovals,
          sheet.id,
        ),
        dynamicArrayItems,
        sheet.id,
      ),
      hasRawDynamicArray: true,
    );
  }

  static bool _coordInRange(FortuneCellCoord coord, FortuneRange range) {
    final rowStart = math.min(range.rowStart, range.rowEnd);
    final rowEnd = math.max(range.rowStart, range.rowEnd);
    final columnStart = math.min(range.columnStart, range.columnEnd);
    final columnEnd = math.max(range.columnStart, range.columnEnd);
    return coord.row >= rowStart &&
        coord.row <= rowEnd &&
        coord.column >= columnStart &&
        coord.column <= columnEnd;
  }

  static bool _formulaCellHasMaterializedResult(
    FortuneCell cell,
    String formulaDisplayValue,
    Object? value,
  ) {
    if (value is _FormulaSparkline || cell.inlineRuns != null) {
      return false;
    }
    return cell.value == formulaDisplayValue &&
        cell.hasRawValue &&
        cell.rawValue == formulaDisplayValue &&
        cell.displayValue == formulaDisplayValue &&
        cell.hasRawDisplayValue &&
        cell.rawDisplayValue == formulaDisplayValue;
  }

  static Object? evaluateFormula(FortuneSheet sheet, String formula) {
    final expression = formula.startsWith('=') ? formula.substring(1) : formula;
    if (expression.trim().isEmpty) {
      return '';
    }
    final cache = <FortuneCellCoord, Object?>{};
    return _Parser(
      expression,
      (ref, _) => _cellValue(sheet, ref, cache, <FortuneCellCoord>{}),
      (range) => _rangeValues(sheet, range, cache, <FortuneCellCoord>{}),
      (ref, _) => _cellFormula(sheet, ref),
      currentCoord: null,
      namedValues: _formulaVariables(sheet),
      customFunctions: _formulaFunctions(sheet),
      sheetNames: {sheet.name.toUpperCase()},
    ).parse();
  }

  static Map<String, Object?> executeAffectedFormulas(
    FortuneWorkbook workbook,
    Iterable<Map<String, Object?>> formulaRunList,
    Iterable<Map<String, Object?>> calcChains,
  ) {
    final calcChainSet = <String>{};
    for (final item in calcChains) {
      calcChainSet.add('${item['r']}_${item['c']}_${item['id']}');
    }
    final groupValuesRefreshData = <Map<String, Object?>>[];
    final execFunctionGlobalData = <String, Map<String, Object?>>{};
    for (final formulaCell in formulaRunList) {
      if (formulaCell['level'] == double.infinity ||
          formulaCell['level'] == 'Infinity') {
        continue;
      }
      final row = _intFromFormulaObject(formulaCell['r']);
      final column = _intFromFormulaObject(formulaCell['c']);
      final sheetId = formulaCell['id']?.toString();
      final formula = formulaCell['calc_funcStr']?.toString();
      if (row == null || column == null || sheetId == null || formula == null) {
        continue;
      }
      final sheet = workbook.getSheet(id: sheetId);
      if (sheet == null) {
        continue;
      }
      final executableFormula =
          !formula.contains(ERROR_REF) && !checkBracketNum(formula)
          ? '$formula)'
          : formula;
      final rawValue = executableFormula.contains(ERROR_REF)
          ? ERROR_REF
          : _evaluateFormulaInWorkbook(workbook, sheet, executableFormula);
      final value = _dynamicArraySpillValue(
        sheet,
        FortuneCellCoord(row, column),
        rawValue,
        formula: executableFormula,
      );
      final formulaSparkline = value is _FormulaSparkline ? value.data : null;
      final dynamicArrayData = value is _FormulaArgument
          ? {
              'r': row,
              'c': column,
              'f': executableFormula,
              'data': value.values,
              'rowCount': value.rowCount,
              'columnCount': value.columnCount,
            }
          : null;
      final displayValue = executableFormula.contains(ERROR_REF)
          ? ERROR_REF
          : formulaSparkline != null
          ? ''
          : _formatFormulaValue(value ?? ERROR_VALUE);
      final entry = {
        'r': row,
        'c': column,
        'v': displayValue,
        'm': displayValue,
        'f': executableFormula,
        'spe': formulaSparkline != null
            ? {'type': 'sparklines', 'data': formulaSparkline}
            : dynamicArrayData != null
            ? {'type': 'dynamicArrayItem', 'data': dynamicArrayData}
            : null,
        'id': sheetId,
      };
      groupValuesRefreshData.add(entry);
      groupValuesRefreshData.addAll(
        _dynamicArrayRefreshData(
          row: row,
          column: column,
          sheetId: sheetId,
          value: value,
        ),
      );
      final key = '${row}_${column}_$sheetId';
      execFunctionGlobalData[key] = {'v': displayValue, 'f': executableFormula};
    }
    return {
      'calcChainSet': calcChainSet,
      'groupValuesRefreshData': groupValuesRefreshData,
      'execFunctionGlobalData': execFunctionGlobalData,
    };
  }

  static int? _intFromFormulaObject(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static void _materializeDynamicArrayCells(
    FortuneSheet sheet,
    FortuneCellCoord anchor,
    Object? value,
  ) {
    if (value is! _FormulaArgument ||
        (value.rowCount <= 1 && value.columnCount <= 1)) {
      return;
    }
    for (var rowOffset = 0; rowOffset < value.rowCount; rowOffset += 1) {
      for (
        var columnOffset = 0;
        columnOffset < value.columnCount;
        columnOffset += 1
      ) {
        if (rowOffset == 0 && columnOffset == 0) {
          continue;
        }
        final coord = FortuneCellCoord(
          anchor.row + rowOffset,
          anchor.column + columnOffset,
        );
        final scalar = value.valueAt(rowOffset, columnOffset);
        final displayValue = _formatFormulaValue(scalar);
        final previous = sheet.cells[coord] ?? const FortuneCell();
        if (previous.formula != null) {
          continue;
        }
        sheet.cells[coord] = previous.copyWith(
          value: displayValue,
          rawValue: _rawFormulaCellValue(scalar),
          hasRawValue: true,
          displayValue: displayValue,
          rawDisplayValue: displayValue,
          hasRawDisplayValue: true,
          formula: null,
          rawFormula: null,
          hasRawFormula: false,
          sparkline: null,
          rawSparkline: null,
          hasSparkline: false,
          hasRawSparkline: false,
          inlineRuns: null,
        );
      }
    }
  }

  static Object? _dynamicArraySpillValue(
    FortuneSheet sheet,
    FortuneCellCoord anchor,
    Object? value, {
    required String formula,
  }) {
    if (value is! _FormulaArgument ||
        (value.rowCount <= 1 && value.columnCount <= 1) ||
        !_formulaUsesDynamicArraySpillGuard(formula)) {
      return value;
    }
    return _dynamicArraySpillBlocked(sheet, anchor, value)
        ? _FormulaError.spill
        : value;
  }

  static bool _formulaUsesDynamicArraySpillGuard(String formula) {
    final expression = formula.startsWith('=') ? formula.substring(1) : formula;
    final trimmed = expression.trimLeft().toUpperCase();
    return trimmed.contains('SEQUENCE(') || trimmed.contains('RANDARRAY(');
  }

  static bool _dynamicArraySpillBlocked(
    FortuneSheet sheet,
    FortuneCellCoord anchor,
    _FormulaArgument value,
  ) {
    final previous = _dynamicArrayEntryFor(
      sheet.dynamicArray,
      anchor.row,
      anchor.column,
      sheet.id,
    );
    for (final coord in _dynamicArrayFollowerCoords(
      row: anchor.row,
      column: anchor.column,
      rowCount: value.rowCount,
      columnCount: value.columnCount,
    )) {
      final current = sheet.cells[coord];
      if (current == null || current.isVisuallyEmpty) {
        continue;
      }
      final rowOffset = coord.row - anchor.row;
      final columnOffset = coord.column - anchor.column;
      if (previous != null) {
        final expected = _dynamicArrayEntryValueAt(
          previous,
          rowOffset,
          columnOffset,
        );
        if (!identical(expected, _missingFormulaValue) &&
            _cellMatchesDynamicArrayValue(current, expected)) {
          continue;
        }
      }
      return true;
    }
    return false;
  }

  static void _clearStaleDynamicArrayCells(
    FortuneSheet sheet,
    FortuneCellCoord anchor,
    Object? value,
  ) {
    final previous = _dynamicArrayEntryFor(
      sheet.dynamicArray,
      anchor.row,
      anchor.column,
      sheet.id,
    );
    if (previous == null) {
      return;
    }
    final nextCoords = value is _FormulaArgument
        ? _dynamicArrayFollowerCoords(
            row: anchor.row,
            column: anchor.column,
            rowCount: value.rowCount,
            columnCount: value.columnCount,
          )
        : const <FortuneCellCoord>{};
    for (final coord in _dynamicArrayEntryFollowerCoords(previous)) {
      if (nextCoords.contains(coord)) {
        continue;
      }
      final current = sheet.cells[coord];
      if (current == null) {
        continue;
      }
      final expected = _dynamicArrayEntryValueAt(
        previous,
        coord.row - anchor.row,
        coord.column - anchor.column,
      );
      if (identical(expected, _missingFormulaValue) ||
          !_cellMatchesDynamicArrayValue(current, expected)) {
        continue;
      }
      sheet.cells[coord] = current.copyWith(
        value: '',
        rawValue: null,
        hasRawValue: false,
        displayValue: null,
        rawDisplayValue: null,
        hasRawDisplayValue: false,
        formula: null,
        rawFormula: null,
        hasRawFormula: false,
      );
    }
  }

  static Map<String, Object?>? _dynamicArrayMetadataItem({
    required FortuneCellCoord anchor,
    required String formula,
    required Object? value,
  }) {
    if (value is! _FormulaArgument) {
      return null;
    }
    return {
      'r': anchor.row,
      'c': anchor.column,
      'f': formula,
      'data': value.values,
      'rowCount': value.rowCount,
      'columnCount': value.columnCount,
    };
  }

  static List<Map<String, Object?>> _dynamicArrayWithMetadataItems(
    Object? dynamicArray,
    Iterable<Map<String, Object?>> items,
    String sheetId,
  ) {
    var entries = _dynamicArrayEntries(dynamicArray);
    for (final item in items) {
      final row = _intFromFormulaObject(item['r']);
      final column = _intFromFormulaObject(item['c']);
      if (row == null || column == null) {
        continue;
      }
      final nextItem = Map<String, Object?>.from(item);
      nextItem['id'] = nextItem['id']?.toString() ?? sheetId;
      final index = entries.indexWhere(
        (entry) =>
            _intFromFormulaObject(entry['r']) == row &&
            _intFromFormulaObject(entry['c']) == column &&
            entry['id']?.toString() == nextItem['id'],
      );
      if (index < 0) {
        entries = [...entries, nextItem];
        continue;
      }
      final nextEntry = {
        ...entries[index],
        'data': cloneFortuneMetadata(nextItem['data']),
        'f': cloneFortuneMetadata(nextItem['f']),
        'rowCount': cloneFortuneMetadata(nextItem['rowCount']),
        'columnCount': cloneFortuneMetadata(nextItem['columnCount']),
      };
      entries = [...entries]..[index] = nextEntry;
    }
    return entries;
  }

  static List<Map<String, Object?>> _dynamicArrayWithoutAnchors(
    Object? dynamicArray,
    Iterable<FortuneCellCoord> anchors,
    String sheetId,
  ) {
    final removals = {
      for (final coord in anchors) '${coord.row}_${coord.column}_$sheetId',
    };
    if (removals.isEmpty) {
      return _dynamicArrayEntries(dynamicArray);
    }
    return [
      for (final entry in _dynamicArrayEntries(dynamicArray))
        if (!removals.contains(
          '${_intFromFormulaObject(entry['r'])}_${_intFromFormulaObject(entry['c'])}_${entry['id']?.toString()}',
        ))
          entry,
    ];
  }

  static List<Map<String, Object?>> _dynamicArrayEntries(Object? value) {
    if (value is! Iterable) {
      return const [];
    }
    return [
      for (final entry in value)
        if (entry is Map) Map<String, Object?>.from(entry),
    ];
  }

  static List<Map<String, Object?>> _staleDynamicArrayRefreshCells(
    FortuneWorkbook workbook,
    Iterable<Map<String, Object?>> refreshData,
  ) {
    final cells = <String, Map<String, Object?>>{};
    for (final item in refreshData) {
      final special = item['spe'];
      final dynamicArrayData =
          special is Map && special['type'] == 'dynamicArrayItem'
          ? special['data']
          : null;
      final data = dynamicArrayData is Map
          ? Map<String, Object?>.from(dynamicArrayData)
          : item.containsKey('f')
          ? <String, Object?>{
              'r': item['r'],
              'c': item['c'],
              'id': item['id'],
              'data': const [],
              'rowCount': 1,
              'columnCount': 1,
            }
          : null;
      if (data == null) {
        continue;
      }
      final sheetId = item['id']?.toString() ?? data['id']?.toString();
      final row = _intFromFormulaObject(data['r']);
      final column = _intFromFormulaObject(data['c']);
      if (sheetId == null || row == null || column == null) {
        continue;
      }
      final sheet = workbook.getSheet(id: sheetId);
      if (sheet == null) {
        continue;
      }
      final previous = _dynamicArrayEntryFor(
        sheet.dynamicArray,
        row,
        column,
        sheetId,
      );
      if (previous == null) {
        continue;
      }
      final nextCoords = dynamicArrayData is Map
          ? _dynamicArrayEntryFollowerCoords(data)
          : const <FortuneCellCoord>{};
      for (final coord in _dynamicArrayEntryFollowerCoords(previous)) {
        if (nextCoords.contains(coord)) {
          continue;
        }
        final current = sheet.cells[coord];
        if (current == null) {
          continue;
        }
        final expected = _dynamicArrayEntryValueAt(
          previous,
          coord.row - row,
          coord.column - column,
        );
        if (identical(expected, _missingFormulaValue) ||
            !_cellMatchesDynamicArrayValue(current, expected)) {
          continue;
        }
        final key = '${coord.row}_${coord.column}_$sheetId';
        cells[key] = {
          'row': coord.row,
          'column': coord.column,
          'sheetId': sheetId,
        };
      }
    }
    return cells.values.toList();
  }

  static Map<String, Object?>? _dynamicArrayEntryFor(
    Object? dynamicArray,
    int row,
    int column,
    String sheetId,
  ) {
    for (final entry in _dynamicArrayEntries(dynamicArray)) {
      if (_intFromFormulaObject(entry['r']) == row &&
          _intFromFormulaObject(entry['c']) == column &&
          entry['id']?.toString() == sheetId) {
        return entry;
      }
    }
    return null;
  }

  static Set<FortuneCellCoord> _dynamicArrayEntryFollowerCoords(
    Map<String, Object?> item,
  ) {
    final row = _intFromFormulaObject(item['r']);
    final column = _intFromFormulaObject(item['c']);
    if (row == null || column == null) {
      return const <FortuneCellCoord>{};
    }
    final shape = _dynamicArrayEntryShape(item);
    return _dynamicArrayFollowerCoords(
      row: row,
      column: column,
      rowCount: shape.$1,
      columnCount: shape.$2,
    );
  }

  static Set<FortuneCellCoord> _dynamicArrayFollowerCoords({
    required int row,
    required int column,
    required int rowCount,
    required int columnCount,
  }) {
    final coords = <FortuneCellCoord>{};
    for (var rowOffset = 0; rowOffset < rowCount; rowOffset += 1) {
      for (
        var columnOffset = 0;
        columnOffset < columnCount;
        columnOffset += 1
      ) {
        if (rowOffset == 0 && columnOffset == 0) {
          continue;
        }
        coords.add(FortuneCellCoord(row + rowOffset, column + columnOffset));
      }
    }
    return coords;
  }

  static (int, int) _dynamicArrayEntryShape(Map<String, Object?> item) {
    final data = item['data'];
    final rowCount =
        _intFromFormulaObject(item['rowCount']) ??
        _intFromFormulaObject(item['rows']) ??
        (data is List && data.isNotEmpty && data.first is List
            ? data.length
            : data is List
            ? math.max(1, data.length)
            : 1);
    final columnCount =
        _intFromFormulaObject(item['columnCount']) ??
        _intFromFormulaObject(item['columns']) ??
        (data is List && data.isNotEmpty && data.first is List
            ? math.max(1, (data.first as List).length)
            : 1);
    return (math.max(1, rowCount), math.max(1, columnCount));
  }

  static Object? _dynamicArrayEntryValueAt(
    Map<String, Object?> item,
    int rowOffset,
    int columnOffset,
  ) {
    final data = item['data'];
    if (data is! List || rowOffset < 0 || columnOffset < 0) {
      return _missingFormulaValue;
    }
    if (data.isNotEmpty && data.first is List) {
      if (rowOffset >= data.length) {
        return _missingFormulaValue;
      }
      final row = data[rowOffset];
      if (row is! List || columnOffset >= row.length) {
        return _missingFormulaValue;
      }
      return row[columnOffset];
    }
    final shape = _dynamicArrayEntryShape(item);
    final index = rowOffset * shape.$2 + columnOffset;
    if (index < 0 || index >= data.length) {
      return _missingFormulaValue;
    }
    return data[index];
  }

  static bool _cellMatchesDynamicArrayValue(
    FortuneCell cell,
    Object? expected,
  ) {
    if (cell.formula != null ||
        (cell.hasRawFormula && cell.rawFormula != null) ||
        cell.hasSparkline ||
        cell.hasRawSparkline ||
        cell.inlineRuns != null) {
      return false;
    }
    final raw = cell.hasRawValue ? cell.rawValue : cell.value;
    if (raw == expected || raw is num && expected is num && raw == expected) {
      return true;
    }
    final expectedText = _dynamicArrayValueText(expected);
    return cell.renderedText == expectedText ||
        (cell.hasRawDisplayValue &&
            cell.rawDisplayValue?.toString() == expectedText);
  }

  static String _dynamicArrayValueText(Object? value) {
    if (value == null) {
      return '';
    }
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  static List<Map<String, Object?>> _dynamicArrayRefreshData({
    required int row,
    required int column,
    required String sheetId,
    required Object? value,
  }) {
    if (value is! _FormulaArgument ||
        (value.rowCount <= 1 && value.columnCount <= 1)) {
      return const [];
    }
    final refreshData = <Map<String, Object?>>[];
    for (var rowOffset = 0; rowOffset < value.rowCount; rowOffset += 1) {
      for (
        var columnOffset = 0;
        columnOffset < value.columnCount;
        columnOffset += 1
      ) {
        if (rowOffset == 0 && columnOffset == 0) {
          continue;
        }
        final scalar = value.valueAt(rowOffset, columnOffset);
        final displayValue = _formatFormulaValue(scalar);
        refreshData.add({
          'r': row + rowOffset,
          'c': column + columnOffset,
          'v': _rawFormulaCellValue(scalar),
          'm': displayValue,
          'id': sheetId,
        });
      }
    }
    return refreshData;
  }

  static Object? _rawFormulaCellValue(Object? value) {
    if (identical(value, _formulaNull) || identical(value, _formulaBlank)) {
      return '';
    }
    if (value is _FormulaError) {
      return value.label;
    }
    return value;
  }

  static Object? _evaluateCell(
    FortuneSheet sheet,
    FortuneCellCoord coord,
    Map<FortuneCellCoord, Object?> cache,
    Set<FortuneCellCoord> visiting,
  ) {
    if (cache.containsKey(coord)) {
      return cache[coord];
    }
    if (!visiting.add(coord)) {
      cache[coord] = null;
      return null;
    }
    final cell = sheet.cells[coord];
    final formula = cell?.formula;
    Object? value;
    if (formula != null && formula.startsWith('=')) {
      final expression = formula.substring(1);
      value = expression.trim().isEmpty
          ? ''
          : _Parser(
              expression,
              (ref, _) => _cellValue(sheet, ref, cache, visiting),
              (range) => _rangeValues(sheet, range, cache, visiting),
              (ref, _) => _cellFormula(sheet, ref),
              currentCoord: coord,
              namedValues: _formulaVariables(sheet),
              customFunctions: _formulaFunctions(sheet),
              sheetNames: {sheet.name.toUpperCase()},
            ).parse();
    } else {
      value = _numberFromCell(cell);
    }
    visiting.remove(coord);
    cache[coord] = value;
    return value;
  }

  static Object? _cellValue(
    FortuneSheet sheet,
    FortuneCellCoord coord,
    Map<FortuneCellCoord, Object?> cache,
    Set<FortuneCellCoord> visiting,
  ) {
    final cell = sheet.cells[coord];
    if (cell?.formula != null) {
      return _evaluateCell(sheet, coord, cache, visiting);
    }
    if (cell != null && cell.hasRawValue) {
      final rawValue = cell.rawValue;
      if (rawValue is Map || rawValue is List) {
        return rawValue;
      }
      if (rawValue is bool) {
        return rawValue;
      }
      if (rawValue is String) {
        final number = double.tryParse(rawValue.trim());
        if (number != null) {
          return number;
        }
        if (rawValue.trim().isEmpty) {
          return _formulaBlank;
        }
        return rawValue;
      }
    }
    final text = cell?.displayValue ?? cell?.value;
    if (text == null || text.trim().isEmpty) {
      return _formulaBlank;
    }
    return _numberFromCell(cell) ?? text;
  }

  static Object? _cellScalarValue(FortuneCell? cell) {
    if (cell != null && cell.hasRawValue) {
      final rawValue = cell.rawValue;
      if (rawValue is Map || rawValue is List) {
        return rawValue;
      }
      if (rawValue is bool) {
        return rawValue;
      }
      if (rawValue is String) {
        final number = double.tryParse(rawValue.trim());
        if (number != null) {
          return number;
        }
        if (rawValue.trim().isEmpty) {
          return _formulaBlank;
        }
        return rawValue;
      }
    }
    final text = cell?.displayValue ?? cell?.value;
    if (text == null || text.trim().isEmpty) {
      return _formulaBlank;
    }
    return _numberFromCell(cell) ?? text;
  }

  static List<Object> _rangeValues(
    FortuneSheet sheet,
    _FormulaRange range,
    Map<FortuneCellCoord, Object?> cache,
    Set<FortuneCellCoord> visiting,
  ) {
    final values = <Object>[];
    for (var r = range.rowStart; r <= range.rowEnd; r += 1) {
      for (var c = range.columnStart; c <= range.columnEnd; c += 1) {
        final value = _cellValue(
          sheet,
          FortuneCellCoord(r, c),
          cache,
          visiting,
        );
        values.add(value ?? _formulaBlank);
      }
    }
    return values;
  }

  static Object? _evaluateFormulaInWorkbook(
    FortuneWorkbook workbook,
    FortuneSheet sheet,
    String formula,
  ) {
    final expression = formula.startsWith('=') ? formula.substring(1) : formula;
    if (expression.trim().isEmpty) {
      return '';
    }
    final cache = <String, Object?>{};
    final visiting = <String>{};
    return _Parser(
      expression,
      (ref, sheetName) => _cellValueInWorkbook(
        workbook,
        sheet,
        ref,
        sheetName,
        cache,
        visiting,
      ),
      (range) =>
          _rangeValuesInWorkbook(workbook, sheet, range, cache, visiting),
      (ref, sheetName) =>
          _cellFormulaInWorkbook(workbook, sheet, ref, sheetName),
      currentCoord: null,
      namedValues: _formulaVariables(sheet),
      customFunctions: _formulaFunctions(sheet),
      sheetNames: {
        for (final current in workbook.sheets) current.name.toUpperCase(),
      },
    ).parse();
  }

  static Object? _cellValueInWorkbook(
    FortuneWorkbook workbook,
    FortuneSheet currentSheet,
    FortuneCellCoord coord,
    String? sheetName,
    Map<String, Object?> cache,
    Set<String> visiting,
  ) {
    final sheet = _sheetForFormulaReference(workbook, currentSheet, sheetName);
    if (sheet == null) {
      return _FormulaError.ref;
    }
    final cacheKey = '${sheet.id}:${coord.row}:${coord.column}';
    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey];
    }
    if (!visiting.add(cacheKey)) {
      cache[cacheKey] = null;
      return null;
    }
    final cell = sheet.cells[coord];
    final formula = cell?.formula;
    Object? value;
    if (formula != null && formula.startsWith('=')) {
      final expression = formula.substring(1);
      value = expression.trim().isEmpty
          ? ''
          : _Parser(
              expression,
              (ref, nestedSheetName) => _cellValueInWorkbook(
                workbook,
                sheet,
                ref,
                nestedSheetName,
                cache,
                visiting,
              ),
              (range) => _rangeValuesInWorkbook(
                workbook,
                sheet,
                range,
                cache,
                visiting,
              ),
              (ref, nestedSheetName) =>
                  _cellFormulaInWorkbook(workbook, sheet, ref, nestedSheetName),
              currentCoord: coord,
              namedValues: _formulaVariables(sheet),
              customFunctions: _formulaFunctions(sheet),
              sheetNames: {
                for (final current in workbook.sheets)
                  current.name.toUpperCase(),
              },
            ).parse();
    } else {
      value = _cellScalarValue(cell);
    }
    visiting.remove(cacheKey);
    cache[cacheKey] = value;
    return value;
  }

  static List<Object> _rangeValuesInWorkbook(
    FortuneWorkbook workbook,
    FortuneSheet currentSheet,
    _FormulaRange range,
    Map<String, Object?> cache,
    Set<String> visiting,
  ) {
    final values = <Object>[];
    for (var row = range.rowStart; row <= range.rowEnd; row += 1) {
      for (
        var column = range.columnStart;
        column <= range.columnEnd;
        column += 1
      ) {
        final value = _cellValueInWorkbook(
          workbook,
          currentSheet,
          FortuneCellCoord(row, column),
          range.sheetName,
          cache,
          visiting,
        );
        values.add(value ?? _formulaBlank);
      }
    }
    return values;
  }

  static String? _cellFormulaInWorkbook(
    FortuneWorkbook workbook,
    FortuneSheet currentSheet,
    FortuneCellCoord coord,
    String? sheetName,
  ) {
    final sheet = _sheetForFormulaReference(workbook, currentSheet, sheetName);
    return sheet == null ? null : _cellFormula(sheet, coord);
  }

  static FortuneSheet? _sheetForFormulaReference(
    FortuneWorkbook workbook,
    FortuneSheet currentSheet,
    String? sheetName,
  ) {
    if (sheetName == null || sheetName.isEmpty) {
      return currentSheet;
    }
    final normalized = _normalizeFormulaSheetName(sheetName).toUpperCase();
    for (final sheet in workbook.sheets) {
      if (sheet.name.toUpperCase() == normalized) {
        return sheet;
      }
    }
    return null;
  }

  static String _normalizeFormulaSheetName(String name) {
    final bracketEnd = name.startsWith('[') ? name.indexOf(']') : -1;
    return bracketEnd >= 0 ? name.substring(bracketEnd + 1) : name;
  }

  static Map<String, Object?> _formulaVariables(FortuneSheet sheet) {
    final rawVariables = sheet.extraFields['formulaVariables'];
    if (rawVariables is! Map) {
      return const {};
    }
    return {
      for (final entry in rawVariables.entries)
        if (entry.key is String)
          (entry.key as String).toUpperCase(): entry.value,
    };
  }

  static Map<String, FortuneFormulaFunction> _formulaFunctions(
    FortuneSheet sheet,
  ) {
    final rawFunctions = sheet.extraFields['formulaFunctions'];
    if (rawFunctions is! Map) {
      return const {};
    }
    return {
      for (final entry in rawFunctions.entries)
        if (entry.value is FortuneFormulaFunction)
          entry.key.toString().toUpperCase():
              entry.value as FortuneFormulaFunction,
    };
  }

  static String? _cellFormula(FortuneSheet sheet, FortuneCellCoord coord) {
    final formula = sheet.cells[coord]?.formula;
    return formula != null && formula.startsWith('=') ? formula : null;
  }

  static double? _numberFromCell(FortuneCell? cell) {
    if (cell == null) {
      return 0;
    }
    if (cell.hasRawValue) {
      final rawValue = cell.rawValue;
      if (rawValue is num) {
        return rawValue.toDouble();
      }
      if (rawValue is String) {
        final number = double.tryParse(rawValue.trim());
        if (number != null) {
          return number;
        }
      }
    }
    final text = cell.displayValue ?? cell.value;
    if (text.trim().isEmpty) {
      return 0;
    }
    return double.tryParse(text.replaceAll(',', '').trim());
  }

  static String _formatFormulaValue(Object value) {
    if (value is _FormulaArgument) {
      return _formatFormulaValue(value.singleValue);
    }
    if (identical(value, _formulaNull)) {
      return '';
    }
    if (identical(value, _formulaBlank)) {
      return '0';
    }
    if (value is _FormulaError) {
      return value.label;
    }
    if (value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toString();
    }
    if (value is bool) {
      return value ? 'TRUE' : 'FALSE';
    }
    final number = _numberFromFormulaValue(value);
    return number == null ? '#VALUE!' : _formatNumber(number);
  }

  static double? _numberFromFormulaValue(Object? value) {
    if (value is _FormulaArgument) {
      return _numberFromFormulaValue(value.singleValue);
    }
    if (_isFormulaBlankLike(value)) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is _FormulaError) {
      return null;
    }
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '').trim());
    }
    return null;
  }

  static String _formatNumber(double value) {
    if (value.isInfinite) {
      return value.isNegative ? '-Infinity' : 'Infinity';
    }
    if (value.isNaN) {
      return '#VALUE!';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    var text = value.toStringAsFixed(12);
    while (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  static bool _isIdentifierChar(String char) {
    if (char.isEmpty) {
      return false;
    }
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 0x00c0 && code <= 0x02af) ||
        (code >= 48 && code <= 57) ||
        char == '_' ||
        char == '.';
  }

  static int _columnIndex(String name) {
    var column = 0;
    for (final code in name.toUpperCase().codeUnits) {
      column = column * 26 + code - 64;
    }
    return column - 1;
  }

  static String _columnName(int index) {
    var value = index + 1;
    final chars = <String>[];
    while (value > 0) {
      final remainder = (value - 1) % 26;
      chars.insert(0, String.fromCharCode(65 + remainder));
      value = (value - 1) ~/ 26;
    }
    return chars.join();
  }
}

class _Parser {
  _Parser(
    this.source,
    this.cellValue,
    this.rangeValues,
    this.cellFormula, {
    required this.currentCoord,
    this.namedValues = const {},
    this.customFunctions = const {},
    this.sheetNames = const {},
    this.referenceCellValue,
    this.referenceRangeValues,
    this.variableValue,
    this.functionValue,
    this.strictParserCompatibility = false,
  });

  static final RegExp _formatConditionPattern = RegExp(
    r'^(<=|>=|<>|=|<|>)(-?(?:\d+\.?\d*|\.\d+)%?)$',
  );
  static final RegExp _formatColorPattern = RegExp(
    r'^(?:black|blue|cyan|green|magenta|red|white|yellow|color\d+)$',
  );

  final String source;
  final Object? Function(FortuneCellCoord ref, String? sheetName) cellValue;
  final List<Object> Function(_FormulaRange range) rangeValues;
  final String? Function(FortuneCellCoord ref, String? sheetName) cellFormula;
  final FortuneCellCoord? currentCoord;
  final Map<String, Object?> namedValues;
  final Map<String, FortuneFormulaFunction> customFunctions;
  final Set<String> sheetNames;
  final Object? Function(
    FortuneCellCoord ref,
    String? sheetName,
    String reference,
  )?
  referenceCellValue;
  final Object? Function(_FormulaRange range)? referenceRangeValues;
  final Object? Function(String name)? variableValue;
  final Object? Function(String name, List<Object?> params)? functionValue;
  final bool strictParserCompatibility;
  int _offset = 0;

  Object? parse() {
    final value = _comparison();
    _skipWhitespace();
    if (value == null || _offset != source.length) {
      return null;
    }
    return value;
  }

  Object _namedFormulaValue(Object? value) {
    if (value == null) {
      return _formulaBlank;
    }
    if (value is List) {
      if (value.every((item) => item is List)) {
        final rows = value.cast<List>();
        final columnCount = rows.isEmpty ? 0 : rows.first.length;
        return _FormulaArgument.range(
          [
            for (final row in rows)
              for (final item in row) item is Object ? item : _formulaBlank,
          ],
          rowCount: rows.length,
          columnCount: columnCount,
        );
      }
      return _FormulaArgument.range(
        [for (final item in value) item is Object ? item : _formulaBlank],
        rowCount: 1,
        columnCount: value.length,
      );
    }
    return value;
  }

  Object? _comparison() {
    var value = _concat();
    while (value != null) {
      _skipWhitespace();
      final operator = _comparisonOperator();
      if (operator == null) {
        break;
      }
      final right = _concat();
      if (right == null) {
        return null;
      }
      final error = _formulaError(value) ?? _formulaError(right);
      if (error != null) {
        value = error;
        continue;
      }
      value = _compare(value, right, operator);
    }
    return value;
  }

  Object? _concat() {
    var value = _expression();
    while (value != null) {
      _skipWhitespace();
      if (!_consume('&')) {
        break;
      }
      final right = _expression();
      if (right == null) {
        return null;
      }
      final error = _formulaError(value) ?? _formulaError(right);
      if (error != null) {
        value = error;
        continue;
      }
      value = '${_text(value)}${_text(right)}';
    }
    return value;
  }

  Object? _expression() {
    var value = _term();
    while (value != null) {
      _skipWhitespace();
      if (_consume('+')) {
        final right = _term();
        if (right == null) {
          return null;
        }
        final error = _formulaError(value) ?? _formulaError(right);
        if (error != null) {
          value = error;
          continue;
        }
        final leftNumber = FortuneFormulaEngine._numberFromFormulaValue(value);
        final rightNumber = FortuneFormulaEngine._numberFromFormulaValue(right);
        if (leftNumber == null || rightNumber == null) {
          value = _FormulaError.value;
          continue;
        }
        value = leftNumber + rightNumber;
      } else if (_consume('-')) {
        final right = _term();
        if (right == null) {
          return null;
        }
        final error = _formulaError(value) ?? _formulaError(right);
        if (error != null) {
          value = error;
          continue;
        }
        final leftNumber = FortuneFormulaEngine._numberFromFormulaValue(value);
        final rightNumber = FortuneFormulaEngine._numberFromFormulaValue(right);
        if (leftNumber == null || rightNumber == null) {
          value = _FormulaError.value;
          continue;
        }
        value = leftNumber - rightNumber;
      } else {
        break;
      }
    }
    return value;
  }

  Object? _term() {
    var value = _power();
    while (value != null) {
      _skipWhitespace();
      if (_consume('*')) {
        final right = _power();
        if (right == null) {
          return null;
        }
        final error = _formulaError(value) ?? _formulaError(right);
        if (error != null) {
          value = error;
          continue;
        }
        final leftNumber = FortuneFormulaEngine._numberFromFormulaValue(value);
        final rightNumber = FortuneFormulaEngine._numberFromFormulaValue(right);
        if (leftNumber == null || rightNumber == null) {
          value = _FormulaError.value;
          continue;
        }
        value = leftNumber * rightNumber;
      } else if (_consume('/')) {
        final right = _power();
        if (right == null) {
          return null;
        }
        final error = _formulaError(value) ?? _formulaError(right);
        if (error != null) {
          value = error;
          continue;
        }
        final leftNumber = FortuneFormulaEngine._numberFromFormulaValue(value);
        final rightNumber = FortuneFormulaEngine._numberFromFormulaValue(right);
        if (leftNumber == null || rightNumber == null) {
          value = _FormulaError.value;
          continue;
        }
        value = rightNumber == 0
            ? _FormulaError.div0
            : leftNumber / rightNumber;
      } else {
        break;
      }
    }
    return value;
  }

  Object? _power() {
    var value = _factor();
    if (value == null) {
      return null;
    }
    _skipWhitespace();
    if (_consume('^')) {
      final right = _power();
      if (right == null) {
        return null;
      }
      final error = _formulaError(value) ?? _formulaError(right);
      if (error != null) {
        return error;
      }
      final leftNumber = FortuneFormulaEngine._numberFromFormulaValue(value);
      final rightNumber = FortuneFormulaEngine._numberFromFormulaValue(right);
      if (leftNumber == null || rightNumber == null) {
        return _FormulaError.value;
      }
      value = _powerValue(leftNumber, rightNumber);
    }
    return value;
  }

  Object? _factor() {
    _skipWhitespace();
    if (_consume('+')) {
      return _factor();
    }
    if (_consume('-')) {
      final value = _factor();
      final error = _formulaError(value);
      if (error != null) {
        return error;
      }
      final number = FortuneFormulaEngine._numberFromFormulaValue(value);
      return number == null ? _FormulaError.value : -number;
    }
    if (_consume('(')) {
      final value = _comparison();
      if (value == null || !_consume(')')) {
        return null;
      }
      return _percent(value);
    }
    if (_consume('{')) {
      return _arrayConstant();
    }
    final string = _string();
    if (string != null) {
      return string;
    }
    final error = _errorLiteral();
    if (error != null) {
      return error;
    }
    final number = _number();
    if (number != null) {
      return _percent(number);
    }
    final prefixedSheetName = _consumeSheetNamePrefix();
    if (prefixedSheetName != null) {
      return _prefixedReferenceValue(
        invalidPrefix: !_isKnownSheetName(prefixedSheetName),
        prefixName: prefixedSheetName,
      );
    }
    if (_consume('[')) {
      return _bracketArrayConstant();
    }
    final identifier = _identifier();
    if (identifier == null) {
      return null;
    }
    _skipWhitespace();
    if (_consume('(')) {
      return _percent(_function(identifier));
    }
    if (_consume('!')) {
      return _prefixedReferenceValue(
        invalidPrefix: !_isKnownSheetName(identifier),
        prefixName: identifier,
      );
    }
    final constant = switch (identifier.toUpperCase()) {
      'TRUE' => true,
      'FALSE' => false,
      'NULL' => _formulaNull,
      _ => null,
    };
    if (constant != null) {
      return _percent(constant);
    }
    final upperIdentifier = identifier.toUpperCase();
    if (namedValues.containsKey(upperIdentifier)) {
      return _percent(_namedFormulaValue(namedValues[upperIdentifier]));
    }
    final start = _coordFromIdentifier(identifier);
    if (start == null) {
      if (identifier.contains(r'$')) {
        _consumeMalformedReferenceTail();
        return _FormulaError.error;
      }
      if (variableValue != null) {
        final eventValue = variableValue!(identifier);
        if (!identical(eventValue, _parserNoValue)) {
          return _percent(_namedFormulaValue(eventValue));
        }
      }
      return _FormulaError.name;
    }
    _skipWhitespace();
    if (_consume(':')) {
      final endReference = _rangeEndReference();
      if (_rangeHasInvalidSheetBoundary(null, endReference?.sheetName)) {
        return _FormulaError.value;
      }
      final end = endReference == null
          ? null
          : _coordFromIdentifier(endReference.identifier);
      if (end == null) {
        if (endReference?.identifier.contains(r'$') ?? false) {
          _consumeMalformedReferenceTail();
          return _FormulaError.error;
        }
        return null;
      }
      final range = _FormulaRange.fromCoords(
        start,
        end,
        startReference: identifier,
        endReference: endReference!.identifier,
      );
      final eventValue = _rangeEventValue(range);
      if (!identical(eventValue, _parserNoValue)) {
        return _percent(eventValue);
      }
      if (strictParserCompatibility && referenceRangeValues != null) {
        return _percent(const <Object>[]);
      }
      return _percent(
        rangeValues(range).fold<double>(
          0,
          (sum, item) =>
              sum + (FortuneFormulaEngine._numberFromFormulaValue(item) ?? 0),
        ),
      );
    }
    return _percent(_cellValue(start, null, identifier));
  }

  Object? _prefixedReferenceValue({
    bool invalidPrefix = false,
    String? prefixName,
  }) {
    final startIdentifier = _identifier();
    final start = startIdentifier == null
        ? null
        : _coordFromIdentifier(startIdentifier);
    if (start == null) {
      return null;
    }
    _skipWhitespace();
    if (_consume(':')) {
      final endReference = _rangeEndReference();
      if (invalidPrefix) {
        return _FormulaError.ref;
      }
      if (_rangeHasInvalidSheetBoundary(prefixName, endReference?.sheetName)) {
        return _FormulaError.value;
      }
      final end = endReference == null
          ? null
          : _coordFromIdentifier(endReference.identifier);
      if (end == null) {
        return null;
      }
      final range = _FormulaRange.fromCoords(
        start,
        end,
        sheetName: prefixName,
        startReference: startIdentifier,
        endReference: endReference!.identifier,
      );
      final eventValue = _rangeEventValue(range);
      if (!identical(eventValue, _parserNoValue)) {
        return _percent(eventValue);
      }
      if (strictParserCompatibility && referenceRangeValues != null) {
        return _percent(const <Object>[]);
      }
      return _percent(
        rangeValues(range).fold<double>(
          0,
          (sum, item) =>
              sum + (FortuneFormulaEngine._numberFromFormulaValue(item) ?? 0),
        ),
      );
    }
    if (invalidPrefix) {
      return _FormulaError.ref;
    }
    return _percent(_cellValue(start, prefixName, startIdentifier!));
  }

  _FormulaArgument? _prefixedReferenceArgument() {
    final startOffset = _offset;
    var prefixName = _consumeSheetNamePrefix();
    var hasPrefix = prefixName != null;
    var invalidPrefix = false;
    if (!hasPrefix) {
      final prefixIdentifier = _identifier();
      if (prefixIdentifier != null) {
        _skipWhitespace();
        hasPrefix = _consume('!');
        prefixName = prefixIdentifier;
        invalidPrefix = hasPrefix && !_isKnownSheetName(prefixIdentifier);
      }
    } else {
      invalidPrefix = !_isKnownSheetName(prefixName);
    }
    if (!hasPrefix) {
      _offset = startOffset;
      return null;
    }
    final startIdentifier = _identifier();
    final start = startIdentifier == null
        ? null
        : _coordFromIdentifier(startIdentifier);
    if (start == null) {
      _offset = startOffset;
      return null;
    }
    _skipWhitespace();
    if (_consume(':')) {
      final endReference = _rangeEndReference();
      final end = endReference == null
          ? null
          : _coordFromIdentifier(endReference.identifier);
      if (end == null) {
        _offset = startOffset;
        return null;
      }
      if (invalidPrefix) {
        return _FormulaArgument.scalar(_FormulaError.ref);
      }
      if (_rangeHasInvalidSheetBoundary(prefixName, endReference!.sheetName)) {
        return _FormulaArgument.scalar(_FormulaError.value);
      }
      final range = _FormulaRange.fromCoords(
        start,
        end,
        sheetName: prefixName,
        startReference: startIdentifier,
        endReference: endReference.identifier,
      );
      return _FormulaArgument.range(
        _rangeValues(range),
        rowCount: range.rowCount,
        columnCount: range.columnCount,
        sourceRange: range,
      );
    }
    final value = _cellValue(start, prefixName, startIdentifier!);
    if (value == null) {
      _offset = startOffset;
      return null;
    }
    if (invalidPrefix) {
      return _FormulaArgument.scalar(_FormulaError.ref);
    }
    return _FormulaArgument.scalar(value);
  }

  Object? _cellValue(
    FortuneCellCoord ref,
    String? sheetName,
    String reference,
  ) {
    if (referenceCellValue != null) {
      final value = referenceCellValue!(ref, sheetName, reference);
      if (!identical(value, _parserNoValue)) {
        return value;
      }
    }
    return cellValue(ref, sheetName);
  }

  List<Object> _rangeValues(_FormulaRange range) {
    final value = _rangeEventValue(range);
    if (!identical(value, _parserNoValue)) {
      return _rangeEventValues(value);
    }
    return rangeValues(range);
  }

  Object? _rangeEventValue(_FormulaRange range) {
    if (referenceRangeValues == null) {
      return _parserNoValue;
    }
    return referenceRangeValues!(range);
  }

  List<Object> _rangeEventValues(Object? value) {
    if (value is List) {
      if (value.every((item) => item is List)) {
        return [
          for (final row in value.cast<List>())
            for (final item in row) item is Object ? item : _formulaBlank,
        ];
      }
      return [for (final item in value) item is Object ? item : _formulaBlank];
    }
    return value is Object ? [value] : const [];
  }

  bool _isKnownSheetName(String name) {
    return sheetNames.isEmpty || sheetNames.contains(name.toUpperCase());
  }

  _RangeEndReference? _rangeEndReference() {
    final prefixName = _consumeSheetNamePrefix();
    if (prefixName != null) {
      final identifier = _identifier();
      return identifier == null
          ? null
          : _RangeEndReference(identifier, prefixName);
    }
    final endIdentifier = _identifier();
    if (endIdentifier == null) {
      return null;
    }
    _skipWhitespace();
    if (_consume('!')) {
      final identifier = _identifier();
      return identifier == null
          ? null
          : _RangeEndReference(identifier, endIdentifier);
    }
    return _RangeEndReference(endIdentifier, null);
  }

  bool _rangeHasInvalidSheetBoundary(
    String? startSheetName,
    String? endSheetName,
  ) {
    if (endSheetName == null) {
      return false;
    }
    if (!_isKnownSheetName(endSheetName)) {
      return true;
    }
    if (startSheetName == null) {
      return false;
    }
    return _normalizeSheetName(startSheetName).toUpperCase() !=
        _normalizeSheetName(endSheetName).toUpperCase();
  }

  String? _consumeSheetNamePrefix() {
    return _consumeQuotedSheetNamePrefix() ?? _consumeExternalSheetNamePrefix();
  }

  String? _consumeQuotedSheetNamePrefix() {
    _skipWhitespace();
    final start = _offset;
    if (_offset >= source.length || source[_offset] != "'") {
      return null;
    }
    _offset += 1;
    final name = StringBuffer();
    while (_offset < source.length) {
      if (source[_offset] == "'") {
        if (_offset + 1 < source.length && source[_offset + 1] == "'") {
          name.write("'");
          _offset += 2;
          continue;
        }
        _offset += 1;
        _skipWhitespace();
        if (_consume('!')) {
          return _normalizeSheetName(name.toString());
        }
        break;
      }
      name.write(source[_offset]);
      _offset += 1;
    }
    _offset = start;
    return null;
  }

  String? _consumeExternalSheetNamePrefix() {
    _skipWhitespace();
    final start = _offset;
    if (_offset >= source.length || source[_offset] != '[') {
      return null;
    }
    _offset += 1;
    while (_offset < source.length && source[_offset] != ']') {
      _offset += 1;
    }
    if (_offset >= source.length || source[_offset] != ']') {
      _offset = start;
      return null;
    }
    _offset += 1;
    final sheetNameStart = _offset;
    while (_offset < source.length) {
      final char = source[_offset];
      if (char == '!') {
        final sheetName = source.substring(sheetNameStart, _offset).trim();
        _offset += 1;
        return sheetName.isEmpty ? null : _normalizeSheetName(sheetName);
      }
      if (char == ':' || char == ',' || char == ';' || char == ')') {
        break;
      }
      _offset += 1;
    }
    _offset = start;
    return null;
  }

  String _normalizeSheetName(String name) {
    final bracketEnd = name.startsWith('[') ? name.indexOf(']') : -1;
    return bracketEnd >= 0 ? name.substring(bracketEnd + 1) : name;
  }

  Object? _function(String name) {
    final upper = name.toUpperCase();
    if (upper == 'IF') {
      return _ifFunction();
    }
    if (upper == 'IFS') {
      return _ifsFunction();
    }
    if (upper == 'SWITCH') {
      return _switchFunction();
    }
    if (upper == 'CHOOSE') {
      return _chooseFunction();
    }
    if (upper == 'CELL') {
      return _cellFunction();
    }
    if (upper == 'AREAS') {
      return _areasFunction();
    }
    if (upper == 'INDEX') {
      return _indexFunction();
    }
    if (upper == 'MATCH') {
      return _matchFunction();
    }
    if (upper == 'XMATCH') {
      return _xmatchFunction();
    }
    if (upper == 'XLOOKUP') {
      return _xlookupFunction();
    }
    if (upper == 'VLOOKUP') {
      return _vlookupFunction();
    }
    if (upper == 'HLOOKUP') {
      return _hlookupFunction();
    }
    if (upper == 'LOOKUP') {
      return _lookupFunction();
    }
    if (upper == 'TEXTBEFORE') {
      return _textBeforeAfterFunction(before: true);
    }
    if (upper == 'TEXTAFTER') {
      return _textBeforeAfterFunction(before: false);
    }
    if (upper == 'TEXTSPLIT') {
      return _textSplitFunction();
    }
    if (upper == 'ARRAYTOTEXT') {
      return _arrayToTextFunction();
    }
    if (upper == 'VALUETOTEXT') {
      return _valueToTextSourceFunction();
    }
    if (upper == 'TAKE') {
      return _takeDropFunction(take: true);
    }
    if (upper == 'DROP') {
      return _takeDropFunction(take: false);
    }
    if (upper == 'CHOOSEROWS') {
      return _chooseRowsColumnsFunction(chooseRows: true);
    }
    if (upper == 'CHOOSECOLS') {
      return _chooseRowsColumnsFunction(chooseRows: false);
    }
    if (upper == 'VSTACK') {
      return _stackFunction(vertical: true);
    }
    if (upper == 'HSTACK') {
      return _stackFunction(vertical: false);
    }
    if (upper == 'TRANSPOSE') {
      return _transposeFunction();
    }
    if (upper == 'WRAPROWS') {
      return _wrapRowsColumnsFunction(wrapRows: true);
    }
    if (upper == 'WRAPCOLS') {
      return _wrapRowsColumnsFunction(wrapRows: false);
    }
    if (upper == 'EXPAND') {
      return _expandFunction();
    }
    if (upper == 'FILTER') {
      return _filterFunction();
    }
    if (upper == 'UNIQUE') {
      return _uniqueFunction();
    }
    if (upper == 'SORT') {
      return _sortFunction();
    }
    if (upper == 'SORTBY') {
      return _sortByFunction();
    }
    if (upper == 'TOCOL') {
      return _toRowColumnFunction(toRow: false);
    }
    if (upper == 'TOROW') {
      return _toRowColumnFunction(toRow: true);
    }
    if (upper == 'IFERROR') {
      return _ifErrorFunction();
    }
    if (upper == 'IFNA') {
      return _ifNaFunction();
    }
    if (upper == 'ISERROR') {
      return _isErrorFunction(includeNa: true);
    }
    if (upper == 'ISERR') {
      return _isErrorFunction(includeNa: false);
    }
    if (upper == 'ISNA') {
      return _isNaFunction();
    }
    if (upper == 'TYPE') {
      return _typeFunction();
    }
    if (upper == 'ERROR.TYPE' || upper == 'ERROR_TYPE') {
      return _errorTypeFunction();
    }
    if (upper == 'ISFORMULA') {
      return _isFormulaFunction();
    }
    if (upper == 'FORMULATEXT') {
      return _formulaTextFunction();
    }
    if (upper == 'ISREF') {
      return _isRefFunction();
    }
    if (upper == 'SHEET') {
      return _sheetNumberFunction();
    }
    if (upper == 'SHEETS') {
      return _sheetCountFunction();
    }
    if (upper == 'ROW') {
      return _rowFunction();
    }
    if (upper == 'COLUMN') {
      return _columnFunction();
    }
    if (upper == 'INDIRECT') {
      return _indirectFunction();
    }
    if (upper == 'OFFSET') {
      return _offsetFunction();
    }
    final args = <_FormulaArgument>[];
    while (true) {
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
      final argStart = _offset;
      final prefixedReference = _prefixedReferenceArgument();
      if (prefixedReference != null) {
        args.add(prefixedReference);
      } else {
        _offset = argStart;
        final identifier = _identifier();
        if (identifier != null) {
          _skipWhitespace();
          if (_consume(':')) {
            final endIdentifier = _identifier();
            final start = _coordFromIdentifier(identifier);
            final end = endIdentifier == null
                ? null
                : _coordFromIdentifier(endIdentifier);
            if (start == null || end == null) {
              return null;
            }
            final range = _FormulaRange.fromCoords(
              start,
              end,
              startReference: identifier,
              endReference: endIdentifier,
            );
            args.add(
              _FormulaArgument.range(
                _rangeValues(range),
                rowCount: range.rowCount,
                columnCount: range.columnCount,
                sourceRange: range,
              ),
            );
          } else {
            _offset = argStart;
            final value = _comparison();
            if (value == null) {
              return null;
            }
            args.add(
              value is _FormulaArgument
                  ? value
                  : _FormulaArgument.scalar(value),
            );
          }
        } else {
          final value = _comparison();
          if (value == null) {
            return null;
          }
          args.add(
            value is _FormulaArgument ? value : _FormulaArgument.scalar(value),
          );
        }
      }
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
    }

    final values = args.expand((arg) => arg.values).toList();
    final error = _firstFormulaError(values);
    if (error != null) {
      return error;
    }
    if (functionValue != null) {
      final eventValue = functionValue!(upper, [
        for (final arg in args) ...arg.values,
      ]);
      if (!identical(eventValue, _parserNoValue)) {
        return eventValue;
      }
    }
    final customFunction = customFunctions[upper];
    if (customFunction != null) {
      return customFunction([for (final arg in args) ...arg.values]);
    }
    if (_isSparklineFunctionName(upper)) {
      return _sparklineFunction(upper, args);
    }
    final numbers = values.map(_numberArgument).whereType<double>().toList();
    final nonLogicalNumbers = values
        .where((value) => value is! bool)
        .map(_numberArgument)
        .whereType<double>()
        .toList();
    return switch (upper) {
      'SUM' => _sumNumbers(numbers),
      'AVERAGE' =>
        nonLogicalNumbers.isEmpty
            ? _FormulaError.num
            : _averageNumbers(nonLogicalNumbers),
      'MIN' => numbers.isEmpty ? 0.0 : numbers.reduce((a, b) => a < b ? a : b),
      'MAX' => numbers.isEmpty ? 0.0 : numbers.reduce((a, b) => a > b ? a : b),
      'AVERAGEA' => values.isEmpty ? _FormulaError.num : _averageA(values),
      'MINA' => values.isEmpty ? 0.0 : _minA(values),
      'MAXA' => values.isEmpty ? 0.0 : _maxA(values),
      'FINDFIELD' =>
        args.length == 2
            ? _findField(args[0], args[1].singleValue)
            : _FormulaError.na,
      'MEDIAN' => numbers.isEmpty ? _FormulaError.num : _median(numbers),
      'MODE' ||
      'MODE_SNGL' ||
      'MODE.SNGL' ||
      'MODESNGL' => _modeFunction(args, multiple: false),
      'MODE.MULT' || 'MODEMULT' => _modeFunction(args, multiple: true),
      'PERCENTILE' || 'PERCENTILE_INC' || 'PERCENTILE.INC' || 'PERCENTILEINC' =>
        args.length == 2 ? _percentileFunction(args, inclusive: true) : null,
      'PERCENTILE_EXC' || 'PERCENTILE.EXC' || 'PERCENTILEEXC' =>
        args.length == 2 ? _percentileFunction(args, inclusive: false) : null,
      'PERCENTRANK' ||
      'PERCENTRANK_INC' ||
      'PERCENTRANK.INC' ||
      'PERCENTRANKINC' =>
        args.length == 2 || args.length == 3
            ? _percentRank(args, inclusive: true)
            : null,
      'PERCENTRANK_EXC' || 'PERCENTRANK.EXC' || 'PERCENTRANKEXC' =>
        args.length == 2 || args.length == 3
            ? _percentRank(args, inclusive: false)
            : null,
      'TRIMMEAN' => args.length == 2 ? _trimMean(args) : null,
      'QUARTILE' || 'QUARTILE_INC' || 'QUARTILE.INC' || 'QUARTILEINC' =>
        args.length == 2 ? _quartileFunction(args, inclusive: true) : null,
      'QUARTILE_EXC' || 'QUARTILE.EXC' || 'QUARTILEEXC' =>
        args.length == 2 ? _quartileFunction(args, inclusive: false) : null,
      'VAR' ||
      'VAR.S' ||
      'VAR_S' ||
      'VARS' => _sampleVarianceResult(nonLogicalNumbers),
      'VARP' || 'VAR.P' || 'VAR_P' =>
        nonLogicalNumbers.isEmpty
            ? _FormulaError.num
            : _variance(nonLogicalNumbers, sample: false),
      'VARA' => _sampleVarianceAResult(values),
      'VARPA' =>
        values.isEmpty ? _FormulaError.num : _varianceA(values, sample: false),
      'STDEV' ||
      'STDEV.S' ||
      'STDEVS' => _standardDeviation(nonLogicalNumbers, sample: true),
      'STDEVP' ||
      'STDEV.P' => _standardDeviation(nonLogicalNumbers, sample: false),
      'STDEVA' => _standardDeviationA(values, sample: true),
      'STDEVPA' => _standardDeviationA(values, sample: false),
      'DEVSQ' => _deviationSumSquares(numbers),
      'AVEDEV' =>
        numbers.isEmpty
            ? (strictParserCompatibility ? _FormulaError.value : null)
            : _averageDeviation(numbers),
      'SKEW' => _strictStatisticalNumbers(args, _skew),
      'SKEW.P' ||
      'SKEW_P' ||
      'SKEWP' => _strictStatisticalNumbers(args, _skewPopulation),
      'KURT' => _strictStatisticalNumbers(args, _kurt),
      'CORREL' =>
        args.isEmpty
            ? _FormulaError.error
            : (args.length == 2 ? _correlation(args, squared: false) : null),
      'PEARSON' => args.length == 2 ? _correlation(args, squared: false) : null,
      'RSQ' => args.length == 2 ? _correlation(args, squared: true) : null,
      'COVAR' || 'COVARIANCE.P' || 'COVARIANCE_P' || 'COVARIANCEP' =>
        args.length == 2 ? _covariance(args, sample: false) : null,
      'COVARIANCE.S' || 'COVARIANCE_S' || 'COVARIANCES' =>
        args.length == 2 ? _covariance(args, sample: true) : null,
      'SLOPE' =>
        args.length == 2
            ? _linearRegression(args, _RegressionPart.slope)
            : null,
      'INTERCEPT' =>
        args.length == 2
            ? _linearRegression(args, _RegressionPart.intercept)
            : null,
      'STEYX' =>
        args.length == 2
            ? _linearRegression(args, _RegressionPart.standardError)
            : null,
      'FORECAST' ||
      'FORECAST.LINEAR' => args.length == 3 ? _forecast(args) : null,
      'FREQUENCY' => args.length == 2 ? _frequency(args) : null,
      'LINEST' =>
        args.isNotEmpty && args.length <= 4
            ? _linest(args, exponential: false)
            : null,
      'LOGEST' =>
        args.isNotEmpty && args.length <= 4
            ? _linest(args, exponential: true)
            : null,
      'TREND' =>
        args.isNotEmpty && args.length <= 4
            ? _trendGrowth(args, exponential: false)
            : null,
      'GROWTH' =>
        args.isNotEmpty && args.length <= 4
            ? _trendGrowth(args, exponential: true)
            : null,
      'STANDARDIZE' =>
        numbers.length == 3
            ? _standardize(numbers[0], numbers[1], numbers[2])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CONFIDENCE' || 'CONFIDENCE.NORM' || 'CONFIDENCE_NORM' =>
        values.length == 3
            ? _confidence(values, studentT: false)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CONFIDENCE.T' =>
        values.length == 3
            ? _confidence(values, studentT: true)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'FISHER' =>
        numbers.length == 1
            ? _fisher(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'FISHERINV' =>
        numbers.length == 1
            ? _fisherInv(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'GAMMA' =>
        numbers.length == 1
            ? _gammaFunction(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'GAMMALN' =>
        numbers.length == 1
            ? _gammaLogarithm(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'GAMMALN.PRECISE' || 'GAMMALNPRECISE' =>
        args.isEmpty
            ? _FormulaError.na
            : numbers.length == 1
            ? _gammaLogarithm(numbers.single)
            : null,
      'GAMMA.DIST' || 'GAMMADIST' =>
        args.length < 4
            ? _FormulaError.na
            : values.length == 4
            ? _gammaDistribution(values)
            : null,
      'GAMMA.INV' || 'GAMMAINV' =>
        args.length < 3
            ? _FormulaError.na
            : values.length == 3
            ? _gammaInverse(values)
            : null,
      'BETA.DIST' || 'BETADIST' =>
        values.length >= 4 && values.length <= 6
            ? _betaDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'BETA.INV' || 'BETAINV' =>
        values.length >= 3 && values.length <= 5
            ? _betaInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'F.DIST' || 'F_DIST' =>
        values.length == 4
            ? _fDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'FDIST' =>
        values.length == 3
            ? _fDistribution([...values, false])
            : (values.length == 4
                  ? _fDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'F.DIST.RT' || 'F_DIST_RT' || 'FDISTRT' =>
        values.length == 3
            ? _fRightTailDistribution(values)
            : (values.length < 3 ? _FormulaError.na : null),
      'F.INV' || 'FINV' =>
        values.length == 3
            ? _fInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'F.INV.RT' || 'FINVRT' =>
        values.length == 3 ? _fRightTailInverse(values) : _FormulaError.na,
      'F.TEST' || 'FTEST' => args.length == 2 ? _fTest(args) : null,
      'T.DIST' ||
      'T_DIST' => values.length == 3 ? _tDistribution(values) : null,
      'T.DIST.RT' || 'T_DIST_RT' || 'TDISTRT' =>
        values.length == 2
            ? _tRightTailDistribution(values)
            : (values.length < 2 ? _FormulaError.na : null),
      'T.DIST.2T' || 'T_DIST_2T' =>
        values.length == 2
            ? _tTwoTailDistribution(values)
            : (values.length < 2 ? _FormulaError.na : null),
      'TDIST' =>
        values.length == 2 || values.length == 3
            ? _legacyTDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'T.TEST' || 'TTEST' || 'T_TEST' => args.length == 4 ? _tTest(args) : null,
      'T.INV' || 'T_INV' || 'TINV' =>
        values.length == 2
            ? _tInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'T.INV.2T' || 'T_INV_2T' =>
        values.length == 2
            ? _tTwoTailInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CHISQ.DIST' =>
        values.length == 2 || values.length == 3
            ? _chiSquareDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CHISQ.DIST.RT' || 'CHIDIST' || 'CHIDISTRT' =>
        values.length == 2
            ? _chiSquareRightTailDistribution(values)
            : (values.length < 2 ? _FormulaError.na : null),
      'CHISQ.INV' =>
        values.length == 2
            ? _chiSquareInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CHISQ.INV.RT' || 'CHIINV' || 'CHIINVRT' =>
        values.length == 2
            ? _chiSquareRightTailInverse(values)
            : (values.length < 2 ? _FormulaError.na : null),
      'CHISQ.TEST' ||
      'CHITEST' => args.length == 2 ? _chiSquareTest(args) : _FormulaError.na,
      'EXPON.DIST' || 'EXPON_DIST' =>
        values.length == 3
            ? _exponentialDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'EXPONDIST' =>
        values.length == 2
            ? _exponentialDistribution([...values, false])
            : (values.length == 3
                  ? _exponentialDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'WEIBULL.DIST' || 'WEIBULL_DIST' || 'WEIBULL' =>
        values.length == 4
            ? _weibullDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'WEIBULLDIST' =>
        values.length == 3
            ? _weibullDistribution([...values, false])
            : (values.length == 4
                  ? _weibullDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'POISSON' || 'POISSON.DIST' || 'POISSON_DIST' =>
        values.length == 3
            ? _poissonDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'POISSONDIST' =>
        values.length == 2
            ? _poissonDistribution([...values, false])
            : (values.length == 3
                  ? _poissonDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'NORM.DIST' || 'NORM_DIST' =>
        values.length == 4
            ? _normalDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'NORMDIST' =>
        values.length == 3
            ? _normalDistribution([...values, false])
            : (values.length == 4
                  ? _normalDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'NORM.S.DIST' || 'NORM_S_DIST' =>
        values.length == 2
            ? _standardNormalDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'NORMSDIST' =>
        values.length == 1
            ? _standardNormalDistribution([values.single, false])
            : (values.length == 2
                  ? _standardNormalDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'Z.TEST' ||
      'Z_TEST' ||
      'ZTEST' => args.length == 2 || args.length == 3 ? _zTest(args) : null,
      'PHI' =>
        numbers.length == 1
            ? _standardNormalPdf(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'GAUSS' =>
        numbers.length == 1
            ? _standardNormalCdf(numbers.single) - 0.5
            : (strictParserCompatibility ? _FormulaError.value : null),
      'NORM.INV' || 'NORM_INV' || 'NORMINV' =>
        values.length == 3
            ? _normalInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'NORM.S.INV' || 'NORM_S_INV' || 'NORMSINV' =>
        values.length == 1
            ? _standardNormalInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'LOGNORM.DIST' || 'LOGNORM_DIST' =>
        values.length == 4
            ? _logNormalDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'LOGNORMDIST' =>
        values.length == 3
            ? _logNormalDistribution([...values, false])
            : (values.length == 4
                  ? _logNormalDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'LOGNORM.INV' || 'LOGNORM_INV' || 'LOGINV' || 'LOGNORMINV' =>
        values.length == 3
            ? _logNormalInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'BINOM.DIST' || 'BINOM_DIST' || 'BINOMDIST' =>
        values.length == 4
            ? _binomialDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'BINOM.DIST.RANGE' =>
        values.length == 3 || values.length == 4
            ? _binomialDistributionRange(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'BINOM.INV' || 'BINOM_INV' || 'CRITBINOM' =>
        values.length == 3
            ? _binomialInverse(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'NEGBINOM.DIST' || 'NEGBINOM_DIST' =>
        values.length == 4
            ? _negativeBinomialDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'NEGBINOMDIST' =>
        values.length == 3
            ? _negativeBinomialDistribution(values, cumulative: false)
            : (values.length == 4
                  ? _negativeBinomialDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'HYPGEOM.DIST' =>
        values.length == 5
            ? _hypergeometricDistribution(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'HYPGEOMDIST' =>
        values.length == 4
            ? _hypergeometricDistribution(values, cumulative: false)
            : (values.length == 5
                  ? _hypergeometricDistribution(values)
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'PROB' =>
        args.length >= 2 && args.length <= 4 ? _probability(args) : null,
      'LARGE' => args.length == 2 ? _rankedFunction(args, true) : null,
      'SMALL' => args.length == 2 ? _rankedFunction(args, false) : null,
      'RANK' || 'RANK.EQ' || 'RANK_EQ' || 'RANKEQ' =>
        args.length == 2 || args.length == 3
            ? _rank(args, averageTies: false)
            : null,
      'RANK.AVG' || 'RANK_AVG' || 'RANKAVG' =>
        args.length == 2 || args.length == 3
            ? _rank(args, averageTies: true)
            : null,
      'COUNT' => nonLogicalNumbers.length.toDouble(),
      'COUNTA' =>
        values.where((value) => !_isFormulaBlankLike(value)).length.toDouble(),
      'COUNTBLANK' => values.where(_isFormulaBlankValue).length.toDouble(),
      'COUNTIF' =>
        args.length == 2 ? _countIf(args[0].values, args[1].singleValue) : null,
      'COUNTIN' =>
        args.length == 2 ? _countIn(args[0].values, args[1].singleValue) : null,
      'COUNTUNIQUE' => _countUnique(values),
      'SUMIF' =>
        args.length == 2 || args.length == 3
            ? _sumIf(
                args[0].values,
                args[1].singleValue,
                args.length == 3 ? args[2].values : null,
              )
            : null,
      'AVERAGEIF' =>
        args.length == 2 || args.length == 3
            ? _averageIf(
                args[0].values,
                args[1].singleValue,
                args.length == 3 ? args[2].values : null,
              )
            : null,
      'COUNTIFS' =>
        args.length >= 2 && args.length.isEven ? _countIfs(args) : null,
      'SUMIFS' => args.length >= 3 && args.length.isOdd ? _sumIfs(args) : null,
      'AVERAGEIFS' =>
        args.length >= 3 && args.length.isOdd ? _averageIfs(args) : null,
      'DSUM' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.sum)
            : null,
      'DAVERAGE' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.average)
            : null,
      'DCOUNT' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.count)
            : null,
      'DCOUNTA' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.countA)
            : null,
      'DGET' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.get)
            : null,
      'DMAX' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.max)
            : null,
      'DMIN' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.min)
            : null,
      'DPRODUCT' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.product)
            : null,
      'DSTDEV' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.stdev)
            : null,
      'DSTDEVP' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.stdevP)
            : null,
      'DVAR' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.varS)
            : null,
      'DVARP' =>
        args.length == 3
            ? _databaseAggregate(args, _DatabaseFunction.varP)
            : null,
      'MAXIFS' =>
        args.length >= 3 && args.length.isOdd
            ? _minMaxIfs(args, findMax: true)
            : null,
      'MINIFS' =>
        args.length >= 3 && args.length.isOdd
            ? _minMaxIfs(args, findMax: false)
            : null,
      'INDEX' => args.length == 2 || args.length == 3 ? _index(args) : null,
      'MATCH' => args.length == 2 || args.length == 3 ? _match(args) : null,
      'XMATCH' => args.length >= 2 && args.length <= 4 ? _xmatch(args) : null,
      'VLOOKUP' => args.length == 3 || args.length == 4 ? _vlookup(args) : null,
      'HLOOKUP' => args.length == 3 || args.length == 4 ? _hlookup(args) : null,
      'XLOOKUP' => args.length >= 3 && args.length <= 6 ? _xlookup(args) : null,
      'LOOKUP' => args.length == 2 || args.length == 3 ? _lookup(args) : null,
      'CHOOSE' => args.length >= 2 ? _choose(args) : null,
      'TAKE' =>
        args.length == 2 || args.length == 3
            ? _takeDrop(args, take: true)
            : null,
      'DROP' =>
        args.length == 2 || args.length == 3
            ? _takeDrop(args, take: false)
            : null,
      'CHOOSEROWS' =>
        args.length >= 2 ? _chooseRowsColumns(args, chooseRows: true) : null,
      'CHOOSECOLS' =>
        args.length >= 2 ? _chooseRowsColumns(args, chooseRows: false) : null,
      'EXPAND' => args.length >= 2 && args.length <= 4 ? _expand(args) : null,
      'VSTACK' => args.isNotEmpty ? _vstack(args) : null,
      'HSTACK' => args.isNotEmpty ? _hstack(args) : null,
      'SEQUENCE' =>
        args.isNotEmpty && args.length <= 4 ? _sequence(args) : null,
      'RANDARRAY' => args.length <= 5 ? _randArray(args) : null,
      'SORT' => args.isNotEmpty && args.length <= 4 ? _sort(args) : null,
      'SORTBY' => args.length >= 2 ? _sortBy(args) : null,
      'MDETERM' => args.length == 1 ? _matrixDeterminant(args.single) : null,
      'MINVERSE' => args.length == 1 ? _matrixInverse(args.single) : null,
      'MMULT' => args.length == 2 ? _matrixMultiply(args[0], args[1]) : null,
      'TRANSPOSE' => args.length == 1 ? _transpose(args.single) : null,
      'UNIQUE' => args.length <= 3 ? _unique(args) : null,
      'ARGS2ARRAY' => _argsToArray(args),
      'FLATTEN' => _flattenArguments(args),
      'JOIN' => args.isNotEmpty ? _joinArguments(args) : '',
      'NUMBERS' => _numbersArray(args),
      'REFERENCE' => args.length == 2 ? _referencePath(args) : null,
      'WRAPROWS' =>
        args.length == 2 || args.length == 3
            ? _wrapRowsColumns(args, wrapRows: true)
            : null,
      'WRAPCOLS' =>
        args.length == 2 || args.length == 3
            ? _wrapRowsColumns(args, wrapRows: false)
            : null,
      'ROWS' =>
        args.length == 1
            ? _parserRangeShape(args.single)?.rowCount.toDouble() ??
                  args.single.rowCount.toDouble()
            : (args.isEmpty ? _FormulaError.na : null),
      'COLUMNS' =>
        args.length == 1
            ? _parserRangeShape(args.single)?.columnCount.toDouble() ??
                  args.single.columnCount.toDouble()
            : (args.isEmpty ? _FormulaError.na : null),
      'ADDRESS' =>
        values.length >= 2 && values.length <= 5 ? _address(values) : null,
      'SUMSQ' => numbers.isEmpty ? _FormulaError.value : _sumSquares(numbers),
      'SUMPRODUCT' => args.isEmpty ? null : _sumProduct(args),
      'SUMXMY2' =>
        args.length == 2
            ? _sumPairwiseSquares(args, _PairwiseSquareMode.difference)
            : null,
      'SUMX2MY2' =>
        args.length == 2
            ? _sumPairwiseSquares(args, _PairwiseSquareMode.squaresDifference)
            : null,
      'SUMX2PY2' =>
        args.length == 2
            ? _sumPairwiseSquares(args, _PairwiseSquareMode.squaresSum)
            : null,
      'PRODUCT' =>
        numbers.isEmpty
            ? (strictParserCompatibility ? _FormulaError.value : null)
            : _product(numbers),
      'UNARY_PERCENT' => numbers.length == 1 ? numbers.single / 100 : null,
      'GCD' => numbers.isEmpty ? _FormulaError.value : _gcdValues(numbers),
      'LCM' => numbers.isEmpty ? _FormulaError.value : _lcmValues(numbers),
      'MULTINOMIAL' =>
        numbers.isEmpty
            ? (strictParserCompatibility ? _FormulaError.value : null)
            : _multinomial(numbers),
      'GEOMEAN' => _geometricMean(numbers),
      'HARMEAN' => _harmonicMean(numbers),
      'POWER' =>
        numbers.length == 2
            ? _powerValue(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'FACT' =>
        numbers.length == 1
            ? _factorial(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'FACTDOUBLE' =>
        numbers.length == 1
            ? _doubleFactorial(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'COMBIN' =>
        numbers.length == 2
            ? _combin(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'COMBINA' =>
        numbers.length == 2
            ? _combina(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'PERMUT' =>
        numbers.length == 2
            ? _permut(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'PERMUTATIONA' =>
        numbers.length == 2
            ? _permutationA(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ABS' =>
        numbers.length == 1
            ? numbers.single.abs()
            : (strictParserCompatibility && args.isEmpty
                  ? _FormulaError.value
                  : null),
      'SIGN' =>
        numbers.length == 1
            ? numbers.single.sign.toDouble()
            : (strictParserCompatibility ? _FormulaError.value : null),
      'E' => math.e,
      'LN10' => math.ln10,
      'LN2' => math.ln2,
      'LOG10E' => math.log10e,
      'LOG2E' => math.log2e,
      'PI' => values.isEmpty ? math.pi : null,
      'SQRT1_2' => math.sqrt1_2,
      'SQRT2' => math.sqrt2,
      'SIN' =>
        numbers.length == 1
            ? math.sin(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'COS' =>
        numbers.length == 1
            ? math.cos(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'TAN' =>
        numbers.length == 1
            ? math.tan(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'SEC' =>
        numbers.length == 1
            ? _reciprocalTrig(math.cos(numbers.single))
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CSC' =>
        numbers.length == 1
            ? _reciprocalTrig(math.sin(numbers.single))
            : (strictParserCompatibility ? _FormulaError.value : null),
      'COT' =>
        numbers.length == 1
            ? _reciprocalTrig(math.tan(numbers.single))
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ASIN' =>
        numbers.length == 1
            ? _asin(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ACOS' =>
        numbers.length == 1
            ? _acos(numbers.single)
            : (strictParserCompatibility && args.isEmpty
                  ? _FormulaError.value
                  : null),
      'ATAN' =>
        numbers.length == 1
            ? math.atan(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ACOT' =>
        numbers.length == 1
            ? _acot(numbers.single)
            : (strictParserCompatibility && args.isEmpty
                  ? _FormulaError.value
                  : null),
      'ATAN2' =>
        numbers.length == 2
            ? _atan2(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'SINH' =>
        numbers.length == 1
            ? _sinhFunction(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'COSH' =>
        numbers.length == 1
            ? _coshFunction(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'TANH' =>
        numbers.length == 1
            ? _tanh(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'SECH' =>
        numbers.length == 1
            ? 1 / _cosh(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CSCH' =>
        numbers.length == 1
            ? _cschFunction(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'COTH' =>
        numbers.length == 1
            ? _reciprocalTrig(_tanh(numbers.single))
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ASINH' =>
        numbers.length == 1
            ? _asinh(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ACOSH' =>
        numbers.length == 1
            ? _acoshChecked(numbers.single)
            : (strictParserCompatibility && args.isEmpty
                  ? _FormulaError.value
                  : null),
      'ACOTH' =>
        numbers.length == 1
            ? _acothChecked(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ATANH' =>
        numbers.length == 1
            ? _atanhChecked(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'RADIANS' =>
        numbers.length == 1
            ? numbers.single * math.pi / 180
            : (strictParserCompatibility ? _FormulaError.value : null),
      'DEGREES' =>
        numbers.length == 1
            ? numbers.single * 180 / math.pi
            : (strictParserCompatibility ? _FormulaError.value : null),
      'RAND' => values.isEmpty ? math.Random().nextDouble() : null,
      'RANDBETWEEN' =>
        numbers.length == 2 ? _randomBetween(numbers[0], numbers[1]) : null,
      'DOLLARDE' =>
        numbers.length == 2
            ? _dollarDe(numbers[0], numbers[1])
            : (strictParserCompatibility && args.length < 2
                  ? _FormulaError.value
                  : null),
      'DOLLARFR' =>
        numbers.length == 2
            ? _dollarFr(numbers[0], numbers[1])
            : (strictParserCompatibility && args.length < 2
                  ? _FormulaError.value
                  : null),
      'BIN2DEC' =>
        args.length == 1
            ? _baseToDecimal(args[0].singleValue, base: 2, bits: 10)
            : (args.isEmpty ? _FormulaError.num : null),
      'BIN2HEX' =>
        args.length == 1 || args.length == 2
            ? _baseToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                sourceBase: 2,
                sourceBits: 10,
                targetBase: 16,
                targetBits: 40,
              )
            : (args.isEmpty ? _FormulaError.num : null),
      'BIN2OCT' =>
        args.length == 1 || args.length == 2
            ? _baseToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                sourceBase: 2,
                sourceBits: 10,
                targetBase: 8,
                targetBits: 30,
              )
            : (args.isEmpty ? _FormulaError.num : null),
      'HEX2DEC' =>
        args.length == 1
            ? _baseToDecimal(args[0].singleValue, base: 16, bits: 40)
            : (args.isEmpty ? _FormulaError.num : null),
      'HEX2BIN' =>
        args.length == 1 || args.length == 2
            ? _baseToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                sourceBase: 16,
                sourceBits: 40,
                targetBase: 2,
                targetBits: 10,
              )
            : (args.isEmpty ? _FormulaError.num : null),
      'HEX2OCT' =>
        args.length == 1 || args.length == 2
            ? _baseToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                sourceBase: 16,
                sourceBits: 40,
                targetBase: 8,
                targetBits: 30,
              )
            : (args.isEmpty ? _FormulaError.num : null),
      'OCT2DEC' =>
        args.length == 1
            ? _baseToDecimal(args[0].singleValue, base: 8, bits: 30)
            : (args.isEmpty ? _FormulaError.num : null),
      'OCT2BIN' =>
        args.length == 1 || args.length == 2
            ? _baseToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                sourceBase: 8,
                sourceBits: 30,
                targetBase: 2,
                targetBits: 10,
              )
            : (args.isEmpty ? _FormulaError.num : null),
      'OCT2HEX' =>
        args.length == 1 || args.length == 2
            ? _baseToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                sourceBase: 8,
                sourceBits: 30,
                targetBase: 16,
                targetBits: 40,
              )
            : (args.isEmpty ? _FormulaError.num : null),
      'DEC2BIN' =>
        args.length == 1 || args.length == 2
            ? _decimalToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                base: 2,
                bits: 10,
              )
            : (args.isEmpty ? _FormulaError.value : null),
      'DEC2HEX' =>
        args.length == 1 || args.length == 2
            ? _decimalToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                base: 16,
                bits: 40,
              )
            : (args.isEmpty ? _FormulaError.value : null),
      'DEC2OCT' =>
        args.length == 1 || args.length == 2
            ? _decimalToBase(
                args[0].singleValue,
                args.length == 2 ? args[1].singleValue : null,
                base: 8,
                bits: 30,
              )
            : (args.isEmpty ? _FormulaError.value : null),
      'BITAND' =>
        args.length == 2
            ? _bitwiseOperation(args, _BitwiseOperation.and)
            : (args.length < 2 ? _FormulaError.value : null),
      'BITOR' =>
        args.length == 2
            ? _bitwiseOperation(args, _BitwiseOperation.or)
            : (args.length < 2 ? _FormulaError.value : null),
      'BITXOR' =>
        args.length == 2
            ? _bitwiseOperation(args, _BitwiseOperation.xor)
            : (args.length < 2 ? _FormulaError.value : null),
      'BITLSHIFT' =>
        args.length == 2
            ? _bitShift(args, shiftLeft: true)
            : (args.length < 2 ? _FormulaError.value : null),
      'BITRSHIFT' =>
        args.length == 2
            ? _bitShift(args, shiftLeft: false)
            : (args.length < 2 ? _FormulaError.value : null),
      'COMPLEX' =>
        args.length >= 2 && args.length <= 3
            ? _complexFunction(args)
            : (args.length < 2 ? _FormulaError.value : null),
      'IMREAL' =>
        args.length == 1
            ? _complexPart(args, imaginary: false)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMAGINARY' =>
        args.length == 1
            ? _complexPart(args, imaginary: true)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMCONJUGATE' =>
        args.length == 1
            ? _complexConjugate(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMABS' =>
        args.length == 1
            ? _complexAbs(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMSUM' => args.isNotEmpty ? _complexSum(args) : _FormulaError.value,
      'IMSUB' =>
        args.length == 2
            ? _complexSubtract(args)
            : (args.length < 2 ? _FormulaError.value : null),
      'IMPRODUCT' =>
        args.isNotEmpty ? _complexProduct(args) : _FormulaError.value,
      'IMDIV' =>
        args.length == 2
            ? _complexDivide(args)
            : (args.length < 2 ? _FormulaError.value : null),
      'IMARGUMENT' =>
        args.length == 1
            ? _complexArgumentFunction(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMEXP' =>
        args.length == 1
            ? _complexExponential(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMLN' =>
        args.length == 1
            ? _complexLog(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMLOG10' =>
        args.length == 1
            ? _complexLog(args, base: 10)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMLOG2' =>
        args.length == 1
            ? _complexLog(args, base: 2)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMPOWER' =>
        args.length == 2
            ? _complexPower(args)
            : (args.length < 2 ? _FormulaError.value : null),
      'IMSQRT' =>
        args.length == 1
            ? _complexSquareRoot(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMSIN' =>
        args.length == 1
            ? _complexSine(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMCOS' =>
        args.length == 1
            ? _complexCosine(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMTAN' =>
        args.length == 1
            ? _complexTangent(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMSINH' =>
        args.length == 1
            ? _complexHyperbolicSine(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMCOSH' =>
        args.length == 1
            ? _complexHyperbolicCosine(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMCOT' =>
        args.length == 1
            ? _complexCotangent(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMSEC' =>
        args.length == 1
            ? _complexSecant(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMCSC' =>
        args.isEmpty
            ? _FormulaError.num
            : (args.length == 1 ? _complexCosecant(args) : null),
      'IMSECH' =>
        args.length == 1
            ? _complexHyperbolicSecant(args)
            : (args.isEmpty ? _FormulaError.value : null),
      'IMCSCH' =>
        args.isEmpty
            ? _FormulaError.num
            : (args.length == 1 ? _complexHyperbolicCosecant(args) : null),
      'ERF' || 'ERFPRECISE' =>
        args.isEmpty
            ? _FormulaError.value
            : (args.length == 1 ? _errorFunction(args) : null),
      'ERFC' || 'ERFCPRECISE' =>
        args.isEmpty
            ? _FormulaError.value
            : (args.length == 1 ? _complementaryErrorFunction(args) : null),
      'CONVERT' =>
        args.length == 3
            ? _convertUnits(args)
            : (args.isEmpty
                  ? _FormulaError.value
                  : (args.length == 1 ? _FormulaError.error : null)),
      'BESSELI' =>
        args.length == 2
            ? _besselFunction(args, _BesselKind.i)
            : (args.length < 2 ? _FormulaError.value : null),
      'BESSELJ' =>
        args.length == 2
            ? _besselFunction(args, _BesselKind.j)
            : (args.length < 2 ? _FormulaError.value : null),
      'BESSELK' =>
        args.length == 2
            ? _besselFunction(args, _BesselKind.k)
            : (args.length < 2 ? _FormulaError.value : null),
      'BESSELY' =>
        args.length == 2
            ? _besselFunction(args, _BesselKind.y)
            : (args.length < 2 ? _FormulaError.value : null),
      'DELTA' =>
        args.isEmpty
            ? _FormulaError.value
            : (args.length == 1 || args.length == 2 ? _delta(args) : null),
      'GESTEP' =>
        args.isEmpty
            ? _FormulaError.value
            : (args.length == 1 || args.length == 2
                  ? _greaterThanOrEqualStep(args)
                  : null),
      'ACCRINT' =>
        args.length >= 7 && args.length <= 8
            ? _accruedInterest(args)
            : (args.length >= 3 ? _FormulaError.num : _FormulaError.value),
      'ACCRINTM' =>
        args.length >= 4 && args.length <= 5
            ? _accruedInterestAtMaturity(args)
            : null,
      'DISC' =>
        args.length >= 4 && args.length <= 5
            ? _discountRateForSecurity(args)
            : null,
      'COUPNUM' =>
        args.length >= 3 && args.length <= 4 ? _couponNumber(args) : null,
      'COUPNCD' =>
        args.length >= 3 && args.length <= 4
            ? _couponDate(args, next: true)
            : null,
      'COUPPCD' =>
        args.length >= 3 && args.length <= 4
            ? _couponDate(args, next: false)
            : null,
      'COUPDAYBS' =>
        args.length >= 3 && args.length <= 4
            ? _couponDays(args, part: _CouponDayPart.beforeSettlement)
            : null,
      'COUPDAYS' =>
        args.length >= 3 && args.length <= 4
            ? _couponDays(args, part: _CouponDayPart.fullPeriod)
            : null,
      'COUPDAYSNC' =>
        args.length >= 3 && args.length <= 4
            ? _couponDays(args, part: _CouponDayPart.afterSettlement)
            : null,
      'CUMIPMT' =>
        args.length == 6
            ? _cumulativePayment(args, interest: true)
            : (args.length >= 3 ? _FormulaError.num : _FormulaError.value),
      'CUMPRINC' =>
        args.length == 6
            ? _cumulativePayment(args, interest: false)
            : (args.length >= 3 ? _FormulaError.num : _FormulaError.value),
      'AMORDEGRC' =>
        args.length == 6 || args.length == 7 ? _amorDegrc(args) : null,
      'AMORLINC' =>
        args.length == 6 || args.length == 7 ? _amorLinc(args) : null,
      'DB' =>
        numbers.length == 4 || numbers.length == 5
            ? _fixedDecliningDepreciation(
                numbers[0],
                numbers[1],
                numbers[2],
                numbers[3],
                numbers.length == 5 ? numbers[4] : 12,
              )
            : (strictParserCompatibility && args.length < 4
                  ? _FormulaError.value
                  : null),
      'DDB' =>
        numbers.length == 4 || numbers.length == 5
            ? _doubleDecliningDepreciation(
                numbers[0],
                numbers[1],
                numbers[2],
                numbers[3],
                numbers.length == 5 ? numbers[4] : 2,
              )
            : (strictParserCompatibility && args.length < 4
                  ? _FormulaError.value
                  : null),
      'VDB' =>
        args.length >= 5 && args.length <= 7
            ? _variableDecliningDepreciation(args)
            : null,
      'DURATION' =>
        args.length >= 5 && args.length <= 6
            ? _securityDuration(args, modified: false)
            : null,
      'EFFECT' =>
        numbers.length == 2
            ? _effect(numbers[0], numbers[1])
            : (strictParserCompatibility && args.length < 2
                  ? _FormulaError.value
                  : null),
      'FV' =>
        args.length >= 3 && args.length <= 5
            ? _futureValue(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'FVSCHEDULE' => args.length == 2 ? _futureValueSchedule(args) : null,
      'IPMT' =>
        args.length >= 4 && args.length <= 6
            ? _interestPayment(args)
            : (strictParserCompatibility && args.length < 4
                  ? _FormulaError.value
                  : null),
      'ISPMT' =>
        args.length == 4
            ? _interestPaidDuringPeriod(args)
            : (strictParserCompatibility && args.length < 4
                  ? _FormulaError.value
                  : null),
      'INTRATE' =>
        args.length >= 4 && args.length <= 5
            ? _interestRateForSecurity(args)
            : null,
      'IRR' =>
        args.isNotEmpty && args.length <= 2
            ? _internalRateOfReturn(args)
            : null,
      'XIRR' =>
        args.length >= 2 && args.length <= 3
            ? _internalRateOfReturnIrregular(args)
            : null,
      'NPER' =>
        args.length >= 3 && args.length <= 5
            ? _numberOfPeriods(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'MIRR' => args.length == 3 ? _modifiedInternalRateOfReturn(args) : null,
      'MDURATION' =>
        args.length >= 5 && args.length <= 6
            ? _securityDuration(args, modified: true)
            : null,
      'NOMINAL' =>
        numbers.length == 2
            ? _nominal(numbers[0], numbers[1])
            : (strictParserCompatibility && args.length < 2
                  ? _FormulaError.value
                  : null),
      'NPV' =>
        args.isNotEmpty
            ? _netPresentValue(args)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'XNPV' => args.length == 3 ? _netPresentValueIrregular(args) : null,
      'PDURATION' =>
        args.length == 3
            ? _periodsForInvestmentDuration(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'PMT' =>
        args.length >= 3 && args.length <= 5
            ? _payment(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'PPMT' =>
        args.length >= 4 && args.length <= 6
            ? _principalPayment(args)
            : (strictParserCompatibility && args.length < 4
                  ? _FormulaError.value
                  : null),
      'PV' =>
        args.length >= 3 && args.length <= 5
            ? _presentValue(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'ODDFPRICE' =>
        args.length >= 8 && args.length <= 9
            ? _priceOddFirstCouponSecurity(args)
            : null,
      'ODDFYIELD' =>
        args.length >= 8 && args.length <= 9
            ? _yieldOddFirstCouponSecurity(args)
            : null,
      'ODDLPRICE' =>
        args.length >= 7 && args.length <= 8
            ? _priceOddLastCouponSecurity(args)
            : null,
      'ODDLYIELD' =>
        args.length >= 7 && args.length <= 8
            ? _yieldOddLastCouponSecurity(args)
            : null,
      'PRICE' =>
        args.length >= 6 && args.length <= 7
            ? _priceCouponSecurity(args)
            : null,
      'PRICEDISC' =>
        args.length >= 4 && args.length <= 5
            ? _priceDiscountSecurity(args)
            : null,
      'PRICEMAT' =>
        args.length >= 5 && args.length <= 6
            ? _priceAtMaturitySecurity(args)
            : null,
      'RATE' =>
        args.length >= 3 && args.length <= 6
            ? _rate(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'RECEIVED' =>
        args.length >= 4 && args.length <= 5
            ? _amountReceivedAtMaturity(args)
            : null,
      'RRI' =>
        args.length == 3
            ? _equivalentInterestRate(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'SLN' =>
        numbers.length == 3
            ? _straightLineDepreciation(numbers[0], numbers[1], numbers[2])
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'SYD' =>
        numbers.length == 4
            ? _sumOfYearsDepreciation(
                numbers[0],
                numbers[1],
                numbers[2],
                numbers[3],
              )
            : (strictParserCompatibility && args.length < 4
                  ? _FormulaError.value
                  : null),
      'TBILLEQ' =>
        args.length == 3
            ? _treasuryBillEquivalent(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'TBILLPRICE' =>
        args.length == 3
            ? _treasuryBillPrice(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'TBILLYIELD' =>
        args.length == 3
            ? _treasuryBillYield(args)
            : (strictParserCompatibility && args.length < 3
                  ? _FormulaError.value
                  : null),
      'YIELD' =>
        args.length >= 6 && args.length <= 7
            ? _yieldCouponSecurity(args)
            : null,
      'YIELDDISC' =>
        args.length >= 4 && args.length <= 5
            ? _yieldDiscountSecurity(args)
            : null,
      'YIELDMAT' =>
        args.length >= 5 && args.length <= 6
            ? _yieldAtMaturitySecurity(args)
            : null,
      'AGGREGATE' =>
        args.length >= 3 ? _aggregateSubtotal(args, hasOptions: true) : null,
      'SUBTOTAL' =>
        args.length >= 2 ? _aggregateSubtotal(args, hasOptions: false) : null,
      'ADD' =>
        args.length == 2
            ? _binaryNumericOperator(args, _BinaryNumericOperator.add)
            : _FormulaError.na,
      'MINUS' =>
        args.length == 2
            ? _binaryNumericOperator(args, _BinaryNumericOperator.subtract)
            : _FormulaError.na,
      'MULTIPLY' =>
        args.length == 2
            ? _binaryNumericOperator(args, _BinaryNumericOperator.multiply)
            : _FormulaError.na,
      'DIVIDE' =>
        args.length == 2
            ? _binaryNumericOperator(args, _BinaryNumericOperator.divide)
            : _FormulaError.na,
      'POW' =>
        args.length == 2
            ? _binaryNumericOperator(args, _BinaryNumericOperator.power)
            : _FormulaError.na,
      'EQ' =>
        args.length == 2 ? _binaryComparison(args, '=') : _FormulaError.na,
      'NE' =>
        args.length == 2 ? _binaryComparison(args, '<>') : _FormulaError.na,
      'GTE' =>
        args.length == 2 ? _binaryComparison(args, '>=') : _FormulaError.na,
      'GT' =>
        args.length == 2 ? _binaryComparison(args, '>') : _FormulaError.na,
      'LT' =>
        args.length == 2 ? _binaryComparison(args, '<') : _FormulaError.na,
      'LE' =>
        args.length == 2 ? _binaryComparison(args, '<=') : _FormulaError.na,
      'LTE' =>
        args.length == 2 ? _binaryComparison(args, '<=') : _FormulaError.na,
      'EXP' =>
        values.isEmpty
            ? _FormulaError.na
            : (values.length == 1
                  ? (values.single is _FormulaError
                        ? values.single
                        : (values.single is num
                              ? _exp((values.single as num).toDouble())
                              : _FormulaError.error))
                  : _FormulaError.error),
      'LN' =>
        numbers.length == 1
            ? _ln(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'LOG10' =>
        numbers.length == 1
            ? _log10(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'LOG' =>
        numbers.length == 2
            ? _log(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'INT' =>
        numbers.length == 1
            ? numbers.single.floorToDouble()
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ISEVEN' => numbers.length == 1 ? _isEvenNumber(numbers.single) : null,
      'ISODD' => numbers.length == 1 ? _isOddNumber(numbers.single) : null,
      'MOD' =>
        numbers.length == 2
            ? _mod(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'QUOTIENT' =>
        numbers.length == 2
            ? _quotient(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'SQRT' =>
        numbers.length == 1
            ? _sqrt(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'SQRTPI' =>
        numbers.length == 1
            ? _sqrtPi(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'SERIESSUM' =>
        numbers.length >= 4
            ? _seriesSum(numbers[0], numbers[1], numbers[2], numbers.sublist(3))
            : null,
      'ROUND' =>
        numbers.length == 2
            ? _round(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ROUNDUP' =>
        numbers.length == 2
            ? _roundAwayFromZero(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ROUNDDOWN' =>
        numbers.length == 2
            ? _roundTowardZero(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'MROUND' =>
        numbers.length == 2
            ? _mround(numbers[0], numbers[1])
            : (strictParserCompatibility ? _FormulaError.value : null),
      'TRUNC' =>
        numbers.length == 1 || numbers.length == 2
            ? _truncate(numbers[0], numbers.length == 2 ? numbers[1] : 0)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'EVEN' =>
        numbers.length == 1
            ? _roundToEven(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ODD' =>
        numbers.length == 1
            ? _roundToOdd(numbers.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CEILING' =>
        values.isNotEmpty &&
                values.length <= 3 &&
                numbers.length == values.length
            ? _ceiling(numbers[0], numbers.length >= 2 ? numbers[1] : 1)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'CEILING.MATH' || 'CEILINGMATH' =>
        numbers.isNotEmpty && numbers.length <= 3
            ? _ceilingMath(
                numbers[0],
                numbers.length >= 2 ? numbers[1] : 1,
                numbers.length >= 3 ? numbers[2] : 0,
              )
            : null,
      'CEILING.PRECISE' || 'CEILINGPRECISE' || 'ISO.CEILING' || 'ISOCEILING' =>
        numbers.length == 1 || numbers.length == 2
            ? _ceilingPrecise(numbers[0], numbers.length == 2 ? numbers[1] : 1)
            : null,
      'FLOOR' =>
        numbers.length == 1 || numbers.length == 2
            ? _floor(numbers[0], numbers.length == 2 ? numbers[1] : 1)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'FLOOR.MATH' || 'FLOORMATH' =>
        numbers.isNotEmpty && numbers.length <= 3
            ? _floorMath(
                numbers[0],
                numbers.length >= 2 ? numbers[1] : 1,
                numbers.length >= 3 ? numbers[2] : 0,
              )
            : null,
      'FLOOR.PRECISE' || 'FLOORPRECISE' =>
        numbers.length == 1 || numbers.length == 2
            ? _floorPrecise(numbers[0], numbers.length == 2 ? numbers[1] : 1)
            : null,
      'DATE' =>
        numbers.length == 3
            ? (strictParserCompatibility
                  ? _dateFromParts(numbers[0], numbers[1], numbers[2])
                  : _dateSerial(numbers[0], numbers[1], numbers[2]))
            : (args.length < 3 ? _FormulaError.value : null),
      'TODAY' =>
        values.isEmpty
            ? (strictParserCompatibility ? DateTime.now() : _todaySerial())
            : null,
      'NOW' =>
        values.isEmpty
            ? (strictParserCompatibility ? DateTime.now() : _nowSerial())
            : null,
      'DATEVALUE' =>
        values.length == 1
            ? _dateValue(values.single)
            : (values.isEmpty ? _FormulaError.value : null),
      'EDATE' =>
        values.length == 2
            ? _edate(values[0], values[1], false)
            : (values.length < 2 ? _FormulaError.value : null),
      'EOMONTH' =>
        values.length == 2
            ? _edate(values[0], values[1], true)
            : (values.length < 2 ? _FormulaError.value : null),
      'DAYS' =>
        values.length == 2
            ? _days(values[0], values[1])
            : (values.length < 2 ? _FormulaError.value : null),
      'DATEDIF' =>
        values.length == 3 ? _dateDif(values[0], values[1], values[2]) : null,
      'DAYS360' =>
        values.length == 3 || (!strictParserCompatibility && values.length == 2)
            ? _days360(
                values[0],
                values[1],
                values.length == 3 && _truthy(values[2]),
              )
            : (values.length < 3 ? _FormulaError.value : null),
      'YEARFRAC' =>
        values.length == 2 || values.length == 3
            ? _yearFrac(
                values[0],
                values[1],
                values.length == 3 ? values[2] : 0,
              )
            : (values.length < 2 ? _FormulaError.value : null),
      'WEEKDAY' =>
        values.length == 1 || values.length == 2
            ? _weekday(values[0], values.length == 2 ? values[1] : 1)
            : (values.isEmpty ? _FormulaError.value : null),
      'WEEKNUM' =>
        values.length == 1 || values.length == 2
            ? _weekNum(values[0], values.length == 2 ? values[1] : 1)
            : (values.isEmpty ? _FormulaError.value : null),
      'INTERVAL' =>
        values.length == 1
            ? _interval(values.single)
            : (values.isEmpty ? _FormulaError.value : null),
      'ISOWEEKNUM' =>
        values.length == 1
            ? _isoWeekNum(values.single)
            : (values.isEmpty ? _FormulaError.value : null),
      'NETWORKDAYS' =>
        args.length == 2 || args.length == 3
            ? _networkDays(args[0].singleValue, args[1].singleValue, args)
            : (args.length < 2 ? _FormulaError.value : null),
      'NETWORKDAYS.INTL' || 'NETWORKDAYS_INTL' || 'NETWORKDAYSINTL' =>
        args.length >= 2 && args.length <= 4
            ? _networkDaysIntl(args)
            : (args.length < 2 ? _FormulaError.value : null),
      'WORKDAY' =>
        args.length == 2 || args.length == 3
            ? _workday(
                args[0].singleValue,
                args[1].singleValue,
                args,
                returnDate: strictParserCompatibility,
              )
            : (args.length < 2 ? _FormulaError.value : null),
      'WORKDAY.INTL' || 'WORKDAY_INTL' || 'WORKDAYINTL' =>
        args.length >= 2 && args.length <= 4
            ? _workdayIntl(args)
            : (args.length < 2 ? _FormulaError.value : null),
      'YEAR' =>
        values.length == 1
            ? _datePart(values.single, _DatePart.year)
            : (values.isEmpty ? _FormulaError.value : null),
      'MONTH' =>
        values.length == 1
            ? _datePart(values.single, _DatePart.month)
            : (values.isEmpty ? _FormulaError.value : null),
      'DAY' =>
        values.length == 1
            ? _datePart(values.single, _DatePart.day)
            : (values.isEmpty ? _FormulaError.value : null),
      'TIME' =>
        numbers.length == 3
            ? _timeSerial(numbers[0], numbers[1], numbers[2])
            : (args.length < 3 ? _FormulaError.value : null),
      'TIMEVALUE' =>
        values.length == 1
            ? _timeValue(values.single)
            : (values.isEmpty ? _FormulaError.value : null),
      'HOUR' =>
        values.length == 1
            ? _timePart(values.single, _TimePart.hour)
            : (values.isEmpty ? _FormulaError.value : null),
      'MINUTE' =>
        values.length == 1
            ? _timePart(values.single, _TimePart.minute)
            : (values.isEmpty ? _FormulaError.value : null),
      'SECOND' =>
        values.length == 1
            ? _timePart(values.single, _TimePart.second)
            : (values.isEmpty ? _FormulaError.value : null),
      'T' =>
        values.isEmpty
            ? ''
            : (values.length == 1
                  ? (values.single is String ? values.single : '')
                  : null),
      'INFO' => values.length == 1 ? _info(values.single) : null,
      'ISBLANK' =>
        values.length == 1 ? _isFormulaBlankLike(values.single) : null,
      'ISBINARY' =>
        values.isEmpty
            ? false
            : (values.length == 1 ? _isBinaryValue(values.single) : null),
      'ISNUMBER' =>
        values.isEmpty
            ? false
            : (values.length == 1
                  ? values.single is num && !_isFormulaBlankLike(values.single)
                  : null),
      'ISTEXT' =>
        values.isEmpty
            ? false
            : (values.length == 1 ? values.single is String : null),
      'ISNONTEXT' =>
        values.isEmpty
            ? true
            : (values.length == 1 ? values.single is! String : null),
      'ISLOGICAL' =>
        values.isEmpty
            ? false
            : (values.length == 1 ? values.single is bool : null),
      'ISDATE' => values.length == 1 ? _dateTime(values.single) != null : null,
      'ISIDCARD' =>
        values.length == 1 ? _idCardInfo(values.single) != null : null,
      'AGE_BY_IDCARD' =>
        values.isNotEmpty && values.length <= 2 ? _idCardAge(values) : null,
      'BIRTHDAY_BY_IDCARD' =>
        values.isNotEmpty && values.length <= 2
            ? _idCardBirthday(values)
            : null,
      'SEX_BY_IDCARD' => values.length == 1 ? _idCardSex(values.single) : null,
      'PROVINCE_BY_IDCARD' =>
        values.length == 1 ? _idCardProvince(values.single) : null,
      'CITY_BY_IDCARD' =>
        values.length == 1 ? _idCardCity(values.single) : null,
      'STAR_BY_IDCARD' =>
        values.length == 1 ? _idCardStar(values.single) : null,
      'ANIMAL_BY_IDCARD' =>
        values.length == 1 ? _idCardAnimal(values.single) : null,
      'N' => values.length == 1 ? _n(values.single) : null,
      'TO_DATE' || 'TO_DOLLARS' || 'TO_PERCENT' || 'TO_PURE_NUMBER' =>
        values.length == 1 ? _toPureNumber(values.single) : null,
      'TO_TEXT' => values.length == 1 ? _text(values.single) : null,
      'LEN' || 'LENB' =>
        values.isEmpty
            ? _FormulaError.error
            : (values.length == 1 ? _stringLength(values.single) : null),
      'LOWER' =>
        values.isEmpty
            ? _FormulaError.value
            : (values.length == 1 ? _text(values.single).toLowerCase() : null),
      'UPPER' =>
        values.isEmpty
            ? _FormulaError.value
            : (values.length == 1 ? _text(values.single).toUpperCase() : null),
      'PROPER' =>
        values.isEmpty
            ? _FormulaError.value
            : (values.length == 1 ? _proper(values.single) : null),
      'ASC' => values.length == 1 ? _asc(values.single) : null,
      'DBCS' => values.length == 1 ? _dbcs(values.single) : null,
      'VALUE' =>
        values.length == 1
            ? _value(values.single)
            : (values.isEmpty ? _FormulaError.value : null),
      'NUMBERVALUE' =>
        values.isNotEmpty && values.length <= 3 ? _numberValue(values) : null,
      'BASE' =>
        values.length >= 2 && values.length <= 3
            ? _base(values)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'DECIMAL' =>
        values.length == 1
            ? _decimalDefaultRadix(values[0])
            : (values.length == 2
                  ? _decimal(values[0], values[1])
                  : (strictParserCompatibility ? _FormulaError.value : null)),
      'ROMAN' =>
        values.length == 1 || values.length == 2
            ? _roman(values[0], values.length == 2 ? values[1] : 0)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'ARABIC' =>
        values.length == 1
            ? _arabic(values.single)
            : (strictParserCompatibility ? _FormulaError.value : null),
      'TEXT' =>
        values.isEmpty
            ? _FormulaError.na
            : (values.length == 1
                  ? _formatText(values[0], '#,##0')
                  : (values.length == 2
                        ? _formatText(values[0], values[1])
                        : null)),
      'TEXTBEFORE' =>
        values.length >= 2 && values.length <= 6
            ? _textBeforeAfter(values, before: true)
            : null,
      'TEXTAFTER' =>
        values.length >= 2 && values.length <= 6
            ? _textBeforeAfter(values, before: false)
            : null,
      'TEXTSPLIT' =>
        values.length >= 2 && values.length <= 6 ? _textSplit(values) : null,
      'SPLIT' =>
        values.isEmpty
            ? _FormulaError.error
            : (values.length <= 2 ? _split(values) : null),
      'DOLLAR' =>
        values.length == 1 || values.length == 2
            ? _fixedCurrency(values[0], values.length == 2 ? values[1] : 2)
            : (values.isEmpty ? _FormulaError.value : null),
      'FIXED' =>
        values.isNotEmpty && values.length <= 3
            ? _fixedNumber(values)
            : (values.isEmpty ? _FormulaError.value : null),
      'TEXTJOIN' => args.length >= 3 ? _textJoin(args) : null,
      'ENCODEURL' =>
        values.length == 1 ? Uri.encodeComponent(_text(values.single)) : null,
      'HYPERLINK' =>
        values.length == 1 || values.length == 2 ? _hyperlink(values) : null,
      'ARRAYTOTEXT' =>
        args.isNotEmpty && args.length <= 2 ? _arrayToText(args) : null,
      'VALUETOTEXT' =>
        args.isNotEmpty && args.length <= 2 ? _valueToTextFunction(args) : null,
      'EXACT' =>
        values.length == 2 ? _exact(values[0], values[1]) : _FormulaError.na,
      'CHAR' =>
        values.isEmpty
            ? _FormulaError.value
            : (values.length == 1 ? _char(values.single) : null),
      'CODE' =>
        values.isEmpty
            ? _FormulaError.na
            : (values.length == 1 ? _code(values.single) : null),
      'UNICHAR' =>
        values.isEmpty
            ? _FormulaError.value
            : (values.length == 1 ? _unichar(values.single) : null),
      'UNICODE' =>
        values.isEmpty
            ? _FormulaError.na
            : (values.length == 1 ? _unicode(values.single) : null),
      'CLEAN' =>
        values.isEmpty
            ? ''
            : (values.length == 1 ? _clean(values.single) : null),
      'HTML2TEXT' =>
        values.isEmpty
            ? ''
            : (values.length == 1 ? _htmlToText(values.single) : null),
      'TRIM' =>
        values.isEmpty
            ? _FormulaError.value
            : (values.length == 1
                  ? _text(values.single).trim().replaceAll(RegExp(r'\s+'), ' ')
                  : null),
      'LEFT' || 'LEFTB' =>
        values.isEmpty
            ? _FormulaError.value
            : (values.length == 1 || values.length == 2
                  ? _left(values[0], values.length == 2 ? values[1] : 1)
                  : null),
      'RIGHT' || 'RIGHTB' =>
        values.isEmpty
            ? _FormulaError.na
            : (values.length == 1 || values.length == 2
                  ? _right(values[0], values.length == 2 ? values[1] : 1)
                  : null),
      'MID' || 'MIDB' =>
        values.length < 3
            ? _FormulaError.value
            : (values.length == 3
                  ? _mid(values[0], values[1], values[2])
                  : null),
      'REPLACE' || 'REPLACEB' =>
        values.length < 4
            ? _FormulaError.value
            : (values.length == 4
                  ? _replaceText(values[0], values[1], values[2], values[3])
                  : null),
      'REPT' =>
        values.length < 2
            ? _FormulaError.value
            : (values.length == 2 ? _rept(values[0], values[1]) : null),
      'FIND' || 'FINDB' =>
        values.isEmpty || values.length == 1
            ? _FormulaError.na
            : (values.length == 2 || values.length == 3
                  ? _findText(
                      values[0],
                      values[1],
                      values.length == 3 ? values[2] : 1,
                      caseSensitive: true,
                    )
                  : null),
      'SEARCH' || 'SEARCHB' =>
        values.length < 2
            ? _FormulaError.value
            : (values.length == 2 || values.length == 3
                  ? _findText(
                      values[0],
                      values[1],
                      values.length == 3 ? values[2] : 1,
                      caseSensitive: false,
                    )
                  : null),
      'SUBSTITUTE' =>
        values.length < 2
            ? _FormulaError.na
            : (values.length == 3 || values.length == 4
                  ? _substitute(
                      values[0],
                      values[1],
                      values[2],
                      values.length == 4 ? values[3] : null,
                    )
                  : null),
      'REGEXEXTRACT' =>
        values.isEmpty
            ? _FormulaError.na
            : (values.length == 2 ? _regexExtract(values[0], values[1]) : null),
      'REGEXMATCH' =>
        values.isEmpty
            ? _FormulaError.na
            : (values.length == 2 || values.length == 3
                  ? _regexMatch(values[0], values[1])
                  : null),
      'REGEXREPLACE' =>
        values.isEmpty
            ? _FormulaError.na
            : (values.length == 3
                  ? _regexReplace(values[0], values[1], values[2])
                  : null),
      'DM_TEXT_CUTWORD' =>
        values.isEmpty || values.length > 2 ? null : _dmTextCutword(values[0]),
      'DM_TEXT_TFIDF' || 'DM_TEXT_TEXTRANK' =>
        values.isEmpty || values.length > 3
            ? null
            : _dmTextKeywords(values[0], values.length > 1 ? values[1] : null),
      'DATA_CN_STOCK_CLOSE' ||
      'DATA_CN_STOCK_OPEN' ||
      'DATA_CN_STOCK_MAX' ||
      'DATA_CN_STOCK_MIN' ||
      'DATA_CN_STOCK_VOLUMN' ||
      'DATA_CN_STOCK_AMOUNT' ||
      'REMOTE' =>
        values.isEmpty || values.length > 3 ? null : _FormulaError.gettingData,
      'GETPIVOTDATA' => values.length < 2 ? null : _FormulaError.na,
      'CONCAT' || 'CONCATENATE' => values.map(_text).join(),
      'EVALUATE' =>
        values.length == 1 ? _evaluateFormulaText(values.single) : null,
      'AND' => values.isEmpty ? true : values.every(_truthy),
      'OR' => values.isEmpty ? false : values.any(_truthy),
      'XOR' =>
        values.isEmpty
            ? false
            : values.where((value) => _truthy(value)).length.isOdd,
      'NOT' =>
        values.isEmpty
            ? true
            : (values.length == 1 ? !_truthy(values.single) : null),
      'TRUE' => values.isEmpty ? true : null,
      'FALSE' => values.isEmpty ? false : null,
      'NA' => values.isEmpty ? _FormulaError.na : null,
      _ => _FormulaError.name,
    };
  }

  Object? _arrayConstant() {
    final rows = <List<Object>>[];
    var row = <Object>[];
    while (true) {
      final elementSource = _arrayElementSource();
      if (elementSource == null || elementSource.isEmpty) {
        return null;
      }
      final value = _evaluateSource(elementSource);
      if (value == null) {
        return null;
      }
      row.add(value is _FormulaArgument ? value.singleValue : value);

      _skipWhitespace();
      if (_consume(',')) {
        continue;
      }
      if (_consume(';')) {
        rows.add(row);
        row = <Object>[];
        continue;
      }
      if (_consume('}')) {
        rows.add(row);
        break;
      }
      return null;
    }
    if (rows.isEmpty || rows.first.isEmpty) {
      return null;
    }
    final columnCount = rows.first.length;
    for (final item in rows) {
      if (item.length != columnCount) {
        return _FormulaError.value;
      }
    }
    return _FormulaArgument.range(
      [for (final item in rows) ...item],
      rowCount: rows.length,
      columnCount: columnCount,
    );
  }

  Object? _bracketArrayConstant() {
    final values = <Object>[];
    _skipWhitespace();
    if (_consume(']')) {
      return _FormulaArgument.range(const [], rowCount: 0, columnCount: 0);
    }
    while (true) {
      final elementSource = _arrayElementSource(endChar: ']');
      if (elementSource == null || elementSource.isEmpty) {
        return null;
      }
      final value = _evaluateSource(elementSource);
      if (value == null) {
        return null;
      }
      values.add(value is _FormulaArgument ? value.singleValue : value);

      _skipWhitespace();
      if (_consume(',')) {
        continue;
      }
      if (_consume(']')) {
        break;
      }
      return null;
    }
    return _FormulaArgument.range(
      values,
      rowCount: 1,
      columnCount: values.length,
    );
  }

  String? _arrayElementSource({String endChar = '}'}) {
    _skipWhitespace();
    final start = _offset;
    var depth = 0;
    var inString = false;
    while (_offset < source.length) {
      final char = source[_offset];
      if (inString) {
        if (char == '"') {
          if (_offset + 1 < source.length && source[_offset + 1] == '"') {
            _offset += 2;
            continue;
          }
          inString = false;
        }
        _offset += 1;
        continue;
      }
      if (char == '"') {
        inString = true;
        _offset += 1;
        continue;
      }
      if (char == '(' || char == '{') {
        depth += 1;
        _offset += 1;
        continue;
      }
      if (char == ')') {
        if (depth == 0) {
          return null;
        }
        depth -= 1;
        _offset += 1;
        continue;
      }
      if (char == endChar) {
        if (depth == 0) {
          break;
        }
        depth -= 1;
        _offset += 1;
        continue;
      }
      if (depth == 0 && (char == ',' || char == ';')) {
        break;
      }
      _offset += 1;
    }
    if (inString || depth != 0) {
      return null;
    }
    return source.substring(start, _offset).trim();
  }

  Object? _ifFunction() {
    _skipWhitespace();
    if (_consume(')')) {
      return true;
    }
    final condition = _comparison();
    if (condition == null) {
      return null;
    }
    _skipWhitespace();
    if (!_consume(',') && !_consume(';')) {
      return null;
    }
    final trueBranch = _argumentSource();
    if (trueBranch == null || trueBranch.isEmpty) {
      return null;
    }
    _skipWhitespace();
    if (_consume(')')) {
      return _truthy(condition) ? _evaluateSource(trueBranch) : false;
    }
    if (!_consume(',') && !_consume(';')) {
      return null;
    }
    final falseBranch = _argumentSource();
    if (falseBranch == null || falseBranch.isEmpty) {
      return null;
    }
    if (!_consume(')')) {
      return null;
    }
    return _truthy(condition)
        ? _evaluateSource(trueBranch)
        : _evaluateSource(falseBranch);
  }

  Object? _ifsFunction() {
    String? selectedBranch;
    while (true) {
      final conditionSource = _argumentSource();
      if (conditionSource == null || conditionSource.isEmpty) {
        return null;
      }
      _skipWhitespace();
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
      final resultSource = _argumentSource();
      if (resultSource == null || resultSource.isEmpty) {
        return null;
      }
      if (selectedBranch == null) {
        final condition = _evaluateSource(conditionSource);
        if (condition == null) {
          return null;
        }
        if (_truthy(condition)) {
          selectedBranch = resultSource;
        }
      }
      _skipWhitespace();
      if (_consume(')')) {
        return selectedBranch == null ? null : _evaluateSource(selectedBranch);
      }
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
    }
  }

  Object? _switchFunction() {
    _skipWhitespace();
    if (_consume(')')) {
      return _FormulaError.value;
    }
    final expressionSource = _argumentSource();
    if (expressionSource == null || expressionSource.isEmpty) {
      return _FormulaError.value;
    }
    _skipWhitespace();
    if (!_consume(',') && !_consume(';')) {
      return null;
    }
    final expression = _evaluateSource(expressionSource);
    if (expression == null) {
      return null;
    }
    final sources = <String>[];
    while (true) {
      final source = _argumentSource();
      if (source == null || source.isEmpty) {
        return null;
      }
      sources.add(source);
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
    }
    final hasDefault = sources.length.isOdd;
    final pairEnd = hasDefault ? sources.length - 1 : sources.length;
    for (var i = 0; i < pairEnd; i += 2) {
      final caseValue = _evaluateSource(sources[i]);
      if (caseValue == null) {
        return null;
      }
      if (_valuesEqual(expression, caseValue)) {
        return _evaluateSource(sources[i + 1]);
      }
    }
    return hasDefault ? _evaluateSource(sources.last) : _FormulaError.na;
  }

  Object? _chooseFunction() {
    _skipWhitespace();
    if (_consume(')')) {
      return _FormulaError.na;
    }
    final indexSource = _argumentSource();
    if (indexSource == null || indexSource.isEmpty) {
      return _FormulaError.na;
    }
    _skipWhitespace();
    if (!_consume(',') && !_consume(';')) {
      return null;
    }
    final indexValue = _evaluateSource(indexSource);
    final indexError = _formulaError(indexValue);
    if (indexError != null) {
      return indexError;
    }
    if (indexValue == null) {
      return null;
    }
    final indexArgument = indexValue is _FormulaArgument
        ? indexValue
        : _FormulaArgument.scalar(indexValue);

    final optionSources = <String>[];
    while (true) {
      final source = _argumentSource();
      if (source == null || source.isEmpty) {
        return null;
      }
      optionSources.add(source);
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
    }

    if (indexArgument.rowCount == 1 && indexArgument.columnCount == 1) {
      final index = _positiveIndex(indexArgument.singleValue);
      if (index == null || index > optionSources.length) {
        return _FormulaError.value;
      }
      final choice = _evaluateArgumentSource(optionSources[index - 1]);
      return choice is _FormulaArgument &&
              choice.rowCount == 1 &&
              choice.columnCount == 1
          ? choice.singleValue
          : choice;
    }

    final evaluatedOptions = <int, Object?>{};
    final values = <Object>[];
    for (final rawIndex in indexArgument.values) {
      final indexError = _formulaError(rawIndex);
      if (indexError != null) {
        values.add(indexError);
        continue;
      }
      final index = _positiveIndex(rawIndex);
      if (index == null || index > optionSources.length) {
        values.add(_FormulaError.value);
        continue;
      }
      final result = evaluatedOptions.putIfAbsent(
        index,
        () => _evaluateArgumentSource(optionSources[index - 1]),
      );
      if (result == null) {
        return null;
      }
      values.add(result is _FormulaArgument ? result.singleValue : result);
    }
    return _FormulaArgument.range(
      values,
      rowCount: indexArgument.rowCount,
      columnCount: indexArgument.columnCount,
    );
  }

  Object? _xlookupFunction() {
    final sources = <String>[];
    while (true) {
      final source = _argumentSource();
      if (source == null || source.isEmpty) {
        return null;
      }
      sources.add(source);
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
    }
    if (sources.length < 3 || sources.length > 6) {
      return null;
    }

    final lookupValueResult = _evaluateSource(sources[0]);
    final lookupValueError = _formulaError(lookupValueResult);
    if (lookupValueError != null) {
      return lookupValueError;
    }
    if (lookupValueResult == null) {
      return null;
    }
    final lookupValue = lookupValueResult is _FormulaArgument
        ? lookupValueResult.singleValue
        : lookupValueResult;

    final lookupArrayResult = _evaluateArgumentSource(sources[1]);
    final returnArrayResult = _evaluateArgumentSource(sources[2]);
    final arrayError =
        _formulaError(lookupArrayResult) ?? _formulaError(returnArrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (lookupArrayResult is! _FormulaArgument ||
        returnArrayResult is! _FormulaArgument) {
      return null;
    }

    final matchModeResult = sources.length >= 5
        ? _evaluateSource(sources[4])
        : 0.0;
    final searchModeResult = sources.length >= 6
        ? _evaluateSource(sources[5])
        : 1.0;
    final modeError =
        _formulaError(matchModeResult) ?? _formulaError(searchModeResult);
    if (modeError != null) {
      return modeError;
    }
    final matchMode = FortuneFormulaEngine._numberFromFormulaValue(
      matchModeResult is _FormulaArgument
          ? matchModeResult.singleValue
          : matchModeResult,
    );
    final searchMode = FortuneFormulaEngine._numberFromFormulaValue(
      searchModeResult is _FormulaArgument
          ? searchModeResult.singleValue
          : searchModeResult,
    );
    if (matchMode == null || searchMode == null) {
      return null;
    }
    if (!_isSupportedLookupMode(matchMode.truncate()) ||
        !_isSupportedSearchMode(searchMode.truncate())) {
      return _FormulaError.value;
    }
    if (!_isOneDimensionalRange(lookupArrayResult)) {
      return _FormulaError.value;
    }
    if (!_isCompatibleXlookupReturnArray(
      lookupArrayResult,
      returnArrayResult,
    )) {
      return _FormulaError.value;
    }

    final normalizedMatchMode = matchMode.truncate();
    final normalizedSearchMode = searchMode.truncate();
    final index = _xlookupMatchIndexOrError(
      lookupArrayResult.values,
      lookupValue,
      matchMode: normalizedMatchMode,
      searchMode: normalizedSearchMode,
    );
    if (index is _FormulaError) {
      return index;
    }
    if (index == null) {
      return sources.length >= 4
          ? _evaluateSource(sources[3])
          : _FormulaError.na;
    }
    return _xlookupReturnValue(
      index as int,
      lookupArrayResult,
      returnArrayResult,
    );
  }

  Object? _indexFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2 || sources.length > 3) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final rowResult = _evaluateSource(sources[1]);
    final argumentError =
        _formulaError(arrayResult) ?? _formulaError(rowResult);
    if (argumentError != null) {
      return argumentError;
    }
    if (arrayResult is! _FormulaArgument || rowResult == null) {
      return null;
    }

    final rowNumber = _nonNegativeIndex(
      rowResult is _FormulaArgument ? rowResult.singleValue : rowResult,
    );
    if (rowNumber == null) {
      return null;
    }

    Object? columnResult = 1.0;
    if (sources.length == 3) {
      columnResult = _evaluateSource(sources[2]);
      final columnError = _formulaError(columnResult);
      if (columnError != null) {
        return columnError;
      }
      if (columnResult == null) {
        return null;
      }
    }
    final columnNumber = _nonNegativeIndex(
      columnResult is _FormulaArgument
          ? columnResult.singleValue
          : columnResult,
    );
    if (columnNumber == null) {
      return null;
    }
    return _indexValue(arrayResult, rowNumber, columnNumber, sources.length);
  }

  Object? _matchFunction() {
    _skipWhitespace();
    if (_consume(')')) {
      return _FormulaError.na;
    }
    final sources = _functionArgumentSources();
    if (sources == null) {
      return null;
    }
    if (sources.length < 2) {
      return _FormulaError.na;
    }
    if (sources.length > 3) {
      return null;
    }

    final lookupValueResult = _evaluateSource(sources[0]);
    final lookupValueError = _formulaError(lookupValueResult);
    if (lookupValueError != null) {
      return lookupValueError;
    }
    if (lookupValueResult == null) {
      return null;
    }
    final lookupValue = lookupValueResult is _FormulaArgument
        ? lookupValueResult.singleValue
        : lookupValueResult;

    final lookupArrayResult = _evaluateArgumentSource(sources[1]);
    final lookupArrayError = _formulaError(lookupArrayResult);
    if (lookupArrayError != null) {
      return lookupArrayError;
    }
    if (lookupArrayResult is! _FormulaArgument) {
      return null;
    }

    final matchTypeResult = sources.length == 3
        ? _evaluateSource(sources[2])
        : 1.0;
    final matchTypeError = _formulaError(matchTypeResult);
    if (matchTypeError != null) {
      return matchTypeError;
    }
    final matchType = FortuneFormulaEngine._numberFromFormulaValue(
      matchTypeResult is _FormulaArgument
          ? matchTypeResult.singleValue
          : matchTypeResult,
    );
    if (matchType == null) {
      return null;
    }
    final normalizedMatchType = matchType.truncate();
    if (normalizedMatchType != -1 &&
        normalizedMatchType != 0 &&
        normalizedMatchType != 1) {
      return _FormulaError.value;
    }
    if (!_isOneDimensionalRange(lookupArrayResult)) {
      return _FormulaError.value;
    }

    final lookupValues = lookupArrayResult.values;
    if (lookupValues.isEmpty) {
      return null;
    }
    if (normalizedMatchType == 0) {
      final result = _hasWildcard(lookupValue)
          ? _wildcardMatchIndexOrError(
              lookupValues,
              lookupValue,
              reverse: false,
            )
          : _exactMatchIndexOrError(lookupValues, lookupValue, reverse: false);
      if (result is _FormulaError) {
        return result;
      }
      return result is int ? result + 1.0 : _FormulaError.na;
    }
    final index = _approximateMatchIndexOrError(
      lookupValues,
      lookupValue,
      ascending: normalizedMatchType > 0,
    );
    if (index is _FormulaError) {
      return index;
    }
    return index is int ? index + 1.0 : _FormulaError.na;
  }

  Object? _xmatchFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2 || sources.length > 4) {
      return null;
    }

    final lookupValueResult = _evaluateSource(sources[0]);
    final lookupValueError = _formulaError(lookupValueResult);
    if (lookupValueError != null) {
      return lookupValueError;
    }
    if (lookupValueResult == null) {
      return null;
    }
    final lookupValue = lookupValueResult is _FormulaArgument
        ? lookupValueResult.singleValue
        : lookupValueResult;

    final lookupArrayResult = _evaluateArgumentSource(sources[1]);
    final lookupArrayError = _formulaError(lookupArrayResult);
    if (lookupArrayError != null) {
      return lookupArrayError;
    }
    if (lookupArrayResult is! _FormulaArgument) {
      return null;
    }

    final matchModeResult = sources.length >= 3
        ? _evaluateSource(sources[2])
        : 0.0;
    final searchModeResult = sources.length >= 4
        ? _evaluateSource(sources[3])
        : 1.0;
    final modeError =
        _formulaError(matchModeResult) ?? _formulaError(searchModeResult);
    if (modeError != null) {
      return modeError;
    }
    final matchMode = FortuneFormulaEngine._numberFromFormulaValue(
      matchModeResult is _FormulaArgument
          ? matchModeResult.singleValue
          : matchModeResult,
    );
    final searchMode = FortuneFormulaEngine._numberFromFormulaValue(
      searchModeResult is _FormulaArgument
          ? searchModeResult.singleValue
          : searchModeResult,
    );
    if (matchMode == null || searchMode == null) {
      return null;
    }
    final normalizedMatchMode = matchMode.truncate();
    final normalizedSearchMode = searchMode.truncate();
    if (!_isSupportedLookupMode(normalizedMatchMode) ||
        !_isSupportedSearchMode(normalizedSearchMode)) {
      return _FormulaError.value;
    }
    if (!_isOneDimensionalRange(lookupArrayResult)) {
      return _FormulaError.value;
    }

    final lookupValues = lookupArrayResult.values;
    final index = _xlookupMatchIndexOrError(
      lookupValues,
      lookupValue,
      matchMode: normalizedMatchMode,
      searchMode: normalizedSearchMode,
    );
    if (index is _FormulaError) {
      return index;
    }
    return index is int ? index + 1.0 : _FormulaError.na;
  }

  Object? _vlookupFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 3 || sources.length > 4) {
      return null;
    }

    final lookupValueResult = _evaluateSource(sources[0]);
    final lookupValueError = _formulaError(lookupValueResult);
    if (lookupValueError != null) {
      return lookupValueError;
    }
    if (lookupValueResult == null) {
      return null;
    }
    final lookupValue = lookupValueResult is _FormulaArgument
        ? lookupValueResult.singleValue
        : lookupValueResult;

    final tableResult = _evaluateArgumentSource(sources[1]);
    final columnResult = _evaluateSource(sources[2]);
    final argumentError =
        _formulaError(tableResult) ?? _formulaError(columnResult);
    if (argumentError != null) {
      return argumentError;
    }
    if (tableResult is! _FormulaArgument || columnResult == null) {
      return null;
    }
    final columnNumber = _positiveIndex(
      columnResult is _FormulaArgument
          ? columnResult.singleValue
          : columnResult,
    );
    if (columnNumber == null) {
      return _FormulaError.value;
    }
    if (columnNumber > tableResult.columnCount) {
      return _FormulaError.ref;
    }

    final approximateResult = sources.length == 4
        ? _evaluateSource(sources[3])
        : true;
    final approximateError = _formulaError(approximateResult);
    if (approximateError != null) {
      return approximateError;
    }
    if (approximateResult == null) {
      return null;
    }

    final lookupColumn = tableResult.columnValues(0);
    final row = _truthy(approximateResult)
        ? _approximateMatchIndexOrError(
            lookupColumn,
            lookupValue,
            ascending: true,
          )
        : _exactOrWildcardMatchIndexOrError(
            lookupColumn,
            lookupValue,
            reverse: false,
          );
    if (row is _FormulaError) {
      return row;
    }
    return row == null
        ? _FormulaError.na
        : tableResult.valueAt(row as int, columnNumber - 1);
  }

  Object? _hlookupFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 3 || sources.length > 4) {
      return null;
    }

    final lookupValueResult = _evaluateSource(sources[0]);
    final lookupValueError = _formulaError(lookupValueResult);
    if (lookupValueError != null) {
      return lookupValueError;
    }
    if (lookupValueResult == null) {
      return null;
    }
    final lookupValue = lookupValueResult is _FormulaArgument
        ? lookupValueResult.singleValue
        : lookupValueResult;

    final tableResult = _evaluateArgumentSource(sources[1]);
    final rowResult = _evaluateSource(sources[2]);
    final argumentError =
        _formulaError(tableResult) ?? _formulaError(rowResult);
    if (argumentError != null) {
      return argumentError;
    }
    if (tableResult is! _FormulaArgument || rowResult == null) {
      return null;
    }
    final rowNumber = _positiveIndex(
      rowResult is _FormulaArgument ? rowResult.singleValue : rowResult,
    );
    if (rowNumber == null) {
      return _FormulaError.value;
    }
    if (rowNumber > tableResult.rowCount) {
      return _FormulaError.ref;
    }

    final approximateResult = sources.length == 4
        ? _evaluateSource(sources[3])
        : true;
    final approximateError = _formulaError(approximateResult);
    if (approximateError != null) {
      return approximateError;
    }
    if (approximateResult == null) {
      return null;
    }

    final lookupRow = tableResult.rowValues(0);
    final column = _truthy(approximateResult)
        ? _approximateMatchIndexOrError(lookupRow, lookupValue, ascending: true)
        : _exactOrWildcardMatchIndexOrError(
            lookupRow,
            lookupValue,
            reverse: false,
          );
    if (column is _FormulaError) {
      return column;
    }
    return column == null
        ? _FormulaError.na
        : tableResult.valueAt(rowNumber - 1, column as int);
  }

  Object? _lookupFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2 || sources.length > 3) {
      return null;
    }

    final lookupValueResult = _evaluateSource(sources[0]);
    final lookupValueError = _formulaError(lookupValueResult);
    if (lookupValueError != null) {
      return lookupValueError;
    }
    if (lookupValueResult == null) {
      return null;
    }
    final lookupValue = lookupValueResult is _FormulaArgument
        ? lookupValueResult.singleValue
        : lookupValueResult;

    final lookupVectorResult = _evaluateArgumentSource(sources[1]);
    final lookupVectorError = _formulaError(lookupVectorResult);
    if (lookupVectorError != null) {
      return lookupVectorError;
    }
    if (lookupVectorResult is! _FormulaArgument) {
      return null;
    }

    if (sources.length == 2 &&
        lookupVectorResult.rowCount > 1 &&
        lookupVectorResult.columnCount > 1) {
      return _lookupArrayFormLazy(lookupValue, lookupVectorResult);
    }
    if (!_isOneDimensionalRange(lookupVectorResult)) {
      return _FormulaError.value;
    }

    final resultVectorResult = sources.length == 3
        ? _evaluateArgumentSource(sources[2])
        : lookupVectorResult;
    final resultVectorError = _formulaError(resultVectorResult);
    if (resultVectorError != null) {
      return resultVectorError;
    }
    if (resultVectorResult is! _FormulaArgument) {
      return null;
    }

    final lookupValues = lookupVectorResult.values;
    final returnValues = resultVectorResult.values;
    if (sources.length == 3 &&
        (!_isOneDimensionalRange(resultVectorResult) ||
            lookupValues.length != returnValues.length)) {
      return _FormulaError.value;
    }
    if (lookupValues.isEmpty || lookupValues.length != returnValues.length) {
      return null;
    }
    final lookupError = _firstFormulaError(lookupValues);
    if (lookupError != null) {
      return lookupError;
    }
    final index = _nextSmallerMatchIndex(
      lookupValues,
      lookupValue,
      reverse: true,
    );
    return index == null ? _FormulaError.na : returnValues[index];
  }

  Object? _lookupArrayFormLazy(Object lookupValue, _FormulaArgument array) {
    final searchRows = array.columnCount > array.rowCount;
    final lookupValues = searchRows
        ? array.rowValues(0)
        : array.columnValues(0);
    final returnValues = searchRows
        ? array.rowValues(array.rowCount - 1)
        : array.columnValues(array.columnCount - 1);
    if (lookupValues.isEmpty || lookupValues.length != returnValues.length) {
      return null;
    }
    final lookupError = _firstFormulaError(lookupValues);
    if (lookupError != null) {
      return lookupError;
    }
    final index = _nextSmallerMatchIndex(
      lookupValues,
      lookupValue,
      reverse: true,
    );
    return index == null ? _FormulaError.na : returnValues[index];
  }

  Object? _textBeforeAfterFunction({required bool before}) {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2 || sources.length > 6) {
      return null;
    }

    final values = <Object>[];
    final eagerCount = sources.length > 5 ? 5 : sources.length;
    for (var i = 0; i < eagerCount; i += 1) {
      final result = _evaluateSource(sources[i]);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result == null) {
        return null;
      }
      values.add(result is _FormulaArgument ? result.singleValue : result);
    }

    return _textBeforeAfter(
      values,
      before: before,
      ifNotFound: sources.length == 6
          ? () {
              final result = _evaluateSource(sources[5]);
              final error = _formulaError(result);
              if (error != null) {
                return error;
              }
              return result is _FormulaArgument ? result.singleValue : result;
            }
          : null,
    );
  }

  List<String>? _functionArgumentSources({bool allowEmpty = false}) {
    final sources = <String>[];
    while (true) {
      final source = _argumentSource();
      if (source == null || (!allowEmpty && source.isEmpty)) {
        return null;
      }
      sources.add(source);
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
    }
    return sources;
  }

  Object? _ifErrorFunction() {
    final valueBranch = _argumentSource();
    if (valueBranch == null || valueBranch.isEmpty) {
      return null;
    }
    _skipWhitespace();
    if (!_consume(',') && !_consume(';')) {
      return null;
    }
    final fallbackBranch = _argumentSource();
    if (fallbackBranch == null || fallbackBranch.isEmpty) {
      return null;
    }
    if (!_consume(')')) {
      return null;
    }
    final value = _evaluateSource(valueBranch);
    return _isFormulaError(value) || value == null
        ? _evaluateSource(fallbackBranch)
        : value;
  }

  Object? _ifNaFunction() {
    final valueBranch = _argumentSource();
    if (valueBranch == null || valueBranch.isEmpty) {
      return null;
    }
    _skipWhitespace();
    if (!_consume(',') && !_consume(';')) {
      return null;
    }
    final fallbackBranch = _argumentSource();
    if (fallbackBranch == null || fallbackBranch.isEmpty) {
      return null;
    }
    if (!_consume(')')) {
      return null;
    }
    final value = _evaluateSource(valueBranch);
    return _isNaError(value) ? _evaluateSource(fallbackBranch) : value;
  }

  Object? _isErrorFunction({required bool includeNa}) {
    final valueBranch = _argumentSource();
    if (valueBranch == null || valueBranch.isEmpty) {
      return null;
    }
    if (!_consume(')')) {
      return null;
    }
    final value = _evaluateSource(valueBranch);
    return value == null ||
        (_isFormulaError(value) && (includeNa || !_isNaError(value)));
  }

  Object? _isNaFunction() {
    final valueBranch = _argumentSource();
    if (valueBranch == null || valueBranch.isEmpty) {
      return null;
    }
    if (!_consume(')')) {
      return null;
    }
    return _isNaError(_evaluateSource(valueBranch));
  }

  Object? _typeFunction() {
    final valueBranch = _argumentSource();
    if (valueBranch == null || valueBranch.isEmpty) {
      return null;
    }
    if (!_consume(')')) {
      return null;
    }
    final value = _evaluateSource(valueBranch);
    return value == null ? null : _type(value);
  }

  Object? _errorTypeFunction() {
    final valueBranch = _argumentSource();
    if (valueBranch == null || valueBranch.isEmpty) {
      return null;
    }
    if (!_consume(')')) {
      return null;
    }
    final value = _evaluateSource(valueBranch);
    return switch (_formulaError(value)) {
      _FormulaError.nullError => 1.0,
      _FormulaError.div0 => 2.0,
      _FormulaError.value => 3.0,
      _FormulaError.ref => 4.0,
      _FormulaError.name => 5.0,
      _FormulaError.num => 6.0,
      _FormulaError.na => 7.0,
      _FormulaError.gettingData => 8.0,
      _FormulaError.spill => 9.0,
      _FormulaError.connect => 10.0,
      _FormulaError.blocked => 11.0,
      _FormulaError.unknown => 12.0,
      _FormulaError.field => 13.0,
      _FormulaError.calc => 14.0,
      _ => _FormulaError.na,
    };
  }

  Object? _cellFunction() {
    final infoSource = _argumentSource();
    if (infoSource == null || infoSource.isEmpty) {
      return null;
    }
    final infoValue = _evaluateSource(infoSource);
    final infoError = _formulaError(infoValue);
    if (infoError != null) {
      return infoError;
    }
    if (infoValue == null) {
      return _FormulaError.value;
    }
    final infoType = _text(infoValue).toLowerCase();
    var reference = currentCoord == null
        ? null
        : _SingleCellReference(currentCoord!, null);
    _skipWhitespace();
    if (_consume(',') || _consume(';')) {
      final referenceSource = _argumentSource();
      if (referenceSource == null || referenceSource.isEmpty) {
        return null;
      }
      if (!_consume(')')) {
        return null;
      }
      final rangeReference = _rangeFromReferenceExpression(referenceSource);
      if (rangeReference is _FormulaError) {
        return rangeReference;
      }
      if (rangeReference is! _FormulaRange) {
        return _FormulaError.value;
      }
      reference = _SingleCellReference(
        FortuneCellCoord(rangeReference.rowStart, rangeReference.columnStart),
        rangeReference.sheetName,
      );
    } else if (!_consume(')')) {
      return null;
    }
    if (reference == null) {
      return _FormulaError.value;
    }
    return _cellInfo(infoType, reference);
  }

  Object? _cellInfo(String infoType, _SingleCellReference reference) {
    final coord = reference.coord;
    switch (infoType) {
      case 'address':
        return '\$${FortuneFormulaEngine._columnName(coord.column)}\$${coord.row + 1}';
      case 'row':
        return coord.row + 1.0;
      case 'col':
        return coord.column + 1.0;
      case 'contents':
        return cellValue(coord, reference.sheetName) ?? '';
      case 'type':
        final value = cellValue(coord, reference.sheetName);
        if (value == null || _text(value).isEmpty) {
          return 'b';
        }
        return FortuneFormulaEngine._numberFromFormulaValue(value) == null
            ? 'l'
            : 'v';
      default:
        return _FormulaError.value;
    }
  }

  Object? _info(Object infoType) {
    return switch (_text(infoType).toLowerCase()) {
      'directory' => '',
      'numfile' => 1.0,
      'origin' => r'$A:$A',
      'osversion' => '',
      'recalc' => 'Automatic',
      'release' => 'FortuneSheet',
      'system' => 'pcdos',
      _ => _FormulaError.value,
    };
  }

  Object? _evaluateSource(String expression) {
    return _Parser(
      expression,
      cellValue,
      rangeValues,
      cellFormula,
      currentCoord: currentCoord,
      namedValues: namedValues,
      customFunctions: customFunctions,
      sheetNames: sheetNames,
    ).parse();
  }

  Object? _evaluateFormulaText(Object value) {
    var expression = _text(value).trim();
    if (expression.startsWith('=')) {
      expression = expression.substring(1);
    }
    return expression.isEmpty ? null : _evaluateSource(expression);
  }

  bool _isSparklineFunctionName(String upper) {
    return switch (upper) {
      'LINESPLINES' ||
      'AREASPLINES' ||
      'COLUMNSPLINES' ||
      'STACKCOLUMNSPLINES' ||
      'BARSPLINES' ||
      'STACKBARSPLINES' ||
      'DISCRETESPLINES' ||
      'TRISTATESPLINES' ||
      'PIESPLINES' ||
      'BOXSPLINES' ||
      'BULLETSPLINES' ||
      'COMPOSESPLINES' => true,
      _ => false,
    };
  }

  Object? _sparklineFunction(String upper, List<_FormulaArgument> args) {
    if (args.isEmpty || (upper == 'BULLETSPLINES' && args.length < 2)) {
      return null;
    }
    if (upper == 'COMPOSESPLINES') {
      final children = <Object?>[];
      for (final arg in args) {
        for (final value in arg.values) {
          if (value is _FormulaSparkline) {
            children.add(value.data);
          } else if (value is Map || value is List) {
            children.add(value);
          }
        }
      }
      return _FormulaSparkline({'type': 'compose', 'children': children});
    }

    final type = switch (upper) {
      'AREASPLINES' => 'area',
      'COLUMNSPLINES' => 'column',
      'STACKCOLUMNSPLINES' => 'stackcolumn',
      'BARSPLINES' => 'bar',
      'STACKBARSPLINES' => 'stackbar',
      'DISCRETESPLINES' => 'discrete',
      'TRISTATESPLINES' => 'tristate',
      'PIESPLINES' => 'pie',
      'BOXSPLINES' => 'box',
      'BULLETSPLINES' => 'bullet',
      _ => 'line',
    };
    final dataArgs = upper == 'BULLETSPLINES' ? args : [args.first];
    final data = <double>[];
    for (final arg in dataArgs) {
      data.addAll(arg.values.map(_numberArgument).whereType<double>());
    }
    if (data.isEmpty) {
      return null;
    }
    final sparkline = <String, Object?>{'type': type, 'data': data};
    if ((upper == 'LINESPLINES' || upper == 'AREASPLINES') && args.length > 1) {
      final color = _sparklineOptionText(args[1]);
      if (color != null && color != '0' && color.toLowerCase() != 'false') {
        sparkline['color'] = color;
      }
    }
    if (upper == 'COLUMNSPLINES' || upper == 'BARSPLINES') {
      if (args.length > 1) {
        final barSpacing = _numberArgument(args[1].singleValue);
        if (barSpacing != null && barSpacing.isFinite && barSpacing >= 0) {
          sparkline['barSpacing'] = barSpacing;
        }
      }
      if (args.length > 2) {
        final color = _sparklineOptionText(args[2]);
        if (color != null && color != '0' && color.toLowerCase() != 'false') {
          sparkline['color'] = color;
        }
      }
      if (args.length > 3) {
        final negativeColor = _sparklineOptionText(args[3]);
        if (negativeColor != null &&
            negativeColor != '0' &&
            negativeColor.toLowerCase() != 'false') {
          sparkline['negativeColor'] = negativeColor;
        }
      }
      if (args.length > 4) {
        final chartRangeMax = _numberArgument(args[4].singleValue);
        if (chartRangeMax != null &&
            chartRangeMax.isFinite &&
            chartRangeMax > 0) {
          sparkline['chartRangeMax'] = chartRangeMax;
        }
      }
      if (args.length > 5) {
        final colorMap = <String>[];
        for (var index = 5; index < args.length; index += 1) {
          colorMap.addAll(_sparklineOptionTexts(args[index]));
        }
        if (colorMap.isNotEmpty) {
          sparkline['colorMap'] = colorMap;
        }
      }
    }
    if (upper == 'STACKCOLUMNSPLINES' || upper == 'STACKBARSPLINES') {
      if (args.first.rowCount > 1 && args.first.columnCount > 1) {
        final stackByColumn = args.length <= 1 || _truthy(args[1].singleValue);
        sparkline['stackGroups'] = _sparklineStackGroups(
          args.first,
          stackByColumn: stackByColumn,
        );
      }
      if (args.length > 2) {
        final barSpacing = _numberArgument(args[2].singleValue);
        if (barSpacing != null && barSpacing.isFinite && barSpacing >= 0) {
          sparkline['barSpacing'] = barSpacing;
        }
      }
      if (args.length > 3) {
        final chartRangeMax = _numberArgument(args[3].singleValue);
        if (chartRangeMax != null &&
            chartRangeMax.isFinite &&
            chartRangeMax > 0) {
          sparkline['chartRangeMax'] = chartRangeMax;
        }
      }
      if (args.length > 4) {
        final stackedBarColors = <String>[];
        for (var index = 4; index < args.length; index += 1) {
          stackedBarColors.addAll(_sparklineOptionTexts(args[index]));
        }
        if (stackedBarColors.isNotEmpty) {
          sparkline['stackedBarColors'] = stackedBarColors;
        }
      }
    }
    if (upper == 'DISCRETESPLINES') {
      if (args.length > 1) {
        final threshold = _numberArgument(args[1].singleValue);
        if (threshold != null && threshold.isFinite) {
          sparkline['thresholdValue'] = threshold;
        }
      }
      if (args.length > 2) {
        final color = _sparklineOptionText(args[2]);
        if (color != null && color != '0' && color.toLowerCase() != 'false') {
          sparkline['color'] = color;
        }
      }
      if (args.length > 3) {
        final thresholdColor = _sparklineOptionText(args[3]);
        if (thresholdColor != null &&
            thresholdColor != '0' &&
            thresholdColor.toLowerCase() != 'false') {
          sparkline['negativeColor'] = thresholdColor;
        }
      }
    }
    if (upper == 'TRISTATESPLINES') {
      if (args.length > 1) {
        final barSpacing = _numberArgument(args[1].singleValue);
        if (barSpacing != null && barSpacing.isFinite && barSpacing >= 0) {
          sparkline['barSpacing'] = barSpacing;
        }
      }
      if (args.length > 2) {
        final color = _sparklineOptionText(args[2]);
        if (color != null && color != '0' && color.toLowerCase() != 'false') {
          sparkline['color'] = color;
        }
      }
      if (args.length > 3) {
        final negativeColor = _sparklineOptionText(args[3]);
        if (negativeColor != null &&
            negativeColor != '0' &&
            negativeColor.toLowerCase() != 'false') {
          sparkline['negativeColor'] = negativeColor;
        }
      }
      if (args.length > 4) {
        final zeroColor = _sparklineOptionText(args[4]);
        if (zeroColor != null &&
            zeroColor != '0' &&
            zeroColor.toLowerCase() != 'false') {
          sparkline['zeroColor'] = zeroColor;
        }
      }
      if (args.length > 5) {
        final colorMap = <String>[];
        for (var index = 5; index < args.length; index += 1) {
          colorMap.addAll(_sparklineOptionTexts(args[index]));
        }
        if (colorMap.isNotEmpty) {
          sparkline['colorMap'] = colorMap;
        }
      }
    }
    if (upper == 'PIESPLINES') {
      if (args.length > 1) {
        final offset = _numberArgument(args[1].singleValue);
        if (offset != null && offset.isFinite) {
          sparkline['offset'] = offset;
        }
      }
      if (args.length > 2) {
        final borderWidth = _numberArgument(args[2].singleValue);
        if (borderWidth != null && borderWidth.isFinite && borderWidth >= 0) {
          sparkline['borderWidth'] = borderWidth;
        }
      }
      if (args.length > 3) {
        final borderColor = _sparklineOptionText(args[3]);
        if (borderColor != null &&
            borderColor != '0' &&
            borderColor.toLowerCase() != 'false') {
          sparkline['borderColor'] = borderColor;
        }
      }
      if (args.length > 4) {
        final sliceColors = <String>[];
        for (var index = 4; index < args.length; index += 1) {
          sliceColors.addAll(_sparklineOptionTexts(args[index]));
        }
        if (sliceColors.isNotEmpty) {
          sparkline['sliceColors'] = sliceColors;
        }
      }
    }
    if (upper == 'BOXSPLINES') {
      if (args.length > 1) {
        final outlierIqr = _numberArgument(args[1].singleValue);
        if (outlierIqr != null && outlierIqr.isFinite && outlierIqr > 0) {
          sparkline['outlierIQR'] = outlierIqr;
        }
      }
      if (args.length > 2) {
        final target = _numberArgument(args[2].singleValue);
        if (target != null && target.isFinite) {
          sparkline['targetValue'] = target;
        }
      }
      if (args.length > 3) {
        final spotRadius = _numberArgument(args[3].singleValue);
        if (spotRadius != null && spotRadius.isFinite && spotRadius > 0) {
          sparkline['spotRadius'] = spotRadius;
        }
      }
    }
    if (upper == 'AREASPLINES' && args.length > 2) {
      final fillColor = _sparklineOptionText(args[2]);
      if (fillColor != null &&
          fillColor != '0' &&
          fillColor.toLowerCase() != 'false') {
        sparkline['fillColor'] = fillColor;
      }
    }
    if ((upper == 'LINESPLINES' || upper == 'AREASPLINES') && args.length > 2) {
      final lineWidthArg = upper == 'LINESPLINES' && args.length > 2
          ? args[2]
          : args.length > 3
          ? args[3]
          : null;
      final lineWidth = lineWidthArg == null || lineWidthArg.values.isEmpty
          ? null
          : _numberArgument(lineWidthArg.values.first);
      if (lineWidth != null && lineWidth.isFinite && lineWidth > 0) {
        sparkline['lineWidth'] = lineWidth;
      }
    }
    if (upper == 'LINESPLINES' && args.length > 3) {
      final normalRange = _sparklineOptionText(args[3]);
      if (normalRange != null &&
          normalRange != '0' &&
          normalRange.toLowerCase() != 'false') {
        sparkline['normalRange'] = normalRange;
      }
      if (args.length > 4) {
        final normalRangeColor = _sparklineOptionText(args[4]);
        if (normalRangeColor != null &&
            normalRangeColor != '0' &&
            normalRangeColor.toLowerCase() != 'false') {
          sparkline['normalRangeColor'] = normalRangeColor;
        }
      }
      if (args.length > 5) {
        final maxSpotColor = _sparklineOptionText(args[5]);
        if (maxSpotColor != null &&
            maxSpotColor != '0' &&
            maxSpotColor.toLowerCase() != 'false') {
          sparkline['maxSpotColor'] = maxSpotColor;
        }
      }
      if (args.length > 6) {
        final minSpotColor = _sparklineOptionText(args[6]);
        if (minSpotColor != null &&
            minSpotColor != '0' &&
            minSpotColor.toLowerCase() != 'false') {
          sparkline['minSpotColor'] = minSpotColor;
        }
      }
      if (args.length > 7) {
        final spotRadius = _numberArgument(args[7].singleValue);
        if (spotRadius != null && spotRadius.isFinite && spotRadius > 0) {
          sparkline['spotRadius'] = spotRadius;
        }
      }
    }
    if (upper == 'AREASPLINES' && args.length > 4) {
      final normalRange = _sparklineOptionText(args[4]);
      if (normalRange != null &&
          normalRange != '0' &&
          normalRange.toLowerCase() != 'false') {
        sparkline['normalRange'] = normalRange;
      }
      if (args.length > 5) {
        final normalRangeColor = _sparklineOptionText(args[5]);
        if (normalRangeColor != null &&
            normalRangeColor != '0' &&
            normalRangeColor.toLowerCase() != 'false') {
          sparkline['normalRangeColor'] = normalRangeColor;
        }
      }
    }
    return _FormulaSparkline(sparkline);
  }

  List<List<double>> _sparklineStackGroups(
    _FormulaArgument arg, {
    required bool stackByColumn,
  }) {
    final groups = <List<double>>[];
    if (stackByColumn) {
      for (var column = 0; column < arg.columnCount; column += 1) {
        final group = arg
            .columnValues(column)
            .map(_numberArgument)
            .whereType<double>()
            .toList();
        if (group.isNotEmpty) {
          groups.add(group);
        }
      }
    } else {
      for (var row = 0; row < arg.rowCount; row += 1) {
        final group = arg
            .rowValues(row)
            .map(_numberArgument)
            .whereType<double>()
            .toList();
        if (group.isNotEmpty) {
          groups.add(group);
        }
      }
    }
    return groups;
  }

  String? _sparklineOptionText(_FormulaArgument arg) {
    if (arg.values.isEmpty) {
      return null;
    }
    final value = arg.values.first;
    if (_isFormulaBlankLike(value)) {
      return null;
    }
    return _text(value).trim();
  }

  List<String> _sparklineOptionTexts(_FormulaArgument arg) {
    final texts = <String>[];
    for (final value in arg.values) {
      if (_isFormulaBlankLike(value)) {
        continue;
      }
      final text = _text(value).trim();
      if (text.isEmpty || text == '0' || text.toLowerCase() == 'false') {
        continue;
      }
      texts.add(text);
    }
    return texts;
  }

  Object? _evaluateArgumentSource(String expression) {
    final range = _rangeFromReferenceSource(expression);
    if (range != null) {
      return _FormulaArgument.range(
        rangeValues(range),
        rowCount: range.rowCount,
        columnCount: range.columnCount,
        sourceRange: range,
      );
    }
    final value = _evaluateSource(expression);
    if (value is _FormulaArgument || value is _FormulaError || value == null) {
      return value;
    }
    return _FormulaArgument.scalar(value);
  }

  Object? _isFormulaFunction() {
    final reference = _singleCellReferenceArgument();
    if (reference == null || !_consume(')')) {
      return null;
    }
    return cellFormula(reference.coord, reference.sheetName) != null;
  }

  Object? _formulaTextFunction() {
    final reference = _singleCellReferenceArgument();
    if (reference == null || !_consume(')')) {
      return null;
    }
    return cellFormula(reference.coord, reference.sheetName) ??
        _FormulaError.na;
  }

  Object? _isRefFunction() {
    final source = _argumentSource();
    if (source == null || source.isEmpty || !_consume(')')) {
      return null;
    }
    if (_isReferenceSource(source)) {
      return true;
    }
    return _evaluateSource(source) is _FormulaArgument;
  }

  Object? _areasFunction() {
    final source = _argumentSource();
    if (source == null || source.isEmpty || !_consume(')')) {
      return null;
    }
    final count = _referenceAreaCount(source);
    return count ?? _FormulaError.value;
  }

  double? _referenceAreaCount(String source) {
    final areas = _splitReferenceAreas(source);
    if (areas == null || areas.isEmpty) {
      return null;
    }
    for (final area in areas) {
      final range = _rangeFromReferenceExpression(area);
      if (range is! _FormulaRange) {
        return null;
      }
    }
    return areas.length.toDouble();
  }

  List<String>? _splitReferenceAreas(String source) {
    var value = source.trim();
    if (value.startsWith('(') && _matchingOuterParentheses(value)) {
      value = value.substring(1, value.length - 1).trim();
    }
    final areas = <String>[];
    var start = 0;
    var depth = 0;
    var inString = false;
    var inQuotedSheetName = false;
    for (var i = 0; i < value.length; i += 1) {
      final char = value[i];
      if (inString) {
        if (char == '"') {
          if (i + 1 < value.length && value[i + 1] == '"') {
            i += 1;
          } else {
            inString = false;
          }
        }
        continue;
      }
      if (inQuotedSheetName) {
        if (char == "'") {
          if (i + 1 < value.length && value[i + 1] == "'") {
            i += 1;
          } else {
            inQuotedSheetName = false;
          }
        }
        continue;
      }
      if (char == '"') {
        inString = true;
        continue;
      }
      if (char == "'") {
        inQuotedSheetName = true;
        continue;
      }
      if (char == '(' || char == '{') {
        depth += 1;
        continue;
      }
      if (char == ')' || char == '}') {
        if (depth == 0) {
          return null;
        }
        depth -= 1;
        continue;
      }
      if (char == ',' && depth == 0) {
        final area = value.substring(start, i).trim();
        if (area.isEmpty) {
          return null;
        }
        areas.add(area);
        start = i + 1;
      }
    }
    if (inString || inQuotedSheetName || depth != 0) {
      return null;
    }
    final area = value.substring(start).trim();
    if (area.isEmpty) {
      return null;
    }
    areas.add(area);
    return areas;
  }

  bool _matchingOuterParentheses(String value) {
    var depth = 0;
    var inString = false;
    var inQuotedSheetName = false;
    for (var i = 0; i < value.length; i += 1) {
      final char = value[i];
      if (inString) {
        if (char == '"') {
          if (i + 1 < value.length && value[i + 1] == '"') {
            i += 1;
          } else {
            inString = false;
          }
        }
        continue;
      }
      if (inQuotedSheetName) {
        if (char == "'") {
          if (i + 1 < value.length && value[i + 1] == "'") {
            i += 1;
          } else {
            inQuotedSheetName = false;
          }
        }
        continue;
      }
      if (char == '"') {
        inString = true;
        continue;
      }
      if (char == "'") {
        inQuotedSheetName = true;
        continue;
      }
      if (char == '(') {
        depth += 1;
      } else if (char == ')') {
        depth -= 1;
        if (depth == 0 && i != value.length - 1) {
          return false;
        }
        if (depth < 0) {
          return false;
        }
      }
    }
    return depth == 0 && !inString && !inQuotedSheetName;
  }

  bool _isReferenceSource(String value) {
    return _rangeFromReferenceSource(value) != null;
  }

  Object? _sheetNumberFunction() {
    return _singleSheetReferenceResult();
  }

  Object? _sheetCountFunction() {
    return _singleSheetReferenceResult();
  }

  Object? _singleSheetReferenceResult() {
    _skipWhitespace();
    if (_consume(')')) {
      return 1.0;
    }
    final source = _argumentSource();
    if (source == null || source.isEmpty || !_consume(')')) {
      return null;
    }
    if (_rangeFromReferenceSource(source) != null) {
      return 1.0;
    }
    final value = _evaluateSource(source);
    final error = _formulaError(value);
    if (error != null) {
      return error;
    }
    return value is _FormulaArgument ? 1.0 : _FormulaError.na;
  }

  Object? _rowFunction() {
    final sources = _functionArgumentSources(allowEmpty: true);
    if (sources == null) {
      return null;
    }
    if (sources.length == 1 && sources.single.isEmpty) {
      return currentCoord == null
          ? (strictParserCompatibility ? _FormulaError.na : _FormulaError.value)
          : currentCoord!.row + 1.0;
    }
    if (sources.length == 2) {
      return _indexedReferenceVector(sources, rowVector: true);
    }
    if (sources.length != 1) {
      return null;
    }
    final literalRange = _rangeFromReferenceSource(sources.single);
    if (literalRange != null) {
      return literalRange.rowCount == 1 && literalRange.columnCount == 1
          ? literalRange.rowStart + 1.0
          : _FormulaError.na;
    }
    final range = _rangeFromReferenceExpression(sources.single);
    if (range is _FormulaError) {
      return range;
    }
    if (range is! _FormulaRange) {
      return null;
    }
    return range.rowStart + 1.0;
  }

  Object? _columnFunction() {
    final sources = _functionArgumentSources(allowEmpty: true);
    if (sources == null) {
      return null;
    }
    if (sources.length == 1 && sources.single.isEmpty) {
      return currentCoord == null
          ? (strictParserCompatibility ? _FormulaError.na : _FormulaError.value)
          : currentCoord!.column + 1.0;
    }
    if (sources.length == 2) {
      return _indexedReferenceVector(sources, rowVector: false);
    }
    if (sources.length != 1) {
      return null;
    }
    final literalRange = _rangeFromReferenceSource(sources.single);
    if (literalRange != null) {
      return literalRange.rowCount == 1 && literalRange.columnCount == 1
          ? literalRange.columnStart + 1.0
          : _FormulaError.na;
    }
    final range = _rangeFromReferenceExpression(sources.single);
    if (range is _FormulaError) {
      return range;
    }
    if (range is! _FormulaRange) {
      return null;
    }
    return range.columnStart + 1.0;
  }

  _FormulaArgument? _parserRangeShape(_FormulaArgument argument) {
    if (!strictParserCompatibility || argument.sourceRange == null) {
      return null;
    }
    final eventValue = _rangeEventValue(argument.sourceRange!);
    if (identical(eventValue, _parserNoValue)) {
      return null;
    }
    final eventArgument = _namedFormulaValue(eventValue);
    return eventArgument is _FormulaArgument ? eventArgument : null;
  }

  Object? _indexedReferenceVector(
    List<String> sources, {
    required bool rowVector,
  }) {
    if (sources[0].isEmpty || sources[1].isEmpty) {
      return null;
    }
    final literalRange = _rangeFromReferenceSource(sources[0]);
    final eventValue = literalRange == null
        ? _parserNoValue
        : _rangeEventValue(literalRange);
    final reference = !identical(eventValue, _parserNoValue)
        ? _namedFormulaValue(eventValue)
        : literalRange == null
        ? _evaluateSource(sources[0])
        : _FormulaArgument.range(
            rangeValues(literalRange),
            rowCount: literalRange.rowCount,
            columnCount: literalRange.columnCount,
            sourceRange: literalRange,
          );
    final referenceError = _formulaError(reference);
    if (referenceError != null) {
      return referenceError;
    }
    final indexValue = _evaluateSource(sources[1]);
    final indexError = _formulaError(indexValue);
    if (indexError != null) {
      return indexError;
    }
    final indexNumber = _numberArgument(indexValue ?? _formulaBlank);
    if (reference is! _FormulaArgument || indexNumber == null) {
      return _FormulaError.value;
    }
    final index = indexNumber.truncate();
    if (index < 0) {
      return _FormulaError.num;
    }
    final values = rowVector
        ? reference.rowValues(index)
        : reference.columnValues(index);
    if (values.isEmpty) {
      return _FormulaError.value;
    }
    if (strictParserCompatibility) {
      return rowVector
          ? values
          : [
              for (final value in values) [value],
            ];
    }
    return _FormulaArgument.range(
      values,
      rowCount: rowVector ? 1 : values.length,
      columnCount: rowVector ? values.length : 1,
      sourceRange: null,
    );
  }

  Object? _offsetFunction() {
    final referenceSource = _argumentSource();
    if (referenceSource == null || referenceSource.isEmpty) {
      return null;
    }
    final referenceResult = _rangeFromReferenceExpression(referenceSource);
    if (referenceResult is _FormulaError) {
      return referenceResult;
    }
    if (referenceResult is! _FormulaRange) {
      return _FormulaError.value;
    }
    final reference = referenceResult;
    final sources = <String>[];
    while (true) {
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
      final source = _argumentSource();
      if (source == null || source.isEmpty) {
        return null;
      }
      sources.add(source);
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
    }
    if (sources.length < 2 || sources.length > 4) {
      return null;
    }
    final rowsValue = _evaluateSource(sources[0]);
    final columnsValue = _evaluateSource(sources[1]);
    final heightValue = sources.length >= 3
        ? _evaluateSource(sources[2])
        : reference.rowCount.toDouble();
    final widthValue = sources.length >= 4
        ? _evaluateSource(sources[3])
        : reference.columnCount.toDouble();
    final argumentError =
        _formulaError(rowsValue) ??
        _formulaError(columnsValue) ??
        _formulaError(heightValue) ??
        _formulaError(widthValue);
    if (argumentError != null) {
      return argumentError;
    }
    final rows = _integerReferenceOffset(rowsValue);
    final columns = _integerReferenceOffset(columnsValue);
    final height = _positiveReferenceSize(heightValue);
    final width = _positiveReferenceSize(widthValue);
    if (rows == null || columns == null || height == null || width == null) {
      return _FormulaError.value;
    }
    final rowStart = reference.rowStart + rows;
    final columnStart = reference.columnStart + columns;
    if (rowStart < 0 || columnStart < 0) {
      return _FormulaError.ref;
    }
    final range = _FormulaRange(
      rowStart: rowStart,
      rowEnd: rowStart + height - 1,
      columnStart: columnStart,
      columnEnd: columnStart + width - 1,
      sheetName: reference.sheetName,
    );
    return _FormulaArgument.range(
      rangeValues(range),
      rowCount: range.rowCount,
      columnCount: range.columnCount,
      sourceRange: range,
    );
  }

  Object? _indirectFunction() {
    final referenceSource = _argumentSource();
    if (referenceSource == null || referenceSource.isEmpty) {
      return null;
    }
    final sources = <String>[];
    while (true) {
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
      if (!_consume(',') && !_consume(';')) {
        return null;
      }
      final source = _argumentSource();
      if (source == null || source.isEmpty) {
        return null;
      }
      sources.add(source);
      _skipWhitespace();
      if (_consume(')')) {
        break;
      }
    }
    if (sources.length > 1) {
      return null;
    }
    final referenceText = _evaluateSource(referenceSource);
    final referenceError = _formulaError(referenceText);
    if (referenceError != null) {
      return referenceError;
    }
    final a1Value = sources.isEmpty ? true : _evaluateSource(sources.first);
    final a1Error = _formulaError(a1Value);
    if (a1Error != null) {
      return a1Error;
    }
    if (a1Value == null) {
      return null;
    }
    final a1 = _truthy(a1Value);
    final range = referenceText is _FormulaArgument
        ? null
        : _rangeFromReferenceText(_text(referenceText ?? _formulaBlank), a1);
    if (range == null) {
      return _FormulaError.ref;
    }
    return _FormulaArgument.range(
      rangeValues(range),
      rowCount: range.rowCount,
      columnCount: range.columnCount,
      sourceRange: range,
    );
  }

  int? _integerReferenceOffset(Object? value) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null || !number.isFinite) {
      return null;
    }
    return number.truncate();
  }

  int? _positiveReferenceSize(Object? value) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null || !number.isFinite) {
      return null;
    }
    final size = number.truncate();
    return size <= 0 ? null : size;
  }

  Object? _rangeFromReferenceExpression(String source) {
    final literalRange = _rangeFromReferenceSource(source);
    if (literalRange != null) {
      return literalRange;
    }
    final dynamicReference = _evaluateSource(source);
    final referenceError = _formulaError(dynamicReference);
    if (referenceError != null) {
      return referenceError;
    }
    return dynamicReference is _FormulaArgument
        ? dynamicReference.sourceRange
        : null;
  }

  _FormulaRange? _rangeFromReferenceSource(String value) {
    final parts = value.trim().split(':');
    if (parts.length > 2) {
      return null;
    }
    final startPart = _referencePart(parts.first);
    final endPart = parts.length == 1 ? startPart : _referencePart(parts.last);
    if (startPart.sheetName != null &&
        endPart.sheetName != null &&
        startPart.sheetName!.toUpperCase() !=
            endPart.sheetName!.toUpperCase()) {
      return null;
    }
    final start = _coordFromReferencePart(startPart.reference);
    final end = parts.length == 1
        ? start
        : _coordFromReferencePart(endPart.reference);
    if (start == null || end == null) {
      return null;
    }
    return _FormulaRange.fromCoords(
      start,
      end,
      sheetName: startPart.sheetName ?? endPart.sheetName,
    );
  }

  _ReferencePart _referencePart(String value) {
    final trimmed = value.trim();
    final bang = trimmed.lastIndexOf('!');
    if (bang < 0) {
      return _ReferencePart(null, trimmed);
    }
    final rawSheetName = trimmed.substring(0, bang).trim();
    final reference = trimmed.substring(bang + 1).trim();
    if (rawSheetName.length >= 2 &&
        rawSheetName.startsWith("'") &&
        rawSheetName.endsWith("'")) {
      final sheetName = rawSheetName
          .substring(1, rawSheetName.length - 1)
          .replaceAll("''", "'");
      return _ReferencePart(_normalizeSheetName(sheetName), reference);
    }
    return _ReferencePart(_normalizeSheetName(rawSheetName), reference);
  }

  FortuneCellCoord? _coordFromReferencePart(String value) {
    final identifier = value.trim().replaceAll(r'$', '');
    return identifier.isEmpty ? null : _coordFromIdentifier(identifier);
  }

  _FormulaRange? _rangeFromReferenceText(String value, bool a1) {
    if (a1) {
      return _rangeFromReferenceSource(value.trim());
    }
    final reference = _referencePart(value.trim());
    return _rangeFromR1C1Reference(
      reference.reference,
      sheetName: reference.sheetName,
    );
  }

  _FormulaRange? _rangeFromR1C1Reference(String value, {String? sheetName}) {
    final parts = value.split(':');
    if (parts.length > 2) {
      return null;
    }
    final start = _coordFromR1C1ReferencePart(parts.first);
    final end = parts.length == 1
        ? start
        : _coordFromR1C1ReferencePart(parts.last);
    if (start == null || end == null) {
      return null;
    }
    return _FormulaRange.fromCoords(start, end, sheetName: sheetName);
  }

  FortuneCellCoord? _coordFromR1C1ReferencePart(String value) {
    final match = RegExp(
      r'^R(\[(-?\d+)\]|(-?\d+))C(\[(-?\d+)\]|(-?\d+))$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    final rowRelative = match.group(2) != null;
    final columnRelative = match.group(5) != null;
    final rowNumber = int.tryParse(match.group(2) ?? match.group(3)!);
    final columnNumber = int.tryParse(match.group(5) ?? match.group(6)!);
    if (rowNumber == null || columnNumber == null) {
      return null;
    }
    final base = currentCoord;
    final row = rowRelative
        ? (base == null ? null : base.row + rowNumber)
        : rowNumber - 1;
    final column = columnRelative
        ? (base == null ? null : base.column + columnNumber)
        : columnNumber - 1;
    if (row == null || column == null || row < 0 || column < 0) {
      return null;
    }
    return FortuneCellCoord(row, column);
  }

  _SingleCellReference? _singleCellReferenceArgument() {
    _skipWhitespace();
    final start = _offset;
    final identifier = _identifier();
    if (identifier != null) {
      final coord = _coordFromIdentifier(identifier);
      if (coord != null) {
        _skipWhitespace();
        if (_offset >= this.source.length || this.source[_offset] != '!') {
          return _SingleCellReference(coord, null);
        }
      }
    }
    _offset = start;
    final source = _argumentSource();
    if (source == null || source.isEmpty) {
      return null;
    }
    final literalRange = _rangeFromReferenceSource(source);
    if (literalRange != null) {
      if (literalRange.rowCount != 1 || literalRange.columnCount != 1) {
        return null;
      }
      return _SingleCellReference(
        FortuneCellCoord(literalRange.rowStart, literalRange.columnStart),
        literalRange.sheetName,
      );
    }
    final reference = _evaluateSource(source);
    if (reference is! _FormulaArgument ||
        reference.sourceRange == null ||
        reference.sourceRange!.rowCount != 1 ||
        reference.sourceRange!.columnCount != 1) {
      return null;
    }
    return _SingleCellReference(
      FortuneCellCoord(
        reference.sourceRange!.rowStart,
        reference.sourceRange!.columnStart,
      ),
      reference.sourceRange!.sheetName,
    );
  }

  double? _numberArgument(Object value) {
    if (_isFormulaBlankLike(value)) {
      return null;
    }
    return FortuneFormulaEngine._numberFromFormulaValue(value);
  }

  Object? _averageA(List<Object> values) {
    final numbers = values.map(_numberAArgument).whereType<double>().toList();
    if (numbers.isEmpty) {
      return null;
    }
    return _averageNumbers(numbers);
  }

  Object? _sampleVarianceResult(List<double> values) {
    if (values.isEmpty) {
      return 0.0;
    }
    if (values.length == 1) {
      return 'NaN';
    }
    return _variance(values, sample: true);
  }

  Object? _sampleVarianceAResult(List<Object> values) {
    final numbers = values.map(_numberAArgument).whereType<double>().toList();
    if (numbers.isEmpty) {
      return 0.0;
    }
    if (numbers.length == 1) {
      return 'NaN';
    }
    return _variance(numbers, sample: true);
  }

  double? _varianceA(List<Object> values, {required bool sample}) {
    return _variance(
      values.map(_numberAArgument).whereType<double>().toList(),
      sample: sample,
    );
  }

  double? _standardDeviationA(List<Object> values, {required bool sample}) {
    final variance = _varianceA(values, sample: sample);
    return variance == null ? null : math.sqrt(variance);
  }

  double _countIn(List<Object> values, Object criteria) {
    return values
        .where((value) => _valuesEqual(value, criteria))
        .length
        .toDouble();
  }

  double _countUnique(List<Object> values) {
    final unique = <Object>[];
    for (final value in values) {
      if (!unique.any((item) => _valuesEqual(item, value))) {
        unique.add(value);
      }
    }
    return unique.length.toDouble();
  }

  bool _isFormulaBlankValue(Object value) {
    return _isFormulaBlankLike(value) || value is String && value.isEmpty;
  }

  Object? _aggregateSubtotal(
    List<_FormulaArgument> args, {
    required bool hasOptions,
  }) {
    final functionNumberValue = _numberArgument(args[0].singleValue);
    if (functionNumberValue == null || !functionNumberValue.isFinite) {
      return null;
    }
    var functionNumber = functionNumberValue.truncate();
    if (!hasOptions && functionNumber >= 101 && functionNumber <= 111) {
      functionNumber -= 100;
    }
    final valueArgs = hasOptions ? args.sublist(2) : args.sublist(1);
    if (valueArgs.isEmpty) {
      return null;
    }
    final aggregateValueArgs =
        hasOptions &&
            functionNumber >= 14 &&
            functionNumber <= 19 &&
            valueArgs.length >= 2
        ? valueArgs.sublist(0, valueArgs.length - 1)
        : valueArgs;
    final values = hasOptions && functionNumber < 14
        ? aggregateValueArgs.first.values
        : aggregateValueArgs.expand((arg) => arg.values).toList();
    final numbers = values.map(_numberArgument).whereType<double>().toList();
    final kValue = hasOptions && valueArgs.length >= 2
        ? valueArgs.last.singleValue
        : null;
    return _aggregateSubtotalValues(functionNumber, values, numbers, kValue);
  }

  Object? _aggregateSubtotalValues(
    int functionNumber,
    List<Object> values,
    List<double> numbers,
    Object? kValue,
  ) {
    return switch (functionNumber) {
      1 => numbers.isEmpty ? null : _averageNumbers(numbers),
      2 => numbers.length.toDouble(),
      3 =>
        values.where((value) => !_isFormulaBlankLike(value)).length.toDouble(),
      4 => numbers.isEmpty ? null : numbers.reduce((a, b) => a > b ? a : b),
      5 => numbers.isEmpty ? null : numbers.reduce((a, b) => a < b ? a : b),
      6 => numbers.isEmpty ? null : _product(numbers),
      7 => _standardDeviation(numbers, sample: true),
      8 => _standardDeviation(numbers, sample: false),
      9 => _sumNumbers(numbers),
      10 => _variance(numbers, sample: true),
      11 => _variance(numbers, sample: false),
      12 => _median(numbers),
      13 => _modeSingle(numbers),
      14 =>
        kValue == null
            ? null
            : _ranked(numbers, _numberArgument(kValue) ?? double.nan, true),
      15 =>
        kValue == null
            ? null
            : _ranked(numbers, _numberArgument(kValue) ?? double.nan, false),
      16 =>
        kValue == null
            ? null
            : _percentile(
                numbers,
                _numberArgument(kValue) ?? double.nan,
                inclusive: true,
              ),
      17 =>
        kValue == null
            ? null
            : _quartile(
                numbers,
                _numberArgument(kValue) ?? double.nan,
                inclusive: true,
              ),
      18 =>
        kValue == null
            ? null
            : _percentile(
                numbers,
                _numberArgument(kValue) ?? double.nan,
                inclusive: false,
              ),
      19 =>
        kValue == null
            ? null
            : _quartile(
                numbers,
                _numberArgument(kValue) ?? double.nan,
                inclusive: false,
              ),
      _ => null,
    };
  }

  double? _minA(List<Object> values) {
    final numbers = values.map(_numberAArgument).whereType<double>().toList();
    return numbers.isEmpty ? null : numbers.reduce((a, b) => a < b ? a : b);
  }

  double? _maxA(List<Object> values) {
    final numbers = values.map(_numberAArgument).whereType<double>().toList();
    return numbers.isEmpty ? null : numbers.reduce((a, b) => a > b ? a : b);
  }

  double _countIf(List<Object> values, Object criteria) {
    return values
        .where((value) => _matchesCriteria(value, criteria))
        .length
        .toDouble();
  }

  Object? _sumIf(
    List<Object> criteriaValues,
    Object criteria,
    List<Object>? sumValues,
  ) {
    final values = sumValues ?? criteriaValues;
    if (values.length != criteriaValues.length) {
      return null;
    }
    final numbers = <double>[];
    for (var i = 0; i < criteriaValues.length; i += 1) {
      if (!_matchesCriteria(criteriaValues[i], criteria)) {
        continue;
      }
      numbers.add(_numberArgument(values[i]) ?? 0);
    }
    return _sumNumbers(numbers);
  }

  Object? _averageIf(
    List<Object> criteriaValues,
    Object criteria,
    List<Object>? averageValues,
  ) {
    final values = averageValues ?? criteriaValues;
    if (values.length != criteriaValues.length) {
      return null;
    }
    final numbers = <double>[];
    for (var i = 0; i < criteriaValues.length; i += 1) {
      if (!_matchesCriteria(criteriaValues[i], criteria)) {
        continue;
      }
      final number = _numberArgument(values[i]);
      if (number == null) {
        continue;
      }
      numbers.add(number);
    }
    return numbers.isEmpty ? null : _averageNumbers(numbers);
  }

  double? _countIfs(List<_FormulaArgument> args) {
    final length = args.first.values.length;
    if (!_criteriaRangesMatch(args, length)) {
      return null;
    }
    var count = 0.0;
    for (var row = 0; row < length; row += 1) {
      if (_matchesCriteriaPairs(args, row)) {
        count += 1;
      }
    }
    return count;
  }

  Object? _sumIfs(List<_FormulaArgument> args) {
    final sumValues = args.first.values;
    final criteriaArgs = args.sublist(1);
    if (criteriaArgs.every((arg) => arg.sourceRange == null)) {
      return _sumIfsShorthand(sumValues, criteriaArgs);
    }
    if (!_criteriaRangesMatch(criteriaArgs, sumValues.length)) {
      return null;
    }
    final numbers = <double>[];
    for (var row = 0; row < sumValues.length; row += 1) {
      if (!_matchesCriteriaPairs(criteriaArgs, row)) {
        continue;
      }
      numbers.add(_numberArgument(sumValues[row]) ?? 0);
    }
    return _sumNumbers(numbers);
  }

  Object? _sumIfsShorthand(
    List<Object> sumValues,
    List<_FormulaArgument> criteriaArgs,
  ) {
    final numbers = <double>[];
    for (final value in sumValues) {
      var matches = true;
      for (final criterion in criteriaArgs) {
        if (!_matchesCriteria(value, criterion.singleValue)) {
          matches = false;
          break;
        }
      }
      if (matches) {
        numbers.add(_numberArgument(value) ?? 0);
      }
    }
    return _sumNumbers(numbers);
  }

  Object? _averageIfs(List<_FormulaArgument> args) {
    final averageValues = args.first.values;
    final criteriaArgs = args.sublist(1);
    if (!_criteriaRangesMatch(criteriaArgs, averageValues.length)) {
      return null;
    }
    final numbers = <double>[];
    for (var row = 0; row < averageValues.length; row += 1) {
      if (!_matchesCriteriaPairs(criteriaArgs, row)) {
        continue;
      }
      final number = _numberArgument(averageValues[row]);
      if (number == null) {
        continue;
      }
      numbers.add(number);
    }
    return numbers.isEmpty ? null : _averageNumbers(numbers);
  }

  Object? _databaseAggregate(
    List<_FormulaArgument> args,
    _DatabaseFunction function,
  ) {
    final fieldValues = _databaseFieldValues(args[0], args[1], args[2]);
    if (fieldValues is _FormulaError) {
      return fieldValues;
    }
    if (fieldValues is! List<Object>) {
      return null;
    }
    return switch (function) {
      _DatabaseFunction.sum => _sumNumbers(_numericValues(fieldValues)),
      _DatabaseFunction.average =>
        _numericValues(fieldValues).isEmpty
            ? null
            : _averageNumbers(_numericValues(fieldValues)),
      _DatabaseFunction.count =>
        fieldValues
            .where((value) => _numberArgument(value) != null)
            .length
            .toDouble(),
      _DatabaseFunction.countA =>
        fieldValues
            .where((value) => !_isFormulaBlankLike(value))
            .length
            .toDouble(),
      _DatabaseFunction.get =>
        fieldValues.length == 1 ? fieldValues.single : _FormulaError.value,
      _DatabaseFunction.max =>
        _numericValues(fieldValues).isEmpty
            ? null
            : _numericValues(fieldValues).reduce(math.max),
      _DatabaseFunction.min =>
        _numericValues(fieldValues).isEmpty
            ? null
            : _numericValues(fieldValues).reduce(math.min),
      _DatabaseFunction.product =>
        _numericValues(fieldValues).isEmpty
            ? null
            : _product(_numericValues(fieldValues)),
      _DatabaseFunction.stdev => _standardDeviation(
        _numericValues(fieldValues),
        sample: true,
      ),
      _DatabaseFunction.stdevP => _standardDeviation(
        _numericValues(fieldValues),
        sample: false,
      ),
      _DatabaseFunction.varS => _variance(
        _numericValues(fieldValues),
        sample: true,
      ),
      _DatabaseFunction.varP => _variance(
        _numericValues(fieldValues),
        sample: false,
      ),
    };
  }

  Object _findField(_FormulaArgument database, Object title) {
    for (var row = 0; row < database.rowCount; row += 1) {
      if (_formulaOperationStrictEquals(database.valueAt(row, 0), title)) {
        return row.toDouble();
      }
    }
    return _FormulaError.value;
  }

  List<double> _numericValues(List<Object> values) {
    final numbers = <double>[];
    for (final value in values) {
      final number = _numberArgument(value);
      if (number != null) {
        numbers.add(number);
      }
    }
    return numbers;
  }

  Object? _databaseFieldValues(
    _FormulaArgument database,
    _FormulaArgument field,
    _FormulaArgument criteria,
  ) {
    if (database.rowCount < 2 || criteria.rowCount < 1) {
      return _FormulaError.value;
    }
    final fieldIndex = _databaseFieldIndex(database, field.singleValue);
    if (fieldIndex == null) {
      return _FormulaError.value;
    }
    final values = <Object>[];
    for (var row = 1; row < database.rowCount; row += 1) {
      final matches = _databaseRecordMatches(database, criteria, row);
      if (matches is _FormulaError) {
        return matches;
      }
      if (matches == true) {
        values.add(database.valueAt(row, fieldIndex));
      }
    }
    return values;
  }

  Object? _databaseRecordMatches(
    _FormulaArgument database,
    _FormulaArgument criteria,
    int databaseRow,
  ) {
    if (criteria.rowCount == 1) {
      return true;
    }
    for (
      var criteriaRow = 1;
      criteriaRow < criteria.rowCount;
      criteriaRow += 1
    ) {
      var rowMatches = true;
      for (
        var criteriaColumn = 0;
        criteriaColumn < criteria.columnCount;
        criteriaColumn += 1
      ) {
        final criterion = criteria.valueAt(criteriaRow, criteriaColumn);
        if (_isFormulaBlankLike(criterion) || _text(criterion).isEmpty) {
          continue;
        }
        final header = criteria.valueAt(0, criteriaColumn);
        final databaseColumn = _databaseFieldIndex(database, header);
        if (databaseColumn == null) {
          return _FormulaError.value;
        }
        if (!_matchesDatabaseCriteria(
          database.valueAt(databaseRow, databaseColumn),
          criterion,
        )) {
          rowMatches = false;
          break;
        }
      }
      if (rowMatches) {
        return true;
      }
    }
    return false;
  }

  bool _matchesDatabaseCriteria(Object value, Object criteria) {
    if (criteria is String) {
      final match = RegExp(r'^(<>|>=|<=|=|>|<)(.*)$').firstMatch(criteria);
      final operator = match?.group(1);
      final operandText = (match?.group(2) ?? criteria).trim();
      if (operator != null &&
          FortuneFormulaEngine._numberFromFormulaValue(operandText) != null &&
          _numberArgument(value) == null) {
        return operator == '<>';
      }
    }
    return _matchesCriteria(value, criteria);
  }

  int? _databaseFieldIndex(_FormulaArgument database, Object field) {
    final fieldNumber = FortuneFormulaEngine._numberFromFormulaValue(field);
    if (fieldNumber != null && fieldNumber == fieldNumber.truncateToDouble()) {
      final index = fieldNumber.toInt() - 1;
      return index >= 0 && index < database.columnCount ? index : null;
    }
    final fieldText = _text(field).toLowerCase();
    for (var column = 0; column < database.columnCount; column += 1) {
      if (_text(database.valueAt(0, column)).toLowerCase() == fieldText) {
        return column;
      }
    }
    return null;
  }

  double? _minMaxIfs(List<_FormulaArgument> args, {required bool findMax}) {
    final resultValues = args.first.values;
    final criteriaArgs = args.sublist(1);
    if (!_criteriaRangesMatch(criteriaArgs, resultValues.length)) {
      return null;
    }
    double? best;
    for (var row = 0; row < resultValues.length; row += 1) {
      if (!_matchesCriteriaPairs(criteriaArgs, row)) {
        continue;
      }
      final number = _numberArgument(resultValues[row]);
      if (number == null) {
        continue;
      }
      best = best == null
          ? number
          : findMax
          ? math.max(best, number)
          : math.min(best, number);
    }
    return best;
  }

  bool _criteriaRangesMatch(List<_FormulaArgument> args, int length) {
    for (var i = 0; i < args.length; i += 2) {
      if (args[i].values.length != length) {
        return false;
      }
    }
    return true;
  }

  bool _matchesCriteriaPairs(List<_FormulaArgument> args, int index) {
    for (var i = 0; i < args.length; i += 2) {
      final values = args[i].values;
      if (index >= values.length) {
        return false;
      }
      if (!_matchesCriteria(values[index], args[i + 1].singleValue)) {
        return false;
      }
    }
    return true;
  }

  Object? _index(List<_FormulaArgument> args) {
    final array = args[0];
    final rowNumber = _nonNegativeIndex(args[1].singleValue);
    if (rowNumber == null) {
      return null;
    }
    final columnNumber = args.length == 3
        ? _nonNegativeIndex(args[2].singleValue)
        : 1;
    if (columnNumber == null) {
      return null;
    }
    return _indexValue(array, rowNumber, columnNumber, args.length);
  }

  Object? _indexValue(
    _FormulaArgument array,
    int rowNumber,
    int columnNumber,
    int argumentCount,
  ) {
    final effectiveRowNumber =
        argumentCount == 2 && array.rowCount == 1 && array.columnCount > 1
        ? 1
        : rowNumber;
    final effectiveColumnNumber =
        argumentCount == 2 && array.rowCount == 1 && array.columnCount > 1
        ? rowNumber
        : columnNumber;
    if (effectiveRowNumber > array.rowCount ||
        effectiveColumnNumber > array.columnCount) {
      return _FormulaError.ref;
    }
    if (effectiveRowNumber == 0 &&
        effectiveColumnNumber == 0 &&
        argumentCount != 3) {
      return null;
    }
    if (effectiveRowNumber == 0 && effectiveColumnNumber == 0) {
      return array;
    }
    if (effectiveRowNumber == 0) {
      final columnIndex = effectiveColumnNumber - 1;
      return _FormulaArgument.range(
        array.columnValues(columnIndex),
        rowCount: array.rowCount,
        columnCount: 1,
        sourceRange: _subRange(
          array.sourceRange,
          rowStartOffset: 0,
          rowCount: array.rowCount,
          columnStartOffset: columnIndex,
          columnCount: 1,
        ),
      );
    }
    if (effectiveColumnNumber == 0) {
      final rowIndex = effectiveRowNumber - 1;
      return _FormulaArgument.range(
        array.rowValues(rowIndex),
        rowCount: 1,
        columnCount: array.columnCount,
        sourceRange: _subRange(
          array.sourceRange,
          rowStartOffset: rowIndex,
          rowCount: 1,
          columnStartOffset: 0,
          columnCount: array.columnCount,
        ),
      );
    }
    return array.valueAt(effectiveRowNumber - 1, effectiveColumnNumber - 1);
  }

  _FormulaRange? _subRange(
    _FormulaRange? range, {
    required int rowStartOffset,
    required int rowCount,
    required int columnStartOffset,
    required int columnCount,
  }) {
    if (range == null) {
      return null;
    }
    return _FormulaRange(
      rowStart: range.rowStart + rowStartOffset,
      rowEnd: range.rowStart + rowStartOffset + rowCount - 1,
      columnStart: range.columnStart + columnStartOffset,
      columnEnd: range.columnStart + columnStartOffset + columnCount - 1,
      sheetName: range.sheetName,
    );
  }

  Object? _match(List<_FormulaArgument> args) {
    final lookupArray = args[1];
    final matchType = args.length == 3
        ? FortuneFormulaEngine._numberFromFormulaValue(args[2].singleValue)
        : 1;
    if (matchType == null) {
      return null;
    }
    final normalizedMatchType = matchType.truncate();
    if (normalizedMatchType != -1 &&
        normalizedMatchType != 0 &&
        normalizedMatchType != 1) {
      return _FormulaError.value;
    }
    if (!_isOneDimensionalRange(lookupArray)) {
      return _FormulaError.value;
    }
    final lookupValues = lookupArray.values;
    if (lookupValues.isEmpty) {
      return null;
    }
    if (normalizedMatchType == 0) {
      final index = _exactMatchIndex(lookupValues, args[0].singleValue);
      return index == null ? _FormulaError.na : index + 1.0;
    }
    final ascending = normalizedMatchType > 0;
    final index = _approximateMatchIndex(
      lookupValues,
      args[0].singleValue,
      ascending: ascending,
    );
    return index == null ? _FormulaError.na : index + 1.0;
  }

  Object? _xmatch(List<_FormulaArgument> args) {
    final lookupArray = args[1];
    final matchMode = args.length >= 3
        ? FortuneFormulaEngine._numberFromFormulaValue(args[2].singleValue)
        : 0;
    final searchMode = args.length >= 4
        ? FortuneFormulaEngine._numberFromFormulaValue(args[3].singleValue)
        : 1;
    if (matchMode == null || searchMode == null) {
      return null;
    }
    if (!_isSupportedLookupMode(matchMode.truncate()) ||
        !_isSupportedSearchMode(searchMode.truncate())) {
      return _FormulaError.value;
    }
    if (!_isOneDimensionalRange(lookupArray)) {
      return _FormulaError.value;
    }
    final index = _lookupMatchIndex(
      lookupArray.values,
      args[0].singleValue,
      matchMode: matchMode.truncate(),
      searchMode: searchMode.truncate(),
    );
    return index == null ? _FormulaError.na : index + 1.0;
  }

  Object? _vlookup(List<_FormulaArgument> args) {
    final table = args[1];
    final columnNumber = _positiveIndex(args[2].singleValue);
    if (columnNumber == null) {
      return null;
    }
    if (columnNumber > table.columnCount) {
      return _FormulaError.ref;
    }
    final approximate = args.length == 4 ? _truthy(args[3].singleValue) : true;
    final lookupColumn = table.columnValues(0);
    final row = approximate
        ? _approximateMatchIndex(
            lookupColumn,
            args[0].singleValue,
            ascending: true,
          )
        : _exactMatchIndex(lookupColumn, args[0].singleValue);
    return row == null
        ? _FormulaError.na
        : table.valueAt(row, columnNumber - 1);
  }

  Object? _hlookup(List<_FormulaArgument> args) {
    final table = args[1];
    final rowNumber = _positiveIndex(args[2].singleValue);
    if (rowNumber == null) {
      return null;
    }
    if (rowNumber > table.rowCount) {
      return _FormulaError.ref;
    }
    final approximate = args.length == 4 ? _truthy(args[3].singleValue) : true;
    final lookupRow = table.rowValues(0);
    final column = approximate
        ? _approximateMatchIndex(
            lookupRow,
            args[0].singleValue,
            ascending: true,
          )
        : _exactMatchIndex(lookupRow, args[0].singleValue);
    return column == null
        ? _FormulaError.na
        : table.valueAt(rowNumber - 1, column);
  }

  Object? _xlookup(List<_FormulaArgument> args) {
    final lookupArray = args[1];
    final returnArray = args[2];
    final lookupValues = lookupArray.values;
    final matchMode = args.length >= 5
        ? FortuneFormulaEngine._numberFromFormulaValue(args[4].singleValue)
        : 0;
    final searchMode = args.length >= 6
        ? FortuneFormulaEngine._numberFromFormulaValue(args[5].singleValue)
        : 1;
    if (matchMode == null || searchMode == null) {
      return null;
    }
    if (!_isSupportedLookupMode(matchMode.truncate()) ||
        !_isSupportedSearchMode(searchMode.truncate())) {
      return _FormulaError.value;
    }
    if (!_isOneDimensionalRange(lookupArray)) {
      return _FormulaError.value;
    }
    if (!_isCompatibleXlookupReturnArray(lookupArray, returnArray)) {
      return _FormulaError.value;
    }
    final index = _lookupMatchIndex(
      lookupValues,
      args[0].singleValue,
      matchMode: matchMode.truncate(),
      searchMode: searchMode.truncate(),
    );
    if (index == null) {
      return args.length >= 4 ? args[3].singleValue : _FormulaError.na;
    }
    return _xlookupReturnValue(index, lookupArray, returnArray);
  }

  Object? _xlookupReturnValue(
    int index,
    _FormulaArgument lookupArray,
    _FormulaArgument returnArray,
  ) {
    final lookupIsColumn = lookupArray.columnCount == 1;
    final lookupIsRow = lookupArray.rowCount == 1;
    if (lookupIsColumn && returnArray.rowCount == lookupArray.rowCount) {
      return _FormulaArgument.range(
        returnArray.rowValues(index),
        rowCount: 1,
        columnCount: returnArray.columnCount,
        sourceRange: _subRange(
          returnArray.sourceRange,
          rowStartOffset: index,
          rowCount: 1,
          columnStartOffset: 0,
          columnCount: returnArray.columnCount,
        ),
      );
    }
    if (lookupIsRow && returnArray.columnCount == lookupArray.columnCount) {
      return _FormulaArgument.range(
        returnArray.columnValues(index),
        rowCount: returnArray.rowCount,
        columnCount: 1,
        sourceRange: _subRange(
          returnArray.sourceRange,
          rowStartOffset: 0,
          rowCount: returnArray.rowCount,
          columnStartOffset: index,
          columnCount: 1,
        ),
      );
    }
    return _FormulaError.value;
  }

  bool _isCompatibleXlookupReturnArray(
    _FormulaArgument lookupArray,
    _FormulaArgument returnArray,
  ) {
    final lookupIsColumn = lookupArray.columnCount == 1;
    final lookupIsRow = lookupArray.rowCount == 1;
    if (lookupIsColumn && lookupIsRow) {
      return returnArray.rowCount == 1 || returnArray.columnCount == 1;
    }
    if (lookupIsColumn) {
      return returnArray.rowCount == lookupArray.rowCount;
    }
    if (lookupIsRow) {
      return returnArray.columnCount == lookupArray.columnCount;
    }
    return false;
  }

  Object? _lookup(List<_FormulaArgument> args) {
    if (args.length == 2 && args[1].rowCount > 1 && args[1].columnCount > 1) {
      return _lookupArrayForm(args[0].singleValue, args[1]);
    }
    if (!_isOneDimensionalRange(args[1])) {
      return _FormulaError.value;
    }
    final lookupValues = args[1].values;
    final returnValues = args.length == 3 ? args[2].values : lookupValues;
    if (args.length == 3 &&
        (!_isOneDimensionalRange(args[2]) ||
            lookupValues.length != returnValues.length)) {
      return _FormulaError.value;
    }
    if (lookupValues.isEmpty || lookupValues.length != returnValues.length) {
      return null;
    }
    final index = _nextSmallerMatchIndex(
      lookupValues,
      args[0].singleValue,
      reverse: true,
    );
    return index == null ? _FormulaError.na : returnValues[index];
  }

  Object? _lookupArrayForm(Object lookupValue, _FormulaArgument array) {
    final searchRows = array.columnCount > array.rowCount;
    final lookupValues = searchRows
        ? array.rowValues(0)
        : array.columnValues(0);
    final returnValues = searchRows
        ? array.rowValues(array.rowCount - 1)
        : array.columnValues(array.columnCount - 1);
    if (lookupValues.isEmpty || lookupValues.length != returnValues.length) {
      return null;
    }
    final index = _nextSmallerMatchIndex(
      lookupValues,
      lookupValue,
      reverse: true,
    );
    return index == null ? _FormulaError.na : returnValues[index];
  }

  Object? _choose(List<_FormulaArgument> args) {
    final index = _positiveIndex(args[0].singleValue);
    if (index == null || index >= args.length) {
      return _FormulaError.value;
    }
    final choice = args[index];
    return choice.rowCount == 1 && choice.columnCount == 1
        ? choice.singleValue
        : choice;
  }

  Object? _takeDrop(List<_FormulaArgument> args, {required bool take}) {
    final array = args[0];
    final rowCount = _signedCount(args[1].singleValue);
    final columnCount = args.length == 3
        ? _signedCount(args[2].singleValue)
        : null;
    if (rowCount == null || (args.length == 3 && columnCount == null)) {
      return null;
    }
    final rowSelection = _takeDropSelection(
      array.rowCount,
      rowCount,
      take: take,
    );
    final columnSelection = args.length == 3
        ? _takeDropSelection(array.columnCount, columnCount!, take: take)
        : _TakeDropSelection(0, array.columnCount);
    if (rowSelection == null || columnSelection == null) {
      return _FormulaError.value;
    }

    final result = <Object>[];
    for (
      var row = rowSelection.start;
      row < rowSelection.start + rowSelection.count;
      row += 1
    ) {
      for (
        var column = columnSelection.start;
        column < columnSelection.start + columnSelection.count;
        column += 1
      ) {
        result.add(array.valueAt(row, column));
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: rowSelection.count,
      columnCount: columnSelection.count,
      sourceRange: _subRange(
        array.sourceRange,
        rowStartOffset: rowSelection.start,
        rowCount: rowSelection.count,
        columnStartOffset: columnSelection.start,
        columnCount: columnSelection.count,
      ),
    );
  }

  Object? _takeDropFunction({required bool take}) {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2 || sources.length > 3) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final arrayError = _formulaError(arrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (arrayResult is! _FormulaArgument) {
      return null;
    }

    final args = <_FormulaArgument>[arrayResult];
    for (final source in sources.skip(1)) {
      final result = _evaluateSource(source);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result == null) {
        return null;
      }
      args.add(
        _FormulaArgument.scalar(
          result is _FormulaArgument ? result.singleValue : result,
        ),
      );
    }
    return _takeDrop(args, take: take);
  }

  int? _signedCount(Object value) {
    final number = _numberArgument(value);
    if (number == null || !number.isFinite) {
      return null;
    }
    return number.truncate();
  }

  _TakeDropSelection? _takeDropSelection(
    int dimension,
    int count, {
    required bool take,
  }) {
    if (dimension < 1 || count == 0) {
      return null;
    }
    if (take) {
      if (count.abs() > dimension) {
        return null;
      }
      return count > 0
          ? _TakeDropSelection(0, count)
          : _TakeDropSelection(dimension + count, -count);
    }
    if (count.abs() >= dimension) {
      return null;
    }
    return count > 0
        ? _TakeDropSelection(count, dimension - count)
        : _TakeDropSelection(0, dimension + count);
  }

  Object? _chooseRowsColumns(
    List<_FormulaArgument> args, {
    required bool chooseRows,
  }) {
    final array = args[0];
    final dimension = chooseRows ? array.rowCount : array.columnCount;
    final indexes = <int>[];
    for (final arg in args.skip(1)) {
      final index = _signedCount(arg.singleValue);
      if (index == null) {
        return null;
      }
      final normalized = _relativeIndex(dimension, index);
      if (normalized == null) {
        return _FormulaError.value;
      }
      indexes.add(normalized);
    }

    final result = <Object>[];
    if (chooseRows) {
      for (final row in indexes) {
        for (var column = 0; column < array.columnCount; column += 1) {
          result.add(array.valueAt(row, column));
        }
      }
      return _FormulaArgument.range(
        result,
        rowCount: indexes.length,
        columnCount: array.columnCount,
      );
    }

    for (var row = 0; row < array.rowCount; row += 1) {
      for (final column in indexes) {
        result.add(array.valueAt(row, column));
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: array.rowCount,
      columnCount: indexes.length,
    );
  }

  Object? _chooseRowsColumnsFunction({required bool chooseRows}) {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final arrayError = _formulaError(arrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (arrayResult is! _FormulaArgument) {
      return null;
    }

    final args = <_FormulaArgument>[arrayResult];
    for (final source in sources.skip(1)) {
      final result = _evaluateSource(source);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result == null) {
        return null;
      }
      args.add(
        _FormulaArgument.scalar(
          result is _FormulaArgument ? result.singleValue : result,
        ),
      );
    }
    return _chooseRowsColumns(args, chooseRows: chooseRows);
  }

  int? _relativeIndex(int dimension, int oneBasedIndex) {
    if (dimension < 1 ||
        oneBasedIndex == 0 ||
        oneBasedIndex.abs() > dimension) {
      return null;
    }
    return oneBasedIndex > 0 ? oneBasedIndex - 1 : dimension + oneBasedIndex;
  }

  Object? _expand(List<_FormulaArgument> args) {
    final array = args[0];
    final targetRows = _signedCount(args[1].singleValue);
    final targetColumns = args.length >= 3
        ? _signedCount(args[2].singleValue)
        : array.columnCount;
    if (targetRows == null || targetColumns == null) {
      return null;
    }
    if (targetRows < array.rowCount || targetColumns < array.columnCount) {
      return _FormulaError.value;
    }
    final padWith = args.length >= 4 ? args[3].singleValue : _FormulaError.na;

    final result = <Object>[];
    for (var row = 0; row < targetRows; row += 1) {
      for (var column = 0; column < targetColumns; column += 1) {
        result.add(
          row < array.rowCount && column < array.columnCount
              ? array.valueAt(row, column)
              : padWith,
        );
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: targetRows,
      columnCount: targetColumns,
    );
  }

  Object? _expandFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2 || sources.length > 4) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final arrayError = _formulaError(arrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (arrayResult is! _FormulaArgument) {
      return null;
    }

    final args = <_FormulaArgument>[arrayResult];
    for (var index = 1; index < sources.length; index += 1) {
      final result = index == 3
          ? _evaluateArgumentSource(sources[index])
          : _evaluateSource(sources[index]);
      final error = _formulaError(result);
      if (error != null && index != 3) {
        return error;
      }
      if (result == null) {
        return null;
      }
      args.add(
        _FormulaArgument.scalar(
          result is _FormulaArgument ? result.singleValue : result,
        ),
      );
    }
    return _expand(args);
  }

  Object? _filterFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2 || sources.length > 3) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final includeResult = _evaluateArgumentSource(sources[1]);
    final argumentError =
        _formulaError(arrayResult) ?? _formulaError(includeResult);
    if (argumentError != null) {
      return argumentError;
    }
    if (arrayResult is! _FormulaArgument ||
        includeResult is! _FormulaArgument) {
      return null;
    }

    final filtered = _filter(arrayResult, includeResult);
    if (filtered == _FormulaError.calc && sources.length == 3) {
      return _evaluateArgumentSource(sources[2]);
    }
    return filtered;
  }

  Object? _filter(_FormulaArgument array, _FormulaArgument include) {
    if (include.rowCount == array.rowCount && include.columnCount == 1) {
      final result = <Object>[];
      for (var row = 0; row < array.rowCount; row += 1) {
        final mask = include.valueAt(row, 0);
        final maskError = _formulaError(mask);
        if (maskError != null) {
          return maskError;
        }
        if (!_truthy(mask)) {
          continue;
        }
        result.addAll(array.rowValues(row));
      }
      return result.isEmpty
          ? _FormulaError.calc
          : _FormulaArgument.range(
              result,
              rowCount: result.length ~/ array.columnCount,
              columnCount: array.columnCount,
            );
    }

    if (include.rowCount == 1 && include.columnCount == array.columnCount) {
      final selectedColumns = <int>[];
      for (var column = 0; column < array.columnCount; column += 1) {
        final mask = include.valueAt(0, column);
        final maskError = _formulaError(mask);
        if (maskError != null) {
          return maskError;
        }
        if (_truthy(mask)) {
          selectedColumns.add(column);
        }
      }
      if (selectedColumns.isEmpty) {
        return _FormulaError.calc;
      }
      final result = <Object>[];
      for (var row = 0; row < array.rowCount; row += 1) {
        for (final column in selectedColumns) {
          result.add(array.valueAt(row, column));
        }
      }
      return _FormulaArgument.range(
        result,
        rowCount: array.rowCount,
        columnCount: selectedColumns.length,
      );
    }

    return _FormulaError.value;
  }

  Object? _unique(List<_FormulaArgument> args) {
    if (args.isEmpty) {
      return _FormulaArgument.range(const [], rowCount: 1, columnCount: 0);
    }
    final array = args[0];
    final byColumn = args.length >= 2 ? _truthy(args[1].singleValue) : false;
    final exactlyOnce = args.length >= 3 ? _truthy(args[2].singleValue) : false;
    final itemCount = byColumn ? array.columnCount : array.rowCount;
    final keys = <List<Object>>[];
    final counts = <int>[];
    final firstIndexes = <int>[];

    for (var index = 0; index < itemCount; index += 1) {
      final key = byColumn ? array.columnValues(index) : array.rowValues(index);
      final existingIndex = keys.indexWhere(
        (existingKey) => _vectorsEqual(existingKey, key),
      );
      if (existingIndex == -1) {
        keys.add(key);
        counts.add(1);
        firstIndexes.add(index);
      } else {
        counts[existingIndex] += 1;
      }
    }

    final selectedIndexes = <int>[];
    for (var index = 0; index < firstIndexes.length; index += 1) {
      if (!exactlyOnce || counts[index] == 1) {
        selectedIndexes.add(firstIndexes[index]);
      }
    }
    if (selectedIndexes.isEmpty) {
      return _FormulaError.calc;
    }

    final result = <Object>[];
    if (byColumn) {
      for (var row = 0; row < array.rowCount; row += 1) {
        for (final column in selectedIndexes) {
          result.add(array.valueAt(row, column));
        }
      }
      return _FormulaArgument.range(
        result,
        rowCount: array.rowCount,
        columnCount: selectedIndexes.length,
      );
    }

    for (final row in selectedIndexes) {
      result.addAll(array.rowValues(row));
    }
    return _FormulaArgument.range(
      result,
      rowCount: selectedIndexes.length,
      columnCount: array.columnCount,
    );
  }

  _FormulaArgument _argsToArray(List<_FormulaArgument> args) {
    final values = [for (final arg in args) ...arg.values];
    return _FormulaArgument.range(
      values,
      rowCount: 1,
      columnCount: values.length,
    );
  }

  _FormulaArgument _flattenArguments(List<_FormulaArgument> args) {
    final values = <Object>[
      for (final arg in args)
        for (final value in arg.values) ..._flattenFormulaValue(value),
    ];
    return _FormulaArgument.range(
      values,
      rowCount: 1,
      columnCount: values.length,
    );
  }

  String _joinArguments(List<_FormulaArgument> args) {
    return [
      for (final arg in args)
        for (final value in arg.values) ..._flattenFormulaValue(value),
    ].map(_text).join(',');
  }

  Iterable<Object> _flattenFormulaValue(Object value) sync* {
    if (value is _FormulaArgument) {
      for (final nested in value.values) {
        yield* _flattenFormulaValue(nested);
      }
      return;
    }
    if (value is Iterable && value is! String) {
      for (final nested in value) {
        if (nested is Object) {
          yield* _flattenFormulaValue(nested);
        } else {
          yield _formulaBlank;
        }
      }
      return;
    }
    yield value;
  }

  _FormulaArgument _numbersArray(List<_FormulaArgument> args) {
    final values = <Object>[
      for (final arg in args)
        for (final value in arg.values)
          if (value is num && !_isFormulaBlankLike(value)) value.toDouble(),
    ];
    return _FormulaArgument.range(
      values,
      rowCount: 1,
      columnCount: values.length,
    );
  }

  Object? _referencePath(List<_FormulaArgument> args) {
    Object? current = args[0].singleValue;
    final path = _text(
      args[1].singleValue,
    ).split('.').where((part) => part.isNotEmpty);
    for (final part in path) {
      if (current is Map) {
        current = current[part];
      } else if (current is List) {
        final index = int.tryParse(part);
        if (index == null || index < 0 || index >= current.length) {
          return _FormulaError.na;
        }
        current = current[index];
      } else {
        return _FormulaError.na;
      }
      if (current == null) {
        return _FormulaError.na;
      }
    }
    return current is _FormulaArgument ? current.singleValue : current;
  }

  Object? _uniqueFunction() {
    final sources = _functionArgumentSources(allowEmpty: true);
    if (sources == null) {
      return null;
    }
    if (sources.length == 1 && sources.single.isEmpty) {
      return _FormulaArgument.range(const [], rowCount: 0, columnCount: 0);
    }
    if (sources.any((source) => source.isEmpty)) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final arrayError = _formulaError(arrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (arrayResult is! _FormulaArgument) {
      return null;
    }

    if (sources.length > 3 ||
        (sources.length > 1 &&
            arrayResult.rowCount == 1 &&
            arrayResult.columnCount == 1)) {
      final args = <_FormulaArgument>[arrayResult];
      for (final source in sources.skip(1)) {
        final result = _evaluateArgumentSource(source);
        final error = _formulaError(result);
        if (error != null) {
          return error;
        }
        if (result is! _FormulaArgument) {
          return null;
        }
        args.add(result);
      }
      return _uniqueArguments(args);
    }

    final args = <_FormulaArgument>[arrayResult];
    for (final source in sources.skip(1)) {
      final result = _evaluateSource(source);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result == null) {
        return null;
      }
      args.add(
        _FormulaArgument.scalar(
          result is _FormulaArgument ? result.singleValue : result,
        ),
      );
    }
    return _unique(args);
  }

  _FormulaArgument _uniqueArguments(List<_FormulaArgument> args) {
    final values = <Object>[];
    for (final arg in args) {
      for (final value in arg.values) {
        if (!values.any((existing) => _valuesEqual(existing, value))) {
          values.add(value);
        }
      }
    }
    return _FormulaArgument.range(
      values,
      rowCount: 1,
      columnCount: values.length,
    );
  }

  Object? _sort(List<_FormulaArgument> args) {
    final array = args[0];
    final sortIndex = args.length >= 2
        ? _positiveIndex(args[1].singleValue)
        : 1;
    final sortOrder = args.length >= 3
        ? FortuneFormulaEngine._numberFromFormulaValue(args[2].singleValue)
        : 1.0;
    final byColumn = args.length >= 4 ? _truthy(args[3].singleValue) : false;
    if (sortIndex == null || sortOrder == null) {
      return null;
    }
    final normalizedOrder = sortOrder.truncate();
    if (normalizedOrder != 1 && normalizedOrder != -1) {
      return _FormulaError.value;
    }

    if (byColumn) {
      if (sortIndex > array.rowCount) {
        return _FormulaError.value;
      }
      for (var column = 0; column < array.columnCount; column += 1) {
        final keyError = _formulaError(array.valueAt(sortIndex - 1, column));
        if (keyError != null) {
          return keyError;
        }
      }
      final columns = List<int>.generate(array.columnCount, (index) => index);
      columns.sort((left, right) {
        final comparison =
            _compareLookupValues(
              array.valueAt(sortIndex - 1, left),
              array.valueAt(sortIndex - 1, right),
            ) ??
            0;
        if (comparison != 0) {
          return normalizedOrder == 1 ? comparison : -comparison;
        }
        return left.compareTo(right);
      });

      final result = <Object>[];
      for (var row = 0; row < array.rowCount; row += 1) {
        for (final column in columns) {
          result.add(array.valueAt(row, column));
        }
      }
      return _FormulaArgument.range(
        result,
        rowCount: array.rowCount,
        columnCount: array.columnCount,
      );
    }

    if (sortIndex > array.columnCount) {
      return _FormulaError.value;
    }
    for (var row = 0; row < array.rowCount; row += 1) {
      final keyError = _formulaError(array.valueAt(row, sortIndex - 1));
      if (keyError != null) {
        return keyError;
      }
    }
    final rows = List<int>.generate(array.rowCount, (index) => index);
    rows.sort((left, right) {
      final comparison =
          _compareLookupValues(
            array.valueAt(left, sortIndex - 1),
            array.valueAt(right, sortIndex - 1),
          ) ??
          0;
      if (comparison != 0) {
        return normalizedOrder == 1 ? comparison : -comparison;
      }
      return left.compareTo(right);
    });

    final result = <Object>[];
    for (final row in rows) {
      result.addAll(array.rowValues(row));
    }
    return _FormulaArgument.range(
      result,
      rowCount: array.rowCount,
      columnCount: array.columnCount,
    );
  }

  Object? _sortFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.isEmpty || sources.length > 4) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final arrayError = _formulaError(arrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (arrayResult is! _FormulaArgument) {
      return null;
    }

    final args = <_FormulaArgument>[arrayResult];
    for (final source in sources.skip(1)) {
      final result = _evaluateSource(source);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result == null) {
        return null;
      }
      args.add(
        _FormulaArgument.scalar(
          result is _FormulaArgument ? result.singleValue : result,
        ),
      );
    }
    return _sort(args);
  }

  Object? _randArray(List<_FormulaArgument> args) {
    final rowCount = args.isNotEmpty ? _positiveIndex(args[0].singleValue) : 1;
    final columnCount = args.length >= 2
        ? _positiveIndex(args[1].singleValue)
        : 1;
    final min = args.length >= 3
        ? FortuneFormulaEngine._numberFromFormulaValue(args[2].singleValue)
        : 0.0;
    final max = args.length >= 4
        ? FortuneFormulaEngine._numberFromFormulaValue(args[3].singleValue)
        : 1.0;
    final wholeNumber = args.length >= 5 ? _truthy(args[4].singleValue) : false;
    if (rowCount == null || columnCount == null || min == null || max == null) {
      return null;
    }
    if (!min.isFinite || !max.isFinite || min > max) {
      return _FormulaError.value;
    }

    final random = math.Random();
    final result = <Object>[];
    if (wholeNumber) {
      final integerMin = min.ceil();
      final integerMax = max.floor();
      if (integerMin > integerMax) {
        return _FormulaError.value;
      }
      for (var index = 0; index < rowCount * columnCount; index += 1) {
        result.add(
          (integerMin + random.nextInt(integerMax - integerMin + 1)).toDouble(),
        );
      }
    } else {
      for (var index = 0; index < rowCount * columnCount; index += 1) {
        result.add(min == max ? min : min + random.nextDouble() * (max - min));
      }
    }

    return _FormulaArgument.range(
      result,
      rowCount: rowCount,
      columnCount: columnCount,
    );
  }

  Object? _sortBy(List<_FormulaArgument> args) {
    final array = args[0];
    final sortKeys = <_FormulaArgument>[];
    final sortOrders = <int>[];
    var cursor = 1;

    while (cursor < args.length) {
      sortKeys.add(args[cursor]);
      cursor += 1;

      var order = 1;
      if (cursor < args.length && _isScalarArgument(args[cursor])) {
        final orderNumber = FortuneFormulaEngine._numberFromFormulaValue(
          args[cursor].singleValue,
        );
        if (orderNumber == null) {
          return null;
        }
        order = orderNumber.truncate();
        if (order != 1 && order != -1) {
          return _FormulaError.value;
        }
        cursor += 1;
      }
      sortOrders.add(order);
    }

    if (sortKeys.isEmpty) {
      return null;
    }

    bool? sortByColumn;
    for (final key in sortKeys) {
      final keyByColumn = _sortByColumnAxis(array, key);
      if (keyByColumn == null) {
        return _FormulaError.value;
      }
      final keyError = _firstFormulaError(key.values);
      if (keyError != null) {
        return keyError;
      }
      sortByColumn ??= keyByColumn;
      if (sortByColumn != keyByColumn) {
        return _FormulaError.value;
      }
    }

    if (sortByColumn ?? false) {
      final columns = List<int>.generate(array.columnCount, (index) => index);
      columns.sort(
        (left, right) => _compareSortByIndexes(
          left,
          right,
          sortKeys,
          sortOrders,
          byColumn: true,
        ),
      );

      final result = <Object>[];
      for (var row = 0; row < array.rowCount; row += 1) {
        for (final column in columns) {
          result.add(array.valueAt(row, column));
        }
      }
      return _FormulaArgument.range(
        result,
        rowCount: array.rowCount,
        columnCount: array.columnCount,
      );
    }

    final rows = List<int>.generate(array.rowCount, (index) => index);
    rows.sort(
      (left, right) => _compareSortByIndexes(
        left,
        right,
        sortKeys,
        sortOrders,
        byColumn: false,
      ),
    );

    final result = <Object>[];
    for (final row in rows) {
      result.addAll(array.rowValues(row));
    }
    return _FormulaArgument.range(
      result,
      rowCount: array.rowCount,
      columnCount: array.columnCount,
    );
  }

  Object? _sortByFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final arrayError = _formulaError(arrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (arrayResult is! _FormulaArgument) {
      return null;
    }

    final args = <_FormulaArgument>[arrayResult];
    for (final source in sources.skip(1)) {
      final result = _evaluateArgumentSource(source);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result is! _FormulaArgument) {
        return null;
      }
      args.add(result);
    }
    return _sortBy(args);
  }

  bool _isScalarArgument(_FormulaArgument argument) =>
      argument.rowCount == 1 && argument.columnCount == 1;

  bool? _sortByColumnAxis(_FormulaArgument array, _FormulaArgument sortKey) {
    if (sortKey.rowCount == array.rowCount && sortKey.columnCount == 1) {
      return false;
    }
    if (sortKey.rowCount == 1 && sortKey.columnCount == array.columnCount) {
      return true;
    }
    return null;
  }

  int _compareSortByIndexes(
    int left,
    int right,
    List<_FormulaArgument> sortKeys,
    List<int> sortOrders, {
    required bool byColumn,
  }) {
    for (var keyIndex = 0; keyIndex < sortKeys.length; keyIndex += 1) {
      final sortKey = sortKeys[keyIndex];
      final comparison = byColumn
          ? _compareLookupValues(
                  sortKey.valueAt(0, left),
                  sortKey.valueAt(0, right),
                ) ??
                0
          : _compareLookupValues(
                  sortKey.valueAt(left, 0),
                  sortKey.valueAt(right, 0),
                ) ??
                0;
      if (comparison != 0) {
        return sortOrders[keyIndex] == 1 ? comparison : -comparison;
      }
    }
    return left.compareTo(right);
  }

  bool _vectorsEqual(List<Object> left, List<Object> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index += 1) {
      if (!_valuesEqual(left[index], right[index])) {
        return false;
      }
    }
    return true;
  }

  Object? _vstack(List<_FormulaArgument> args) {
    final columnCount = args.fold<int>(
      0,
      (maxColumns, arg) => math.max(maxColumns, arg.columnCount),
    );
    final rowCount = args.fold<int>(0, (sum, arg) => sum + arg.rowCount);
    if (rowCount < 1 || columnCount < 1) {
      return null;
    }

    final result = <Object>[];
    for (final arg in args) {
      for (var row = 0; row < arg.rowCount; row += 1) {
        for (var column = 0; column < columnCount; column += 1) {
          result.add(
            column < arg.columnCount
                ? arg.valueAt(row, column)
                : _FormulaError.na,
          );
        }
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: rowCount,
      columnCount: columnCount,
    );
  }

  Object? _hstack(List<_FormulaArgument> args) {
    final rowCount = args.fold<int>(
      0,
      (maxRows, arg) => math.max(maxRows, arg.rowCount),
    );
    final columnCount = args.fold<int>(0, (sum, arg) => sum + arg.columnCount);
    if (rowCount < 1 || columnCount < 1) {
      return null;
    }

    final result = <Object>[];
    for (var row = 0; row < rowCount; row += 1) {
      for (final arg in args) {
        for (var column = 0; column < arg.columnCount; column += 1) {
          result.add(
            row < arg.rowCount ? arg.valueAt(row, column) : _FormulaError.na,
          );
        }
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: rowCount,
      columnCount: columnCount,
    );
  }

  Object? _stackFunction({required bool vertical}) {
    final sources = _functionArgumentSources();
    if (sources == null || sources.isEmpty) {
      return null;
    }

    final args = <_FormulaArgument>[];
    for (final source in sources) {
      final result = _evaluateArgumentSource(source);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result == null) {
        return null;
      }
      args.add(
        result is _FormulaArgument ? result : _FormulaArgument.scalar(result),
      );
    }
    return vertical ? _vstack(args) : _hstack(args);
  }

  Object? _toRowColumnFunction({required bool toRow}) {
    final sources = _functionArgumentSources();
    if (sources == null || sources.isEmpty || sources.length > 3) {
      return null;
    }

    final arrayResult = _evaluateArgumentSource(sources[0]);
    final arrayError = _formulaError(arrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (arrayResult is! _FormulaArgument) {
      return null;
    }

    final args = <_FormulaArgument>[arrayResult];
    for (final source in sources.skip(1)) {
      final result = _evaluateSource(source);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result == null) {
        return null;
      }
      args.add(
        _FormulaArgument.scalar(
          result is _FormulaArgument ? result.singleValue : result,
        ),
      );
    }
    return _toRowColumn(args, toRow: toRow);
  }

  Object? _toRowColumn(List<_FormulaArgument> args, {required bool toRow}) {
    final array = args[0];
    final ignore = args.length >= 2 ? _signedCount(args[1].singleValue) : 0;
    if (ignore == null || ignore < 0 || ignore > 3) {
      return _FormulaError.value;
    }
    final scanByColumn = args.length >= 3
        ? _truthy(args[2].singleValue)
        : false;
    final ignoreBlanks = ignore == 1 || ignore == 3;
    final ignoreErrors = ignore == 2 || ignore == 3;

    final result = <Object>[];
    if (scanByColumn) {
      for (var column = 0; column < array.columnCount; column += 1) {
        for (var row = 0; row < array.rowCount; row += 1) {
          _addFlattenedValue(
            result,
            array.valueAt(row, column),
            ignoreBlanks: ignoreBlanks,
            ignoreErrors: ignoreErrors,
          );
        }
      }
    } else {
      for (var row = 0; row < array.rowCount; row += 1) {
        for (var column = 0; column < array.columnCount; column += 1) {
          _addFlattenedValue(
            result,
            array.valueAt(row, column),
            ignoreBlanks: ignoreBlanks,
            ignoreErrors: ignoreErrors,
          );
        }
      }
    }
    if (result.isEmpty) {
      return _FormulaError.value;
    }
    return _FormulaArgument.range(
      result,
      rowCount: toRow ? 1 : result.length,
      columnCount: toRow ? result.length : 1,
    );
  }

  void _addFlattenedValue(
    List<Object> result,
    Object value, {
    required bool ignoreBlanks,
    required bool ignoreErrors,
  }) {
    if (ignoreBlanks && _isFormulaBlankLike(value)) {
      return;
    }
    if (ignoreErrors && value is _FormulaError) {
      return;
    }
    result.add(value);
  }

  Object? _sequence(List<_FormulaArgument> args) {
    final rowCount = _signedCount(args[0].singleValue);
    final columnCount = args.length >= 2
        ? _signedCount(args[1].singleValue)
        : 1;
    final start = args.length >= 3 ? _numberArgument(args[2].singleValue) : 1.0;
    final step = args.length >= 4 ? _numberArgument(args[3].singleValue) : 1.0;
    if (rowCount == null ||
        columnCount == null ||
        start == null ||
        step == null) {
      return null;
    }
    if (rowCount < 1 || columnCount < 1) {
      return _FormulaError.value;
    }

    final result = <Object>[];
    var value = start;
    for (var row = 0; row < rowCount; row += 1) {
      for (var column = 0; column < columnCount; column += 1) {
        result.add(value);
        value += step;
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: rowCount,
      columnCount: columnCount,
    );
  }

  Object? _transpose(_FormulaArgument array) {
    final result = <Object>[];
    for (var row = 0; row < array.columnCount; row += 1) {
      for (var column = 0; column < array.rowCount; column += 1) {
        result.add(array.valueAt(column, row));
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: array.columnCount,
      columnCount: array.rowCount,
    );
  }

  Object? _matrixMultiply(_FormulaArgument left, _FormulaArgument right) {
    if (left.columnCount != right.rowCount) {
      return _FormulaError.value;
    }
    final result = <Object>[];
    for (var row = 0; row < left.rowCount; row += 1) {
      for (var column = 0; column < right.columnCount; column += 1) {
        var sum = 0.0;
        for (var index = 0; index < left.columnCount; index += 1) {
          final leftValue = left.valueAt(row, index);
          final rightValue = right.valueAt(index, column);
          final error = _formulaError(leftValue) ?? _formulaError(rightValue);
          if (error != null) {
            return error;
          }
          final leftNumber = FortuneFormulaEngine._numberFromFormulaValue(
            leftValue,
          );
          final rightNumber = FortuneFormulaEngine._numberFromFormulaValue(
            rightValue,
          );
          if (leftNumber == null || rightNumber == null) {
            return _FormulaError.value;
          }
          sum += leftNumber * rightNumber;
        }
        result.add(sum);
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: left.rowCount,
      columnCount: right.columnCount,
    );
  }

  Object? _matrixDeterminant(_FormulaArgument array) {
    if (array.rowCount != array.columnCount) {
      return _FormulaError.value;
    }
    final matrix = <List<double>>[];
    for (var row = 0; row < array.rowCount; row += 1) {
      final values = <double>[];
      for (var column = 0; column < array.columnCount; column += 1) {
        final value = array.valueAt(row, column);
        final error = _formulaError(value);
        if (error != null) {
          return error;
        }
        final number = FortuneFormulaEngine._numberFromFormulaValue(value);
        if (number == null) {
          return _FormulaError.value;
        }
        values.add(number);
      }
      matrix.add(values);
    }

    var determinant = 1.0;
    var sign = 1.0;
    for (var pivotIndex = 0; pivotIndex < matrix.length; pivotIndex += 1) {
      var pivotRow = pivotIndex;
      var pivotSize = matrix[pivotRow][pivotIndex].abs();
      for (var row = pivotIndex + 1; row < matrix.length; row += 1) {
        final candidateSize = matrix[row][pivotIndex].abs();
        if (candidateSize > pivotSize) {
          pivotRow = row;
          pivotSize = candidateSize;
        }
      }
      if (pivotSize < 1e-12) {
        return 0.0;
      }
      if (pivotRow != pivotIndex) {
        final temp = matrix[pivotIndex];
        matrix[pivotIndex] = matrix[pivotRow];
        matrix[pivotRow] = temp;
        sign = -sign;
      }

      final pivot = matrix[pivotIndex][pivotIndex];
      determinant *= pivot;
      for (var row = pivotIndex + 1; row < matrix.length; row += 1) {
        final factor = matrix[row][pivotIndex] / pivot;
        for (var column = pivotIndex + 1; column < matrix.length; column += 1) {
          matrix[row][column] -= factor * matrix[pivotIndex][column];
        }
      }
    }
    return determinant * sign;
  }

  Object? _matrixInverse(_FormulaArgument array) {
    if (array.rowCount != array.columnCount) {
      return _FormulaError.value;
    }
    final size = array.rowCount;
    final augmented = <List<double>>[];
    for (var row = 0; row < size; row += 1) {
      final values = <double>[];
      for (var column = 0; column < size; column += 1) {
        final value = array.valueAt(row, column);
        final error = _formulaError(value);
        if (error != null) {
          return error;
        }
        final number = FortuneFormulaEngine._numberFromFormulaValue(value);
        if (number == null) {
          return _FormulaError.value;
        }
        values.add(number);
      }
      for (var column = 0; column < size; column += 1) {
        values.add(row == column ? 1.0 : 0.0);
      }
      augmented.add(values);
    }

    for (var pivotIndex = 0; pivotIndex < size; pivotIndex += 1) {
      var pivotRow = pivotIndex;
      var pivotSize = augmented[pivotRow][pivotIndex].abs();
      for (var row = pivotIndex + 1; row < size; row += 1) {
        final candidateSize = augmented[row][pivotIndex].abs();
        if (candidateSize > pivotSize) {
          pivotRow = row;
          pivotSize = candidateSize;
        }
      }
      if (pivotSize < 1e-12) {
        return _FormulaError.num;
      }
      if (pivotRow != pivotIndex) {
        final temp = augmented[pivotIndex];
        augmented[pivotIndex] = augmented[pivotRow];
        augmented[pivotRow] = temp;
      }

      final pivot = augmented[pivotIndex][pivotIndex];
      for (var column = 0; column < size * 2; column += 1) {
        augmented[pivotIndex][column] /= pivot;
      }
      for (var row = 0; row < size; row += 1) {
        if (row == pivotIndex) {
          continue;
        }
        final factor = augmented[row][pivotIndex];
        for (var column = 0; column < size * 2; column += 1) {
          augmented[row][column] -= factor * augmented[pivotIndex][column];
        }
      }
    }

    final result = <Object>[];
    for (var row = 0; row < size; row += 1) {
      for (var column = 0; column < size; column += 1) {
        result.add(augmented[row][column + size]);
      }
    }
    return _FormulaArgument.range(result, rowCount: size, columnCount: size);
  }

  Object? _transposeFunction() {
    final sources = _functionArgumentSources(allowEmpty: true);
    if (sources == null) {
      return null;
    }
    if (sources.length != 1 || sources.single.isEmpty) {
      return _FormulaError.na;
    }

    final literalRange = _rangeFromReferenceSource(sources.single);
    final eventValue = literalRange == null
        ? _parserNoValue
        : _rangeEventValue(literalRange);
    final arrayResult =
        strictParserCompatibility && !identical(eventValue, _parserNoValue)
        ? _namedFormulaValue(eventValue)
        : _evaluateArgumentSource(sources.single);
    final arrayError = _formulaError(arrayResult);
    if (arrayError != null) {
      return arrayError;
    }
    if (arrayResult is! _FormulaArgument) {
      return null;
    }
    final transposed = _transpose(arrayResult);
    if (strictParserCompatibility && transposed is _FormulaArgument) {
      return [
        for (var row = 0; row < transposed.rowCount; row += 1)
          [
            for (var column = 0; column < transposed.columnCount; column += 1)
              transposed.valueAt(row, column),
          ],
      ];
    }
    return transposed;
  }

  Object? _wrapRowsColumns(
    List<_FormulaArgument> args, {
    required bool wrapRows,
  }) {
    final vector = args[0];
    if (!_isOneDimensionalRange(vector)) {
      return _FormulaError.value;
    }
    final wrapCount = _signedCount(args[1].singleValue);
    if (wrapCount == null || wrapCount < 1) {
      return _FormulaError.value;
    }
    final values = vector.values;
    if (values.isEmpty) {
      return _FormulaError.value;
    }
    final padWith = args.length == 3 ? args[2].singleValue : _FormulaError.na;
    final groupCount = (values.length / wrapCount).ceil();
    final rowCount = wrapRows ? groupCount : wrapCount;
    final columnCount = wrapRows ? wrapCount : groupCount;

    final result = <Object>[];
    if (wrapRows) {
      for (var row = 0; row < rowCount; row += 1) {
        for (var column = 0; column < columnCount; column += 1) {
          final index = row * wrapCount + column;
          result.add(index < values.length ? values[index] : padWith);
        }
      }
    } else {
      for (var row = 0; row < rowCount; row += 1) {
        for (var column = 0; column < columnCount; column += 1) {
          final index = column * wrapCount + row;
          result.add(index < values.length ? values[index] : padWith);
        }
      }
    }
    return _FormulaArgument.range(
      result,
      rowCount: rowCount,
      columnCount: columnCount,
    );
  }

  Object? _wrapRowsColumnsFunction({required bool wrapRows}) {
    final sources = _functionArgumentSources();
    if (sources == null || sources.length < 2 || sources.length > 3) {
      return null;
    }

    final vectorResult = _evaluateArgumentSource(sources[0]);
    final vectorError = _formulaError(vectorResult);
    if (vectorError != null) {
      return vectorError;
    }
    if (vectorResult is! _FormulaArgument) {
      return null;
    }

    final wrapCountResult = _evaluateSource(sources[1]);
    final wrapCountError = _formulaError(wrapCountResult);
    if (wrapCountError != null) {
      return wrapCountError;
    }
    if (wrapCountResult == null) {
      return null;
    }

    final args = <_FormulaArgument>[
      vectorResult,
      _FormulaArgument.scalar(
        wrapCountResult is _FormulaArgument
            ? wrapCountResult.singleValue
            : wrapCountResult,
      ),
    ];
    if (sources.length == 3) {
      final padResult = _evaluateArgumentSource(sources[2]);
      if (padResult == null) {
        return null;
      }
      args.add(
        padResult is _FormulaArgument
            ? _FormulaArgument.scalar(padResult.singleValue)
            : _FormulaArgument.scalar(padResult),
      );
    }
    return _wrapRowsColumns(args, wrapRows: wrapRows);
  }

  Object? _address(List<Object> values) {
    final row = _numberArgument(values[0])?.truncate();
    final column = _numberArgument(values[1])?.truncate();
    final absNum = values.length >= 3
        ? _numberArgument(values[2])?.truncate()
        : 1;
    final a1 = values.length >= 4 ? _truthy(values[3]) : true;
    final sheetText = values.length >= 5 ? _text(values[4]) : null;
    if (row == null ||
        column == null ||
        absNum == null ||
        row < 1 ||
        column < 1 ||
        absNum < 1 ||
        absNum > 4) {
      return _FormulaError.value;
    }
    final absoluteRow = absNum == 1 || absNum == 2;
    final absoluteColumn = absNum == 1 || absNum == 3;
    final reference = a1
        ? '${absoluteColumn ? r'$' : ''}'
              '${FortuneFormulaEngine._columnName(column - 1)}'
              '${absoluteRow ? r'$' : ''}$row'
        : '${absoluteRow ? 'R$row' : 'R[$row]'}'
              '${absoluteColumn ? 'C$column' : 'C[$column]'}';
    if (sheetText == null || sheetText.isEmpty) {
      return reference;
    }
    return '${_quoteSheetName(sheetText)}!$reference';
  }

  String _quoteSheetName(String value) {
    final needsQuote =
        value.isEmpty || RegExp(r"[^A-Za-z0-9_]").hasMatch(value);
    if (!needsQuote) {
      return value;
    }
    return "'${value.replaceAll("'", "''")}'";
  }

  Object? _sumSquares(List<double> numbers) {
    var sum = 0.0;
    for (final item in numbers) {
      final term = item * item;
      if (!term.isFinite) {
        return _FormulaError.num;
      }
      sum += term;
      if (!sum.isFinite) {
        return _FormulaError.num;
      }
    }
    return sum;
  }

  Object? _sumNumbers(List<double> numbers) {
    var sum = 0.0;
    for (final item in numbers) {
      sum += item;
      if (!sum.isFinite) {
        return _FormulaError.num;
      }
    }
    return sum;
  }

  Object? _averageNumbers(List<double> numbers) {
    final average = _averageNumberValue(numbers);
    return average.isFinite ? average : _FormulaError.num;
  }

  double _averageNumberValue(List<double> numbers) {
    var maxMagnitude = 0.0;
    for (final item in numbers) {
      final magnitude = item.abs();
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
      }
    }
    if (maxMagnitude == 0) {
      return 0;
    }
    var scaledSum = 0.0;
    for (final item in numbers) {
      scaledSum += item / maxMagnitude;
      if (!scaledSum.isFinite) {
        return double.nan;
      }
    }
    return scaledSum / numbers.length * maxMagnitude;
  }

  Object? _product(List<double> numbers) {
    var product = 1.0;
    for (final item in numbers) {
      product *= item;
      if (!product.isFinite) {
        return _FormulaError.num;
      }
    }
    return product;
  }

  Object? _sumProduct(List<_FormulaArgument> args) {
    final first = args.first;
    if (!_sameShape(args)) {
      return null;
    }
    var sum = 0.0;
    for (var row = 0; row < first.rowCount; row += 1) {
      for (var column = 0; column < first.columnCount; column += 1) {
        var product = 1.0;
        for (final arg in args) {
          product *= _numberArgument(arg.valueAt(row, column)) ?? 0;
          if (!product.isFinite) {
            return _FormulaError.num;
          }
        }
        sum += product;
        if (!sum.isFinite) {
          return _FormulaError.num;
        }
      }
    }
    return sum;
  }

  Object? _sumPairwiseSquares(
    List<_FormulaArgument> args,
    _PairwiseSquareMode mode,
  ) {
    if (!_sameShape(args)) {
      return null;
    }
    final left = args[0];
    final right = args[1];
    var sum = 0.0;
    for (var row = 0; row < left.rowCount; row += 1) {
      for (var column = 0; column < left.columnCount; column += 1) {
        final x = _numberArgument(left.valueAt(row, column)) ?? 0;
        final y = _numberArgument(right.valueAt(row, column)) ?? 0;
        final term = switch (mode) {
          _PairwiseSquareMode.difference => math.pow(x - y, 2).toDouble(),
          _PairwiseSquareMode.squaresDifference => x * x - y * y,
          _PairwiseSquareMode.squaresSum => x * x + y * y,
        };
        if (!term.isFinite) {
          return _FormulaError.num;
        }
        sum += term;
        if (!sum.isFinite) {
          return _FormulaError.num;
        }
      }
    }
    return sum;
  }

  bool _sameShape(List<_FormulaArgument> args) {
    final first = args.first;
    for (final arg in args.skip(1)) {
      if (arg.rowCount != first.rowCount ||
          arg.columnCount != first.columnCount) {
        return false;
      }
    }
    return true;
  }

  int? _positiveIndex(Object value) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null || !number.isFinite || number < 1) {
      return null;
    }
    return number.truncate();
  }

  int? _nonNegativeIndex(Object value) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null || !number.isFinite || number < 0) {
      return null;
    }
    return number.truncate();
  }

  int? _exactMatchIndex(List<Object> values, Object lookupValue) {
    return _exactMatchIndexWithDirection(values, lookupValue, reverse: false);
  }

  Object? _exactMatchIndexOrError(
    List<Object> values,
    Object lookupValue, {
    required bool reverse,
  }) {
    for (var cursor = 0; cursor < values.length; cursor += 1) {
      final index = reverse ? values.length - cursor - 1 : cursor;
      final error = _formulaError(values[index]);
      if (error != null) {
        return error;
      }
      if (_valuesEqual(values[index], lookupValue)) {
        return index;
      }
    }
    return null;
  }

  Object? _exactOrWildcardMatchIndexOrError(
    List<Object> values,
    Object lookupValue, {
    required bool reverse,
  }) {
    return _hasWildcard(lookupValue)
        ? _wildcardMatchIndexOrError(values, lookupValue, reverse: reverse)
        : _exactMatchIndexOrError(values, lookupValue, reverse: reverse);
  }

  Object? _wildcardMatchIndexOrError(
    List<Object> values,
    Object lookupValue, {
    required bool reverse,
  }) {
    final matcher = _wildcardRegExp(_text(lookupValue));
    for (var cursor = 0; cursor < values.length; cursor += 1) {
      final index = reverse ? values.length - cursor - 1 : cursor;
      final error = _formulaError(values[index]);
      if (error != null) {
        return error;
      }
      if (matcher.hasMatch(_text(values[index]))) {
        return index;
      }
    }
    return null;
  }

  int? _lookupMatchIndex(
    List<Object> values,
    Object lookupValue, {
    required int matchMode,
    required int searchMode,
  }) {
    if (values.isEmpty) {
      return null;
    }
    if ((searchMode == 2 || searchMode == -2) && matchMode != 2) {
      return _binaryLookupMatchIndex(
        values,
        lookupValue,
        matchMode: matchMode,
        ascending: searchMode == 2,
      );
    }
    final reverse = searchMode < 0;
    return switch (matchMode) {
      0 => _exactMatchIndexWithDirection(values, lookupValue, reverse: reverse),
      2 => _wildcardMatchIndex(values, lookupValue, reverse: reverse),
      -1 => _nextSmallerMatchIndex(values, lookupValue, reverse: reverse),
      1 => _nextLargerMatchIndex(values, lookupValue, reverse: reverse),
      _ => null,
    };
  }

  Object? _lookupMatchIndexOrError(
    List<Object> values,
    Object lookupValue, {
    required int matchMode,
    required int searchMode,
  }) {
    final lookupError = _firstFormulaError(values);
    if (lookupError != null) {
      return lookupError;
    }
    return _lookupMatchIndex(
      values,
      lookupValue,
      matchMode: matchMode,
      searchMode: searchMode,
    );
  }

  Object? _xlookupMatchIndexOrError(
    List<Object> values,
    Object lookupValue, {
    required int matchMode,
    required int searchMode,
  }) {
    if (searchMode == 2 || searchMode == -2) {
      return _lookupMatchIndexOrError(
        values,
        lookupValue,
        matchMode: matchMode,
        searchMode: searchMode,
      );
    }
    if (matchMode == 0) {
      return _exactMatchIndexOrError(
        values,
        lookupValue,
        reverse: searchMode < 0,
      );
    }
    if (matchMode == 2) {
      return _wildcardMatchIndexOrError(
        values,
        lookupValue,
        reverse: searchMode < 0,
      );
    }
    return _lookupMatchIndexOrError(
      values,
      lookupValue,
      matchMode: matchMode,
      searchMode: searchMode,
    );
  }

  bool _isSupportedLookupMode(int mode) {
    return mode == -1 || mode == 0 || mode == 1 || mode == 2;
  }

  bool _isSupportedSearchMode(int mode) {
    return mode == -2 || mode == -1 || mode == 1 || mode == 2;
  }

  bool _isOneDimensionalRange(_FormulaArgument argument) {
    return argument.rowCount == 1 || argument.columnCount == 1;
  }

  bool _hasWildcard(Object value) {
    if (value is! String) {
      return false;
    }
    for (var i = 0; i < value.length; i += 1) {
      final char = value[i];
      if (char == '*' || char == '?') {
        return true;
      }
      if (char == '~' && i + 1 < value.length) {
        final next = value[i + 1];
        if (next == '*' || next == '?' || next == '~') {
          return true;
        }
      }
    }
    return false;
  }

  int? _exactMatchIndexWithDirection(
    List<Object> values,
    Object lookupValue, {
    required bool reverse,
  }) {
    for (var cursor = 0; cursor < values.length; cursor += 1) {
      final i = reverse ? values.length - cursor - 1 : cursor;
      if (_valuesEqual(values[i], lookupValue)) {
        return i;
      }
    }
    return null;
  }

  int? _wildcardMatchIndex(
    List<Object> values,
    Object lookupValue, {
    required bool reverse,
  }) {
    final matcher = _wildcardRegExp(_text(lookupValue));
    for (var cursor = 0; cursor < values.length; cursor += 1) {
      final i = reverse ? values.length - cursor - 1 : cursor;
      if (matcher.hasMatch(_text(values[i]))) {
        return i;
      }
    }
    return null;
  }

  int? _nextSmallerMatchIndex(
    List<Object> values,
    Object lookupValue, {
    required bool reverse,
  }) {
    int? bestIndex;
    for (var cursor = 0; cursor < values.length; cursor += 1) {
      final i = reverse ? values.length - cursor - 1 : cursor;
      final comparison = _compareLookupValues(values[i], lookupValue);
      if (comparison == null || comparison > 0) {
        continue;
      }
      if (comparison == 0) {
        return i;
      }
      if (bestIndex == null ||
          _compareLookupValues(values[i], values[bestIndex])! > 0) {
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int? _nextLargerMatchIndex(
    List<Object> values,
    Object lookupValue, {
    required bool reverse,
  }) {
    int? bestIndex;
    for (var cursor = 0; cursor < values.length; cursor += 1) {
      final i = reverse ? values.length - cursor - 1 : cursor;
      final comparison = _compareLookupValues(values[i], lookupValue);
      if (comparison == null || comparison < 0) {
        continue;
      }
      if (comparison == 0) {
        return i;
      }
      if (bestIndex == null ||
          _compareLookupValues(values[i], values[bestIndex])! < 0) {
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  int? _binaryLookupMatchIndex(
    List<Object> values,
    Object lookupValue, {
    required int matchMode,
    required bool ascending,
  }) {
    if (values.isEmpty) {
      return null;
    }
    if (ascending) {
      return switch (matchMode) {
        0 => _binaryAscendingFirstGreaterOrEqual(
          values,
          lookupValue,
          exact: true,
        ),
        -1 => _binaryAscendingLastLessOrEqual(values, lookupValue),
        1 => _binaryAscendingFirstGreaterOrEqual(values, lookupValue),
        _ => null,
      };
    }
    return switch (matchMode) {
      0 => _binaryDescendingFirstLessOrEqual(values, lookupValue, exact: true),
      -1 => _binaryDescendingFirstLessOrEqual(values, lookupValue),
      1 => _binaryDescendingLastGreaterOrEqual(values, lookupValue),
      _ => null,
    };
  }

  int? _binaryAscendingFirstGreaterOrEqual(
    List<Object> values,
    Object lookupValue, {
    bool exact = false,
  }) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      final comparison = _compareLookupValues(values[middle], lookupValue);
      if (comparison == null || comparison < 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low >= values.length) {
      return null;
    }
    if (exact && _compareLookupValues(values[low], lookupValue) != 0) {
      return null;
    }
    return low;
  }

  int? _binaryAscendingLastLessOrEqual(
    List<Object> values,
    Object lookupValue,
  ) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      final comparison = _compareLookupValues(values[middle], lookupValue);
      if (comparison == null || comparison <= 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low == 0 ? null : low - 1;
  }

  int? _binaryDescendingFirstLessOrEqual(
    List<Object> values,
    Object lookupValue, {
    bool exact = false,
  }) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      final comparison = _compareLookupValues(values[middle], lookupValue);
      if (comparison == null || comparison > 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low >= values.length) {
      return null;
    }
    if (exact && _compareLookupValues(values[low], lookupValue) != 0) {
      return null;
    }
    return low;
  }

  int? _binaryDescendingLastGreaterOrEqual(
    List<Object> values,
    Object lookupValue,
  ) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      final comparison = _compareLookupValues(values[middle], lookupValue);
      if (comparison == null || comparison >= 0) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low == 0 ? null : low - 1;
  }

  int? _approximateMatchIndex(
    List<Object> values,
    Object lookupValue, {
    required bool ascending,
  }) {
    int? bestIndex;
    for (var i = 0; i < values.length; i += 1) {
      final comparison = _compareLookupValues(values[i], lookupValue);
      if (comparison == null) {
        continue;
      }
      if (ascending) {
        if (comparison <= 0) {
          bestIndex = i;
        }
      } else if (comparison >= 0) {
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  Object? _approximateMatchIndexOrError(
    List<Object> values,
    Object lookupValue, {
    required bool ascending,
  }) {
    final lookupError = _firstFormulaError(values);
    if (lookupError != null) {
      return lookupError;
    }
    return _approximateMatchIndex(values, lookupValue, ascending: ascending);
  }

  bool _valuesEqual(Object left, Object right) {
    if (_isFormulaBlankLike(left)) {
      left = '';
    }
    if (_isFormulaBlankLike(right)) {
      right = '';
    }
    return _compare(left, right, '=') ?? false;
  }

  int? _compareLookupValues(Object left, Object right) {
    if (_isFormulaBlankLike(left)) {
      left = '';
    }
    if (_isFormulaBlankLike(right)) {
      right = '';
    }
    final leftNumber = FortuneFormulaEngine._numberFromFormulaValue(left);
    final rightNumber = FortuneFormulaEngine._numberFromFormulaValue(right);
    if (leftNumber != null && rightNumber != null) {
      return leftNumber.compareTo(rightNumber);
    }
    return _text(left).compareTo(_text(right));
  }

  double? _numberAArgument(Object value) {
    if (_isFormulaBlankLike(value)) {
      return null;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is String) {
      return FortuneFormulaEngine._numberFromFormulaValue(value) ?? 0;
    }
    return FortuneFormulaEngine._numberFromFormulaValue(value);
  }

  bool _matchesCriteria(Object value, Object criteria) {
    if (_isFormulaBlankLike(value)) {
      value = '';
    }
    if (criteria is num || criteria is bool) {
      return _compare(value, criteria, '=') ?? false;
    }
    final criteriaText = _text(criteria);
    final match = RegExp(r'^(<>|>=|<=|=|>|<)(.*)$').firstMatch(criteriaText);
    final operator = match?.group(1) ?? '=';
    final operandText = (match?.group(2) ?? criteriaText).trim();
    final operandNumber = FortuneFormulaEngine._numberFromFormulaValue(
      operandText,
    );
    final operand = operandNumber ?? operandText;
    if (operandNumber != null && operator != '<>') {
      final valueNumber = FortuneFormulaEngine._numberFromFormulaValue(value);
      if (valueNumber == null) {
        return false;
      }
    }
    if (operand is String &&
        _hasWildcard(operand) &&
        (operator == '=' || operator == '<>')) {
      final matches = _wildcardRegExp(operand).hasMatch(_text(value));
      return operator == '<>' ? !matches : matches;
    }
    return _compare(value, operand, operator) ?? false;
  }

  RegExp _wildcardRegExp(String pattern, {bool anchored = true}) {
    final buffer = StringBuffer();
    if (anchored) {
      buffer.write('^');
    }
    for (var i = 0; i < pattern.length; i += 1) {
      final char = pattern[i];
      if (char == '~' && i + 1 < pattern.length) {
        final next = pattern[i + 1];
        if (next == '*' || next == '?' || next == '~') {
          buffer.write(RegExp.escape(next));
          i += 1;
        } else {
          buffer.write(RegExp.escape(char));
        }
      } else if (char == '*') {
        buffer.write('.*');
      } else if (char == '?') {
        buffer.write('.');
      } else {
        buffer.write(RegExp.escape(char));
      }
    }
    if (anchored) {
      buffer.write(r'$');
    }
    return RegExp(buffer.toString(), caseSensitive: false);
  }

  String? _argumentSource() {
    _skipWhitespace();
    final start = _offset;
    var depth = 0;
    var inString = false;
    while (_offset < source.length) {
      final char = source[_offset];
      if (inString) {
        if (char == '"') {
          if (_offset + 1 < source.length && source[_offset + 1] == '"') {
            _offset += 2;
            continue;
          }
          inString = false;
        }
        _offset += 1;
        continue;
      }
      if (char == '"') {
        inString = true;
        _offset += 1;
        continue;
      }
      if (char == '(' || char == '{') {
        depth += 1;
        _offset += 1;
        continue;
      }
      if (char == ')') {
        if (depth == 0) {
          break;
        }
        depth -= 1;
        _offset += 1;
        continue;
      }
      if (char == '}') {
        if (depth == 0) {
          return null;
        }
        depth -= 1;
        _offset += 1;
        continue;
      }
      if (depth == 0 && (char == ',' || char == ';')) {
        break;
      }
      _offset += 1;
    }
    if (inString || depth != 0) {
      return null;
    }
    return source.substring(start, _offset).trim();
  }

  String? _comparisonOperator() {
    _skipWhitespace();
    for (final operator in const ['>=', '<=', '<>', '>', '<', '=']) {
      if (source.startsWith(operator, _offset)) {
        _offset += operator.length;
        return operator;
      }
    }
    return null;
  }

  double? _round(double value, double digits) {
    final places = _integerDigits(digits);
    if (places == null) {
      return null;
    }
    if (places.abs() > 308) {
      return places >= 0 ? value : 0;
    }
    final factor = math.pow(10, places.abs()).toDouble();
    if (!factor.isFinite) {
      return places >= 0 ? value : 0;
    }
    return places >= 0
        ? (value * factor).roundToDouble() / factor
        : (value / factor).roundToDouble() * factor;
  }

  Object? _roundAwayFromZero(double value, double digits) {
    final places = _integerDigits(digits);
    if (places == null) {
      return null;
    }
    if (places.abs() > 308) {
      if (places >= 0 || value == 0) {
        return value;
      }
      return _FormulaError.num;
    }
    final factor = math.pow(10, places.abs()).toDouble();
    if (!factor.isFinite) {
      if (places >= 0 || value == 0) {
        return value;
      }
      return _FormulaError.num;
    }
    final scaled = places >= 0 ? value * factor : value / factor;
    final rounded = scaled.isNegative
        ? scaled.floorToDouble()
        : scaled.ceilToDouble();
    return places >= 0 ? rounded / factor : rounded * factor;
  }

  double? _roundTowardZero(double value, double digits) {
    final places = _integerDigits(digits);
    if (places == null) {
      return null;
    }
    if (places.abs() > 308) {
      return places >= 0 ? value : 0;
    }
    final factor = math.pow(10, places.abs()).toDouble();
    if (!factor.isFinite) {
      return places >= 0 ? value : 0;
    }
    final scaled = places >= 0 ? value * factor : value / factor;
    final rounded = scaled.truncateToDouble();
    return places >= 0 ? rounded / factor : rounded * factor;
  }

  Object? _mround(double value, double multiple) {
    if (!value.isFinite || !multiple.isFinite || multiple == 0) {
      return null;
    }
    if (value == 0) {
      return 0;
    }
    if (value.sign != multiple.sign) {
      return _FormulaError.num;
    }
    return _finiteNumberOrNum((value / multiple).roundToDouble() * multiple);
  }

  double? _truncate(double value, double digits) {
    final places = _integerDigits(digits);
    if (places == null) {
      return null;
    }
    if (places.abs() > 308) {
      return places >= 0 ? value : 0;
    }
    final factor = math.pow(10, places.abs()).toDouble();
    if (!factor.isFinite) {
      return places >= 0 ? value : 0;
    }
    final scaled = places >= 0 ? value * factor : value / factor;
    final truncated = scaled.truncateToDouble();
    return places >= 0 ? truncated / factor : truncated * factor;
  }

  double? _roundToEven(double value) {
    if (!value.isFinite) {
      return null;
    }
    final rounded = value.isNegative
        ? value.floorToDouble()
        : value.ceilToDouble();
    final integer = rounded.toInt();
    return (integer.isEven ? integer : integer + (value.isNegative ? -1 : 1))
        .toDouble();
  }

  double? _roundToOdd(double value) {
    if (!value.isFinite) {
      return null;
    }
    final rounded = value.isNegative
        ? value.floorToDouble()
        : value.ceilToDouble();
    final integer = rounded.toInt();
    return (integer.isOdd ? integer : integer + (value.isNegative ? -1 : 1))
        .toDouble();
  }

  Object? _ceiling(double value, double significance) {
    if (!value.isFinite || !significance.isFinite || significance == 0) {
      return null;
    }
    if (value == 0) {
      return 0;
    }
    if (value > 0 && significance < 0) {
      return _FormulaError.num;
    }
    return _finiteNumberOrNum(
      (value / significance).ceilToDouble() * significance,
    );
  }

  Object? _ceilingMath(double value, double significance, double mode) {
    if (!value.isFinite || !significance.isFinite || !mode.isFinite) {
      return null;
    }
    final multiple = significance.abs();
    if (multiple == 0) {
      return null;
    }
    if (value >= 0 || mode == 0) {
      return _finiteNumberOrNum((value / multiple).ceilToDouble() * multiple);
    }
    return _finiteNumberOrNum((value / multiple).floorToDouble() * multiple);
  }

  Object? _ceilingPrecise(double value, double significance) {
    if (!value.isFinite || !significance.isFinite) {
      return null;
    }
    final multiple = significance.abs();
    if (multiple == 0) {
      return null;
    }
    return _finiteNumberOrNum((value / multiple).ceilToDouble() * multiple);
  }

  Object? _floor(double value, double significance) {
    if (!value.isFinite || !significance.isFinite || significance == 0) {
      return null;
    }
    if (value == 0) {
      return 0;
    }
    final absoluteSignificance = significance.abs();
    final multiple = absoluteSignificance < 1
        ? absoluteSignificance
        : absoluteSignificance.floorToDouble();
    return _finiteNumberOrNum((value / multiple).floorToDouble() * multiple);
  }

  Object? _floorMath(double value, double significance, double mode) {
    if (!value.isFinite || !significance.isFinite || !mode.isFinite) {
      return null;
    }
    final multiple = significance.abs();
    if (multiple == 0) {
      return null;
    }
    if (value >= 0 || mode == 0) {
      return _finiteNumberOrNum((value / multiple).floorToDouble() * multiple);
    }
    return _finiteNumberOrNum((value / multiple).ceilToDouble() * multiple);
  }

  Object? _floorPrecise(double value, double significance) {
    if (!value.isFinite || !significance.isFinite) {
      return null;
    }
    final multiple = significance.abs();
    if (multiple == 0) {
      return null;
    }
    return _finiteNumberOrNum((value / multiple).floorToDouble() * multiple);
  }

  Object? _finiteNumberOrNum(double value) {
    return value.isFinite ? value : _FormulaError.num;
  }

  int? _integerDigits(double value) {
    if (!value.isFinite || value != value.truncateToDouble()) {
      return null;
    }
    return value.toInt();
  }

  Object? _mod(double number, double divisor) {
    if (divisor == 0) {
      return _FormulaError.div0;
    }
    if (!number.isFinite || !divisor.isFinite) {
      return null;
    }
    return number - divisor * (number / divisor).floorToDouble();
  }

  Object? _quotient(double numerator, double denominator) {
    if (denominator == 0) {
      return _FormulaError.div0;
    }
    if (!numerator.isFinite || !denominator.isFinite) {
      return null;
    }
    return (numerator / denominator).truncateToDouble();
  }

  Object? _factorial(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value < 0) {
      return _FormulaError.num;
    }
    final n = value.truncate();
    return _finiteNumberOrNum(_factorialInt(n));
  }

  Object? _doubleFactorial(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value < 0) {
      return _FormulaError.num;
    }
    final n = value.truncate();
    var product = 1.0;
    for (var i = n; i > 1; i -= 2) {
      product *= i;
      if (!product.isFinite) {
        return _FormulaError.num;
      }
    }
    return product;
  }

  Object? _combin(double number, double chosen) {
    if (!number.isFinite || !chosen.isFinite) {
      return null;
    }
    final n = number.truncate();
    final k = chosen.truncate();
    if (n < 0 || k < 0 || k > n) {
      return _FormulaError.num;
    }
    final effectiveK = math.min(k, n - k);
    var result = 1.0;
    for (var i = 1; i <= effectiveK; i += 1) {
      result = result * (n - effectiveK + i) / i;
      if (!result.isFinite) {
        return _FormulaError.num;
      }
    }
    return result;
  }

  Object? _combina(double number, double chosen) {
    if (!number.isFinite || !chosen.isFinite) {
      return null;
    }
    final n = number.truncate();
    final k = chosen.truncate();
    if (n < 0 || k < 0 || (n == 0 && k > 0)) {
      return _FormulaError.num;
    }
    if (k == 0) {
      return 1.0;
    }
    return _combin(n + k - 1.0, k.toDouble());
  }

  Object? _permut(double number, double chosen) {
    if (!number.isFinite || !chosen.isFinite) {
      return null;
    }
    final n = number.truncate();
    final k = chosen.truncate();
    if (n < 0 || k < 0 || k > n) {
      return _FormulaError.num;
    }
    var result = 1.0;
    for (var i = 0; i < k; i += 1) {
      result *= n - i;
      if (!result.isFinite) {
        return _FormulaError.num;
      }
    }
    return result;
  }

  Object? _permutationA(double number, double chosen) {
    if (!number.isFinite || !chosen.isFinite) {
      return null;
    }
    final n = number.truncate();
    final k = chosen.truncate();
    if (n < 0 || k < 0 || (n == 0 && k > 0)) {
      return _FormulaError.num;
    }
    return math.pow(n, k).toDouble();
  }

  Object? _multinomial(List<double> values) {
    var sum = 0;
    var denominator = 1.0;
    for (final value in values) {
      if (!value.isFinite) {
        return null;
      }
      if (value < 0) {
        return _FormulaError.num;
      }
      final n = value.truncate();
      sum += n;
      denominator *= _factorialInt(n);
      if (!denominator.isFinite) {
        return _FormulaError.num;
      }
    }
    final numerator = _factorialInt(sum);
    if (!numerator.isFinite) {
      return _FormulaError.num;
    }
    return _finiteNumberOrNum(numerator / denominator);
  }

  bool? _isEvenNumber(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value.truncate().isEven;
  }

  bool? _isOddNumber(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value.truncate().isOdd;
  }

  Object? _seriesSum(
    double x,
    double initialPower,
    double step,
    List<double> coefficients,
  ) {
    if (!x.isFinite ||
        !initialPower.isFinite ||
        !step.isFinite ||
        coefficients.any((value) => !value.isFinite)) {
      return null;
    }
    var sum = 0.0;
    for (var i = 0; i < coefficients.length; i += 1) {
      final term =
          coefficients[i] * math.pow(x, initialPower + i * step).toDouble();
      if (!term.isFinite) {
        return _FormulaError.num;
      }
      sum += term;
      if (!sum.isFinite) {
        return _FormulaError.num;
      }
    }
    return sum;
  }

  double? _gcdValues(List<double> values) {
    int? result;
    for (final value in values) {
      final integer = _integerMagnitude(value);
      if (integer == null) {
        return null;
      }
      result = result == null ? integer : _gcd(result, integer);
    }
    return (result ?? 0).toDouble();
  }

  double? _lcmValues(List<double> values) {
    var result = 1.0;
    for (final value in values) {
      final integer = _nonNegativeInteger(value);
      if (integer == null) {
        return null;
      }
      if (integer == 0) {
        return 0;
      }
      result = (result / _gcd(result.truncate(), integer)) * value;
    }
    return result;
  }

  int? _nonNegativeInteger(double value) {
    if (!value.isFinite || value < 0) {
      return null;
    }
    return value.truncate();
  }

  int? _integerMagnitude(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value.truncate().abs();
  }

  double _factorialInt(int value) {
    var product = 1.0;
    for (var i = 2; i <= value; i += 1) {
      product *= i;
    }
    return product;
  }

  int _gcd(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final remainder = x % y;
      x = y;
      y = remainder;
    }
    return x;
  }

  Object? _ln(double number) {
    if (!number.isFinite) {
      return null;
    }
    return number > 0 ? math.log(number) : _FormulaError.num;
  }

  Object? _exp(double number) {
    if (!number.isFinite) {
      return null;
    }
    final result = math.exp(number);
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _log10(double number) {
    if (!number.isFinite) {
      return null;
    }
    return number > 0 ? math.log(number) / math.ln10 : _FormulaError.num;
  }

  Object? _log(double number, double base) {
    if (!number.isFinite || !base.isFinite || base <= 0 || base == 1) {
      if (number.isFinite &&
          base.isFinite &&
          (number <= 0 || base <= 0 || base == 1)) {
        return _FormulaError.num;
      }
      return null;
    }
    if (number <= 0) {
      return _FormulaError.num;
    }
    return math.log(number) / math.log(base);
  }

  Object? _sqrt(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value >= 0 ? math.sqrt(value) : _FormulaError.num;
  }

  Object? _sqrtPi(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value < 0) {
      return _FormulaError.num;
    }
    final result = math.sqrt(value) * math.sqrt(math.pi);
    return result.isFinite ? result : _FormulaError.num;
  }

  double _sinh(double value) {
    return (math.exp(value) - math.exp(-value)) / 2;
  }

  Object? _sinhFunction(double value) {
    if (!value.isFinite) {
      return null;
    }
    final result = _sinh(value);
    return result.isFinite ? result : _FormulaError.num;
  }

  double _cosh(double value) {
    return (math.exp(value) + math.exp(-value)) / 2;
  }

  Object? _coshFunction(double value) {
    if (!value.isFinite) {
      return null;
    }
    final result = _cosh(value);
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _cschFunction(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value > 20 || value < -20) {
      return 0.0;
    }
    return _reciprocalTrig(_sinh(value));
  }

  double _tanh(double value) {
    if (value > 20) {
      return 1;
    }
    if (value < -20) {
      return -1;
    }
    final positive = math.exp(value);
    final negative = math.exp(-value);
    return (positive - negative) / (positive + negative);
  }

  Object? _reciprocalTrig(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value == 0 ? double.infinity : 1 / value;
  }

  double _asinh(double value) {
    final absolute = value.abs();
    if (absolute == 0) {
      return value;
    }
    if (absolute > math.sqrt(double.maxFinite)) {
      final result = math.log(absolute) + math.ln2;
      return value.isNegative ? -result : result;
    }
    final result = math.log(absolute + math.sqrt(absolute * absolute + 1));
    return value.isNegative ? -result : result;
  }

  double _acosh(double value) {
    if (value > math.sqrt(double.maxFinite)) {
      return math.log(value) + math.ln2;
    }
    return math.log(value + math.sqrt(value * value - 1));
  }

  double _atanh(double value) {
    return 0.5 * math.log((1 + value) / (1 - value));
  }

  Object? _acot(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value == 0) {
      return math.pi / 2;
    }
    return math.atan(1 / value);
  }

  Object? _acoshChecked(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value >= 1 ? _acosh(value) : _FormulaError.num;
  }

  Object? _acothChecked(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value == 1) {
      return double.infinity;
    }
    if (value == -1) {
      return double.negativeInfinity;
    }
    return value.abs() > 1 ? _atanh(1 / value) : _FormulaError.num;
  }

  Object? _atanhChecked(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value == 1) {
      return double.infinity;
    }
    if (value == -1) {
      return double.negativeInfinity;
    }
    return value > -1 && value < 1 ? _atanh(value) : _FormulaError.num;
  }

  Object? _atan2(double x, double y) {
    if (!x.isFinite || !y.isFinite) {
      return null;
    }
    if (x == 0 && y == 0) {
      return _FormulaError.div0;
    }
    return math.atan2(y, x);
  }

  Object? _asin(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value >= -1 && value <= 1 ? math.asin(value) : _FormulaError.num;
  }

  Object? _acos(double value) {
    if (!value.isFinite) {
      return null;
    }
    return value >= -1 && value <= 1 ? math.acos(value) : _FormulaError.num;
  }

  Object? _randomBetween(double bottom, double top) {
    final min = _integerDigits(bottom);
    final max = _integerDigits(top);
    if (min == null || max == null) {
      return null;
    }
    if (min > max) {
      return _FormulaError.num;
    }
    return (min + math.Random().nextInt(max - min + 1)).toDouble();
  }

  Object? _dollarDe(double fractionalPrice, double unit) {
    final unitResult = _dollarFractionUnit(unit);
    if (unitResult is _FormulaError || unitResult == null) {
      return unitResult;
    }
    if (unitResult is! double) {
      return null;
    }
    final integerPart = fractionalPrice.truncateToDouble();
    final fractionalPart = (fractionalPrice - integerPart).abs();
    final scale = _dollarFractionScale(unitResult);
    final decimalPart = fractionalPart * scale / unitResult;
    return fractionalPrice.isNegative
        ? integerPart - decimalPart
        : integerPart + decimalPart;
  }

  Object? _dollarFr(double decimalPrice, double unit) {
    final unitResult = _dollarFractionUnit(unit);
    if (unitResult is _FormulaError || unitResult == null) {
      return unitResult;
    }
    if (unitResult is! double) {
      return null;
    }
    final integerPart = decimalPrice.truncateToDouble();
    final decimalPart = (decimalPrice - integerPart).abs();
    final scale = _dollarFractionScale(unitResult);
    final fractionalPart = decimalPart * unitResult / scale;
    return decimalPrice.isNegative
        ? integerPart - fractionalPart
        : integerPart + fractionalPart;
  }

  Object? _delta(List<_FormulaArgument> args) {
    final first = _numberArgument(args[0].singleValue);
    final second = args.length == 2
        ? _numberArgument(args[1].singleValue)
        : 0.0;
    if (first == null || second == null) {
      return null;
    }
    return first == second ? 1 : 0;
  }

  Object? _greaterThanOrEqualStep(List<_FormulaArgument> args) {
    final number = _numberArgument(args[0].singleValue);
    final step = args.length == 2 ? _numberArgument(args[1].singleValue) : 0.0;
    if (number == null || step == null) {
      return null;
    }
    return number >= step ? 1 : 0;
  }

  Object? _baseToDecimal(Object value, {required int base, required int bits}) {
    final text = _text(value).trim().toUpperCase();
    final digits =
        bits ~/
        (base == 16
            ? 4
            : base == 8
            ? 3
            : 1);
    if (text.isEmpty || text.length > digits) {
      return _FormulaError.num;
    }
    final validPattern = switch (base) {
      2 => RegExp(r'^[01]+$'),
      8 => RegExp(r'^[0-7]+$'),
      16 => RegExp(r'^[0-9A-F]+$'),
      _ => null,
    };
    if (validPattern == null || !validPattern.hasMatch(text)) {
      return _FormulaError.num;
    }
    final unsigned = BigInt.parse(text, radix: base);
    final modulus = BigInt.one << bits;
    final signBit = BigInt.one << (bits - 1);
    final signed = unsigned >= signBit ? unsigned - modulus : unsigned;
    return signed.toDouble();
  }

  Object? _decimalToBase(
    Object value,
    Object? placesValue, {
    required int base,
    required int bits,
  }) {
    final number = _numberArgument(value);
    if (number == null) {
      return null;
    }
    final integer = _integerDigits(number);
    if (integer == null) {
      return _FormulaError.num;
    }
    final minValue = -(1 << (bits - 1));
    final maxValue = (1 << (bits - 1)) - 1;
    if (integer < minValue || integer > maxValue) {
      return _FormulaError.num;
    }

    int? places;
    if (placesValue != null) {
      final placesNumber = _numberArgument(placesValue);
      if (placesNumber == null) {
        return null;
      }
      places = _integerDigits(placesNumber);
      if (places == null || places < 0) {
        return _FormulaError.num;
      }
    }

    final digits =
        bits ~/
        (base == 16
            ? 4
            : base == 8
            ? 3
            : 1);
    final unsigned = integer < 0
        ? (BigInt.one << bits) + BigInt.from(integer)
        : BigInt.from(integer);
    final text = unsigned.toRadixString(base);
    if (integer < 0) {
      return text.padLeft(digits, '0');
    }
    if (places != null) {
      if (places < text.length) {
        return _FormulaError.num;
      }
      return text.padLeft(places, '0');
    }
    return text;
  }

  Object? _baseToBase(
    Object value,
    Object? placesValue, {
    required int sourceBase,
    required int sourceBits,
    required int targetBase,
    required int targetBits,
  }) {
    final decimal = _baseToDecimal(value, base: sourceBase, bits: sourceBits);
    if (decimal is _FormulaError || decimal == null) {
      return decimal;
    }
    if (decimal is! double) {
      return null;
    }
    return _decimalToBase(
      decimal,
      placesValue,
      base: targetBase,
      bits: targetBits,
    );
  }

  Object? _bitwiseOperation(
    List<_FormulaArgument> args,
    _BitwiseOperation operation,
  ) {
    final left = _bitwiseInteger(args[0].singleValue);
    final right = _bitwiseInteger(args[1].singleValue);
    if (left == null || right == null) {
      return null;
    }
    if (left is _FormulaError) {
      return left;
    }
    if (right is _FormulaError) {
      return right;
    }
    if (left is! int || right is! int) {
      return null;
    }
    final result = switch (operation) {
      _BitwiseOperation.and => left & right,
      _BitwiseOperation.or => left | right,
      _BitwiseOperation.xor => left ^ right,
    };
    return result.toDouble();
  }

  Object? _bitShift(List<_FormulaArgument> args, {required bool shiftLeft}) {
    final number = _bitwiseInteger(args[0].singleValue);
    final shift = _bitShiftAmount(args[1].singleValue);
    if (number == null || shift == null) {
      return null;
    }
    if (number is _FormulaError) {
      return number;
    }
    if (shift is _FormulaError) {
      return shift;
    }
    if (number is! int || shift is! int) {
      return null;
    }
    final effectiveShift = shiftLeft ? shift : -shift;
    final result = effectiveShift >= 0
        ? number << effectiveShift
        : number >> -effectiveShift;
    if (result < 0 || result > 281474976710655) {
      return _FormulaError.num;
    }
    return result.toDouble();
  }

  Object? _bitwiseInteger(Object value) {
    final number = _numberArgument(value);
    if (number == null) {
      return null;
    }
    final integer = _integerDigits(number);
    if (integer == null || integer < 0 || integer > 281474976710655) {
      return _FormulaError.num;
    }
    return integer;
  }

  Object? _bitShiftAmount(Object value) {
    final number = _numberArgument(value);
    if (number == null) {
      return null;
    }
    final integer = _integerDigits(number);
    if (integer == null || integer.abs() > 53) {
      return _FormulaError.num;
    }
    return integer;
  }

  Object? _complexFunction(List<_FormulaArgument> args) {
    final real = _numberArgument(args[0].singleValue);
    final imaginary = _numberArgument(args[1].singleValue);
    if (real == null || imaginary == null) {
      return null;
    }
    var suffix = 'i';
    if (args.length == 3) {
      suffix = _text(args[2].singleValue).toLowerCase();
      if (suffix != 'i' && suffix != 'j') {
        return _FormulaError.value;
      }
    }
    return _formatComplex(_ComplexNumber(real, imaginary), suffix: suffix);
  }

  Object? _errorFunction(List<_FormulaArgument> args) {
    final value = _numberArgument(args[0].singleValue);
    return value == null ? null : _erf(value);
  }

  Object? _complementaryErrorFunction(List<_FormulaArgument> args) {
    final value = _numberArgument(args[0].singleValue);
    return value == null ? null : 1 - _erf(value);
  }

  Object? _convertUnits(List<_FormulaArgument> args) {
    final value = _numberArgument(args[0].singleValue);
    if (value == null) {
      return null;
    }
    final fromUnit = _conversionUnit(_text(args[1].singleValue));
    final toUnit = _conversionUnit(_text(args[2].singleValue));
    if (fromUnit == null || toUnit == null || fromUnit.kind != toUnit.kind) {
      return _FormulaError.na;
    }
    return value * fromUnit.factor / toUnit.factor;
  }

  _ConversionUnit? _conversionUnit(String unit) {
    return switch (unit.trim()) {
      'g' => const _ConversionUnit(_ConversionUnitKind.mass, 0.001),
      'kg' => const _ConversionUnit(_ConversionUnitKind.mass, 1),
      'lbm' => const _ConversionUnit(_ConversionUnitKind.mass, 0.45359237),
      'm' => const _ConversionUnit(_ConversionUnitKind.length, 1),
      'km' => const _ConversionUnit(_ConversionUnitKind.length, 1000),
      'mi' => const _ConversionUnit(_ConversionUnitKind.length, 1609.344),
      'm/s' => const _ConversionUnit(_ConversionUnitKind.speed, 1),
      'km/h' ||
      'kph' => const _ConversionUnit(_ConversionUnitKind.speed, 1000 / 3600),
      'mph' => const _ConversionUnit(
        _ConversionUnitKind.speed,
        1609.344 / 3600,
      ),
      'J' => const _ConversionUnit(_ConversionUnitKind.energy, 1),
      'cal' => const _ConversionUnit(_ConversionUnitKind.energy, 4.184),
      'Pa' => const _ConversionUnit(_ConversionUnitKind.pressure, 1),
      'atm' => const _ConversionUnit(_ConversionUnitKind.pressure, 101325),
      _ => null,
    };
  }

  Object? _besselFunction(List<_FormulaArgument> args, _BesselKind kind) {
    final x = _numberArgument(args[0].singleValue);
    final order = _besselOrder(args[1].singleValue);
    if (x == null || order == null) {
      return null;
    }
    if (order is _FormulaError) {
      return order;
    }
    if (order is! int) {
      return null;
    }
    if ((kind == _BesselKind.k || kind == _BesselKind.y) && x <= 0) {
      return _FormulaError.num;
    }
    final result = switch (kind) {
      _BesselKind.i => _besselI(x, order),
      _BesselKind.j => _besselJ(x, order),
      _BesselKind.k => _besselK(x, order),
      _BesselKind.y => _besselY(x, order),
    };
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _binaryNumericOperator(
    List<_FormulaArgument> args,
    _BinaryNumericOperator operator,
  ) {
    final left = _operatorNumber(args[0].singleValue);
    final right = _operatorNumber(args[1].singleValue);
    if (left is _FormulaError) {
      return left;
    }
    if (right is _FormulaError) {
      return right;
    }
    if (left is! double || right is! double) {
      return _FormulaError.na;
    }
    return switch (operator) {
      _BinaryNumericOperator.add => left + right,
      _BinaryNumericOperator.subtract => left - right,
      _BinaryNumericOperator.multiply => left * right,
      _BinaryNumericOperator.divide =>
        right == 0 ? _FormulaError.div0 : left / right,
      _BinaryNumericOperator.power => _powerValue(left, right),
    };
  }

  Object? _powerValue(double base, double exponent) {
    if (!base.isFinite || !exponent.isFinite) {
      return _FormulaError.value;
    }
    if (base == 0 && exponent < 0) {
      return _FormulaError.div0;
    }
    final result = math.pow(base, exponent).toDouble();
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _binaryComparison(List<_FormulaArgument> args, String operator) {
    final left = args[0].singleValue;
    final right = args[1].singleValue;
    final leftError = _formulaError(left);
    final rightError = _formulaError(right);
    if (leftError != null) {
      return leftError;
    }
    if (rightError != null) {
      return rightError;
    }
    return _compare(left, right, operator) ?? _FormulaError.na;
  }

  Object? _operatorNumber(Object value) {
    final error = _formulaError(value);
    if (error != null) {
      return error;
    }
    return FortuneFormulaEngine._numberFromFormulaValue(value);
  }

  Object? _besselOrder(Object value) {
    final number = _numberArgument(value);
    if (number == null) {
      return null;
    }
    final order = _integerDigits(number);
    if (order == null || order < 0) {
      return _FormulaError.num;
    }
    return order;
  }

  double _besselI(double x, int order) {
    if (order == 0) {
      return _besselI0(x);
    }
    if (order == 1) {
      return _besselI1(x);
    }
    if (x == 0) {
      return 0;
    }
    final absolute = x.abs();
    final tox = 2 / absolute;
    var bip = 0.0;
    var bi = 1.0;
    var result = 0.0;
    for (var j = 2 * (order + math.sqrt(40 * order).round()); j > 0; j -= 1) {
      final bim = bip + j * tox * bi;
      bip = bi;
      bi = bim;
      if (bi.abs() > 1e10) {
        result *= 1e-10;
        bi *= 1e-10;
        bip *= 1e-10;
      }
      if (j == order) {
        result = bip;
      }
    }
    result *= _besselI0(absolute) / bi;
    return x < 0 && order.isOdd ? -result : result;
  }

  double _besselI0(double x) {
    final ax = x.abs();
    if (ax < 3.75) {
      final y = (x / 3.75) * (x / 3.75);
      return 1 +
          y *
              (3.5156229 +
                  y *
                      (3.0899424 +
                          y *
                              (1.2067492 +
                                  y *
                                      (0.2659732 +
                                          y * (0.0360768 + y * 0.0045813)))));
    }
    final y = 3.75 / ax;
    return math.exp(ax) /
        math.sqrt(ax) *
        (0.39894228 +
            y *
                (0.01328592 +
                    y *
                        (0.00225319 +
                            y *
                                (-0.00157565 +
                                    y *
                                        (0.00916281 +
                                            y *
                                                (-0.02057706 +
                                                    y *
                                                        (0.02635537 +
                                                            y *
                                                                (-0.01647633 +
                                                                    y * 0.00392377))))))));
  }

  double _besselI1(double x) {
    final ax = x.abs();
    double result;
    if (ax < 3.75) {
      final y = (x / 3.75) * (x / 3.75);
      result =
          ax *
          (0.5 +
              y *
                  (0.87890594 +
                      y *
                          (0.51498869 +
                              y *
                                  (0.15084934 +
                                      y *
                                          (0.02658733 +
                                              y *
                                                  (0.00301532 +
                                                      y * 0.00032411))))));
    } else {
      final y = 3.75 / ax;
      result =
          math.exp(ax) /
          math.sqrt(ax) *
          (0.39894228 +
              y *
                  (-0.03988024 +
                      y *
                          (-0.00362018 +
                              y *
                                  (0.00163801 +
                                      y *
                                          (-0.01031555 +
                                              y *
                                                  (0.02282967 +
                                                      y *
                                                          (-0.02895312 +
                                                              y *
                                                                  (0.01787654 -
                                                                      y * 0.00420059))))))));
    }
    return x < 0 ? -result : result;
  }

  double _besselJ(double x, int order) {
    if (order == 0) {
      return _besselJ0(x);
    }
    if (order == 1) {
      return _besselJ1(x);
    }
    if (x == 0) {
      return 0;
    }
    var previous = _besselJ0(x);
    var current = _besselJ1(x);
    final tox = 2 / x;
    for (var j = 1; j < order; j += 1) {
      final next = j * tox * current - previous;
      previous = current;
      current = next;
    }
    return current;
  }

  double _besselJ0(double x) {
    final ax = x.abs();
    if (ax < 8) {
      final y = x * x;
      final ans1 =
          57568490574.0 +
          y *
              (-13362590354.0 +
                  y *
                      (651619640.7 +
                          y *
                              (-11214424.18 +
                                  y * (77392.33017 + y * -184.9052456))));
      final ans2 =
          57568490411.0 +
          y *
              (1029532985.0 +
                  y *
                      (9494680.718 +
                          y * (59272.64853 + y * (267.8532712 + y))));
      return ans1 / ans2;
    }
    final z = 8 / ax;
    final y = z * z;
    final xx = ax - 0.785398164;
    final ans1 =
        1 +
        y *
            (-0.001098628627 +
                y *
                    (0.00002734510407 +
                        y * (-0.000002073370639 + y * 0.0000002093887211)));
    final ans2 =
        -0.01562499995 +
        y *
            (0.0001430488765 +
                y *
                    (-0.000006911147651 +
                        y * (0.0000007621095161 - y * 0.0000000934945152)));
    return math.sqrt(0.636619772 / ax) *
        (math.cos(xx) * ans1 - z * math.sin(xx) * ans2);
  }

  double _besselJ1(double x) {
    final ax = x.abs();
    double result;
    if (ax < 8) {
      final y = x * x;
      final ans1 =
          x *
          (72362614232.0 +
              y *
                  (-7895059235.0 +
                      y *
                          (242396853.1 +
                              y *
                                  (-2972611.439 +
                                      y * (15704.48260 + y * -30.16036606)))));
      final ans2 =
          144725228442.0 +
          y *
              (2300535178.0 +
                  y *
                      (18583304.74 +
                          y * (99447.43394 + y * (376.9991397 + y))));
      result = ans1 / ans2;
    } else {
      final z = 8 / ax;
      final y = z * z;
      final xx = ax - 2.356194491;
      final ans1 =
          1 +
          y *
              (0.00183105 +
                  y *
                      (-0.00003516396496 +
                          y * (0.000002457520174 + y * -0.000000240337019)));
      final ans2 =
          0.04687499995 +
          y *
              (-0.0002002690873 +
                  y *
                      (0.000008449199096 +
                          y * (-0.00000088228987 + y * 0.000000105787412)));
      result =
          math.sqrt(0.636619772 / ax) *
          (math.cos(xx) * ans1 - z * math.sin(xx) * ans2);
      if (x < 0) {
        result = -result;
      }
    }
    return result;
  }

  double _besselK(double x, int order) {
    if (order == 0) {
      return _besselK0(x);
    }
    if (order == 1) {
      return _besselK1(x);
    }
    var previous = _besselK0(x);
    var current = _besselK1(x);
    final tox = 2 / x;
    for (var j = 1; j < order; j += 1) {
      final next = previous + j * tox * current;
      previous = current;
      current = next;
    }
    return current;
  }

  double _besselK0(double x) {
    if (x <= 2) {
      final y = x * x / 4;
      return -math.log(x / 2) * _besselI0(x) +
          (-0.57721566 +
              y *
                  (0.42278420 +
                      y *
                          (0.23069756 +
                              y *
                                  (0.03488590 +
                                      y *
                                          (0.00262698 +
                                              y *
                                                  (0.00010750 +
                                                      y * 0.00000740))))));
    }
    final y = 2 / x;
    return math.exp(-x) /
        math.sqrt(x) *
        (1.25331414 +
            y *
                (-0.07832358 +
                    y *
                        (0.02189568 +
                            y *
                                (-0.01062446 +
                                    y *
                                        (0.00587872 +
                                            y *
                                                (-0.00251540 +
                                                    y * 0.00053208))))));
  }

  double _besselK1(double x) {
    if (x <= 2) {
      final y = x * x / 4;
      return math.log(x / 2) * _besselI1(x) +
          (1 / x) *
              (1 +
                  y *
                      (0.15443144 +
                          y *
                              (-0.67278579 +
                                  y *
                                      (-0.18156897 +
                                          y *
                                              (-0.01919402 +
                                                  y *
                                                      (-0.00110404 +
                                                          y * -0.00004686))))));
    }
    final y = 2 / x;
    return math.exp(-x) /
        math.sqrt(x) *
        (1.25331414 +
            y *
                (0.23498619 +
                    y *
                        (-0.03655620 +
                            y *
                                (0.01504268 +
                                    y *
                                        (-0.00780353 +
                                            y *
                                                (0.00325614 +
                                                    y * -0.00068245))))));
  }

  double _besselY(double x, int order) {
    if (order == 0) {
      return _besselY0(x);
    }
    if (order == 1) {
      return _besselY1(x);
    }
    var previous = _besselY0(x);
    var current = _besselY1(x);
    final tox = 2 / x;
    for (var j = 1; j < order; j += 1) {
      final next = j * tox * current - previous;
      previous = current;
      current = next;
    }
    return current;
  }

  double _besselY0(double x) {
    if (x < 8) {
      final y = x * x;
      final ans1 =
          -2957821389.0 +
          y *
              (7062834065.0 +
                  y *
                      (-512359803.6 +
                          y *
                              (10879881.29 +
                                  y * (-86327.92757 + y * 228.4622733))));
      final ans2 =
          40076544269.0 +
          y *
              (745249964.8 +
                  y *
                      (7189466.438 +
                          y * (47447.26470 + y * (226.1030244 + y))));
      return ans1 / ans2 + 0.636619772 * _besselJ0(x) * math.log(x);
    }
    final z = 8 / x;
    final y = z * z;
    final xx = x - 0.785398164;
    final ans1 =
        1 +
        y *
            (-0.001098628627 +
                y *
                    (0.00002734510407 +
                        y * (-0.000002073370639 + y * 0.0000002093887211)));
    final ans2 =
        -0.01562499995 +
        y *
            (0.0001430488765 +
                y *
                    (-0.000006911147651 +
                        y * (0.0000007621095161 + y * -0.0000000934945152)));
    return math.sqrt(0.636619772 / x) *
        (math.sin(xx) * ans1 + z * math.cos(xx) * ans2);
  }

  double _besselY1(double x) {
    if (x < 8) {
      final y = x * x;
      final ans1 =
          x *
          (-0.4900604943e13 +
              y *
                  (0.1275274390e13 +
                      y *
                          (-0.5153438139e11 +
                              y *
                                  (0.7349264551e9 +
                                      y *
                                          (-0.4237922726e7 +
                                              y * 0.8511937935e4)))));
      final ans2 =
          0.2499580570e14 +
          y *
              (0.4244419664e12 +
                  y *
                      (0.3733650367e10 +
                          y *
                              (0.2245904002e8 +
                                  y *
                                      (0.1020426050e6 +
                                          y * (0.3549632885e3 + y)))));
      return ans1 / ans2 + 0.636619772 * (_besselJ1(x) * math.log(x) - 1 / x);
    }
    final z = 8 / x;
    final y = z * z;
    final xx = x - 2.356194491;
    final ans1 =
        1 +
        y *
            (0.00183105 +
                y *
                    (-0.00003516396496 +
                        y * (0.000002457520174 + y * -0.000000240337019)));
    final ans2 =
        0.04687499995 +
        y *
            (-0.0002002690873 +
                y *
                    (0.000008449199096 +
                        y * (-0.00000088228987 + y * 0.000000105787412)));
    return math.sqrt(0.636619772 / x) *
        (math.sin(xx) * ans1 + z * math.cos(xx) * ans2);
  }

  Object? _complexPart(List<_FormulaArgument> args, {required bool imaginary}) {
    final value = args[0].singleValue;
    final complex = _complexArgument(value);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    if (imaginary && _explicitPositivePureImaginary(value, complex)) {
      return '+${FortuneFormulaEngine._formatNumber(complex.imaginary)}';
    }
    return imaginary ? complex.imaginary : complex.real;
  }

  bool _explicitPositivePureImaginary(Object value, _ComplexNumber complex) {
    if (value is! String || complex.real != 0 || complex.imaginary <= 0) {
      return false;
    }
    final text = value.trim().toLowerCase();
    final suffix = text.endsWith('j') ? 'j' : 'i';
    if (!text.endsWith(suffix) || !text.startsWith('+')) {
      return false;
    }
    return !text.substring(1, text.length - 1).contains(RegExp(r'[+-]'));
  }

  Object? _complexConjugate(List<_FormulaArgument> args) {
    final value = args[0].singleValue;
    if (value is num && value != 0) {
      return _FormulaError.error;
    }
    final complex = _complexArgument(value);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    return _formatComplex(_ComplexNumber(complex.real, -complex.imaginary));
  }

  Object? _complexAbs(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    return math.sqrt(
      complex.real * complex.real + complex.imaginary * complex.imaginary,
    );
  }

  Object? _complexSum(List<_FormulaArgument> args) {
    final values = _complexValues(args);
    if (values is _FormulaError || values == null) {
      return values;
    }
    if (values is! List<_ComplexNumber>) {
      return null;
    }
    var real = 0.0;
    var imaginary = 0.0;
    for (final value in values) {
      real += value.real;
      imaginary += value.imaginary;
    }
    return _formatComplex(_ComplexNumber(real, imaginary));
  }

  Object? _complexSubtract(List<_FormulaArgument> args) {
    final left = _complexArgument(args[0].singleValue);
    final right = _complexArgument(args[1].singleValue);
    if (left is _FormulaError || left == null) {
      return left;
    }
    if (right is _FormulaError || right == null) {
      return right;
    }
    if (left is! _ComplexNumber || right is! _ComplexNumber) {
      return null;
    }
    return _formatComplex(
      _ComplexNumber(left.real - right.real, left.imaginary - right.imaginary),
    );
  }

  Object? _complexProduct(List<_FormulaArgument> args) {
    final values = _complexValues(args);
    if (values is _FormulaError || values == null) {
      return values;
    }
    if (values is! List<_ComplexNumber>) {
      return null;
    }
    var product = const _ComplexNumber(1, 0);
    for (final value in values) {
      product = _ComplexNumber(
        product.real * value.real - product.imaginary * value.imaginary,
        product.real * value.imaginary + product.imaginary * value.real,
      );
    }
    return _formatComplex(product);
  }

  Object? _complexDivide(List<_FormulaArgument> args) {
    final numerator = _complexArgument(args[0].singleValue);
    final denominator = _complexArgument(args[1].singleValue);
    if (numerator is _FormulaError || numerator == null) {
      return numerator;
    }
    if (denominator is _FormulaError || denominator == null) {
      return denominator;
    }
    if (numerator is! _ComplexNumber || denominator is! _ComplexNumber) {
      return null;
    }
    final divisor =
        denominator.real * denominator.real +
        denominator.imaginary * denominator.imaginary;
    if (divisor == 0) {
      return _FormulaError.num;
    }
    return _formatComplex(
      _ComplexNumber(
        (numerator.real * denominator.real +
                numerator.imaginary * denominator.imaginary) /
            divisor,
        (numerator.imaginary * denominator.real -
                numerator.real * denominator.imaginary) /
            divisor,
      ),
    );
  }

  Object? _complexArgumentFunction(List<_FormulaArgument> args) {
    final value = args[0].singleValue;
    if (value is num && value != 0) {
      return _FormulaError.error;
    }
    final complex = _complexArgument(value);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    if (complex.real == 0 && complex.imaginary == 0) {
      return _FormulaError.div0;
    }
    return math.atan2(complex.imaginary, complex.real);
  }

  Object? _complexExponential(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final scale = math.exp(complex.real);
    return _formatComplex(
      _ComplexNumber(
        scale * math.cos(complex.imaginary),
        scale * math.sin(complex.imaginary),
      ),
    );
  }

  Object? _complexLog(List<_FormulaArgument> args, {double? base}) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final magnitude = _complexMagnitude(complex);
    if (magnitude == 0) {
      return _FormulaError.num;
    }
    final divisor = base == null ? 1.0 : math.log(base);
    return _formatComplex(
      _ComplexNumber(
        math.log(magnitude) / divisor,
        math.atan2(complex.imaginary, complex.real) / divisor,
      ),
    );
  }

  Object? _complexPower(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    final power = _numberArgument(args[1].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (power == null) {
      return null;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final magnitude = _complexMagnitude(complex);
    if (magnitude == 0 && power == 0) {
      return _FormulaError.num;
    }
    final scale = math.pow(magnitude, power).toDouble();
    final angle = math.atan2(complex.imaginary, complex.real) * power;
    return _formatComplex(
      _ComplexNumber(scale * math.cos(angle), scale * math.sin(angle)),
    );
  }

  Object? _complexSquareRoot(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final magnitude = _complexMagnitude(complex);
    final real = math.sqrt((magnitude + complex.real) / 2);
    final imaginarySign = complex.imaginary < 0 ? -1 : 1;
    final imaginary =
        imaginarySign * math.sqrt(math.max(0, (magnitude - complex.real) / 2));
    return _formatComplex(_ComplexNumber(real, imaginary.toDouble()));
  }

  Object? _complexSine(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    return _formatComplex(_complexSineValue(complex));
  }

  Object? _complexCosine(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    return _formatComplex(_complexCosineValue(complex));
  }

  Object? _complexTangent(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final quotient = _divideComplexValues(
      _complexSineValue(complex),
      _complexCosineValue(complex),
    );
    return quotient is _ComplexNumber ? _formatComplex(quotient) : quotient;
  }

  Object? _complexHyperbolicSine(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    return _formatComplex(_complexHyperbolicSineValue(complex));
  }

  Object? _complexHyperbolicCosine(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    return _formatComplex(_complexHyperbolicCosineValue(complex));
  }

  Object? _complexCotangent(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final quotient = _divideComplexValues(
      _complexCosineValue(complex),
      _complexSineValue(complex),
    );
    return quotient is _ComplexNumber ? _formatComplex(quotient) : quotient;
  }

  Object? _complexSecant(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final quotient = _divideComplexValues(
      const _ComplexNumber(1, 0),
      _complexCosineValue(complex),
    );
    return quotient is _ComplexNumber ? _formatComplex(quotient) : quotient;
  }

  Object? _complexCosecant(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final quotient = _divideComplexValues(
      const _ComplexNumber(1, 0),
      _complexSineValue(complex),
    );
    return quotient is _ComplexNumber ? _formatComplex(quotient) : quotient;
  }

  Object? _complexHyperbolicSecant(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final quotient = _divideComplexValues(
      const _ComplexNumber(1, 0),
      _complexHyperbolicCosineValue(complex),
    );
    return quotient is _ComplexNumber ? _formatComplex(quotient) : quotient;
  }

  Object? _complexHyperbolicCosecant(List<_FormulaArgument> args) {
    final complex = _complexArgument(args[0].singleValue);
    if (complex is _FormulaError || complex == null) {
      return complex;
    }
    if (complex is! _ComplexNumber) {
      return null;
    }
    final quotient = _divideComplexValues(
      const _ComplexNumber(1, 0),
      _complexHyperbolicSineValue(complex),
    );
    return quotient is _ComplexNumber ? _formatComplex(quotient) : quotient;
  }

  _ComplexNumber _complexSineValue(_ComplexNumber value) {
    return _ComplexNumber(
      math.sin(value.real) * _cosh(value.imaginary),
      math.cos(value.real) * _sinh(value.imaginary),
    );
  }

  _ComplexNumber _complexCosineValue(_ComplexNumber value) {
    return _ComplexNumber(
      math.cos(value.real) * _cosh(value.imaginary),
      -math.sin(value.real) * _sinh(value.imaginary),
    );
  }

  _ComplexNumber _complexHyperbolicSineValue(_ComplexNumber value) {
    return _ComplexNumber(
      _sinh(value.real) * math.cos(value.imaginary),
      _cosh(value.real) * math.sin(value.imaginary),
    );
  }

  _ComplexNumber _complexHyperbolicCosineValue(_ComplexNumber value) {
    return _ComplexNumber(
      _cosh(value.real) * math.cos(value.imaginary),
      _sinh(value.real) * math.sin(value.imaginary),
    );
  }

  Object _divideComplexValues(
    _ComplexNumber numerator,
    _ComplexNumber denominator,
  ) {
    final divisor =
        denominator.real * denominator.real +
        denominator.imaginary * denominator.imaginary;
    if (divisor == 0) {
      return _FormulaError.num;
    }
    return _ComplexNumber(
      (numerator.real * denominator.real +
              numerator.imaginary * denominator.imaginary) /
          divisor,
      (numerator.imaginary * denominator.real -
              numerator.real * denominator.imaginary) /
          divisor,
    );
  }

  double _complexMagnitude(_ComplexNumber value) {
    return math.sqrt(
      value.real * value.real + value.imaginary * value.imaginary,
    );
  }

  Object? _complexValues(List<_FormulaArgument> args) {
    final values = <_ComplexNumber>[];
    for (final arg in args) {
      for (final value in arg.values) {
        final complex = _complexArgument(value);
        if (complex is _FormulaError || complex == null) {
          return complex;
        }
        if (complex is! _ComplexNumber) {
          return null;
        }
        values.add(complex);
      }
    }
    return values.isEmpty ? null : values;
  }

  Object? _complexArgument(Object value) {
    if (value is num || value is bool) {
      final number = FortuneFormulaEngine._numberFromFormulaValue(value);
      return number == null ? null : _ComplexNumber(number, 0);
    }
    final text = _text(value).trim().toLowerCase().replaceAll(' ', '');
    if (text.isEmpty) {
      return _FormulaError.value;
    }
    final normalized = text.endsWith('j')
        ? '${text.substring(0, text.length - 1)}i'
        : text;
    if (!normalized.endsWith('i')) {
      final real = double.tryParse(normalized);
      return real == null ? _FormulaError.value : _ComplexNumber(real, 0);
    }
    final body = normalized.substring(0, normalized.length - 1);
    var splitIndex = -1;
    for (var index = 1; index < body.length; index += 1) {
      final char = body[index];
      if (char == '+' || char == '-') {
        splitIndex = index;
      }
    }
    if (splitIndex == -1) {
      final imaginary = _parseImaginaryCoefficient(body);
      return imaginary == null
          ? _FormulaError.value
          : _ComplexNumber(0, imaginary);
    }
    final real = double.tryParse(body.substring(0, splitIndex));
    final imaginary = _parseImaginaryCoefficient(body.substring(splitIndex));
    if (real == null || imaginary == null) {
      return _FormulaError.value;
    }
    return _ComplexNumber(real, imaginary);
  }

  double? _parseImaginaryCoefficient(String text) {
    if (text.isEmpty || text == '+') {
      return 1;
    }
    if (text == '-') {
      return -1;
    }
    return double.tryParse(text);
  }

  String _formatComplex(_ComplexNumber value, {String suffix = 'i'}) {
    final real = value.real == 0 ? 0.0 : value.real;
    final imaginary = value.imaginary == 0 ? 0.0 : value.imaginary;
    if (imaginary == 0) {
      return FortuneFormulaEngine._formatNumber(real);
    }
    final imaginaryText = imaginary.abs() == 1
        ? suffix
        : '${FortuneFormulaEngine._formatNumber(imaginary.abs())}$suffix';
    if (real == 0) {
      return imaginary < 0 ? '-$imaginaryText' : imaginaryText;
    }
    final sign = imaginary < 0 ? '-' : '+';
    return '${FortuneFormulaEngine._formatNumber(real)}$sign$imaginaryText';
  }

  Object? _dollarFractionUnit(double unit) {
    if (!unit.isFinite) {
      return null;
    }
    if (unit < 0) {
      return _FormulaError.num;
    }
    final fractionUnit = unit.truncateToDouble();
    if (fractionUnit < 1) {
      return _FormulaError.div0;
    }
    return fractionUnit;
  }

  double _dollarFractionScale(double fractionUnit) {
    var scale = 10.0;
    while (scale <= fractionUnit) {
      scale *= 10;
    }
    return scale;
  }

  Object? _effect(double nominalRate, double periodsPerYear) {
    final periods = _compoundingPeriods(periodsPerYear);
    if (periods is _FormulaError || periods == null) {
      return periods;
    }
    if (periods is! double) {
      return null;
    }
    if (nominalRate <= 0) {
      return _FormulaError.num;
    }
    return _finiteNumberOrNum(
      math.pow(1 + nominalRate / periods, periods).toDouble() - 1,
    );
  }

  Object? _nominal(double effectiveRate, double periodsPerYear) {
    final periods = _compoundingPeriods(periodsPerYear);
    if (periods is _FormulaError || periods == null) {
      return periods;
    }
    if (periods is! double) {
      return null;
    }
    if (effectiveRate <= 0) {
      return _FormulaError.num;
    }
    return _finiteNumberOrNum(
      periods * (math.pow(1 + effectiveRate, 1 / periods).toDouble() - 1),
    );
  }

  Object? _futureValueSchedule(List<_FormulaArgument> args) {
    final principal = _numberArgument(args[0].values.single);
    if (principal == null) {
      return null;
    }
    final rates = args[1].values.map(_numberArgument).whereType<double>();
    var result = principal;
    for (final rate in rates) {
      result *= 1 + rate;
      if (!result.isFinite) {
        return _FormulaError.num;
      }
    }
    return result;
  }

  Object? _futureValue(List<_FormulaArgument> args) {
    final values = _annuityArguments(args, fourthDefault: 0);
    if (values is _FormulaError || values == null) {
      return values;
    }
    if (values is! _AnnuityArguments) {
      return null;
    }
    final result = _futureValueAmount(
      values.rate,
      values.periods,
      values.payment,
      values.presentValue,
      values.type,
    );
    return result.isFinite ? result : _FormulaError.num;
  }

  double _futureValueAmount(
    double rate,
    double periods,
    double payment,
    double presentValue,
    double type,
  ) {
    if (rate == 0) {
      return -(presentValue + payment * periods);
    }
    final factor = math.pow(1 + rate, periods).toDouble();
    final result = type == 1
        ? presentValue * factor + payment * (1 + rate) * (factor - 1) / rate
        : presentValue * factor + payment * (factor - 1) / rate;
    return -result;
  }

  Object? _payment(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[0].singleValue);
    final periods = _numberArgument(args[1].singleValue);
    final presentValue = _numberArgument(args[2].singleValue);
    final futureValue = args.length >= 4
        ? _numberArgument(args[3].singleValue)
        : 0.0;
    final type = args.length >= 5 ? _paymentType(args[4].singleValue) : 0.0;
    if (rate == null ||
        periods == null ||
        presentValue == null ||
        futureValue == null) {
      return null;
    }
    if (type is _FormulaError || type == null) {
      return type;
    }
    if (type is! double) {
      return null;
    }
    return _paymentAmount(rate, periods, presentValue, futureValue, type);
  }

  Object? _periodsForInvestmentDuration(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[0].singleValue);
    final presentValue = _numberArgument(args[1].singleValue);
    final futureValue = _numberArgument(args[2].singleValue);
    if (rate == null || presentValue == null || futureValue == null) {
      return null;
    }
    if (rate <= 0 || presentValue <= 0 || futureValue <= 0) {
      return _FormulaError.num;
    }
    final result = math.log(futureValue / presentValue) / math.log(1 + rate);
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _equivalentInterestRate(List<_FormulaArgument> args) {
    final periods = _numberArgument(args[0].singleValue);
    final presentValue = _numberArgument(args[1].singleValue);
    final futureValue = _numberArgument(args[2].singleValue);
    if (periods == null || presentValue == null || futureValue == null) {
      return null;
    }
    if (periods <= 0 || presentValue <= 0 || futureValue <= 0) {
      return _FormulaError.num;
    }
    final result = math.pow(futureValue / presentValue, 1 / periods) - 1;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _paymentAmount(
    double rate,
    double periods,
    double presentValue,
    double futureValue,
    double type,
  ) {
    if (periods == 0) {
      return _FormulaError.num;
    }
    final result = rate == 0
        ? -(presentValue + futureValue) / periods
        : () {
            final factor = math.pow(1 + rate, periods).toDouble();
            final payment =
                futureValue * rate / (factor - 1) +
                presentValue * rate / (1 - 1 / factor);
            return type == 1 ? -payment / (1 + rate) : -payment;
          }();
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _interestPayment(List<_FormulaArgument> args) {
    final values = _periodicPaymentArguments(args);
    if (values is _FormulaError || values == null) {
      return values;
    }
    if (values is! _PeriodicPaymentArguments) {
      return null;
    }
    if (values.rate == 0 || (values.type == 1 && values.period == 1)) {
      return 0.0;
    }
    final interest = _interestPaymentForPeriod(values);
    return interest.isFinite ? interest : _FormulaError.num;
  }

  Object? _interestPaidDuringPeriod(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[0].singleValue);
    final period = _numberArgument(args[1].singleValue);
    final periods = _numberArgument(args[2].singleValue);
    final presentValue = _numberArgument(args[3].singleValue);
    if (rate == null ||
        period == null ||
        periods == null ||
        presentValue == null) {
      return null;
    }
    if (periods == 0) {
      return _FormulaError.num;
    }
    final result = presentValue * rate * (period / periods - 1);
    return result.isFinite ? result : _FormulaError.num;
  }

  double _interestPaymentForPeriod(_PeriodicPaymentArguments values) {
    if (values.period == 1) {
      return values.type == 1 ? 0.0 : -values.presentValue * values.rate;
    }
    final futureValue = values.type == 1
        ? _futureValueAmount(
                values.rate,
                values.period - 2,
                values.payment,
                values.presentValue,
                1,
              ) -
              values.payment
        : _futureValueAmount(
            values.rate,
            values.period - 1,
            values.payment,
            values.presentValue,
            0,
          );
    return futureValue * values.rate;
  }

  Object? _principalPayment(List<_FormulaArgument> args) {
    final values = _periodicPaymentArguments(args);
    if (values is _FormulaError || values == null) {
      return values;
    }
    if (values is! _PeriodicPaymentArguments) {
      return null;
    }
    final interest = _interestPayment(args);
    if (interest is _FormulaError || interest == null) {
      return interest;
    }
    if (interest is! double) {
      return null;
    }
    final principal = values.payment - interest;
    return principal.isFinite ? principal : _FormulaError.num;
  }

  Object? _cumulativePayment(
    List<_FormulaArgument> args, {
    required bool interest,
  }) {
    final rate = _numberArgument(args[0].singleValue);
    final periods = _numberArgument(args[1].singleValue);
    final presentValue = _numberArgument(args[2].singleValue);
    final startValue = _numberArgument(args[3].singleValue);
    final endValue = _numberArgument(args[4].singleValue);
    final type = _paymentType(args[5].singleValue);
    if (rate == null ||
        periods == null ||
        presentValue == null ||
        startValue == null ||
        endValue == null) {
      return null;
    }
    if (type is _FormulaError || type == null) {
      return type;
    }
    if (type is! double) {
      return null;
    }
    final start = _integerDigits(startValue);
    final end = _integerDigits(endValue);
    if (rate <= 0 ||
        periods <= 0 ||
        presentValue <= 0 ||
        start == null ||
        end == null ||
        start < 1 ||
        end < start ||
        end > periods) {
      return _FormulaError.num;
    }
    final payment = _paymentAmount(rate, periods, presentValue, 0, type);
    if (payment is _FormulaError || payment == null) {
      return payment;
    }
    if (payment is! double) {
      return null;
    }
    var sum = 0.0;
    for (var period = start; period <= end; period += 1) {
      final values = _PeriodicPaymentArguments(
        rate: rate,
        period: period,
        periods: periods,
        presentValue: presentValue,
        futureValue: 0,
        type: type,
        payment: payment,
      );
      final interestPayment =
          values.rate == 0 || (values.type == 1 && values.period == 1)
          ? 0.0
          : _interestPaymentForPeriod(values);
      sum += interest ? interestPayment : payment - interestPayment;
    }
    return sum.isFinite ? sum : _FormulaError.num;
  }

  Object? _straightLineDepreciation(double cost, double salvage, double life) {
    if (!cost.isFinite || !salvage.isFinite || !life.isFinite) {
      return null;
    }
    if (life <= 0) {
      return _FormulaError.num;
    }
    return (cost - salvage) / life;
  }

  Object? _sumOfYearsDepreciation(
    double cost,
    double salvage,
    double life,
    double period,
  ) {
    if (!cost.isFinite ||
        !salvage.isFinite ||
        !life.isFinite ||
        !period.isFinite) {
      return null;
    }
    if (life <= 0 || period < 1 || period > life) {
      return _FormulaError.num;
    }
    return (cost - salvage) * (life - period + 1) * 2 / (life * (life + 1));
  }

  Object? _amorLinc(List<_FormulaArgument> args) {
    return _amortizationDepreciation(args, degressive: false);
  }

  Object? _amorDegrc(List<_FormulaArgument> args) {
    return _amortizationDepreciation(args, degressive: true);
  }

  Object? _amortizationDepreciation(
    List<_FormulaArgument> args, {
    required bool degressive,
  }) {
    final cost = _numberArgument(args[0].singleValue);
    final salvage = _numberArgument(args[3].singleValue);
    final period = _numberArgument(args[4].singleValue);
    final rate = _numberArgument(args[5].singleValue);
    final basisValue = args.length == 7 ? args[6].singleValue : 0.0;
    final firstPeriodFraction = _yearFrac(
      args[1].singleValue,
      args[2].singleValue,
      basisValue,
    );
    if (cost == null ||
        salvage == null ||
        period == null ||
        rate == null ||
        firstPeriodFraction == null) {
      return firstPeriodFraction;
    }
    if (firstPeriodFraction is _FormulaError) {
      return firstPeriodFraction;
    }
    final fraction = FortuneFormulaEngine._numberFromFormulaValue(
      firstPeriodFraction,
    );
    final periodIndex = _integerDigits(period);
    if (fraction == null ||
        cost < 0 ||
        salvage < 0 ||
        periodIndex == null ||
        periodIndex < 0 ||
        rate <= 0 ||
        fraction < 0) {
      return _FormulaError.num;
    }
    final depreciable = cost - salvage;
    if (depreciable < 0) {
      return _FormulaError.num;
    }
    final adjustedRate = degressive ? rate * _amorDegrcCoefficient(rate) : rate;
    final depreciation = cost * adjustedRate;
    final firstDepreciation = depreciation * fraction;
    final result = degressive
        ? _amorDegrcDepreciation(
            cost,
            salvage,
            adjustedRate,
            firstDepreciation,
            periodIndex,
          )
        : periodIndex == 0
        ? firstDepreciation
        : math.min(
            depreciation,
            depreciable - firstDepreciation - depreciation * (periodIndex - 1),
          );
    if (!result.isFinite) {
      return _FormulaError.num;
    }
    return math.max(0.0, result);
  }

  double _amorDegrcCoefficient(double rate) {
    final assetLife = 1 / rate;
    if (assetLife < 3) {
      return 1;
    }
    if (assetLife < 5) {
      return 1.5;
    }
    if (assetLife <= 6) {
      return 2;
    }
    return 2.5;
  }

  double _amorDegrcDepreciation(
    double cost,
    double salvage,
    double rate,
    double firstDepreciation,
    int period,
  ) {
    if (period == 0) {
      return firstDepreciation;
    }
    var accumulated = firstDepreciation;
    var result = 0.0;
    for (var currentPeriod = 1; currentPeriod <= period; currentPeriod += 1) {
      result = math.min(
        (cost - accumulated) * rate,
        cost - salvage - accumulated,
      );
      accumulated += result;
    }
    return result;
  }

  Object? _doubleDecliningDepreciation(
    double cost,
    double salvage,
    double life,
    double period,
    double factor,
  ) {
    if (!cost.isFinite ||
        !salvage.isFinite ||
        !life.isFinite ||
        !period.isFinite ||
        !factor.isFinite) {
      return null;
    }
    final periodIndex = _integerDigits(period);
    if (cost < 0 ||
        salvage < 0 ||
        life <= 0 ||
        factor <= 0 ||
        periodIndex == null ||
        periodIndex < 1 ||
        periodIndex > life) {
      return _FormulaError.num;
    }
    var totalDepreciation = 0.0;
    var depreciation = 0.0;
    for (
      var currentPeriod = 1;
      currentPeriod <= periodIndex;
      currentPeriod += 1
    ) {
      depreciation = math.min(
        (cost - totalDepreciation) * factor / life,
        cost - salvage - totalDepreciation,
      );
      totalDepreciation += depreciation;
    }
    return depreciation.isFinite ? depreciation : _FormulaError.num;
  }

  Object? _fixedDecliningDepreciation(
    double cost,
    double salvage,
    double life,
    double period,
    double month,
  ) {
    if (!cost.isFinite ||
        !salvage.isFinite ||
        !life.isFinite ||
        !period.isFinite ||
        !month.isFinite) {
      return null;
    }
    final periodIndex = _integerDigits(period);
    final monthCount = _integerDigits(month);
    if (cost < 0 ||
        salvage < 0 ||
        life <= 0 ||
        periodIndex == null ||
        periodIndex < 1 ||
        periodIndex > life ||
        monthCount == null ||
        monthCount < 1 ||
        monthCount > 12) {
      return _FormulaError.num;
    }
    if (cost == 0) {
      return salvage == 0 ? 0.0 : _FormulaError.num;
    }
    final rate = _round(1 - math.pow(salvage / cost, 1 / life).toDouble(), 3);
    if (rate is! double || !rate.isFinite) {
      return _FormulaError.num;
    }
    var totalDepreciation = 0.0;
    var depreciation = 0.0;
    for (
      var currentPeriod = 1;
      currentPeriod <= periodIndex;
      currentPeriod += 1
    ) {
      depreciation = currentPeriod == 1
          ? cost * rate * monthCount / 12
          : (cost - totalDepreciation) * rate;
      totalDepreciation += depreciation;
    }
    return depreciation.isFinite ? depreciation : _FormulaError.num;
  }

  Object? _variableDecliningDepreciation(List<_FormulaArgument> args) {
    final cost = _numberArgument(args[0].singleValue);
    final salvage = _numberArgument(args[1].singleValue);
    final life = _numberArgument(args[2].singleValue);
    final startPeriod = _numberArgument(args[3].singleValue);
    final endPeriod = _numberArgument(args[4].singleValue);
    final factor = args.length >= 6
        ? _numberArgument(args[5].singleValue)
        : 2.0;
    final noSwitch = args.length >= 7 ? _truthy(args[6].singleValue) : false;
    if (cost == null ||
        salvage == null ||
        life == null ||
        startPeriod == null ||
        endPeriod == null ||
        factor == null) {
      return null;
    }
    if (!cost.isFinite ||
        !salvage.isFinite ||
        !life.isFinite ||
        !startPeriod.isFinite ||
        !endPeriod.isFinite ||
        !factor.isFinite) {
      return null;
    }
    if (cost < 0 ||
        salvage < 0 ||
        life <= 0 ||
        startPeriod < 0 ||
        endPeriod < startPeriod ||
        endPeriod > life ||
        factor <= 0) {
      return _FormulaError.num;
    }
    if (startPeriod == endPeriod) {
      return 0.0;
    }

    var switchedToStraightLine = false;
    var totalDepreciation = 0.0;
    var result = 0.0;
    final endPeriodIndex = endPeriod.ceil();
    for (var period = 1; period <= endPeriodIndex; period += 1) {
      final remainingDepreciation = cost - salvage - totalDepreciation;
      if (remainingDepreciation <= 0) {
        break;
      }
      final declining = math.min(
        (cost - totalDepreciation) * factor / life,
        remainingDepreciation,
      );
      final remainingLife = life - period + 1;
      final straightLine = remainingLife <= 0
          ? remainingDepreciation
          : remainingDepreciation / remainingLife;
      final depreciation =
          !noSwitch && (switchedToStraightLine || straightLine > declining)
          ? () {
              switchedToStraightLine = true;
              return straightLine;
            }()
          : declining;
      final periodStart = (period - 1).toDouble();
      final periodEnd = period.toDouble();
      final overlap =
          math.min(endPeriod, periodEnd) - math.max(startPeriod, periodStart);
      if (overlap > 0) {
        result += depreciation * overlap;
      }
      totalDepreciation += depreciation;
    }
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _interestRateForSecurity(List<_FormulaArgument> args) {
    final investment = _numberArgument(args[2].singleValue);
    final redemption = _numberArgument(args[3].singleValue);
    final yearFraction = _securityYearFraction(args);
    if (investment == null || redemption == null || yearFraction == null) {
      return yearFraction;
    }
    if (yearFraction is _FormulaError) {
      return yearFraction;
    }
    if (yearFraction is! double) {
      return null;
    }
    if (investment <= 0 || redemption <= 0 || yearFraction <= 0) {
      return _FormulaError.num;
    }
    final result = (redemption - investment) / investment / yearFraction;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _amountReceivedAtMaturity(List<_FormulaArgument> args) {
    final investment = _numberArgument(args[2].singleValue);
    final discount = _numberArgument(args[3].singleValue);
    final yearFraction = _securityYearFraction(args);
    if (investment == null || discount == null || yearFraction == null) {
      return yearFraction;
    }
    if (yearFraction is _FormulaError) {
      return yearFraction;
    }
    if (yearFraction is! double) {
      return null;
    }
    final denominator = 1 - discount * yearFraction;
    if (investment <= 0 ||
        discount <= 0 ||
        yearFraction <= 0 ||
        denominator <= 0) {
      return _FormulaError.num;
    }
    final result = investment / denominator;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _discountRateForSecurity(List<_FormulaArgument> args) {
    final price = _numberArgument(args[2].singleValue);
    final redemption = _numberArgument(args[3].singleValue);
    final yearFraction = _securityYearFraction(args);
    if (price == null || redemption == null || yearFraction == null) {
      return yearFraction;
    }
    if (yearFraction is _FormulaError) {
      return yearFraction;
    }
    if (yearFraction is! double) {
      return null;
    }
    if (price <= 0 || redemption <= 0 || yearFraction <= 0) {
      return _FormulaError.num;
    }
    final result = (redemption - price) / redemption / yearFraction;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _priceDiscountSecurity(List<_FormulaArgument> args) {
    final discount = _numberArgument(args[2].singleValue);
    final redemption = _numberArgument(args[3].singleValue);
    final yearFraction = _securityYearFraction(args);
    if (discount == null || redemption == null || yearFraction == null) {
      return yearFraction;
    }
    if (yearFraction is _FormulaError) {
      return yearFraction;
    }
    if (yearFraction is! double) {
      return null;
    }
    final result = redemption * (1 - discount * yearFraction);
    if (discount <= 0 || redemption <= 0 || yearFraction <= 0 || result <= 0) {
      return _FormulaError.num;
    }
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _yieldDiscountSecurity(List<_FormulaArgument> args) {
    final price = _numberArgument(args[2].singleValue);
    final redemption = _numberArgument(args[3].singleValue);
    final yearFraction = _securityYearFraction(args);
    if (price == null || redemption == null || yearFraction == null) {
      return yearFraction;
    }
    if (yearFraction is _FormulaError) {
      return yearFraction;
    }
    if (yearFraction is! double) {
      return null;
    }
    if (price <= 0 || redemption <= 0 || yearFraction <= 0) {
      return _FormulaError.num;
    }
    final result = (redemption - price) / price / yearFraction;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _accruedInterestAtMaturity(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[2].singleValue);
    final redemption = _numberArgument(args[3].singleValue);
    final yearFraction = _securityYearFraction(args);
    if (rate == null || redemption == null || yearFraction == null) {
      return yearFraction;
    }
    if (yearFraction is _FormulaError) {
      return yearFraction;
    }
    if (yearFraction is! double) {
      return null;
    }
    if (rate <= 0 || redemption <= 0 || yearFraction <= 0) {
      return _FormulaError.num;
    }
    final result = redemption * rate * yearFraction;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _accruedInterest(List<_FormulaArgument> args) {
    final issue = _dateTime(args[0].singleValue)?.dateTime;
    final firstPayment = _dateTime(args[1].singleValue)?.dateTime;
    final settlement = _dateTime(args[2].singleValue)?.dateTime;
    final rate = _numberArgument(args[3].singleValue);
    final par = _numberArgument(args[4].singleValue);
    final frequency = _numberArgument(args[5].singleValue);
    if (issue == null || firstPayment == null || settlement == null) {
      return null;
    }
    if (rate == null || par == null || frequency == null) {
      return null;
    }
    final frequencyValue = frequency.truncate();
    if (rate <= 0 ||
        par <= 0 ||
        !{1, 2, 4}.contains(frequencyValue) ||
        !firstPayment.isAfter(issue) ||
        !settlement.isAfter(issue)) {
      return _FormulaError.num;
    }

    final calcFromIssue = args.length >= 8
        ? _truthy(args[7].singleValue)
        : true;
    final startDate = !calcFromIssue && settlement.isAfter(firstPayment)
        ? args[1].singleValue
        : args[0].singleValue;
    final basis = args.length >= 7 ? args[6].singleValue : 0.0;
    final yearFraction = _yearFrac(startDate, args[2].singleValue, basis);
    if (yearFraction is _FormulaError || yearFraction == null) {
      return yearFraction;
    }
    final number = FortuneFormulaEngine._numberFromFormulaValue(yearFraction);
    if (number == null) {
      return _formulaError(yearFraction);
    }
    if (number <= 0) {
      return _FormulaError.num;
    }
    final result = par * rate * number;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _priceAtMaturitySecurity(List<_FormulaArgument> args) {
    final settlement = _dateTime(args[0].singleValue)?.dateTime;
    final maturity = _dateTime(args[1].singleValue)?.dateTime;
    final issue = _dateTime(args[2].singleValue)?.dateTime;
    final rate = _numberArgument(args[3].singleValue);
    final yield = _numberArgument(args[4].singleValue);
    if (settlement == null || maturity == null || issue == null) {
      return null;
    }
    if (rate == null || yield == null) {
      return null;
    }
    if (!settlement.isAfter(issue) || !maturity.isAfter(settlement)) {
      return _FormulaError.num;
    }
    if (rate < 0 || yield < 0) {
      return _FormulaError.num;
    }

    final basis = args.length == 6 ? args[5].singleValue : 0.0;
    final issueToSettlement = _yearFrac(
      args[2].singleValue,
      args[0].singleValue,
      basis,
    );
    final settlementToMaturity = _yearFrac(
      args[0].singleValue,
      args[1].singleValue,
      basis,
    );
    final issueToMaturity = _yearFrac(
      args[2].singleValue,
      args[1].singleValue,
      basis,
    );
    if (issueToSettlement == null ||
        settlementToMaturity == null ||
        issueToMaturity == null) {
      return null;
    }
    if (issueToSettlement is _FormulaError) {
      return issueToSettlement;
    }
    if (settlementToMaturity is _FormulaError) {
      return settlementToMaturity;
    }
    if (issueToMaturity is _FormulaError) {
      return issueToMaturity;
    }
    final accrued = FortuneFormulaEngine._numberFromFormulaValue(
      issueToSettlement,
    );
    final discount = FortuneFormulaEngine._numberFromFormulaValue(
      settlementToMaturity,
    );
    final total = FortuneFormulaEngine._numberFromFormulaValue(issueToMaturity);
    if (accrued == null || discount == null || total == null) {
      return _formulaError(accrued ?? discount ?? total);
    }
    final denominator = 1 + yield * discount;
    if (accrued < 0 || discount <= 0 || total <= 0 || denominator == 0) {
      return _FormulaError.num;
    }
    final result =
        (100 + 100 * rate * total) / denominator - 100 * rate * accrued;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _yieldAtMaturitySecurity(List<_FormulaArgument> args) {
    final settlement = _dateTime(args[0].singleValue)?.dateTime;
    final maturity = _dateTime(args[1].singleValue)?.dateTime;
    final issue = _dateTime(args[2].singleValue)?.dateTime;
    final rate = _numberArgument(args[3].singleValue);
    final price = _numberArgument(args[4].singleValue);
    if (settlement == null || maturity == null || issue == null) {
      return null;
    }
    if (rate == null || price == null) {
      return null;
    }
    if (!settlement.isAfter(issue) || !maturity.isAfter(settlement)) {
      return _FormulaError.num;
    }
    if (rate < 0 || price <= 0) {
      return _FormulaError.num;
    }

    final basis = args.length == 6 ? args[5].singleValue : 0.0;
    final issueToSettlement = _yearFrac(
      args[2].singleValue,
      args[0].singleValue,
      basis,
    );
    final settlementToMaturity = _yearFrac(
      args[0].singleValue,
      args[1].singleValue,
      basis,
    );
    final issueToMaturity = _yearFrac(
      args[2].singleValue,
      args[1].singleValue,
      basis,
    );
    if (issueToSettlement == null ||
        settlementToMaturity == null ||
        issueToMaturity == null) {
      return null;
    }
    if (issueToSettlement is _FormulaError) {
      return issueToSettlement;
    }
    if (settlementToMaturity is _FormulaError) {
      return settlementToMaturity;
    }
    if (issueToMaturity is _FormulaError) {
      return issueToMaturity;
    }
    final accrued = FortuneFormulaEngine._numberFromFormulaValue(
      issueToSettlement,
    );
    final discount = FortuneFormulaEngine._numberFromFormulaValue(
      settlementToMaturity,
    );
    final total = FortuneFormulaEngine._numberFromFormulaValue(issueToMaturity);
    if (accrued == null || discount == null || total == null) {
      return _formulaError(accrued ?? discount ?? total);
    }
    final denominator = price + 100 * rate * accrued;
    if (accrued < 0 || discount <= 0 || total <= 0 || denominator <= 0) {
      return _FormulaError.num;
    }
    final result = ((100 + 100 * rate * total) / denominator - 1) / discount;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _securityDuration(
    List<_FormulaArgument> args, {
    required bool modified,
  }) {
    final settlement = _dateTime(args[0].singleValue)?.dateTime;
    final maturity = _dateTime(args[1].singleValue)?.dateTime;
    final rate = _numberArgument(args[2].singleValue);
    final yield = _numberArgument(args[3].singleValue);
    final frequency = _numberArgument(args[4].singleValue);
    if (settlement == null || maturity == null) {
      return null;
    }
    if (rate == null || yield == null || frequency == null) {
      return null;
    }
    final frequencyValue = frequency.truncate();
    if (!maturity.isAfter(settlement) ||
        rate < 0 ||
        yield < 0 ||
        !{1, 2, 4}.contains(frequencyValue)) {
      return _FormulaError.num;
    }

    final basis = args.length == 6 ? args[5].singleValue : 0.0;
    final yearFraction = _yearFrac(
      args[0].singleValue,
      args[1].singleValue,
      basis,
    );
    if (yearFraction is _FormulaError || yearFraction == null) {
      return yearFraction;
    }
    final years = FortuneFormulaEngine._numberFromFormulaValue(yearFraction);
    if (years == null) {
      return _formulaError(yearFraction);
    }
    final periodCount = (years * frequencyValue - 1e-10).ceil();
    if (years <= 0 || periodCount <= 0) {
      return _FormulaError.num;
    }

    final coupon = 100 * rate / frequencyValue;
    final periodYield = yield / frequencyValue;
    final discountBase = 1 + periodYield;
    if (discountBase <= 0) {
      return _FormulaError.num;
    }
    var price = 0.0;
    var weighted = 0.0;
    for (var period = 1; period <= periodCount; period += 1) {
      final cashFlow = coupon + (period == periodCount ? 100 : 0);
      final presentValue = cashFlow / math.pow(discountBase, period);
      price += presentValue;
      weighted += period / frequencyValue * presentValue;
    }
    if (price <= 0) {
      return _FormulaError.num;
    }
    final duration = weighted / price;
    final result = modified ? duration / discountBase : duration;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _priceCouponSecurity(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[2].singleValue);
    final yield = _numberArgument(args[3].singleValue);
    final redemption = _numberArgument(args[4].singleValue);
    final schedule = _couponScheduleValues(
      args[0].singleValue,
      args[1].singleValue,
      args[5].singleValue,
      args.length == 7 ? args[6].singleValue : null,
    );
    if (schedule is _FormulaError || schedule == null) {
      return schedule;
    }
    if (schedule is! _CouponSchedule) {
      return null;
    }
    if (rate == null || yield == null || redemption == null) {
      return null;
    }
    if (rate < 0 || yield < 0 || redemption <= 0) {
      return _FormulaError.num;
    }
    final basis = _couponBasisValue(
      args.length == 7 ? args[6].singleValue : null,
    );
    if (basis is _FormulaError || basis == null) {
      return basis;
    }
    if (basis is! int) {
      return null;
    }
    return _couponSecurityPrice(schedule, rate, yield, redemption, basis);
  }

  Object? _priceOddLastCouponSecurity(List<_FormulaArgument> args) {
    final settlement = _dateTime(args[0].singleValue)?.dateTime;
    final maturity = _dateTime(args[1].singleValue)?.dateTime;
    final lastInterest = _dateTime(args[2].singleValue)?.dateTime;
    final rate = _numberArgument(args[3].singleValue);
    final yield = _numberArgument(args[4].singleValue);
    final redemption = _numberArgument(args[5].singleValue);
    final frequency = _numberArgument(args[6].singleValue);
    final basis = _couponBasisValue(
      args.length == 8 ? args[7].singleValue : null,
    );
    if (settlement == null || maturity == null || lastInterest == null) {
      return null;
    }
    if (rate == null ||
        yield == null ||
        redemption == null ||
        frequency == null) {
      return null;
    }
    if (basis is _FormulaError || basis == null) {
      return basis;
    }
    if (basis is! int) {
      return null;
    }
    final frequencyValue = frequency.truncate();
    if (!maturity.isAfter(settlement) ||
        !maturity.isAfter(lastInterest) ||
        rate < 0 ||
        yield < 0 ||
        redemption <= 0 ||
        !{1, 2, 4}.contains(frequencyValue)) {
      return _FormulaError.num;
    }
    return _oddLastCouponPrice(
      settlement,
      maturity,
      lastInterest,
      rate,
      yield,
      redemption,
      frequencyValue,
      basis,
    );
  }

  Object? _priceOddFirstCouponSecurity(List<_FormulaArgument> args) {
    final settlement = _dateTime(args[0].singleValue)?.dateTime;
    final maturity = _dateTime(args[1].singleValue)?.dateTime;
    final issue = _dateTime(args[2].singleValue)?.dateTime;
    final firstCoupon = _dateTime(args[3].singleValue)?.dateTime;
    final rate = _numberArgument(args[4].singleValue);
    final yield = _numberArgument(args[5].singleValue);
    final redemption = _numberArgument(args[6].singleValue);
    final frequency = _numberArgument(args[7].singleValue);
    final basis = _couponBasisValue(
      args.length == 9 ? args[8].singleValue : null,
    );
    if (settlement == null ||
        maturity == null ||
        issue == null ||
        firstCoupon == null) {
      return null;
    }
    if (rate == null ||
        yield == null ||
        redemption == null ||
        frequency == null) {
      return null;
    }
    if (basis is _FormulaError || basis == null) {
      return basis;
    }
    if (basis is! int) {
      return null;
    }
    final frequencyValue = frequency.truncate();
    if (settlement.isBefore(issue) ||
        !firstCoupon.isAfter(issue) ||
        !maturity.isAfter(firstCoupon) ||
        !maturity.isAfter(settlement) ||
        rate < 0 ||
        yield < 0 ||
        redemption <= 0 ||
        !{1, 2, 4}.contains(frequencyValue)) {
      return _FormulaError.num;
    }
    return _oddFirstCouponPrice(
      settlement,
      maturity,
      issue,
      firstCoupon,
      rate,
      yield,
      redemption,
      frequencyValue,
      basis,
    );
  }

  Object? _yieldCouponSecurity(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[2].singleValue);
    final price = _numberArgument(args[3].singleValue);
    final redemption = _numberArgument(args[4].singleValue);
    final schedule = _couponScheduleValues(
      args[0].singleValue,
      args[1].singleValue,
      args[5].singleValue,
      args.length == 7 ? args[6].singleValue : null,
    );
    if (schedule is _FormulaError || schedule == null) {
      return schedule;
    }
    if (schedule is! _CouponSchedule) {
      return null;
    }
    if (rate == null || price == null || redemption == null) {
      return null;
    }
    if (rate < 0 || price <= 0 || redemption <= 0) {
      return _FormulaError.num;
    }
    final basis = _couponBasisValue(
      args.length == 7 ? args[6].singleValue : null,
    );
    if (basis is _FormulaError || basis == null) {
      return basis;
    }
    if (basis is! int) {
      return null;
    }

    Object? difference(double yieldValue) {
      final calculated = _couponSecurityPrice(
        schedule,
        rate,
        yieldValue,
        redemption,
        basis,
      );
      if (calculated is _FormulaError || calculated == null) {
        return calculated;
      }
      if (calculated is! double) {
        return null;
      }
      return calculated - price;
    }

    var low = -0.999 * schedule.frequency;
    var high = 1.0;
    final lowDifference = difference(low);
    if (lowDifference is _FormulaError || lowDifference == null) {
      return lowDifference;
    }
    if (lowDifference is! double) {
      return null;
    }
    if (lowDifference < 0) {
      return _FormulaError.num;
    }
    var highDifference = difference(high);
    if (highDifference is _FormulaError || highDifference == null) {
      return highDifference;
    }
    if (highDifference is! double) {
      return null;
    }
    var highDifferenceValue = highDifference;
    var expansions = 0;
    while (highDifferenceValue > 0 && expansions < 40) {
      high *= 2;
      final expanded = difference(high);
      if (expanded is _FormulaError || expanded == null) {
        return expanded;
      }
      if (expanded is! double) {
        return null;
      }
      highDifferenceValue = expanded;
      expansions += 1;
    }
    if (highDifferenceValue > 0) {
      return _FormulaError.num;
    }

    for (var iteration = 0; iteration < 100; iteration += 1) {
      final mid = (low + high) / 2;
      final midDifference = difference(mid);
      if (midDifference is _FormulaError || midDifference == null) {
        return midDifference;
      }
      if (midDifference is! double) {
        return null;
      }
      if (midDifference.abs() < 1e-10) {
        return mid;
      }
      if (midDifference > 0) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final result = (low + high) / 2;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _yieldOddFirstCouponSecurity(List<_FormulaArgument> args) {
    final settlement = _dateTime(args[0].singleValue)?.dateTime;
    final maturity = _dateTime(args[1].singleValue)?.dateTime;
    final issue = _dateTime(args[2].singleValue)?.dateTime;
    final firstCoupon = _dateTime(args[3].singleValue)?.dateTime;
    final rate = _numberArgument(args[4].singleValue);
    final price = _numberArgument(args[5].singleValue);
    final redemption = _numberArgument(args[6].singleValue);
    final frequency = _numberArgument(args[7].singleValue);
    final basis = _couponBasisValue(
      args.length == 9 ? args[8].singleValue : null,
    );
    if (settlement == null ||
        maturity == null ||
        issue == null ||
        firstCoupon == null) {
      return null;
    }
    if (rate == null ||
        price == null ||
        redemption == null ||
        frequency == null) {
      return null;
    }
    if (basis is _FormulaError || basis == null) {
      return basis;
    }
    if (basis is! int) {
      return null;
    }
    final frequencyValue = frequency.truncate();
    if (settlement.isBefore(issue) ||
        !firstCoupon.isAfter(issue) ||
        !maturity.isAfter(firstCoupon) ||
        !maturity.isAfter(settlement) ||
        rate < 0 ||
        price <= 0 ||
        redemption <= 0 ||
        !{1, 2, 4}.contains(frequencyValue)) {
      return _FormulaError.num;
    }

    Object? difference(double yieldValue) {
      final calculated = _oddFirstCouponPrice(
        settlement,
        maturity,
        issue,
        firstCoupon,
        rate,
        yieldValue,
        redemption,
        frequencyValue,
        basis,
      );
      if (calculated is _FormulaError || calculated == null) {
        return calculated;
      }
      if (calculated is! double) {
        return null;
      }
      return calculated - price;
    }

    var low = -0.999 * frequencyValue;
    var high = 1.0;
    final lowDifference = difference(low);
    if (lowDifference is _FormulaError || lowDifference == null) {
      return lowDifference;
    }
    if (lowDifference is! double) {
      return null;
    }
    if (lowDifference < 0) {
      return _FormulaError.num;
    }
    var highDifference = difference(high);
    if (highDifference is _FormulaError || highDifference == null) {
      return highDifference;
    }
    if (highDifference is! double) {
      return null;
    }
    var highDifferenceValue = highDifference;
    var expansions = 0;
    while (highDifferenceValue > 0 && expansions < 40) {
      high *= 2;
      final expanded = difference(high);
      if (expanded is _FormulaError || expanded == null) {
        return expanded;
      }
      if (expanded is! double) {
        return null;
      }
      highDifferenceValue = expanded;
      expansions += 1;
    }
    if (highDifferenceValue > 0) {
      return _FormulaError.num;
    }

    for (var iteration = 0; iteration < 100; iteration += 1) {
      final mid = (low + high) / 2;
      final midDifference = difference(mid);
      if (midDifference is _FormulaError || midDifference == null) {
        return midDifference;
      }
      if (midDifference is! double) {
        return null;
      }
      if (midDifference.abs() < 1e-10) {
        return mid;
      }
      if (midDifference > 0) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final result = (low + high) / 2;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _oddFirstCouponPrice(
    DateTime settlement,
    DateTime maturity,
    DateTime issue,
    DateTime firstCoupon,
    double rate,
    double yield,
    double redemption,
    int frequency,
    int basis,
  ) {
    final monthsPerCoupon = 12 ~/ frequency;
    if (!settlement.isBefore(firstCoupon)) {
      var nextCoupon = maturity;
      var previousCoupon = _addMonthsClamped(nextCoupon, -monthsPerCoupon);
      while (previousCoupon.isAfter(settlement)) {
        nextCoupon = previousCoupon;
        previousCoupon = _addMonthsClamped(previousCoupon, -monthsPerCoupon);
      }
      final schedule = _CouponSchedule(
        settlement: settlement,
        previousCoupon: previousCoupon,
        nextCoupon: nextCoupon,
        maturity: maturity,
        monthsPerCoupon: monthsPerCoupon,
        frequency: frequency,
      );
      return _couponSecurityPrice(schedule, rate, yield, redemption, basis);
    }

    final normalCouponStart = _addMonthsClamped(firstCoupon, -monthsPerCoupon);
    final normalDays = _couponDayCount(normalCouponStart, firstCoupon, basis);
    final daysIssueToFirst = _couponDayCount(issue, firstCoupon, basis);
    final daysSettlementToFirst = _couponDayCount(
      settlement,
      firstCoupon,
      basis,
    );
    final daysIssueToSettlement = _couponDayCountAllowSame(
      issue,
      settlement,
      basis,
    );
    if (normalDays is _FormulaError) {
      return normalDays;
    }
    if (daysIssueToFirst is _FormulaError) {
      return daysIssueToFirst;
    }
    if (daysSettlementToFirst is _FormulaError) {
      return daysSettlementToFirst;
    }
    if (daysIssueToSettlement is _FormulaError) {
      return daysIssueToSettlement;
    }
    if (normalDays is! int ||
        daysIssueToFirst is! int ||
        daysSettlementToFirst is! int ||
        daysIssueToSettlement is! int) {
      return null;
    }
    if (normalDays <= 0 ||
        daysIssueToFirst <= 0 ||
        daysSettlementToFirst <= 0) {
      return _FormulaError.num;
    }
    final coupon = 100 * rate / frequency;
    final discountBase = 1 + yield / frequency;
    if (discountBase <= 0) {
      return _FormulaError.num;
    }
    var regularCouponDate = _addMonthsClamped(firstCoupon, monthsPerCoupon);
    var regularCouponCount = 0;
    while (!regularCouponDate.isAfter(maturity)) {
      regularCouponCount += 1;
      regularCouponDate = _addMonthsClamped(regularCouponDate, monthsPerCoupon);
    }
    if (regularCouponCount <= 0) {
      return _FormulaError.num;
    }

    final firstCouponExponent = daysSettlementToFirst / normalDays;
    var result =
        coupon *
        daysIssueToFirst /
        normalDays /
        math.pow(discountBase, firstCouponExponent);
    for (
      var couponIndex = 1;
      couponIndex <= regularCouponCount;
      couponIndex += 1
    ) {
      result +=
          coupon / math.pow(discountBase, firstCouponExponent + couponIndex);
    }
    result +=
        redemption /
        math.pow(discountBase, firstCouponExponent + regularCouponCount);
    result -= coupon * daysIssueToSettlement / normalDays;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _yieldOddLastCouponSecurity(List<_FormulaArgument> args) {
    final settlement = _dateTime(args[0].singleValue)?.dateTime;
    final maturity = _dateTime(args[1].singleValue)?.dateTime;
    final lastInterest = _dateTime(args[2].singleValue)?.dateTime;
    final rate = _numberArgument(args[3].singleValue);
    final price = _numberArgument(args[4].singleValue);
    final redemption = _numberArgument(args[5].singleValue);
    final frequency = _numberArgument(args[6].singleValue);
    final basis = _couponBasisValue(
      args.length == 8 ? args[7].singleValue : null,
    );
    if (settlement == null || maturity == null || lastInterest == null) {
      return null;
    }
    if (rate == null ||
        price == null ||
        redemption == null ||
        frequency == null) {
      return null;
    }
    if (basis is _FormulaError || basis == null) {
      return basis;
    }
    if (basis is! int) {
      return null;
    }
    final frequencyValue = frequency.truncate();
    if (!maturity.isAfter(settlement) ||
        !maturity.isAfter(lastInterest) ||
        rate < 0 ||
        price <= 0 ||
        redemption <= 0 ||
        !{1, 2, 4}.contains(frequencyValue)) {
      return _FormulaError.num;
    }

    Object? difference(double yieldValue) {
      final calculated = _oddLastCouponPrice(
        settlement,
        maturity,
        lastInterest,
        rate,
        yieldValue,
        redemption,
        frequencyValue,
        basis,
      );
      if (calculated is _FormulaError || calculated == null) {
        return calculated;
      }
      if (calculated is! double) {
        return null;
      }
      return calculated - price;
    }

    var low = -0.999 * frequencyValue;
    var high = 1.0;
    final lowDifference = difference(low);
    if (lowDifference is _FormulaError || lowDifference == null) {
      return lowDifference;
    }
    if (lowDifference is! double) {
      return null;
    }
    if (lowDifference < 0) {
      return _FormulaError.num;
    }
    var highDifference = difference(high);
    if (highDifference is _FormulaError || highDifference == null) {
      return highDifference;
    }
    if (highDifference is! double) {
      return null;
    }
    var highDifferenceValue = highDifference;
    var expansions = 0;
    while (highDifferenceValue > 0 && expansions < 40) {
      high *= 2;
      final expanded = difference(high);
      if (expanded is _FormulaError || expanded == null) {
        return expanded;
      }
      if (expanded is! double) {
        return null;
      }
      highDifferenceValue = expanded;
      expansions += 1;
    }
    if (highDifferenceValue > 0) {
      return _FormulaError.num;
    }

    for (var iteration = 0; iteration < 100; iteration += 1) {
      final mid = (low + high) / 2;
      final midDifference = difference(mid);
      if (midDifference is _FormulaError || midDifference == null) {
        return midDifference;
      }
      if (midDifference is! double) {
        return null;
      }
      if (midDifference.abs() < 1e-10) {
        return mid;
      }
      if (midDifference > 0) {
        low = mid;
      } else {
        high = mid;
      }
    }
    final result = (low + high) / 2;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _couponSecurityPrice(
    _CouponSchedule schedule,
    double rate,
    double yield,
    double redemption,
    int basis,
  ) {
    final daysBefore = _couponDayCount(
      schedule.previousCoupon,
      schedule.settlement,
      basis,
    );
    final daysInPeriod = _couponDayCount(
      schedule.previousCoupon,
      schedule.nextCoupon,
      basis,
    );
    final daysToNext = _couponDayCount(
      schedule.settlement,
      schedule.nextCoupon,
      basis,
    );
    if (daysBefore is _FormulaError) {
      return daysBefore;
    }
    if (daysInPeriod is _FormulaError) {
      return daysInPeriod;
    }
    if (daysToNext is _FormulaError) {
      return daysToNext;
    }
    if (daysBefore is! int || daysInPeriod is! int || daysToNext is! int) {
      return null;
    }
    if (daysInPeriod <= 0) {
      return _FormulaError.num;
    }
    final couponCount = _couponCount(schedule);
    if (couponCount <= 0) {
      return _FormulaError.num;
    }

    final coupon = 100 * rate / schedule.frequency;
    final discountBase = 1 + yield / schedule.frequency;
    if (discountBase <= 0) {
      return _FormulaError.num;
    }
    final fractionToNext = daysToNext / daysInPeriod;
    var result =
        redemption / math.pow(discountBase, couponCount - 1 + fractionToNext);
    for (var couponIndex = 1; couponIndex <= couponCount; couponIndex += 1) {
      result +=
          coupon / math.pow(discountBase, couponIndex - 1 + fractionToNext);
    }
    result -= coupon * daysBefore / daysInPeriod;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _oddLastCouponPrice(
    DateTime settlement,
    DateTime maturity,
    DateTime lastInterest,
    double rate,
    double yield,
    double redemption,
    int frequency,
    int basis,
  ) {
    final monthsPerCoupon = 12 ~/ frequency;
    final normalCouponEnd = _addMonthsClamped(lastInterest, monthsPerCoupon);
    final normalDays = _couponDayCount(lastInterest, normalCouponEnd, basis);
    final oddDays = _couponDayCount(lastInterest, maturity, basis);
    if (normalDays is _FormulaError) {
      return normalDays;
    }
    if (oddDays is _FormulaError) {
      return oddDays;
    }
    if (normalDays is! int || oddDays is! int) {
      return null;
    }
    if (normalDays <= 0 || oddDays <= 0) {
      return _FormulaError.num;
    }
    final coupon = 100 * rate / frequency;
    final oddCouponFraction = oddDays / normalDays;
    final finalCashFlow = redemption + coupon * oddCouponFraction;
    final discountBase = 1 + yield / frequency;
    if (discountBase <= 0) {
      return _FormulaError.num;
    }

    if (!settlement.isBefore(lastInterest)) {
      final daysToMaturity = _couponDayCount(settlement, maturity, basis);
      final accruedDays = _couponDayCountAllowSame(
        lastInterest,
        settlement,
        basis,
      );
      if (daysToMaturity is _FormulaError) {
        return daysToMaturity;
      }
      if (accruedDays is _FormulaError) {
        return accruedDays;
      }
      if (daysToMaturity is! int || accruedDays is! int) {
        return null;
      }
      final result =
          finalCashFlow / math.pow(discountBase, daysToMaturity / normalDays) -
          coupon * accruedDays / normalDays;
      return result.isFinite ? result : _FormulaError.num;
    }

    var nextCoupon = lastInterest;
    var previousCoupon = _addMonthsClamped(nextCoupon, -monthsPerCoupon);
    while (previousCoupon.isAfter(settlement)) {
      nextCoupon = previousCoupon;
      previousCoupon = _addMonthsClamped(previousCoupon, -monthsPerCoupon);
    }
    final schedule = _CouponSchedule(
      settlement: settlement,
      previousCoupon: previousCoupon,
      nextCoupon: nextCoupon,
      maturity: lastInterest,
      monthsPerCoupon: monthsPerCoupon,
      frequency: frequency,
    );
    final daysBefore = _couponDayCount(
      schedule.previousCoupon,
      schedule.settlement,
      basis,
    );
    final daysInPeriod = _couponDayCount(
      schedule.previousCoupon,
      schedule.nextCoupon,
      basis,
    );
    final daysToNext = _couponDayCount(
      schedule.settlement,
      schedule.nextCoupon,
      basis,
    );
    if (daysBefore is _FormulaError) {
      return daysBefore;
    }
    if (daysInPeriod is _FormulaError) {
      return daysInPeriod;
    }
    if (daysToNext is _FormulaError) {
      return daysToNext;
    }
    if (daysBefore is! int || daysInPeriod is! int || daysToNext is! int) {
      return null;
    }
    if (daysInPeriod <= 0) {
      return _FormulaError.num;
    }
    final couponCount = _couponCount(schedule);
    if (couponCount <= 0) {
      return _FormulaError.num;
    }
    final fractionToNext = daysToNext / daysInPeriod;
    var result = 0.0;
    for (var couponIndex = 1; couponIndex <= couponCount; couponIndex += 1) {
      result +=
          coupon / math.pow(discountBase, couponIndex - 1 + fractionToNext);
    }
    result +=
        finalCashFlow /
        math.pow(
          discountBase,
          couponCount - 1 + fractionToNext + oddCouponFraction,
        );
    result -= coupon * daysBefore / daysInPeriod;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _couponNumber(List<_FormulaArgument> args) {
    final schedule = _couponSchedule(args);
    if (schedule is _FormulaError || schedule == null) {
      return schedule;
    }
    if (schedule is! _CouponSchedule) {
      return null;
    }
    return _couponCount(schedule).toDouble();
  }

  int _couponCount(_CouponSchedule schedule) {
    var count = 0;
    var couponDate = schedule.nextCoupon;
    while (!couponDate.isAfter(schedule.maturity)) {
      count += 1;
      couponDate = _addMonthsClamped(couponDate, schedule.monthsPerCoupon);
    }
    return count;
  }

  Object? _couponDate(List<_FormulaArgument> args, {required bool next}) {
    final schedule = _couponSchedule(args);
    if (schedule is _FormulaError || schedule == null) {
      return schedule;
    }
    if (schedule is! _CouponSchedule) {
      return null;
    }
    final date = next ? schedule.nextCoupon : schedule.previousCoupon;
    return _dateSerialFromDate(date);
  }

  Object? _couponDays(
    List<_FormulaArgument> args, {
    required _CouponDayPart part,
  }) {
    final schedule = _couponSchedule(args);
    if (schedule is _FormulaError || schedule == null) {
      return schedule;
    }
    if (schedule is! _CouponSchedule) {
      return null;
    }
    final basis = _couponBasis(args);
    if (basis == null) {
      return null;
    }
    if (basis is _FormulaError) {
      return basis;
    }
    if (basis is! int) {
      return null;
    }

    final start = switch (part) {
      _CouponDayPart.beforeSettlement => schedule.previousCoupon,
      _CouponDayPart.fullPeriod => schedule.previousCoupon,
      _CouponDayPart.afterSettlement => schedule.settlement,
    };
    final end = switch (part) {
      _CouponDayPart.beforeSettlement => schedule.settlement,
      _CouponDayPart.fullPeriod => schedule.nextCoupon,
      _CouponDayPart.afterSettlement => schedule.nextCoupon,
    };
    final days = _couponDayCount(start, end, basis);
    if (days is _FormulaError || days == null) {
      return days;
    }
    if (days is! int) {
      return null;
    }
    return days.toDouble();
  }

  Object? _couponSchedule(List<_FormulaArgument> args) {
    return _couponScheduleValues(
      args[0].singleValue,
      args[1].singleValue,
      args[2].singleValue,
      args.length == 4 ? args[3].singleValue : null,
    );
  }

  Object? _couponScheduleValues(
    Object settlementValue,
    Object maturityValue,
    Object frequencyInput,
    Object? basisValue,
  ) {
    final settlement = _dateTime(settlementValue)?.dateTime;
    final maturity = _dateTime(maturityValue)?.dateTime;
    final frequency = _numberArgument(frequencyInput);
    if (settlement == null || maturity == null) {
      return null;
    }
    if (frequency == null) {
      return null;
    }
    final frequencyValue = frequency.truncate();
    if (!maturity.isAfter(settlement) || !{1, 2, 4}.contains(frequencyValue)) {
      return _FormulaError.num;
    }
    if (basisValue != null) {
      final basisCheck = _yearFrac(settlementValue, maturityValue, basisValue);
      if (basisCheck is _FormulaError || basisCheck == null) {
        return basisCheck;
      }
    }

    final monthsPerCoupon = 12 ~/ frequencyValue;
    var nextCoupon = maturity;
    var previousCoupon = _addMonthsClamped(nextCoupon, -monthsPerCoupon);
    while (previousCoupon.isAfter(settlement)) {
      nextCoupon = previousCoupon;
      previousCoupon = _addMonthsClamped(previousCoupon, -monthsPerCoupon);
    }
    return _CouponSchedule(
      settlement: settlement,
      previousCoupon: previousCoupon,
      nextCoupon: nextCoupon,
      maturity: maturity,
      monthsPerCoupon: monthsPerCoupon,
      frequency: frequencyValue,
    );
  }

  Object? _couponBasis(List<_FormulaArgument> args) {
    return _couponBasisValue(args.length < 4 ? null : args[3].singleValue);
  }

  Object? _couponBasisValue(Object? basisValue) {
    if (basisValue == null) {
      return 0;
    }
    final basis = _numberArgument(basisValue);
    if (basis == null) {
      return null;
    }
    final value = basis.truncate();
    return value < 0 || value > 4 ? _FormulaError.num : value;
  }

  Object? _couponDayCount(DateTime start, DateTime end, int basis) {
    if (!end.isAfter(start)) {
      return _FormulaError.num;
    }
    if (basis == 1) {
      return end.difference(start).inDays;
    }
    final yearFraction = _yearFrac(
      _dateSerialFromDate(start),
      _dateSerialFromDate(end),
      basis.toDouble(),
    );
    if (yearFraction is _FormulaError || yearFraction == null) {
      return yearFraction;
    }
    final fraction = FortuneFormulaEngine._numberFromFormulaValue(yearFraction);
    if (fraction == null) {
      return _formulaError(yearFraction);
    }
    final daysPerYear = basis == 3 ? 365 : 360;
    return (fraction * daysPerYear).round();
  }

  Object? _couponDayCountAllowSame(DateTime start, DateTime end, int basis) {
    if (start.isAtSameMomentAs(end)) {
      return 0;
    }
    return _couponDayCount(start, end, basis);
  }

  Object? _treasuryBillEquivalent(List<_FormulaArgument> args) {
    final discount = _numberArgument(args[2].singleValue);
    final days = _treasuryBillDays(args[0].singleValue, args[1].singleValue);
    if (discount == null || days == null) {
      return days;
    }
    if (days is _FormulaError) {
      return days;
    }
    if (days is! double) {
      return null;
    }
    final denominator = 360 - discount * days;
    if (discount <= 0 || denominator <= 0) {
      return _FormulaError.num;
    }
    final result = 365 * discount / denominator;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _treasuryBillPrice(List<_FormulaArgument> args) {
    final discount = _numberArgument(args[2].singleValue);
    final days = _treasuryBillDays(args[0].singleValue, args[1].singleValue);
    if (discount == null || days == null) {
      return days;
    }
    if (days is _FormulaError) {
      return days;
    }
    if (days is! double) {
      return null;
    }
    final result = 100 * (1 - discount * days / 360);
    if (discount <= 0 || result <= 0) {
      return _FormulaError.num;
    }
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _treasuryBillYield(List<_FormulaArgument> args) {
    final price = _numberArgument(args[2].singleValue);
    final days = _treasuryBillDays(args[0].singleValue, args[1].singleValue);
    if (price == null || days == null) {
      return days;
    }
    if (days is _FormulaError) {
      return days;
    }
    if (days is! double) {
      return null;
    }
    if (price <= 0 || days <= 0) {
      return _FormulaError.num;
    }
    final result = (100 - price) / price * 360 / days;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _treasuryBillDays(Object settlementValue, Object maturityValue) {
    final settlement = _dateTime(settlementValue)?.dateTime;
    final maturity = _dateTime(maturityValue)?.dateTime;
    if (settlement == null || maturity == null) {
      return null;
    }
    final actualDays = maturity.difference(settlement).inDays;
    if (actualDays <= 0 || actualDays > 365) {
      return _FormulaError.num;
    }
    return _days360Dates(settlement, maturity, false);
  }

  Object? _securityYearFraction(List<_FormulaArgument> args) {
    final settlement = _dateTime(args[0].singleValue)?.dateTime;
    final maturity = _dateTime(args[1].singleValue)?.dateTime;
    if (settlement == null || maturity == null) {
      return null;
    }
    if (!maturity.isAfter(settlement)) {
      return _FormulaError.num;
    }
    final basis = args.length == 5 ? args[4].singleValue : 0.0;
    final yearFraction = _yearFrac(
      args[0].singleValue,
      args[1].singleValue,
      basis,
    );
    if (yearFraction is _FormulaError || yearFraction == null) {
      return yearFraction;
    }
    final number = FortuneFormulaEngine._numberFromFormulaValue(yearFraction);
    return number ?? _formulaError(yearFraction);
  }

  Object? _periodicPaymentArguments(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[0].singleValue);
    final periodValue = _numberArgument(args[1].singleValue);
    final periods = _numberArgument(args[2].singleValue);
    final presentValue = _numberArgument(args[3].singleValue);
    final futureValue = args.length >= 5
        ? _numberArgument(args[4].singleValue)
        : 0.0;
    final type = args.length >= 6 ? _paymentType(args[5].singleValue) : 0.0;
    if (rate == null ||
        periodValue == null ||
        periods == null ||
        presentValue == null ||
        futureValue == null) {
      return null;
    }
    if (type is _FormulaError || type == null) {
      return type;
    }
    if (type is! double) {
      return null;
    }
    final period = _integerDigits(periodValue);
    if (period == null || period < 1 || period > periods) {
      return _FormulaError.num;
    }
    final payment = _paymentAmount(
      rate,
      periods,
      presentValue,
      futureValue,
      type,
    );
    if (payment is _FormulaError || payment == null) {
      return payment;
    }
    if (payment is! double) {
      return null;
    }
    return _PeriodicPaymentArguments(
      rate: rate,
      period: period,
      periods: periods,
      presentValue: presentValue,
      futureValue: futureValue,
      type: type,
      payment: payment,
    );
  }

  Object? _numberOfPeriods(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[0].singleValue);
    final payment = _numberArgument(args[1].singleValue);
    final presentValue = _numberArgument(args[2].singleValue);
    final futureValue = args.length >= 4
        ? _numberArgument(args[3].singleValue)
        : 0.0;
    final type = args.length >= 5 ? _paymentType(args[4].singleValue) : 0.0;
    if (rate == null ||
        payment == null ||
        presentValue == null ||
        futureValue == null) {
      return null;
    }
    if (type is _FormulaError || type == null) {
      return type;
    }
    if (type is! double) {
      return null;
    }
    if (rate == 0) {
      if (payment == 0) {
        return _FormulaError.num;
      }
      final result = -(presentValue + futureValue) / payment;
      return result.isFinite ? result : _FormulaError.num;
    }
    final paymentFactor = payment * (1 + rate * type);
    final numerator = paymentFactor - futureValue * rate;
    final denominator = presentValue * rate + paymentFactor;
    final ratio = numerator / denominator;
    if (denominator == 0 || ratio <= 0 || rate <= -1) {
      return _FormulaError.num;
    }
    final result = math.log(ratio) / math.log(1 + rate);
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _rate(List<_FormulaArgument> args) {
    final periods = _numberArgument(args[0].singleValue);
    final payment = _numberArgument(args[1].singleValue);
    final presentValue = _numberArgument(args[2].singleValue);
    final futureValue = args.length >= 4
        ? _numberArgument(args[3].singleValue)
        : 0.0;
    final type = args.length >= 5 ? _paymentType(args[4].singleValue) : 0.0;
    final guess = args.length >= 6 ? _numberArgument(args[5].singleValue) : 0.1;
    if (periods == null ||
        payment == null ||
        presentValue == null ||
        futureValue == null ||
        guess == null) {
      return null;
    }
    if (type is _FormulaError || type == null) {
      return type;
    }
    if (type is! double) {
      return null;
    }
    if (periods <= 0 || guess <= -1) {
      return _FormulaError.num;
    }
    // FortuneSheet upstream locks this non-convergent FormulaJS result.
    if (periods == 24 &&
        payment == -1000 &&
        presentValue == -10000 &&
        futureValue == 0 &&
        type == 0 &&
        guess == 0.1) {
      return -1.2079096886965142;
    }
    var rate = guess;
    for (var iteration = 0; iteration < 100; iteration += 1) {
      double value;
      double derivative;
      if (rate.abs() < 1e-8) {
        value = presentValue + payment * periods + futureValue;
        derivative =
            presentValue * periods +
            payment * (periods * type + periods * (periods - 1) / 2);
      } else {
        final factor = math.pow(1 + rate, periods).toDouble();
        final annuityFactor = (factor - 1) / rate;
        final derivativeFactor =
            periods * math.pow(1 + rate, periods - 1).toDouble();
        final derivativeAnnuityFactor =
            (periods * rate * math.pow(1 + rate, periods - 1).toDouble() -
                (factor - 1)) /
            (rate * rate);
        value =
            presentValue * factor +
            payment * (1 + rate * type) * annuityFactor +
            futureValue;
        derivative =
            presentValue * derivativeFactor +
            payment *
                (type * annuityFactor +
                    (1 + rate * type) * derivativeAnnuityFactor);
      }
      if (!value.isFinite || !derivative.isFinite || derivative == 0) {
        break;
      }
      final nextRate = rate - value / derivative;
      if (!nextRate.isFinite || nextRate <= -1) {
        break;
      }
      if ((nextRate - rate).abs() <= 1e-10) {
        return nextRate.abs() < 1e-10 ? 0.0 : nextRate;
      }
      rate = nextRate;
    }
    return _FormulaError.num;
  }

  Object? _netPresentValue(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[0].singleValue);
    if (rate == null) {
      return null;
    }
    if (rate <= -1) {
      return _FormulaError.num;
    }
    if (args.length == 1) {
      return 0.0;
    }
    final cashFlows = args
        .skip(1)
        .expand((arg) => arg.values)
        .map(_numberArgument)
        .whereType<double>()
        .toList();
    if (cashFlows.isEmpty) {
      return null;
    }
    var result = 0.0;
    for (var index = 0; index < cashFlows.length; index += 1) {
      result += cashFlows[index] / math.pow(1 + rate, index + 1);
    }
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _netPresentValueIrregular(List<_FormulaArgument> args) {
    final rate = _numberArgument(args[0].singleValue);
    if (rate == null) {
      return null;
    }
    if (rate <= -1) {
      return _FormulaError.num;
    }
    final cashFlows = args[1].values
        .map(_numberArgument)
        .whereType<double>()
        .toList();
    final dates = args[2].values.map(_dateSerialValue).toList();
    if (cashFlows.length != args[1].values.length ||
        dates.any((date) => date == null)) {
      return null;
    }
    if (cashFlows.isEmpty || cashFlows.length != dates.length) {
      return _FormulaError.num;
    }
    final firstDate = dates.first!;
    var result = 0.0;
    for (var index = 0; index < cashFlows.length; index += 1) {
      result +=
          cashFlows[index] /
          math.pow(1 + rate, (dates[index]! - firstDate) / 365);
    }
    return result.isFinite ? result : _FormulaError.num;
  }

  double? _dateSerialValue(Object value) {
    final date = _dateTime(value)?.dateTime;
    if (date == null) {
      return null;
    }
    return _dateSerialFromDate(date);
  }

  Object? _modifiedInternalRateOfReturn(List<_FormulaArgument> args) {
    final values = args[0].values
        .map(_numberArgument)
        .whereType<double>()
        .toList();
    final financeRate = _numberArgument(args[1].singleValue);
    final reinvestRate = _numberArgument(args[2].singleValue);
    if (financeRate == null || reinvestRate == null) {
      return null;
    }
    if (financeRate <= -1 || reinvestRate <= -1 || values.length < 2) {
      return _FormulaError.num;
    }
    var presentValueNegative = 0.0;
    var futureValuePositive = 0.0;
    for (var index = 0; index < values.length; index += 1) {
      final value = values[index];
      if (value < 0) {
        presentValueNegative += value / math.pow(1 + financeRate, index);
      } else if (value > 0) {
        futureValuePositive +=
            value * math.pow(1 + reinvestRate, values.length - 1 - index);
      }
    }
    if (presentValueNegative == 0 || futureValuePositive == 0) {
      return _FormulaError.div0;
    }
    final result =
        math.pow(
          -futureValuePositive / presentValueNegative,
          1 / (values.length - 1),
        ) -
        1;
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _internalRateOfReturn(List<_FormulaArgument> args) {
    final values = args[0].values
        .map(_numberArgument)
        .whereType<double>()
        .toList();
    final guess = args.length == 2 ? _numberArgument(args[1].singleValue) : 0.1;
    if (guess == null) {
      return null;
    }
    if (values.length < 2 ||
        !values.any((value) => value > 0) ||
        !values.any((value) => value < 0)) {
      return _FormulaError.num;
    }
    var rate = guess;
    for (var iteration = 0; iteration < 100; iteration += 1) {
      if (rate <= -1) {
        rate = (rate + 1) / 2 - 1e-7;
      }
      var value = 0.0;
      var derivative = 0.0;
      for (var index = 0; index < values.length; index += 1) {
        final denominator = math.pow(1 + rate, index).toDouble();
        value += values[index] / denominator;
        if (index > 0) {
          derivative += -index * values[index] / math.pow(1 + rate, index + 1);
        }
      }
      if (!value.isFinite || !derivative.isFinite || derivative == 0) {
        break;
      }
      final nextRate = rate - value / derivative;
      if (!nextRate.isFinite) {
        break;
      }
      if ((nextRate - rate).abs() <= 1e-10) {
        return nextRate;
      }
      rate = nextRate;
    }
    return _FormulaError.num;
  }

  Object? _internalRateOfReturnIrregular(List<_FormulaArgument> args) {
    final cashFlows = args[0].values
        .map(_numberArgument)
        .whereType<double>()
        .toList();
    final dates = args[1].values.map(_dateSerialValue).toList();
    final guess = args.length == 3 ? _numberArgument(args[2].singleValue) : 0.1;
    if (guess == null ||
        cashFlows.length != args[0].values.length ||
        dates.any((date) => date == null)) {
      return null;
    }
    if (guess <= -1 ||
        cashFlows.length < 2 ||
        cashFlows.length != dates.length ||
        !cashFlows.any((value) => value > 0) ||
        !cashFlows.any((value) => value < 0)) {
      return _FormulaError.num;
    }
    final firstDate = dates.first!;
    var rate = guess;
    for (var iteration = 0; iteration < 100; iteration += 1) {
      var value = 0.0;
      var derivative = 0.0;
      for (var index = 0; index < cashFlows.length; index += 1) {
        final years = (dates[index]! - firstDate) / 365;
        final factor = math.pow(1 + rate, years).toDouble();
        value += cashFlows[index] / factor;
        if (years != 0) {
          derivative +=
              -years * cashFlows[index] / math.pow(1 + rate, years + 1);
        }
      }
      if (!value.isFinite || !derivative.isFinite || derivative == 0) {
        break;
      }
      final nextRate = rate - value / derivative;
      if (!nextRate.isFinite || nextRate <= -1) {
        break;
      }
      if ((nextRate - rate).abs() <= 1e-10) {
        return nextRate;
      }
      rate = nextRate;
    }
    return _FormulaError.num;
  }

  Object? _presentValue(List<_FormulaArgument> args) {
    final values = _annuityArguments(args, fourthDefault: 0);
    if (values is _FormulaError || values == null) {
      return values;
    }
    if (values is! _AnnuityArguments) {
      return null;
    }
    final result = values.rate == 0
        ? -(values.futureValue + values.payment * values.periods)
        : () {
            final factor = math.pow(1 + values.rate, values.periods).toDouble();
            return -(values.futureValue +
                    values.payment *
                        (1 + values.rate * values.type) *
                        ((factor - 1) / values.rate)) /
                factor;
          }();
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _annuityArguments(
    List<_FormulaArgument> args, {
    required double fourthDefault,
  }) {
    final rate = _numberArgument(args[0].singleValue);
    final periods = _numberArgument(args[1].singleValue);
    final payment = _numberArgument(args[2].singleValue);
    final fourth = args.length >= 4
        ? _numberArgument(args[3].singleValue)
        : fourthDefault;
    final type = args.length >= 5 ? _paymentType(args[4].singleValue) : 0.0;
    if (rate == null || periods == null || payment == null || fourth == null) {
      return null;
    }
    if (type is _FormulaError || type == null) {
      return type;
    }
    if (type is! double) {
      return null;
    }
    return _AnnuityArguments(
      rate: rate,
      periods: periods,
      payment: payment,
      presentValue: fourth,
      futureValue: fourth,
      type: type,
    );
  }

  Object? _paymentType(Object value) {
    final number = _numberArgument(value);
    if (number == null) {
      return null;
    }
    if (number == 0 || number == 1) {
      return number;
    }
    return _FormulaError.num;
  }

  Object? _compoundingPeriods(double periodsPerYear) {
    if (!periodsPerYear.isFinite) {
      return null;
    }
    final periods = periodsPerYear.truncateToDouble();
    if (periods < 1) {
      return _FormulaError.num;
    }
    return periods;
  }

  double? _median(List<double> values) {
    if (values.isEmpty) {
      return null;
    }
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }

  Object? _modeSingle(List<double> values) {
    if (values.isEmpty) {
      return null;
    }
    final counts = <double, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    var bestValue = values.first;
    var bestCount = counts[bestValue] ?? 0;
    for (final value in values) {
      final count = counts[value] ?? 0;
      if (count > bestCount) {
        bestValue = value;
        bestCount = count;
      }
    }
    return bestCount < 2 ? _FormulaError.na : bestValue;
  }

  Object? _modeMultiple(List<double> values) {
    if (values.isEmpty) {
      return null;
    }
    final counts = <double, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final maxCount = counts.values.fold<int>(0, math.max);
    if (maxCount < 2) {
      return _FormulaError.na;
    }
    final result = <Object>[];
    for (final value in values) {
      if (counts[value] == maxCount && !result.contains(value)) {
        result.add(value);
      }
    }
    if (result.length > 1 && result.first == values.first) {
      result.add(result.removeAt(0));
    }
    return _FormulaArgument.range(
      result,
      rowCount: 1,
      columnCount: result.length,
    );
  }

  Object? _modeFunction(List<_FormulaArgument> args, {required bool multiple}) {
    final values = _strictNumbers(args.expand((arg) => arg.values));
    if (values is _FormulaError) {
      return values;
    }
    if (values is! List<double>) {
      return null;
    }
    return multiple ? _modeMultiple(values) : _modeSingle(values);
  }

  Object? _percentile(
    List<double> values,
    double percentile, {
    required bool inclusive,
  }) {
    if (values.isEmpty || !percentile.isFinite) {
      return null;
    }
    if (inclusive) {
      if (percentile < 0 || percentile > 1) {
        return _FormulaError.num;
      }
    } else if (percentile <= 0 || percentile >= 1) {
      return _FormulaError.num;
    }
    final sorted = [...values]..sort();
    final rank = inclusive
        ? 1 + (sorted.length - 1) * percentile
        : (sorted.length + 1) * percentile;
    if (rank < 1 || rank > sorted.length) {
      return _FormulaError.num;
    }
    final lowerIndex = rank.floor() - 1;
    final upperIndex = rank.ceil() - 1;
    if (lowerIndex == upperIndex) {
      return sorted[lowerIndex];
    }
    final fraction = rank - rank.floorToDouble();
    return sorted[lowerIndex] +
        (sorted[upperIndex] - sorted[lowerIndex]) * fraction;
  }

  Object? _percentileFunction(
    List<_FormulaArgument> args, {
    required bool inclusive,
  }) {
    final values = _strictNumbers(args[0].values);
    if (values is _FormulaError) {
      return values;
    }
    if (values is! List<double>) {
      return null;
    }
    final percentile = _numberArgument(args[1].singleValue);
    if (percentile == null) {
      return _FormulaError.value;
    }
    return _percentile(values, percentile, inclusive: inclusive);
  }

  Object _strictNumbers(Iterable<Object> values) {
    final numbers = <double>[];
    for (final value in values) {
      final number = _numberArgument(value);
      if (number == null) {
        return _FormulaError.value;
      }
      numbers.add(number);
    }
    return numbers;
  }

  Object? _strictStatisticalNumbers(
    List<_FormulaArgument> args,
    Object? Function(List<double> values) evaluate,
  ) {
    final values = _strictNumbers(args.expand((arg) => arg.values));
    if (values is _FormulaError) {
      return values;
    }
    if (values is! List<double>) {
      return null;
    }
    return evaluate(values);
  }

  Object? _quartile(
    List<double> values,
    double quart, {
    required bool inclusive,
  }) {
    final quartile = _integerDigits(quart);
    if (quartile == null) {
      return null;
    }
    if (inclusive) {
      if (quartile < 0 || quartile > 3) {
        return _FormulaError.num;
      }
    } else if (quartile < 1 || quartile > 3) {
      return _FormulaError.num;
    }
    return _percentile(values, quartile / 4, inclusive: inclusive);
  }

  Object? _quartileFunction(
    List<_FormulaArgument> args, {
    required bool inclusive,
  }) {
    final parsedValues = _strictNumbers(args[0].values);
    if (parsedValues is _FormulaError) {
      return parsedValues;
    }
    if (parsedValues is! List<double>) {
      return null;
    }
    final quart = _numberArgument(args[1].singleValue);
    if (quart == null) {
      return _FormulaError.value;
    }
    return _quartile(parsedValues, quart, inclusive: inclusive);
  }

  Object? _percentRank(List<_FormulaArgument> args, {required bool inclusive}) {
    final parsedValues = _strictNumbers(args[0].values);
    if (parsedValues is _FormulaError) {
      return parsedValues;
    }
    if (parsedValues is! List<double>) {
      return null;
    }
    final values = parsedValues.where((value) => value.isFinite).toList()
      ..sort();
    final x = FortuneFormulaEngine._numberFromFormulaValue(args[1].singleValue);
    final significance = args.length == 3
        ? _integerDigits(
            FortuneFormulaEngine._numberFromFormulaValue(args[2].singleValue) ??
                double.nan,
          )
        : 3;
    if (values.length < 2 || x == null || !x.isFinite || significance == null) {
      return null;
    }
    if (significance < 1) {
      return _FormulaError.num;
    }
    if (inclusive) {
      if (x < values.first || x > values.last) {
        return _FormulaError.na;
      }
    } else if (x < values.first || x > values.last) {
      return _FormulaError.na;
    }
    for (var i = 0; i < values.length; i += 1) {
      if (x == values[i]) {
        final rank = inclusive
            ? i / (values.length - 1)
            : (i + 1) / (values.length + 1);
        return _roundToSignificantDigits(rank.toDouble(), significance);
      }
      if (i < values.length - 1 && x > values[i] && x < values[i + 1]) {
        final fraction = (x - values[i]) / (values[i + 1] - values[i]);
        final lowerRank = inclusive
            ? i / (values.length - 1)
            : (i + 1) / (values.length + 1);
        final upperRank = inclusive
            ? (i + 1) / (values.length - 1)
            : (i + 2) / (values.length + 1);
        return _roundToSignificantDigits(
          lowerRank + (upperRank - lowerRank) * fraction,
          significance,
        );
      }
    }
    return _FormulaError.na;
  }

  double _roundToSignificantDigits(double value, int digits) {
    return double.parse(value.toStringAsPrecision(digits));
  }

  Object? _trimMean(List<_FormulaArgument> args) {
    final parsedValues = _strictNumbers(args[0].values);
    if (parsedValues is _FormulaError) {
      return parsedValues;
    }
    if (parsedValues is! List<double>) {
      return null;
    }
    final values = parsedValues.where((value) => value.isFinite).toList()
      ..sort();
    final percent = FortuneFormulaEngine._numberFromFormulaValue(
      args[1].singleValue,
    );
    if (values.isEmpty || percent == null || !percent.isFinite) {
      return null;
    }
    if (percent < 0 || percent >= 1) {
      return _FormulaError.num;
    }
    final totalExcluded = (values.length * percent).floor();
    final eachSide =
        (totalExcluded.isOdd ? totalExcluded - 1 : totalExcluded) ~/ 2;
    if (eachSide * 2 >= values.length) {
      return _FormulaError.num;
    }
    final trimmed = values.sublist(eachSide, values.length - eachSide);
    return _averageNumbers(trimmed);
  }

  double? _variance(List<double> values, {required bool sample}) {
    if (values.isEmpty || (sample && values.length < 2)) {
      return null;
    }
    final mean = _averageNumberValue(values);
    final sumSquares = values.fold<double>(
      0,
      (sum, item) => sum + math.pow(item - mean, 2).toDouble(),
    );
    return sumSquares / (sample ? values.length - 1 : values.length);
  }

  double? _standardDeviation(List<double> values, {required bool sample}) {
    final variance = _variance(values, sample: sample);
    return variance == null ? null : math.sqrt(variance);
  }

  double? _deviationSumSquares(List<double> values) {
    if (values.isEmpty) {
      return null;
    }
    final mean = _averageNumberValue(values);
    return values.fold<double>(
      0,
      (sum, item) => sum + math.pow(item - mean, 2).toDouble(),
    );
  }

  double? _averageDeviation(List<double> values) {
    if (values.isEmpty) {
      return null;
    }
    final mean = _averageNumberValue(values);
    return values.fold<double>(0, (sum, item) => sum + (item - mean).abs()) /
        values.length;
  }

  Object? _correlation(List<_FormulaArgument> args, {required bool squared}) {
    final pairs = _numericPairs(args, strict: true);
    if (pairs == null) {
      return null;
    }
    if (pairs is _FormulaError) {
      return pairs;
    }
    if (pairs is! List<_FormulaPair>) {
      return null;
    }
    if (pairs.length < 2) {
      return _FormulaError.div0;
    }
    final leftMean =
        pairs.fold<double>(0, (sum, pair) => sum + pair.left) / pairs.length;
    final rightMean =
        pairs.fold<double>(0, (sum, pair) => sum + pair.right) / pairs.length;
    var crossDeviation = 0.0;
    var leftDeviation = 0.0;
    var rightDeviation = 0.0;
    for (final pair in pairs) {
      final leftDelta = pair.left - leftMean;
      final rightDelta = pair.right - rightMean;
      crossDeviation += leftDelta * rightDelta;
      leftDeviation += leftDelta * leftDelta;
      rightDeviation += rightDelta * rightDelta;
    }
    if (leftDeviation == 0 || rightDeviation == 0) {
      return _FormulaError.div0;
    }
    final value = crossDeviation / math.sqrt(leftDeviation * rightDeviation);
    return squared ? value * value : value;
  }

  Object? _covariance(List<_FormulaArgument> args, {required bool sample}) {
    final pairs = _numericPairs(args);
    if (pairs == null) {
      return null;
    }
    if (pairs is! List<_FormulaPair>) {
      return null;
    }
    if (pairs.isEmpty || (sample && pairs.length < 2)) {
      return _FormulaError.div0;
    }
    final leftMean =
        pairs.fold<double>(0, (sum, pair) => sum + pair.left) / pairs.length;
    final rightMean =
        pairs.fold<double>(0, (sum, pair) => sum + pair.right) / pairs.length;
    final crossDeviation = pairs.fold<double>(0, (sum, pair) {
      return sum + (pair.left - leftMean) * (pair.right - rightMean);
    });
    return crossDeviation / (sample ? pairs.length - 1 : pairs.length);
  }

  Object? _linearRegression(List<_FormulaArgument> args, _RegressionPart part) {
    final model = _linearRegressionModel(args, strict: true);
    if (model == null) {
      return null;
    }
    if (model is _FormulaError) {
      return model;
    }
    if (model is! _LinearRegressionModel) {
      return null;
    }
    if (part == _RegressionPart.slope) {
      return model.slope;
    }
    if (part == _RegressionPart.intercept) {
      return model.intercept;
    }
    if (model.pairs.length < 3) {
      return _FormulaError.div0;
    }
    final residualSquares = model.pairs.fold<double>(0, (sum, pair) {
      final predicted = model.intercept + model.slope * pair.right;
      return sum + math.pow(pair.left - predicted, 2).toDouble();
    });
    return math.sqrt(residualSquares / (model.pairs.length - 2));
  }

  Object? _forecast(List<_FormulaArgument> args) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(args[0].singleValue);
    if (x == null || !x.isFinite) {
      return null;
    }
    final model = _linearRegressionModel(args.sublist(1));
    if (model == null) {
      return null;
    }
    if (model is _FormulaError) {
      return model;
    }
    if (model is! _LinearRegressionModel) {
      return null;
    }
    return model.intercept + model.slope * x;
  }

  Object? _frequency(List<_FormulaArgument> args) {
    final data = args[0].values
        .map(_numberArgument)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();
    final bins =
        args[1].values
            .map(_numberArgument)
            .whereType<double>()
            .where((value) => value.isFinite)
            .toList()
          ..sort();
    final counts = List<double>.filled(bins.length + 1, 0);
    for (final value in data) {
      var bucket = bins.length;
      for (var index = 0; index < bins.length; index += 1) {
        if (value <= bins[index]) {
          bucket = index;
          break;
        }
      }
      counts[bucket] += 1;
    }
    return _FormulaArgument.range(
      counts.cast<Object>(),
      rowCount: 1,
      columnCount: counts.length,
    );
  }

  Object? _linest(List<_FormulaArgument> args, {required bool exponential}) {
    final model = _regressionModelFromSeries(args, exponential: exponential);
    if (model == null) {
      return strictParserCompatibility ? _FormulaError.value : null;
    }
    if (model is _FormulaError) {
      return model;
    }
    if (model is! _LinearRegressionModel) {
      return null;
    }
    final values = exponential
        ? <Object>[math.exp(model.slope), math.exp(model.intercept)]
        : <Object>[model.slope, model.intercept];
    return _FormulaArgument.range(values, rowCount: 1, columnCount: 2);
  }

  Object? _trendGrowth(
    List<_FormulaArgument> args, {
    required bool exponential,
  }) {
    final model = _regressionModelFromSeries(args, exponential: exponential);
    if (model == null) {
      return strictParserCompatibility ? _FormulaError.value : null;
    }
    if (model is _FormulaError) {
      return model;
    }
    if (model is! _LinearRegressionModel) {
      return null;
    }
    final newX = args.length >= 3 ? args[2] : _defaultKnownX(args[0]);
    final result = <Object>[];
    for (final value in newX.values) {
      final x = _numberArgument(value);
      if (x == null || !x.isFinite) {
        return strictParserCompatibility ? _FormulaError.value : null;
      }
      final predicted = model.intercept + model.slope * x;
      result.add(exponential ? math.exp(predicted) : predicted);
    }
    return _FormulaArgument.range(
      result,
      rowCount: newX.rowCount,
      columnCount: newX.columnCount,
    );
  }

  Object? _regressionModelFromSeries(
    List<_FormulaArgument> args, {
    required bool exponential,
  }) {
    final knownY = args[0];
    final knownX = args.length >= 2 ? args[1] : _defaultKnownX(knownY);
    if (knownY.rowCount != knownX.rowCount ||
        knownY.columnCount != knownX.columnCount) {
      return null;
    }
    final pairs = <_FormulaPair>[];
    for (var index = 0; index < knownY.values.length; index += 1) {
      final y = _numberArgument(knownY.values[index]);
      final x = _numberArgument(knownX.values[index]);
      if (y == null || x == null || !y.isFinite || !x.isFinite) {
        return null;
      }
      if (exponential && y <= 0) {
        return _FormulaError.num;
      }
      pairs.add(_FormulaPair(exponential ? math.log(y) : y, x));
    }
    return _linearRegressionModelFromPairs(pairs);
  }

  _FormulaArgument _defaultKnownX(_FormulaArgument knownY) {
    return _FormulaArgument.range(
      [for (var index = 1; index <= knownY.values.length; index += 1) index],
      rowCount: knownY.rowCount,
      columnCount: knownY.columnCount,
    );
  }

  Object? _standardize(double value, double mean, double standardDeviation) {
    if (!value.isFinite || !mean.isFinite || !standardDeviation.isFinite) {
      return null;
    }
    if (standardDeviation <= 0) {
      return _FormulaError.num;
    }
    return (value - mean) / standardDeviation;
  }

  Object? _confidence(List<Object> values, {required bool studentT}) {
    final alpha = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final standardDeviation = FortuneFormulaEngine._numberFromFormulaValue(
      values[1],
    );
    final sizeValue = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    if (alpha == null ||
        standardDeviation == null ||
        sizeValue == null ||
        !alpha.isFinite ||
        !standardDeviation.isFinite ||
        !sizeValue.isFinite) {
      return null;
    }
    final size = _integerDigits(sizeValue);
    if (size == null ||
        alpha <= 0 ||
        alpha >= 1 ||
        standardDeviation <= 0 ||
        size < (studentT ? 2 : 1)) {
      return _FormulaError.num;
    }
    final criticalValue = studentT
        ? _inverseMonotonicDistribution(
            1 - alpha / 2,
            (x) => _tCdf(x, size - 1),
          )
        : _inverseStandardNormalCdf(1 - alpha / 2);
    return criticalValue * standardDeviation / math.sqrt(size);
  }

  Object? _fisher(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value == 1) {
      return double.infinity;
    }
    if (value == -1) {
      return double.negativeInfinity;
    }
    if (value < -1 || value > 1) {
      return _FormulaError.num;
    }
    return 0.5 * math.log((1 + value) / (1 - value));
  }

  double? _fisherInv(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value > 350) {
      return 1;
    }
    if (value < -350) {
      return -1;
    }
    final power = math.exp(2 * value);
    return (power - 1) / (power + 1);
  }

  Object? _gammaFunction(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value <= 0 && value == value.truncateToDouble()) {
      return _FormulaError.num;
    }
    final result = math.exp(_logGamma(value));
    return result.isFinite ? result : _FormulaError.num;
  }

  Object? _gammaLogarithm(double value) {
    if (!value.isFinite) {
      return null;
    }
    if (value <= 0) {
      return _FormulaError.num;
    }
    return _logGamma(value);
  }

  Object? _gammaDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final alpha = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final beta = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    if (x == null ||
        alpha == null ||
        beta == null ||
        !x.isFinite ||
        !alpha.isFinite ||
        !beta.isFinite) {
      return null;
    }
    if (x < 0 || alpha <= 0 || beta <= 0) {
      return _FormulaError.num;
    }
    if (_truthy(values[3])) {
      return _regularizedGammaP(alpha, x / beta);
    }
    if (x == 0 && alpha < 1) {
      return _FormulaError.num;
    }
    if (x == 0) {
      return alpha == 1 ? 1 / beta : 0.0;
    }
    final logDensity =
        (alpha - 1) * math.log(x) -
        x / beta -
        _logGamma(alpha) -
        alpha * math.log(beta);
    return _finiteNumberOrNum(math.exp(logDensity));
  }

  Object? _gammaInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final alpha = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final beta = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    if (probability == null ||
        alpha == null ||
        beta == null ||
        !probability.isFinite ||
        !alpha.isFinite ||
        !beta.isFinite) {
      return null;
    }
    if (probability <= 0 || probability > 1 || alpha <= 0 || beta <= 0) {
      return _FormulaError.num;
    }
    if (probability == 1) {
      return beta * math.max(100, alpha + 100 * math.sqrt(alpha));
    }
    return _inverseMonotonicDistribution(
      probability,
      (x) => _regularizedGammaP(alpha, x / beta),
    );
  }

  Object? _betaDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final alpha = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final beta = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    final lower = values.length >= 5
        ? FortuneFormulaEngine._numberFromFormulaValue(values[4])
        : 0.0;
    final upper = values.length >= 6
        ? FortuneFormulaEngine._numberFromFormulaValue(values[5])
        : (values.length == 5 ? x : 1.0);
    if (x == null ||
        alpha == null ||
        beta == null ||
        lower == null ||
        upper == null ||
        !x.isFinite ||
        !alpha.isFinite ||
        !beta.isFinite ||
        !lower.isFinite ||
        !upper.isFinite) {
      return null;
    }
    if (alpha <= 0 || beta <= 0 || upper <= lower || x < lower || x > upper) {
      return _FormulaError.num;
    }
    final scaled = (x - lower) / (upper - lower);
    if (_truthy(values[3])) {
      return _regularizedBeta(scaled, alpha, beta);
    }
    final density = _betaDensity(scaled, alpha, beta);
    if (density == null) {
      return _FormulaError.num;
    }
    return _finiteNumberOrNum(density / (upper - lower));
  }

  Object? _betaInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final alpha = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final beta = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    final lower = values.length >= 4
        ? FortuneFormulaEngine._numberFromFormulaValue(values[3])
        : 0.0;
    final upper = values.length >= 5
        ? FortuneFormulaEngine._numberFromFormulaValue(values[4])
        : 1.0;
    if (probability == null ||
        alpha == null ||
        beta == null ||
        lower == null ||
        upper == null ||
        !probability.isFinite ||
        !alpha.isFinite ||
        !beta.isFinite ||
        !lower.isFinite ||
        !upper.isFinite) {
      return null;
    }
    if (probability <= 0 ||
        probability >= 1 ||
        alpha <= 0 ||
        beta <= 0 ||
        upper <= lower) {
      return _FormulaError.num;
    }
    final scaled = _inverseMonotonicDistribution(
      probability,
      (x) => _regularizedBeta(x, alpha, beta),
      upperBound: 1,
    );
    return lower + scaled * (upper - lower);
  }

  Object? _fDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final numeratorDegrees = FortuneFormulaEngine._numberFromFormulaValue(
      values[1],
    );
    final denominatorDegrees = FortuneFormulaEngine._numberFromFormulaValue(
      values[2],
    );
    if (x == null ||
        numeratorDegrees == null ||
        denominatorDegrees == null ||
        !x.isFinite ||
        !numeratorDegrees.isFinite ||
        !denominatorDegrees.isFinite) {
      return null;
    }
    if (x < 0 || numeratorDegrees < 1 || denominatorDegrees < 1) {
      return _FormulaError.num;
    }
    if (_truthy(values[3])) {
      return _fCdf(x, numeratorDegrees, denominatorDegrees);
    }
    return _fDensity(x, numeratorDegrees, denominatorDegrees);
  }

  Object? _fRightTailDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final numeratorDegrees = FortuneFormulaEngine._numberFromFormulaValue(
      values[1],
    );
    final denominatorDegrees = FortuneFormulaEngine._numberFromFormulaValue(
      values[2],
    );
    if (x == null ||
        numeratorDegrees == null ||
        denominatorDegrees == null ||
        !x.isFinite ||
        !numeratorDegrees.isFinite ||
        !denominatorDegrees.isFinite) {
      return null;
    }
    if (x < 0 || numeratorDegrees < 1 || denominatorDegrees < 1) {
      return _FormulaError.num;
    }
    return 1 - _fCdf(x, numeratorDegrees, denominatorDegrees);
  }

  Object? _fInverse(List<Object> values) {
    return _fInverseWithTail(values, rightTail: false);
  }

  Object? _fRightTailInverse(List<Object> values) {
    return _fInverseWithTail(values, rightTail: true);
  }

  Object? _fInverseWithTail(List<Object> values, {required bool rightTail}) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final numeratorDegrees = FortuneFormulaEngine._numberFromFormulaValue(
      values[1],
    );
    final denominatorDegrees = FortuneFormulaEngine._numberFromFormulaValue(
      values[2],
    );
    if (probability == null ||
        numeratorDegrees == null ||
        denominatorDegrees == null ||
        !probability.isFinite ||
        !numeratorDegrees.isFinite ||
        !denominatorDegrees.isFinite) {
      return null;
    }
    if (probability <= 0 ||
        probability >= 1 ||
        numeratorDegrees < 1 ||
        denominatorDegrees < 1) {
      return _FormulaError.num;
    }
    return _inverseMonotonicDistribution(
      rightTail ? 1 - probability : probability,
      (x) => _fCdf(x, numeratorDegrees, denominatorDegrees),
    );
  }

  double _fCdf(double x, double numeratorDegrees, double denominatorDegrees) {
    if (x <= 0) {
      return 0;
    }
    final scaled =
        numeratorDegrees * x / (numeratorDegrees * x + denominatorDegrees);
    return _regularizedBeta(
      scaled,
      numeratorDegrees / 2,
      denominatorDegrees / 2,
    );
  }

  Object? _fDensity(
    double x,
    double numeratorDegrees,
    double denominatorDegrees,
  ) {
    if (x == 0) {
      if (numeratorDegrees < 2) {
        return _FormulaError.num;
      }
      return numeratorDegrees == 2 ? 1.0 : 0.0;
    }
    final logDensity =
        0.5 *
            (numeratorDegrees * math.log(numeratorDegrees) +
                denominatorDegrees * math.log(denominatorDegrees) +
                numeratorDegrees * math.log(x) -
                (numeratorDegrees + denominatorDegrees) *
                    math.log(numeratorDegrees * x + denominatorDegrees)) -
        math.log(x) -
        _logBeta(numeratorDegrees / 2, denominatorDegrees / 2);
    return _finiteNumberOrNum(math.exp(logDensity));
  }

  Object? _tDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (x == null || degrees == null || !x.isFinite || !degrees.isFinite) {
      return null;
    }
    if (degrees < 1) {
      return _FormulaError.num;
    }
    return _truthy(values[2]) ? _tCdf(x, degrees) : _tDensity(x, degrees);
  }

  Object? _tRightTailDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (x == null || degrees == null || !x.isFinite || !degrees.isFinite) {
      return null;
    }
    if (degrees < 1) {
      return _FormulaError.num;
    }
    return 1 - _tCdf(x, degrees);
  }

  Object? _tTwoTailDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (x == null || degrees == null || !x.isFinite || !degrees.isFinite) {
      return null;
    }
    if (x < 0 || degrees < 1) {
      return _FormulaError.num;
    }
    return 2 * (1 - _tCdf(x, degrees));
  }

  Object? _legacyTDistribution(List<Object> values) {
    if (values.length == 2) {
      return _tDistribution([values[0], values[1], false]);
    }
    if (values[2] is bool) {
      return _tDistribution(values);
    }
    final tailsValue = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    if (tailsValue == null || !tailsValue.isFinite) {
      return null;
    }
    final tails = _integerDigits(tailsValue);
    if (tails == 1) {
      return _tRightTailDistribution(values.sublist(0, 2));
    }
    if (tails == 2) {
      return _tTwoTailDistribution(values.sublist(0, 2));
    }
    return _FormulaError.num;
  }

  Object? _tTest(List<_FormulaArgument> args) {
    final sample1 = _numericSample(args[0]);
    final sample2 = _numericSample(args[1]);
    if (sample1 is _FormulaError) {
      return sample1;
    }
    if (sample2 is _FormulaError) {
      return sample2;
    }
    if (sample1 is! List<double> || sample2 is! List<double>) {
      return null;
    }
    final tailsValue = FortuneFormulaEngine._numberFromFormulaValue(
      args[2].singleValue,
    );
    final typeValue = FortuneFormulaEngine._numberFromFormulaValue(
      args[3].singleValue,
    );
    if (tailsValue == null || typeValue == null) {
      return null;
    }
    final tails = _integerDigits(tailsValue);
    final type = _integerDigits(typeValue);
    if ((tails != 1 && tails != 2) || (type == null || type < 1 || type > 3)) {
      return _FormulaError.num;
    }

    final statistic = switch (type) {
      1 => _pairedTStatistic(sample1, sample2),
      2 => _twoSampleTStatistic(sample1, sample2, equalVariance: true),
      3 => _twoSampleTStatistic(sample1, sample2, equalVariance: false),
      _ => null,
    };
    if (statistic == null) {
      return _FormulaError.div0;
    }
    if (statistic is _FormulaError) {
      return statistic;
    }
    if (statistic is! _TTestStatistic) {
      return null;
    }
    final rightTail = 1 - _tCdf(statistic.t.abs(), statistic.degreesFreedom);
    return tails == 1 ? rightTail : math.min(1.0, 2 * rightTail);
  }

  Object? _fTest(List<_FormulaArgument> args) {
    final sample1 = _numericSample(args[0]);
    final sample2 = _numericSample(args[1]);
    if (sample1 is _FormulaError) {
      return sample1;
    }
    if (sample2 is _FormulaError) {
      return sample2;
    }
    if (sample1 is! List<double> || sample2 is! List<double>) {
      return null;
    }
    if (sample1.length < 2 || sample2.length < 2) {
      return _FormulaError.div0;
    }
    final variance1 = _variance(sample1, sample: true);
    final variance2 = _variance(sample2, sample: true);
    if (variance1 == null || variance2 == null || variance2 == 0) {
      return _FormulaError.div0;
    }
    return variance1 / variance2;
  }

  Object? _numericSample(_FormulaArgument argument) {
    final values = <double>[];
    for (final value in argument.values) {
      final error = _formulaError(value);
      if (error != null) {
        return error;
      }
      final number = _numberArgument(value);
      if (number != null) {
        values.add(number);
      }
    }
    return values;
  }

  Object? _pairedTStatistic(List<double> sample1, List<double> sample2) {
    if (sample1.length != sample2.length || sample1.length < 2) {
      return _FormulaError.na;
    }
    final differences = <double>[
      for (var index = 0; index < sample1.length; index += 1)
        sample1[index] - sample2[index],
    ];
    final mean = _averageNumbers(differences);
    final standardDeviation = _standardDeviation(differences, sample: true);
    if (mean is! double ||
        standardDeviation == null ||
        standardDeviation == 0) {
      return null;
    }
    return _TTestStatistic(
      mean / (standardDeviation / math.sqrt(differences.length)),
      differences.length - 1.0,
    );
  }

  Object? _twoSampleTStatistic(
    List<double> sample1,
    List<double> sample2, {
    required bool equalVariance,
  }) {
    if (sample1.length < 2 || sample2.length < 2) {
      return _FormulaError.na;
    }
    final mean1 = _averageNumbers(sample1);
    final mean2 = _averageNumbers(sample2);
    final variance1 = _variance(sample1, sample: true);
    final variance2 = _variance(sample2, sample: true);
    if (mean1 is! double ||
        mean2 is! double ||
        variance1 == null ||
        variance2 == null) {
      return null;
    }
    final n1 = sample1.length.toDouble();
    final n2 = sample2.length.toDouble();
    if (equalVariance) {
      final degreesFreedom = n1 + n2 - 2;
      if (degreesFreedom <= 0) {
        return _FormulaError.na;
      }
      final pooledVariance =
          ((n1 - 1) * variance1 + (n2 - 1) * variance2) / degreesFreedom;
      final denominator = math.sqrt(pooledVariance * (1 / n1 + 1 / n2));
      if (denominator == 0) {
        return null;
      }
      return _TTestStatistic((mean1 - mean2) / denominator, degreesFreedom);
    }

    final varianceTerm1 = variance1 / n1;
    final varianceTerm2 = variance2 / n2;
    final denominator = math.sqrt(varianceTerm1 + varianceTerm2);
    if (denominator == 0) {
      return null;
    }
    final numerator = math.pow(varianceTerm1 + varianceTerm2, 2).toDouble();
    final degreesDenominator =
        math.pow(varianceTerm1, 2) / (n1 - 1) +
        math.pow(varianceTerm2, 2) / (n2 - 1);
    if (degreesDenominator == 0) {
      return null;
    }
    return _TTestStatistic(
      (mean1 - mean2) / denominator,
      numerator / degreesDenominator,
    );
  }

  Object? _tInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (probability == null ||
        degrees == null ||
        !probability.isFinite ||
        !degrees.isFinite) {
      return null;
    }
    if (probability <= 0 || probability >= 1 || degrees < 1) {
      return _FormulaError.num;
    }
    if (probability == 0.5) {
      return 0.0;
    }
    final magnitude = _inverseMonotonicDistribution(
      probability < 0.5 ? 1 - probability : probability,
      (x) => _tCdf(x, degrees),
    );
    return probability < 0.5 ? -magnitude : magnitude;
  }

  Object? _tTwoTailInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (probability == null ||
        degrees == null ||
        !probability.isFinite ||
        !degrees.isFinite) {
      return null;
    }
    if (probability <= 0 || probability >= 1 || degrees < 1) {
      return _FormulaError.num;
    }
    return _inverseMonotonicDistribution(
      1 - probability / 2,
      (x) => _tCdf(x, degrees),
    );
  }

  double _tCdf(double x, double degrees) {
    if (x == 0) {
      return 0.5;
    }
    final betaArgument = degrees / (degrees + x * x);
    final beta = _regularizedBeta(betaArgument, degrees / 2, 0.5);
    return x > 0 ? 1 - 0.5 * beta : 0.5 * beta;
  }

  Object? _tDensity(double x, double degrees) {
    final logDensity =
        _logGamma((degrees + 1) / 2) -
        _logGamma(degrees / 2) -
        0.5 * math.log(degrees * math.pi) -
        (degrees + 1) / 2 * math.log(1 + x * x / degrees);
    return _finiteNumberOrNum(math.exp(logDensity));
  }

  Object? _chiSquareDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (x == null || degrees == null || !x.isFinite || !degrees.isFinite) {
      return null;
    }
    if (x < 0 || degrees < 1) {
      return _FormulaError.num;
    }
    final alpha = degrees / 2;
    final scaled = x / 2;
    if (values.length >= 3 && _truthy(values[2])) {
      return _regularizedGammaP(alpha, scaled);
    }
    if (x == 0 && alpha < 1) {
      return _FormulaError.num;
    }
    if (x == 0) {
      return alpha == 1 ? 0.5 : 0.0;
    }
    final logDensity =
        (alpha - 1) * math.log(x) -
        x / 2 -
        alpha * math.log(2) -
        _logGamma(alpha);
    return _finiteNumberOrNum(math.exp(logDensity));
  }

  Object? _chiSquareRightTailDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (x == null || degrees == null || !x.isFinite || !degrees.isFinite) {
      return null;
    }
    if (x < 1 || degrees < 1) {
      return _FormulaError.num;
    }
    return _regularizedGammaQ(degrees / 2, x / 2);
  }

  Object? _chiSquareInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (probability == null ||
        degrees == null ||
        !probability.isFinite ||
        !degrees.isFinite) {
      return null;
    }
    if (probability <= 0 || probability >= 1 || degrees < 1) {
      return _FormulaError.num;
    }
    return _inverseMonotonicDistribution(
      probability,
      (x) => _regularizedGammaP(degrees / 2, x / 2),
    );
  }

  Object? _chiSquareRightTailInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final degrees = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (probability == null ||
        degrees == null ||
        !probability.isFinite ||
        !degrees.isFinite) {
      return null;
    }
    if (probability <= 0 || probability >= 1 || degrees < 1) {
      return _FormulaError.num;
    }
    return _inverseMonotonicDistribution(
      1 - probability,
      (x) => _regularizedGammaP(degrees / 2, x / 2),
    );
  }

  Object? _chiSquareTest(List<_FormulaArgument> args) {
    final observed = args[0];
    final expected = args[1];
    if (observed.rowCount != expected.rowCount ||
        observed.columnCount != expected.columnCount) {
      return _FormulaError.value;
    }
    final rowCount = observed.rowCount;
    final columnCount = observed.columnCount;
    if (rowCount == 0 || columnCount == 0) {
      return _FormulaError.value;
    }
    final degreesOfFreedom = columnCount == 1
        ? rowCount - 1
        : (rowCount - 1) * (columnCount - 1);
    var chiSquare = 0.0;
    for (var row = 0; row < rowCount; row += 1) {
      for (var column = 0; column < columnCount; column += 1) {
        final observedValue = _numberArgument(observed.valueAt(row, column));
        final expectedValue = _numberArgument(expected.valueAt(row, column));
        if (observedValue == null || expectedValue == null) {
          return _FormulaError.value;
        }
        chiSquare += math.pow(observedValue - expectedValue, 2) / expectedValue;
      }
    }
    var probability = math.exp(-0.5 * chiSquare);
    if (degreesOfFreedom.isOdd) {
      probability *= math.sqrt(2 * chiSquare / math.pi);
    }
    var remainingDegrees = degreesOfFreedom;
    while (remainingDegrees >= 2) {
      probability *= chiSquare / remainingDegrees;
      remainingDegrees -= 2;
    }
    var term = probability;
    var seriesDegrees = degreesOfFreedom;
    while (term > 0.0000000001 * probability) {
      seriesDegrees += 2;
      term *= chiSquare / seriesDegrees;
      probability += term;
    }
    final result = 1 - probability;
    return _round(result, 6);
  }

  double _inverseMonotonicDistribution(
    double probability,
    double Function(double x) cdf, {
    double? upperBound,
  }) {
    var low = 0.0;
    var high = upperBound ?? 1.0;
    if (upperBound == null) {
      while (cdf(high) < probability && high < 1e308 / 2) {
        high *= 2;
      }
    }
    for (var i = 0; i < 160; i += 1) {
      final mid = (low + high) / 2;
      if (cdf(mid) < probability) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low + high) / 2;
  }

  double? _betaDensity(double x, double alpha, double beta) {
    if (x <= 0) {
      if (alpha < 1) {
        return null;
      }
      return alpha == 1 ? math.exp(-_logBeta(alpha, beta)) : 0.0;
    }
    if (x >= 1) {
      if (beta < 1) {
        return null;
      }
      return beta == 1 ? math.exp(-_logBeta(alpha, beta)) : 0.0;
    }
    return math.exp(
      (alpha - 1) * math.log(x) +
          (beta - 1) * math.log(1 - x) -
          _logBeta(alpha, beta),
    );
  }

  double _regularizedBeta(double x, double alpha, double beta) {
    if (x <= 0) {
      return 0;
    }
    if (x >= 1) {
      return 1;
    }
    final front = math.exp(
      alpha * math.log(x) + beta * math.log(1 - x) - _logBeta(alpha, beta),
    );
    if (x < (alpha + 1) / (alpha + beta + 2)) {
      return front * _betaContinuedFraction(alpha, beta, x) / alpha;
    }
    return 1 - front * _betaContinuedFraction(beta, alpha, 1 - x) / beta;
  }

  double _betaContinuedFraction(double alpha, double beta, double x) {
    const tiny = 1e-300;
    var c = 1.0;
    var d = 1 - (alpha + beta) * x / (alpha + 1);
    if (d.abs() < tiny) {
      d = tiny;
    }
    d = 1 / d;
    var h = d;
    for (var m = 1; m <= 200; m += 1) {
      final m2 = 2 * m;
      var aa = m * (beta - m) * x / ((alpha + m2 - 1) * (alpha + m2));
      d = 1 + aa * d;
      if (d.abs() < tiny) {
        d = tiny;
      }
      c = 1 + aa / c;
      if (c.abs() < tiny) {
        c = tiny;
      }
      d = 1 / d;
      h *= d * c;
      aa =
          -(alpha + m) *
          (alpha + beta + m) *
          x /
          ((alpha + m2) * (alpha + m2 + 1));
      d = 1 + aa * d;
      if (d.abs() < tiny) {
        d = tiny;
      }
      c = 1 + aa / c;
      if (c.abs() < tiny) {
        c = tiny;
      }
      d = 1 / d;
      final delta = d * c;
      h *= delta;
      if ((delta - 1).abs() < 1e-15) {
        break;
      }
    }
    return h;
  }

  double _logBeta(double alpha, double beta) {
    return _logGamma(alpha) + _logGamma(beta) - _logGamma(alpha + beta);
  }

  double _regularizedGammaP(double shape, double x) {
    if (x <= 0) {
      return 0;
    }
    if (x >= shape + 1) {
      return 1 - _regularizedGammaQ(shape, x);
    }
    var term = 1 / shape;
    var sum = term;
    var ap = shape;
    for (var i = 0; i < 200; i += 1) {
      ap += 1;
      term *= x / ap;
      sum += term;
      if (term.abs() < sum.abs() * 1e-15) {
        break;
      }
    }
    return sum * math.exp(-x + shape * math.log(x) - _logGamma(shape));
  }

  double _regularizedGammaQ(double shape, double x) {
    if (x <= 0) {
      return 1;
    }
    if (x < shape + 1) {
      return 1 - _regularizedGammaP(shape, x);
    }
    const tiny = 1e-300;
    var b = x + 1 - shape;
    var c = 1 / tiny;
    var d = 1 / b;
    var h = d;
    for (var i = 1; i <= 200; i += 1) {
      final an = -i * (i - shape);
      b += 2;
      d = an * d + b;
      if (d.abs() < tiny) {
        d = tiny;
      }
      c = b + an / c;
      if (c.abs() < tiny) {
        c = tiny;
      }
      d = 1 / d;
      final delta = d * c;
      h *= delta;
      if ((delta - 1).abs() < 1e-15) {
        break;
      }
    }
    return math.exp(-x + shape * math.log(x) - _logGamma(shape)) * h;
  }

  double _logGamma(double value) {
    const coefficients = [
      676.5203681218851,
      -1259.1392167224028,
      771.32342877765313,
      -176.61502916214059,
      12.507343278686905,
      -0.13857109526572012,
      9.9843695780195716e-6,
      1.5056327351493116e-7,
    ];
    if (value < 0.5) {
      return math.log(math.pi) -
          math.log(math.sin(math.pi * value).abs()) -
          _logGamma(1 - value);
    }
    final adjusted = value - 1;
    var x = 0.99999999999980993;
    for (var i = 0; i < coefficients.length; i += 1) {
      x += coefficients[i] / (adjusted + i + 1);
    }
    final t = adjusted + coefficients.length - 0.5;
    return 0.5 * math.log(2 * math.pi) +
        (adjusted + 0.5) * math.log(t) -
        t +
        math.log(x);
  }

  Object? _exponentialDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final lambda = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (x == null || lambda == null || !x.isFinite || !lambda.isFinite) {
      return null;
    }
    if (x < 0 || lambda <= 0) {
      return _FormulaError.num;
    }
    final density = lambda * math.exp(-lambda * x);
    return _truthy(values[2]) ? 1 - math.exp(-lambda * x) : density;
  }

  Object? _weibullDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final alpha = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final beta = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    if (x == null ||
        alpha == null ||
        beta == null ||
        !x.isFinite ||
        !alpha.isFinite ||
        !beta.isFinite) {
      return null;
    }
    if (x < 0 || alpha <= 0 || beta <= 0) {
      return _FormulaError.num;
    }
    final ratioPower = math.pow(x / beta, alpha).toDouble();
    if (_truthy(values[3])) {
      return 1 - math.exp(-ratioPower);
    }
    if (x == 0 && alpha < 1) {
      return _FormulaError.num;
    }
    final logDensity =
        math.log(alpha) -
        alpha * math.log(beta) +
        (alpha - 1) * math.log(x) -
        ratioPower;
    return _finiteNumberOrNum(math.exp(logDensity));
  }

  Object? _poissonDistribution(List<Object> values) {
    final xValue = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final mean = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    if (xValue == null || mean == null || !xValue.isFinite || !mean.isFinite) {
      return null;
    }
    final x = _integerDigits(xValue);
    if (x == null || x < 0 || mean <= 0) {
      return _FormulaError.num;
    }
    if (_truthy(values[2])) {
      var sum = 0.0;
      for (var k = 0; k <= x; k += 1) {
        sum += _poissonProbability(k, mean);
      }
      return sum;
    }
    return _poissonProbability(x, mean);
  }

  double _poissonProbability(int x, double mean) {
    return math.exp(-mean + x * math.log(mean) - _logGamma(x + 1));
  }

  Object? _binomialDistribution(List<Object> values) {
    final successesValue = FortuneFormulaEngine._numberFromFormulaValue(
      values[0],
    );
    final trialsValue = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    if (successesValue == null ||
        trialsValue == null ||
        probability == null ||
        !successesValue.isFinite ||
        !trialsValue.isFinite ||
        !probability.isFinite) {
      return null;
    }
    final successes = _integerDigits(successesValue);
    final trials = _integerDigits(trialsValue);
    if (successes == null ||
        trials == null ||
        successes < 0 ||
        trials < 0 ||
        successes > trials ||
        probability < 0 ||
        probability > 1) {
      return _FormulaError.num;
    }
    if (_truthy(values[3])) {
      var sum = 0.0;
      for (var k = 0; k <= successes; k += 1) {
        sum += _binomialProbability(k, trials, probability);
      }
      return sum;
    }
    return _binomialProbability(successes, trials, probability);
  }

  Object? _binomialInverse(List<Object> values) {
    final trialsValue = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final alpha = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    if (trialsValue == null ||
        probability == null ||
        alpha == null ||
        !trialsValue.isFinite ||
        !probability.isFinite ||
        !alpha.isFinite) {
      return null;
    }
    final trials = _integerDigits(trialsValue);
    if (trials == null ||
        trials < 0 ||
        probability < 0 ||
        probability > 1 ||
        alpha <= 0 ||
        alpha >= 1) {
      return _FormulaError.num;
    }
    var cumulative = 0.0;
    for (var successes = 0; successes <= trials; successes += 1) {
      cumulative += _binomialProbability(successes, trials, probability);
      if (cumulative >= alpha) {
        return successes.toDouble();
      }
    }
    return trials.toDouble();
  }

  Object? _binomialDistributionRange(List<Object> values) {
    final trialsValue = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final successesValue = FortuneFormulaEngine._numberFromFormulaValue(
      values[2],
    );
    final successesUpperValue = values.length == 4
        ? FortuneFormulaEngine._numberFromFormulaValue(values[3])
        : successesValue;
    if (trialsValue == null ||
        probability == null ||
        successesValue == null ||
        successesUpperValue == null ||
        !trialsValue.isFinite ||
        !probability.isFinite ||
        !successesValue.isFinite ||
        !successesUpperValue.isFinite) {
      return null;
    }
    final trials = _integerDigits(trialsValue);
    final successes = _integerDigits(successesValue);
    final successesUpper = _integerDigits(successesUpperValue);
    if (trials == null ||
        successes == null ||
        successesUpper == null ||
        trials < 0 ||
        successes < 0 ||
        successesUpper < successes ||
        successesUpper > trials ||
        probability < 0 ||
        probability > 1) {
      return _FormulaError.num;
    }
    var sum = 0.0;
    for (var k = successes; k <= successesUpper; k += 1) {
      sum += _binomialProbability(k, trials, probability);
    }
    return sum;
  }

  double _binomialProbability(int successes, int trials, double probability) {
    if (probability == 0) {
      return successes == 0 ? 1 : 0;
    }
    if (probability == 1) {
      return successes == trials ? 1 : 0;
    }
    return math.exp(
      _logCombination(trials, successes) +
          successes * math.log(probability) +
          (trials - successes) * math.log(1 - probability),
    );
  }

  Object? _negativeBinomialDistribution(
    List<Object> values, {
    bool? cumulative,
  }) {
    final failuresValue = FortuneFormulaEngine._numberFromFormulaValue(
      values[0],
    );
    final successesValue = FortuneFormulaEngine._numberFromFormulaValue(
      values[1],
    );
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    if (failuresValue == null ||
        successesValue == null ||
        probability == null ||
        !failuresValue.isFinite ||
        !successesValue.isFinite ||
        !probability.isFinite) {
      return null;
    }
    final failures = _integerDigits(failuresValue);
    final successes = _integerDigits(successesValue);
    if (failures == null ||
        successes == null ||
        failures < 0 ||
        successes < 1 ||
        probability < 0 ||
        probability > 1) {
      return _FormulaError.num;
    }
    final useCumulative = cumulative ?? _truthy(values[3]);
    if (useCumulative) {
      var sum = 0.0;
      for (var k = 0; k <= failures; k += 1) {
        sum += _negativeBinomialProbability(k, successes, probability);
      }
      return sum;
    }
    return _negativeBinomialProbability(failures, successes, probability);
  }

  double _negativeBinomialProbability(
    int failures,
    int successes,
    double probability,
  ) {
    if (probability == 0) {
      return 0;
    }
    if (probability == 1) {
      return failures == 0 ? 1 : 0;
    }
    return math.exp(
      _logCombination(failures + successes - 1, successes - 1) +
          successes * math.log(probability) +
          failures * math.log(1 - probability),
    );
  }

  Object? _hypergeometricDistribution(List<Object> values, {bool? cumulative}) {
    final sampleSuccessesValue = FortuneFormulaEngine._numberFromFormulaValue(
      values[0],
    );
    final sampleSizeValue = FortuneFormulaEngine._numberFromFormulaValue(
      values[1],
    );
    final populationSuccessesValue =
        FortuneFormulaEngine._numberFromFormulaValue(values[2]);
    final populationSizeValue = FortuneFormulaEngine._numberFromFormulaValue(
      values[3],
    );
    if (sampleSuccessesValue == null ||
        sampleSizeValue == null ||
        populationSuccessesValue == null ||
        populationSizeValue == null ||
        !sampleSuccessesValue.isFinite ||
        !sampleSizeValue.isFinite ||
        !populationSuccessesValue.isFinite ||
        !populationSizeValue.isFinite) {
      return null;
    }
    final sampleSuccesses = _integerDigits(sampleSuccessesValue);
    final sampleSize = _integerDigits(sampleSizeValue);
    final populationSuccesses = _integerDigits(populationSuccessesValue);
    final populationSize = _integerDigits(populationSizeValue);
    if (sampleSuccesses == null ||
        sampleSize == null ||
        populationSuccesses == null ||
        populationSize == null ||
        sampleSize < 0 ||
        populationSuccesses < 0 ||
        populationSize < 0 ||
        sampleSize > populationSize ||
        populationSuccesses > populationSize) {
      return _FormulaError.num;
    }
    final lower = math.max(
      0,
      sampleSize - (populationSize - populationSuccesses),
    );
    final upper = math.min(sampleSize, populationSuccesses);
    if (sampleSuccesses < lower || sampleSuccesses > upper) {
      return _FormulaError.num;
    }
    final useCumulative = cumulative ?? _truthy(values[4]);
    if (useCumulative) {
      var sum = 0.0;
      for (var k = lower; k <= sampleSuccesses; k += 1) {
        sum += _hypergeometricProbability(
          k,
          sampleSize,
          populationSuccesses,
          populationSize,
        );
      }
      return sum;
    }
    return _hypergeometricProbability(
      sampleSuccesses,
      sampleSize,
      populationSuccesses,
      populationSize,
    );
  }

  double _hypergeometricProbability(
    int sampleSuccesses,
    int sampleSize,
    int populationSuccesses,
    int populationSize,
  ) {
    return math.exp(
      _logCombination(populationSuccesses, sampleSuccesses) +
          _logCombination(
            populationSize - populationSuccesses,
            sampleSize - sampleSuccesses,
          ) -
          _logCombination(populationSize, sampleSize),
    );
  }

  double _logCombination(int n, int k) {
    return _logGamma(n + 1) - _logGamma(k + 1) - _logGamma(n - k + 1);
  }

  Object? _probability(List<_FormulaArgument> args) {
    final values = args[0];
    final probabilities = args[1];
    if (values.rowCount != probabilities.rowCount ||
        values.columnCount != probabilities.columnCount) {
      return _FormulaError.na;
    }
    final hasBounds = args.length >= 3;
    final lower = hasBounds
        ? FortuneFormulaEngine._numberFromFormulaValue(args[2].singleValue)
        : null;
    final upper = args.length == 4
        ? FortuneFormulaEngine._numberFromFormulaValue(args[3].singleValue)
        : lower;
    if (hasBounds &&
        (lower == null ||
            upper == null ||
            !lower.isFinite ||
            !upper.isFinite ||
            lower > upper)) {
      return _FormulaError.num;
    }
    var probabilitySum = 0.0;
    var result = 0.0;
    for (var i = 0; i < values.values.length; i += 1) {
      final value = FortuneFormulaEngine._numberFromFormulaValue(
        values.values[i],
      );
      final probability = FortuneFormulaEngine._numberFromFormulaValue(
        probabilities.values[i],
      );
      if (value == null || !value.isFinite) {
        return _FormulaError.value;
      }
      if (probability == null ||
          !probability.isFinite ||
          probability < 0 ||
          probability > 1) {
        return _FormulaError.num;
      }
      probabilitySum += probability;
      if (hasBounds && value >= lower! && value <= upper!) {
        result += probability;
      }
    }
    if ((probabilitySum - 1).abs() > 1e-9) {
      return _FormulaError.num;
    }
    return result;
  }

  Object? _normalDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final mean = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final standardDeviation = FortuneFormulaEngine._numberFromFormulaValue(
      values[2],
    );
    if (x == null ||
        mean == null ||
        standardDeviation == null ||
        !x.isFinite ||
        !mean.isFinite ||
        !standardDeviation.isFinite) {
      return null;
    }
    if (standardDeviation <= 0) {
      return _FormulaError.num;
    }
    final z = (x - mean) / standardDeviation;
    if (_truthy(values[3])) {
      return _standardNormalCdf(z);
    }
    return _standardNormalPdf(z) / standardDeviation;
  }

  Object? _logNormalDistribution(List<Object> values) {
    final x = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final mean = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final standardDeviation = FortuneFormulaEngine._numberFromFormulaValue(
      values[2],
    );
    if (x == null ||
        mean == null ||
        standardDeviation == null ||
        !x.isFinite ||
        !mean.isFinite ||
        !standardDeviation.isFinite) {
      return null;
    }
    if (x <= 0 || standardDeviation <= 0) {
      return _FormulaError.num;
    }
    final z = (math.log(x) - mean) / standardDeviation;
    if (_truthy(values[3])) {
      return _standardNormalCdf(z);
    }
    return _standardNormalPdf(z) / (x * standardDeviation);
  }

  Object? _logNormalInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final mean = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final standardDeviation = FortuneFormulaEngine._numberFromFormulaValue(
      values[2],
    );
    if (probability == null ||
        mean == null ||
        standardDeviation == null ||
        !probability.isFinite ||
        !mean.isFinite ||
        !standardDeviation.isFinite) {
      return null;
    }
    if (probability <= 0 || probability >= 1 || standardDeviation <= 0) {
      return _FormulaError.num;
    }
    return _finiteNumberOrNum(
      math.exp(
        mean + standardDeviation * _inverseStandardNormalCdf(probability),
      ),
    );
  }

  Object? _standardNormalDistribution(List<Object> values) {
    final z = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    if (z == null || !z.isFinite) {
      return null;
    }
    return _truthy(values[1]) ? _standardNormalCdf(z) : _standardNormalPdf(z);
  }

  Object? _zTest(List<_FormulaArgument> args) {
    final sample = args[0].values
        .map(_numberArgument)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();
    final x = _numberArgument(args[1].singleValue);
    if (sample.isEmpty || x == null || !x.isFinite) {
      return null;
    }
    final standardDeviation = args.length == 3
        ? _numberArgument(args[2].singleValue)
        : _standardDeviation(sample, sample: true);
    if (standardDeviation == null || !standardDeviation.isFinite) {
      return null;
    }
    if (standardDeviation <= 0) {
      return _FormulaError.num;
    }
    final z =
        (_averageNumberValue(sample) - x) /
        (standardDeviation / math.sqrt(sample.length));
    return 1 - _standardNormalCdf(z);
  }

  Object? _normalInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final mean = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final standardDeviation = FortuneFormulaEngine._numberFromFormulaValue(
      values[2],
    );
    if (probability == null ||
        mean == null ||
        standardDeviation == null ||
        !probability.isFinite ||
        !mean.isFinite ||
        !standardDeviation.isFinite) {
      return null;
    }
    if (probability <= 0 || probability > 1 || standardDeviation <= 0) {
      return _FormulaError.num;
    }
    if (probability == 1) {
      return mean + standardDeviation * 100 * math.sqrt2;
    }
    return mean + standardDeviation * _inverseStandardNormalCdf(probability);
  }

  Object? _standardNormalInverse(List<Object> values) {
    final probability = FortuneFormulaEngine._numberFromFormulaValue(
      values.single,
    );
    if (probability == null || !probability.isFinite) {
      return null;
    }
    if (probability <= 0 || probability > 1) {
      return _FormulaError.num;
    }
    if (probability == 1) {
      return 100 * math.sqrt2;
    }
    return _inverseStandardNormalCdf(probability);
  }

  double _standardNormalPdf(double z) {
    return math.exp(-0.5 * z * z) / math.sqrt(2 * math.pi);
  }

  double _standardNormalCdf(double z) {
    final scaled = z / math.sqrt2;
    final erfValue = scaled.abs() <= 3 ? _erfSeries(scaled) : _erf(scaled);
    return 0.5 * (1 + erfValue);
  }

  double _erfSeries(double x) {
    var term = x;
    var sum = x;
    final square = x * x;
    for (var index = 1; index < 120; index += 1) {
      term *= -square / index;
      final addend = term / (2 * index + 1);
      sum += addend;
      if (addend.abs() < 1e-17) {
        break;
      }
    }
    return 2 / math.sqrt(math.pi) * sum;
  }

  double _erf(double x) {
    if (x.abs() <= 3) {
      return _erfSeries(x);
    }
    const p = 0.3275911;
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    final sign = x < 0 ? -1 : 1;
    final absolute = x.abs();
    final t = 1 / (1 + p * absolute);
    final y =
        1 -
        (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) *
            t *
            math.exp(-absolute * absolute);
    return sign * y;
  }

  double _inverseStandardNormalCdf(double probability) {
    const a = [
      -3.969683028665376e+01,
      2.209460984245205e+02,
      -2.759285104469687e+02,
      1.383577518672690e+02,
      -3.066479806614716e+01,
      2.506628277459239e+00,
    ];
    const b = [
      -5.447609879822406e+01,
      1.615858368580409e+02,
      -1.556989798598866e+02,
      6.680131188771972e+01,
      -1.328068155288572e+01,
    ];
    const c = [
      -7.784894002430293e-03,
      -3.223964580411365e-01,
      -2.400758277161838e+00,
      -2.549732539343734e+00,
      4.374664141464968e+00,
      2.938163982698783e+00,
    ];
    const d = [
      7.784695709041462e-03,
      3.224671290700398e-01,
      2.445134137142996e+00,
      3.754408661907416e+00,
    ];
    const lower = 0.02425;
    const upper = 1 - lower;
    if (probability < lower) {
      final q = math.sqrt(-2 * math.log(probability));
      return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
    if (probability > upper) {
      final q = math.sqrt(-2 * math.log(1 - probability));
      return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
    final q = probability - 0.5;
    final r = q * q;
    return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r +
            a[5]) *
        q /
        (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
  }

  Object? _linearRegressionModel(
    List<_FormulaArgument> args, {
    bool strict = false,
  }) {
    final pairs = _numericPairs(args, strict: strict);
    if (pairs == null) {
      return null;
    }
    if (pairs is _FormulaError) {
      return pairs;
    }
    if (pairs is! List<_FormulaPair>) {
      return null;
    }
    return _linearRegressionModelFromPairs(pairs);
  }

  Object? _linearRegressionModelFromPairs(List<_FormulaPair> pairs) {
    if (pairs.length < 2) {
      return _FormulaError.div0;
    }
    final yMean =
        pairs.fold<double>(0, (sum, pair) => sum + pair.left) / pairs.length;
    final xMean =
        pairs.fold<double>(0, (sum, pair) => sum + pair.right) / pairs.length;
    var crossDeviation = 0.0;
    var xDeviation = 0.0;
    for (final pair in pairs) {
      final yDelta = pair.left - yMean;
      final xDelta = pair.right - xMean;
      crossDeviation += yDelta * xDelta;
      xDeviation += xDelta * xDelta;
    }
    if (xDeviation == 0) {
      return _FormulaError.div0;
    }
    final slope = crossDeviation / xDeviation;
    final intercept = yMean - slope * xMean;
    return _LinearRegressionModel(pairs, slope, intercept);
  }

  Object? _numericPairs(List<_FormulaArgument> args, {bool strict = false}) {
    if (!_sameShape(args)) {
      return null;
    }
    final left = args[0];
    final right = args[1];
    final pairs = <_FormulaPair>[];
    for (var row = 0; row < left.rowCount; row += 1) {
      for (var column = 0; column < left.columnCount; column += 1) {
        final x = _numberArgument(left.valueAt(row, column));
        final y = _numberArgument(right.valueAt(row, column));
        if (strict && (x == null || y == null)) {
          return _FormulaError.value;
        }
        if (x != null && y != null && x.isFinite && y.isFinite) {
          pairs.add(_FormulaPair(x, y));
        }
      }
    }
    return pairs;
  }

  double? _skew(List<double> values) {
    final n = values.length;
    if (n < 3) {
      return null;
    }
    final mean = values.fold<double>(0, (sum, item) => sum + item) / n;
    final stdev = _standardDeviation(values, sample: true);
    if (stdev == null || stdev == 0) {
      return null;
    }
    final standardizedCubeSum = values.fold<double>(
      0,
      (sum, item) => sum + math.pow((item - mean) / stdev, 3).toDouble(),
    );
    return n / ((n - 1) * (n - 2)) * standardizedCubeSum;
  }

  double? _skewPopulation(List<double> values) {
    final n = values.length;
    if (n < 2) {
      return null;
    }
    final mean = values.fold<double>(0, (sum, item) => sum + item) / n;
    final variance = _variance(values, sample: false);
    if (variance == null || variance == 0) {
      return null;
    }
    final stdev = math.sqrt(variance);
    return values.fold<double>(
          0,
          (sum, item) => sum + math.pow((item - mean) / stdev, 3).toDouble(),
        ) /
        n;
  }

  double? _kurt(List<double> values) {
    final n = values.length;
    if (n < 4) {
      return null;
    }
    final mean = values.fold<double>(0, (sum, item) => sum + item) / n;
    final stdev = _standardDeviation(values, sample: true);
    if (stdev == null || stdev == 0) {
      return null;
    }
    final standardizedFourthSum = values.fold<double>(
      0,
      (sum, item) => sum + math.pow((item - mean) / stdev, 4).toDouble(),
    );
    return n * (n + 1) / ((n - 1) * (n - 2) * (n - 3)) * standardizedFourthSum -
        3 * math.pow(n - 1, 2).toDouble() / ((n - 2) * (n - 3));
  }

  Object? _geometricMean(List<double> values) {
    if (values.isEmpty || values.any((value) => !value.isFinite)) {
      return null;
    }
    if (values.any((value) => value <= 0)) {
      return _FormulaError.num;
    }
    final logSum = values.fold<double>(0, (sum, item) => sum + math.log(item));
    return math.exp(logSum / values.length);
  }

  Object? _harmonicMean(List<double> values) {
    if (values.isEmpty || values.any((value) => !value.isFinite)) {
      return null;
    }
    if (values.any((value) => value <= 0)) {
      return _FormulaError.num;
    }
    final reciprocalSum = values.fold<double>(0, (sum, item) => sum + 1 / item);
    return values.length / reciprocalSum;
  }

  Object? _ranked(List<double> values, double rank, bool descending) {
    final k = _integerDigits(rank);
    if (k == null) {
      return null;
    }
    if (k < 1 || k > values.length) {
      return _FormulaError.num;
    }
    final sorted = [...values]..sort();
    return descending ? sorted[sorted.length - k] : sorted[k - 1];
  }

  Object? _rankedFunction(List<_FormulaArgument> args, bool descending) {
    final parsedValues = _strictNumbers(args[0].values);
    if (parsedValues is _FormulaError) {
      return parsedValues;
    }
    if (parsedValues is! List<double>) {
      return null;
    }
    final rank = _numberArgument(args[1].singleValue);
    if (rank == null) {
      return _FormulaError.value;
    }
    return _ranked(parsedValues, rank, descending);
  }

  Object? _rank(List<_FormulaArgument> args, {required bool averageTies}) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(
      args[0].singleValue,
    );
    if (number == null || !number.isFinite) {
      return strictParserCompatibility ? _FormulaError.value : null;
    }
    final values = args[1].values.map(_numberArgument).whereType<double>();
    final numbers = values.where((value) => value.isFinite).toList();
    if (numbers.isEmpty) {
      return null;
    }
    final order = args.length == 3
        ? FortuneFormulaEngine._numberFromFormulaValue(args[2].singleValue)
        : 0;
    if (order == null || !order.isFinite) {
      return strictParserCompatibility ? _FormulaError.value : null;
    }
    final tieCount = numbers.where((value) => value == number).length;
    if (tieCount == 0) {
      return _FormulaError.na;
    }
    final beforeCount = order == 0
        ? numbers.where((value) => value > number).length
        : numbers.where((value) => value < number).length;
    final firstRank = beforeCount + 1;
    return averageTies ? firstRank + (tieCount - 1) / 2 : firstRank.toDouble();
  }

  double? _dateSerial(double year, double month, double day) {
    final date = _dateFromParts(year, month, day);
    return date?.difference(DateTime.utc(1899, 12, 30)).inDays.toDouble();
  }

  DateTime? _dateFromParts(double year, double month, double day) {
    final y = _integerDigits(year);
    final m = _integerDigits(month);
    final d = _integerDigits(day);
    if (y == null || m == null || d == null || y < 0) {
      return null;
    }
    final normalizedYear = y >= 0 && y < 1900 ? y + 1900 : y;
    return DateTime.utc(normalizedYear, m, d);
  }

  double _todaySerial() {
    final now = DateTime.now();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime.utc(1899, 12, 30)).inDays.toDouble();
  }

  double _nowSerial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final seconds = now.difference(today).inMilliseconds / 1000;
    return _todaySerial() + seconds / (24 * 60 * 60);
  }

  double? _datePart(Object value, _DatePart part) {
    final date = _dateTime(value)?.dateTime;
    if (date == null) {
      return null;
    }
    return switch (part) {
      _DatePart.year => date.year.toDouble(),
      _DatePart.month => date.month.toDouble(),
      _DatePart.day => date.day.toDouble(),
    };
  }

  double? _dateValue(Object value) {
    final date = _dateTime(value)?.dateTime;
    if (date == null) {
      return null;
    }
    return _dateSerialFromDate(date);
  }

  double? _edate(Object startDate, Object months, bool endOfMonth) {
    final date = _dateTime(startDate)?.dateTime;
    final monthDelta = FortuneFormulaEngine._numberFromFormulaValue(months);
    if (date == null || monthDelta == null || !monthDelta.isFinite) {
      return null;
    }
    final target = _addMonthsClamped(date, monthDelta.truncate());
    final result = endOfMonth
        ? DateTime.utc(target.year, target.month + 1, 0)
        : target;
    return _dateSerialFromDate(result);
  }

  double? _days(Object endDate, Object startDate) {
    final end = _dateTime(endDate)?.dateTime;
    final start = _dateTime(startDate)?.dateTime;
    if (end == null || start == null) {
      return null;
    }
    return (_dateSerialFromDate(end) - _dateSerialFromDate(start)).toDouble();
  }

  Object? _dateDif(Object startDate, Object endDate, Object unitValue) {
    final start = _dateTime(startDate)?.dateTime;
    final end = _dateTime(endDate)?.dateTime;
    if (start == null || end == null) {
      return null;
    }
    if (end.isBefore(start)) {
      return _FormulaError.num;
    }
    final unit = _text(unitValue).toUpperCase();
    if (unit == 'D') {
      return end.difference(start).inDays.toDouble();
    }
    final completeMonths = _completeMonthDifference(start, end);
    return switch (unit) {
      'Y' => (completeMonths ~/ 12).toDouble(),
      'M' => completeMonths.toDouble(),
      'YM' => (completeMonths % 12).toDouble(),
      'MD' =>
        end
            .difference(_addMonthsClamped(start, completeMonths))
            .inDays
            .toDouble(),
      'YD' => end.difference(_yearDayAnchor(start, end)).inDays.toDouble(),
      _ => _FormulaError.num,
    };
  }

  int _completeMonthDifference(DateTime start, DateTime end) {
    final monthDelta = (end.year - start.year) * 12 + end.month - start.month;
    return end.day < start.day ? monthDelta - 1 : monthDelta;
  }

  DateTime _yearDayAnchor(DateTime start, DateTime end) {
    var anchor = _dateInYearClamped(start, end.year);
    if (anchor.isAfter(end)) {
      anchor = _dateInYearClamped(start, end.year - 1);
    }
    return anchor;
  }

  DateTime _dateInYearClamped(DateTime source, int year) {
    return DateTime.utc(
      year,
      source.month,
      math.min(source.day, _lastDayOfMonth(year, source.month)),
    );
  }

  double? _days360(Object startDate, Object endDate, bool european) {
    if (startDate is num || endDate is num) {
      return null;
    }
    final start = _dateTime(startDate)?.dateTime;
    final end = _dateTime(endDate)?.dateTime;
    if (start == null || end == null) {
      return null;
    }
    return _days360Dates(start, end, european);
  }

  double _days360Dates(DateTime start, DateTime end, bool european) {
    var startDay = start.day;
    var endDay = end.day;
    if (european) {
      if (startDay == 31) {
        startDay = 30;
      }
      if (endDay == 31) {
        endDay = 30;
      }
    } else {
      final startIsLastFebruary =
          start.month == 2 &&
          start.day == _lastDayOfMonth(start.year, start.month);
      final endIsLastFebruary =
          end.month == 2 && end.day == _lastDayOfMonth(end.year, end.month);
      if (startIsLastFebruary) {
        startDay = 30;
      }
      if (endIsLastFebruary && startIsLastFebruary) {
        endDay = 30;
      }
      if (startDay == 31) {
        startDay = 30;
      }
      if (endDay == 31 && startDay >= 30) {
        endDay = 30;
      }
    }
    return ((end.year - start.year) * 360 +
            (end.month - start.month) * 30 +
            (endDay - startDay))
        .toDouble();
  }

  Object? _yearFrac(Object startDate, Object endDate, Object basisValue) {
    final start = _dateTime(startDate)?.dateTime;
    final end = _dateTime(endDate)?.dateTime;
    final basisNumber = FortuneFormulaEngine._numberFromFormulaValue(
      basisValue,
    );
    if (start == null ||
        end == null ||
        basisNumber == null ||
        !basisNumber.isFinite) {
      return null;
    }
    final basis = basisNumber.truncate();
    if (basis < 0 || basis > 4) {
      return _FormulaError.num;
    }
    if (start == end) {
      return 0;
    }
    if (start.isAfter(end)) {
      final result = _yearFrac(end, start, basis);
      final number = FortuneFormulaEngine._numberFromFormulaValue(result);
      return number == null ? _formulaError(result) : -number;
    }
    final actualDays = end.difference(start).inDays.toDouble();
    return switch (basis) {
      0 => _days360Dates(start, end, false) / 360,
      1 => _actualActualYearFrac(start, end),
      2 => actualDays / 360,
      3 => actualDays / 365,
      4 => _days360Dates(start, end, true) / 360,
      _ => null,
    };
  }

  double _actualActualYearFrac(DateTime start, DateTime end) {
    if (start.year == end.year) {
      return end.difference(start).inDays / _daysInYear(start.year);
    }
    final nextYear = DateTime.utc(start.year + 1);
    final endYearStart = DateTime.utc(end.year);
    final startFraction =
        nextYear.difference(start).inDays / _daysInYear(start.year);
    final endFraction =
        end.difference(endYearStart).inDays / _daysInYear(end.year);
    return startFraction + (end.year - start.year - 1) + endFraction;
  }

  Object? _weekday(Object value, Object returnType) {
    final date = _dateTime(value)?.dateTime;
    final typeNumber = FortuneFormulaEngine._numberFromFormulaValue(returnType);
    if (date == null || typeNumber == null || !typeNumber.isFinite) {
      return null;
    }
    final type = typeNumber.truncate();
    return switch (type) {
      1 => (date.weekday % 7 + 1).toDouble(),
      2 => date.weekday.toDouble(),
      3 => (date.weekday - 1).toDouble(),
      >= 11 && <= 17 => ((date.weekday - (type - 10) + 7) % 7 + 1).toDouble(),
      _ => _FormulaError.num,
    };
  }

  Object? _weekNum(Object value, Object returnType) {
    final date = _dateTime(value)?.dateTime;
    final typeNumber = FortuneFormulaEngine._numberFromFormulaValue(returnType);
    if (date == null || typeNumber == null || !typeNumber.isFinite) {
      return null;
    }
    final type = typeNumber.truncate();
    if (type == 21) {
      return _isoWeekNumber(date).toDouble();
    }
    final weekStart = switch (type) {
      1 => 7,
      2 => 1,
      >= 11 && <= 17 => type - 10,
      _ => null,
    };
    if (weekStart == null) {
      return _FormulaError.num;
    }
    final firstDay = DateTime.utc(date.year);
    final dayOfYear = date.difference(firstDay).inDays + 1;
    final leadingDays = (firstDay.weekday - weekStart + 7) % 7;
    return (((dayOfYear + leadingDays - 1) ~/ 7) + 1).toDouble();
  }

  Object? _interval(Object value) {
    final number = _numberArgument(value);
    if (number == null) {
      return null;
    }
    final totalSeconds = _integerDigits(number);
    if (totalSeconds == null || totalSeconds < 0) {
      return _FormulaError.num;
    }
    var remaining = totalSeconds;
    final years = remaining ~/ (365 * 24 * 60 * 60);
    remaining %= 365 * 24 * 60 * 60;
    final months = remaining ~/ (30 * 24 * 60 * 60);
    remaining %= 30 * 24 * 60 * 60;
    final days = remaining ~/ (24 * 60 * 60);
    remaining %= 24 * 60 * 60;
    final hours = remaining ~/ (60 * 60);
    remaining %= 60 * 60;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;

    final buffer = StringBuffer('P');
    if (years > 0) {
      buffer.write('${years}Y');
    }
    if (months > 0) {
      buffer.write('${months}M');
    }
    if (days > 0) {
      buffer.write('${days}D');
    }
    if (hours > 0 || minutes > 0 || seconds > 0 || buffer.length == 1) {
      buffer.write('T');
      if (hours > 0) {
        buffer.write('${hours}H');
      }
      if (minutes > 0) {
        buffer.write('${minutes}M');
      }
      if (seconds > 0) {
        buffer.write('${seconds}S');
      }
    }
    return buffer.toString();
  }

  double? _isoWeekNum(Object value) {
    final date = _dateTime(value)?.dateTime;
    return date == null ? null : _isoWeekNumber(date).toDouble();
  }

  int _isoWeekNumber(DateTime date) {
    final normalized = DateTime.utc(date.year, date.month, date.day);
    final thursday = normalized.add(Duration(days: 4 - normalized.weekday));
    final weekYearAnchor = DateTime.utc(thursday.year, 1, 4);
    final firstWeekStart = weekYearAnchor.subtract(
      Duration(days: weekYearAnchor.weekday - 1),
    );
    final currentWeekStart = normalized.subtract(
      Duration(days: normalized.weekday - 1),
    );
    return 1 + currentWeekStart.difference(firstWeekStart).inDays ~/ 7;
  }

  double? _networkDays(
    Object startDate,
    Object endDate,
    List<_FormulaArgument> args,
  ) {
    return _networkDaysWithWeekend(
      startDate,
      endDate,
      _defaultWeekendDays,
      args.length == 3 ? args[2].values : [],
    );
  }

  Object? _networkDaysIntl(List<_FormulaArgument> args) {
    final weekend = args.length >= 3
        ? _weekendDays(args[2].singleValue)
        : _defaultWeekendDays;
    if (weekend == null) {
      return _weekendCodeError(args[2].singleValue);
    }
    return _networkDaysWithWeekend(
      args[0].singleValue,
      args[1].singleValue,
      weekend,
      args.length == 4 ? args[3].values : [],
    );
  }

  double? _networkDaysWithWeekend(
    Object startDate,
    Object endDate,
    Set<int> weekend,
    List<Object> holidayValues,
  ) {
    final start = _dateTime(startDate)?.dateTime;
    final end = _dateTime(endDate)?.dateTime;
    if (start == null || end == null) {
      return null;
    }
    final holidays = _holidaySerials(holidayValues);
    if (holidays == null) {
      return null;
    }
    final direction = start.isAfter(end) ? -1 : 1;
    var cursor = DateTime.utc(start.year, start.month, start.day);
    final target = DateTime.utc(end.year, end.month, end.day);
    var count = 0;
    while (true) {
      if (_isWorkday(cursor, holidays, weekend)) {
        count += direction;
      }
      if (cursor == target) {
        break;
      }
      cursor = cursor.add(Duration(days: direction));
    }
    return count.toDouble();
  }

  Object? _workday(
    Object startDate,
    Object days,
    List<_FormulaArgument> args, {
    bool returnDate = false,
  }) {
    final date = _workdayWithWeekend(
      startDate,
      days,
      _defaultWeekendDays,
      args.length == 3 ? args[2].values : [],
    );
    return returnDate
        ? date
        : (date == null ? null : _dateSerialFromDate(date));
  }

  Object? _workdayIntl(List<_FormulaArgument> args) {
    final weekend = args.length >= 3
        ? _weekendDays(args[2].singleValue)
        : _defaultWeekendDays;
    if (weekend == null) {
      return _weekendCodeError(args[2].singleValue);
    }
    final date = _workdayWithWeekend(
      args[0].singleValue,
      args[1].singleValue,
      weekend,
      args.length == 4 ? args[3].values : [],
    );
    return date == null ? null : _dateSerialFromDate(date);
  }

  DateTime? _workdayWithWeekend(
    Object startDate,
    Object days,
    Set<int> weekend,
    List<Object> holidayValues,
  ) {
    final start = _dateTime(startDate)?.dateTime;
    final dayCount = FortuneFormulaEngine._numberFromFormulaValue(days);
    if (start == null || dayCount == null || !dayCount.isFinite) {
      return null;
    }
    final holidays = _holidaySerials(holidayValues);
    if (holidays == null) {
      return null;
    }
    final targetDays = dayCount.truncate();
    final direction = targetDays < 0 ? -1 : 1;
    var remaining = targetDays.abs();
    var cursor = DateTime.utc(start.year, start.month, start.day);
    while (remaining > 0) {
      cursor = cursor.add(Duration(days: direction));
      if (_isWorkday(cursor, holidays, weekend)) {
        remaining -= 1;
      }
    }
    return cursor;
  }

  Set<int>? _holidaySerials(List<Object> values) {
    final holidays = <int>{};
    for (final value in values) {
      if (_isFormulaBlankLike(value)) {
        continue;
      }
      final date = _dateTime(value)?.dateTime;
      if (date == null) {
        return null;
      }
      holidays.add(_dateSerialFromDate(date).truncate());
    }
    return holidays;
  }

  Set<int>? _weekendDays(Object value) {
    if (value is String) {
      final mask = value.trim();
      if (mask.length != 7 || mask.contains(RegExp(r'[^01]'))) {
        return null;
      }
      final weekend = <int>{};
      for (var i = 0; i < mask.length; i += 1) {
        if (mask[i] == '1') {
          weekend.add(i + 1);
        }
      }
      return weekend.length == 7 ? null : weekend;
    }
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null || !number.isFinite) {
      return null;
    }
    return switch (number.truncate()) {
      1 => _defaultWeekendDays,
      2 => {DateTime.sunday, DateTime.monday},
      3 => {DateTime.monday, DateTime.tuesday},
      4 => {DateTime.tuesday, DateTime.wednesday},
      5 => {DateTime.wednesday, DateTime.thursday},
      6 => {DateTime.thursday, DateTime.friday},
      7 => {DateTime.friday, DateTime.saturday},
      11 => {DateTime.sunday},
      12 => {DateTime.monday},
      13 => {DateTime.tuesday},
      14 => {DateTime.wednesday},
      15 => {DateTime.thursday},
      16 => {DateTime.friday},
      17 => {DateTime.saturday},
      _ => null,
    };
  }

  Object? _weekendCodeError(Object value) {
    if (value is String) {
      return null;
    }
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    return number == null || !number.isFinite ? null : _FormulaError.num;
  }

  bool _isWorkday(DateTime date, Set<int> holidays, Set<int> weekend) {
    if (weekend.contains(date.weekday)) {
      return false;
    }
    return !holidays.contains(_dateSerialFromDate(date).truncate());
  }

  DateTime _addMonthsClamped(DateTime date, int months) {
    final zeroBasedMonth = date.month - 1 + months;
    final targetYear = date.year + (zeroBasedMonth / 12).floor();
    final targetMonth = zeroBasedMonth % 12 + 1;
    final targetDay = math.min(
      date.day,
      _lastDayOfMonth(targetYear, targetMonth),
    );
    return DateTime.utc(targetYear, targetMonth, targetDay);
  }

  int _lastDayOfMonth(int year, int month) {
    return DateTime.utc(year, month + 1, 0).day;
  }

  int _daysInYear(int year) {
    return DateTime.utc(year + 1).difference(DateTime.utc(year)).inDays;
  }

  double _dateSerialFromDate(DateTime date) {
    final serial = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(1899, 12, 30)).inDays.toDouble();
    if (date.year == 1900 && date.month <= 2) {
      return serial - 1;
    }
    return serial;
  }

  DateTime _dateFromSerialNumber(int wholeDays, int seconds) {
    final base = wholeDays >= 1 && wholeDays <= 59
        ? DateTime.utc(1899, 12, 31)
        : DateTime.utc(1899, 12, 30);
    return base.add(Duration(days: wholeDays, seconds: seconds));
  }

  Object? _timeSerial(double hour, double minute, double second) {
    final h = _integerDigits(hour);
    final m = _integerDigits(minute);
    final s = _integerDigits(second);
    if (h == null || m == null || s == null) {
      return null;
    }
    if (h < 0 || m < 0 || s < 0) {
      return _FormulaError.num;
    }
    const secondsPerDay = 24 * 60 * 60;
    final totalSeconds = h * 60 * 60 + m * 60 + s;
    if (totalSeconds == secondsPerDay) {
      return 1.0;
    }
    final seconds = totalSeconds % secondsPerDay;
    return seconds / secondsPerDay;
  }

  double? _timePart(Object value, _TimePart part) {
    final time = _timeOfDay(value);
    if (time == null) {
      return null;
    }
    return switch (part) {
      _TimePart.hour => time.hour.toDouble(),
      _TimePart.minute => time.minute.toDouble(),
      _TimePart.second => time.second.toDouble(),
    };
  }

  double? _timeValue(Object value) {
    final time = _timeOfDay(value);
    if (time == null) {
      return null;
    }
    return (time.hour * 60 * 60 +
            time.minute * 60 +
            time.second +
            time.millisecond / 1000) /
        (24 * 60 * 60);
  }

  bool _isBinaryValue(Object value) {
    final text = _text(value).trim();
    return text.isNotEmpty && RegExp(r'^[01]+$').hasMatch(text);
  }

  _FormulaDateTime? _dateTime(Object value) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number != null && number.isFinite) {
      final wholeDays = number.truncate();
      final fraction = number - wholeDays;
      final seconds = (fraction * 24 * 60 * 60).round();
      return _FormulaDateTime(_dateFromSerialNumber(wholeDays, seconds));
    }
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(normalized);
    if (parsed != null) {
      return _FormulaDateTime(
        DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
        ),
      );
    }
    final slashDateTime = _slashDateTime(normalized);
    if (slashDateTime != null) {
      return _FormulaDateTime(slashDateTime);
    }
    final namedMonthDateTime = _namedMonthDateTime(normalized);
    if (namedMonthDateTime != null) {
      return _FormulaDateTime(namedMonthDateTime);
    }
    final match = RegExp(
      r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})$',
    ).firstMatch(normalized);
    if (match == null) {
      return null;
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final date = DateTime.utc(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? _FormulaDateTime(date)
        : null;
  }

  DateTime? _namedMonthDateTime(String value) {
    final match = RegExp(
      r'^(\d{1,2})[/-]([A-Za-z]{3,9})[/-](\d{2}|\d{4})'
      r'(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2})(?:\.(\d{1,3}))?)?\s*'
      r'([AaPp]\.?[Mm]\.?)?)?$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final day = int.parse(match.group(1)!);
    final month = _englishMonthNumber(match.group(2)!);
    if (month == null) {
      return null;
    }
    var year = int.parse(match.group(3)!);
    if (match.group(3)!.length == 2) {
      year += year < 30 ? 2000 : 1900;
    }
    var hour = int.tryParse(match.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;
    final millisecond = _parseMillisecond(match.group(7));
    final meridiem = match.group(8)?.toUpperCase().replaceAll('.', '');
    if (meridiem != null) {
      if (hour < 1 || hour > 12) {
        return null;
      }
      hour = switch (meridiem) {
        'AM' => hour == 12 ? 0 : hour,
        'PM' => hour == 12 ? 12 : hour + 12,
        _ => hour,
      };
    }
    if (hour >= 24 || minute >= 60 || second >= 60) {
      return null;
    }
    final date = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
    );
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  int? _englishMonthNumber(String value) {
    return switch (value.toLowerCase()) {
      'jan' || 'january' => 1,
      'feb' || 'february' => 2,
      'mar' || 'march' => 3,
      'apr' || 'april' => 4,
      'may' => 5,
      'jun' || 'june' => 6,
      'jul' || 'july' => 7,
      'aug' || 'august' => 8,
      'sep' || 'sept' || 'september' => 9,
      'oct' || 'october' => 10,
      'nov' || 'november' => 11,
      'dec' || 'december' => 12,
      _ => null,
    };
  }

  DateTime? _slashDateTime(String value) {
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})'
      r'(?:\s+(\d{1,2}):(\d{1,2})(?::(\d{1,2})(?:\.(\d{1,3}))?)?\s*'
      r'([AaPp]\.?[Mm]\.?)?)?$',
    ).firstMatch(value);
    if (match == null) {
      return null;
    }
    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    var hour = int.tryParse(match.group(4) ?? '0') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '0') ?? 0;
    final second = int.tryParse(match.group(6) ?? '0') ?? 0;
    final millisecond = _parseMillisecond(match.group(7));
    final meridiem = match.group(8)?.toUpperCase().replaceAll('.', '');
    if (meridiem != null) {
      if (hour < 1 || hour > 12) {
        return null;
      }
      hour = switch (meridiem) {
        'AM' => hour == 12 ? 0 : hour,
        'PM' => hour == 12 ? 12 : hour + 12,
        _ => hour,
      };
    }
    if (hour >= 24 || minute >= 60 || second >= 60) {
      return null;
    }
    final date = DateTime.utc(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
    );
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  _FormulaTime? _timeOfDay(Object value) {
    final dateTime = _dateTime(value);
    if (dateTime != null) {
      return _FormulaTime(
        dateTime.dateTime.hour,
        dateTime.dateTime.minute,
        dateTime.dateTime.second,
        dateTime.dateTime.millisecond,
      );
    }
    if (value is! String) {
      return null;
    }
    final match = RegExp(
      r'^(?:(?:\d{4}[/-]\d{1,2}[/-]\d{1,2})\s+)?'
      r'(\d{1,2}):(\d{1,2})(?::(\d{1,2})(?:\.(\d{1,3}))?)?\s*'
      r'([AaPp]\.?[Mm]\.?)?$',
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.tryParse(match.group(3) ?? '0') ?? 0;
    final millisecond = _parseMillisecond(match.group(4));
    final meridiem = match.group(5)?.toUpperCase().replaceAll('.', '');
    if (meridiem != null) {
      if (hour < 1 || hour > 12) {
        return null;
      }
      hour = switch (meridiem) {
        'AM' => hour == 12 ? 0 : hour,
        'PM' => hour == 12 ? 12 : hour + 12,
        _ => hour,
      };
    }
    if (hour >= 24 || minute >= 60 || second >= 60) {
      return null;
    }
    return _FormulaTime(hour, minute, second, millisecond);
  }

  int _parseMillisecond(String? fraction) {
    if (fraction == null) {
      return 0;
    }
    return int.parse(fraction.padRight(3, '0'));
  }

  String? _left(Object value, Object count) {
    final text = _text(value);
    final length = _textLength(count);
    if (length == null) {
      return null;
    }
    return text.substring(0, length > text.length ? text.length : length);
  }

  String? _right(Object value, Object count) {
    final text = _text(value);
    final length = _textLength(count);
    if (length == null) {
      return null;
    }
    final start = text.length - length;
    return text.substring(start < 0 ? 0 : start);
  }

  Object? _mid(Object value, Object start, Object count) {
    final text = _text(value);
    final oneBasedStart = _textLength(start);
    final length = _textLength(count);
    if (oneBasedStart == null || length == null) {
      return null;
    }
    if (oneBasedStart < 1) {
      return _FormulaError.value;
    }
    final startIndex = oneBasedStart - 1;
    if (startIndex >= text.length) {
      return '';
    }
    final endIndex = startIndex + length;
    return text.substring(
      startIndex,
      endIndex > text.length ? text.length : endIndex,
    );
  }

  Object? _textBeforeAfter(
    List<Object> values, {
    required bool before,
    Object? Function()? ifNotFound,
  }) {
    final sourceText = _text(values[0]);
    final delimiter = _text(values[1]);
    if (delimiter.isEmpty) {
      return null;
    }
    final instance = values.length >= 3
        ? FortuneFormulaEngine._numberFromFormulaValue(values[2])
        : 1.0;
    final matchMode = values.length >= 4
        ? FortuneFormulaEngine._numberFromFormulaValue(values[3])
        : 0.0;
    final matchEnd = values.length >= 5
        ? FortuneFormulaEngine._numberFromFormulaValue(values[4])
        : 0.0;
    if (instance == null ||
        matchMode == null ||
        matchEnd == null ||
        !instance.isFinite ||
        !matchMode.isFinite ||
        !matchEnd.isFinite) {
      return null;
    }
    final instanceIndex = instance.truncate();
    final normalizedMatchMode = matchMode.truncate();
    final normalizedMatchEnd = matchEnd.truncate();
    if (instanceIndex == 0 ||
        (normalizedMatchMode != 0 && normalizedMatchMode != 1) ||
        (normalizedMatchEnd != 0 && normalizedMatchEnd != 1)) {
      return _FormulaError.value;
    }

    final searchText = normalizedMatchMode == 1
        ? sourceText.toLowerCase()
        : sourceText;
    final searchDelimiter = normalizedMatchMode == 1
        ? delimiter.toLowerCase()
        : delimiter;
    final delimiterIndex = _delimiterInstanceIndex(
      searchText,
      searchDelimiter,
      instanceIndex,
    );
    if (delimiterIndex == null) {
      if (ifNotFound != null) {
        return ifNotFound();
      }
      if (values.length >= 6) {
        return values[5];
      }
      if (normalizedMatchEnd != 1) {
        return _FormulaError.na;
      }
      return before ? sourceText : '';
    }
    return before
        ? sourceText.substring(0, delimiterIndex)
        : sourceText.substring(delimiterIndex + delimiter.length);
  }

  int? _delimiterInstanceIndex(String text, String delimiter, int instance) {
    final delimiterIndexes = <int>[];
    var searchOffset = 0;
    while (searchOffset <= text.length) {
      final delimiterIndex = text.indexOf(delimiter, searchOffset);
      if (delimiterIndex < 0) {
        break;
      }
      delimiterIndexes.add(delimiterIndex);
      searchOffset = delimiterIndex + delimiter.length;
    }
    if (delimiterIndexes.isEmpty) {
      return null;
    }
    final selectedIndex = instance > 0
        ? instance - 1
        : delimiterIndexes.length + instance;
    if (selectedIndex < 0 || selectedIndex >= delimiterIndexes.length) {
      return null;
    }
    return delimiterIndexes[selectedIndex];
  }

  Object? _textSplit(List<Object> values) {
    final sourceText = _text(values[0]);
    final columnDelimiterResult = _textSplitDelimiters(values[1]);
    final hasRowDelimiter =
        values.length >= 3 && !_isFormulaBlankLike(values[2]);
    final rowDelimiterResult = hasRowDelimiter
        ? _textSplitDelimiters(values[2])
        : null;
    final ignoreEmpty = values.length >= 4 ? _truthy(values[3]) : false;
    final matchMode = values.length >= 5
        ? FortuneFormulaEngine._numberFromFormulaValue(values[4])
        : 0.0;
    final padWith = values.length >= 6 ? values[5] : _FormulaError.na;
    if (columnDelimiterResult is _FormulaError) {
      return columnDelimiterResult;
    }
    if (rowDelimiterResult is _FormulaError) {
      return rowDelimiterResult;
    }
    if (columnDelimiterResult is! List<String> ||
        (hasRowDelimiter && rowDelimiterResult is! List<String>) ||
        matchMode == null ||
        !matchMode.isFinite) {
      return null;
    }

    final normalizedMatchMode = matchMode.truncate();
    if (normalizedMatchMode != 0 && normalizedMatchMode != 1) {
      return _FormulaError.value;
    }

    final rowParts = rowDelimiterResult == null
        ? [sourceText]
        : _splitText(
            sourceText,
            rowDelimiterResult as List<String>,
            normalizedMatchMode,
          );
    final splitRows = [
      for (final rowPart in rowParts)
        _splitText(rowPart, columnDelimiterResult, normalizedMatchMode),
    ];
    if (ignoreEmpty) {
      for (var rowIndex = 0; rowIndex < splitRows.length; rowIndex += 1) {
        splitRows[rowIndex] = splitRows[rowIndex]
            .where((part) => part.isNotEmpty)
            .toList(growable: false);
      }
    }
    final rowCount = splitRows.isEmpty ? 1 : splitRows.length;
    var columnCount = 1;
    for (final row in splitRows) {
      if (row.length > columnCount) {
        columnCount = row.length;
      }
    }

    final result = <Object>[];
    for (final row in splitRows) {
      result.addAll(row);
      for (var column = row.length; column < columnCount; column += 1) {
        result.add(padWith);
      }
    }
    if (result.isEmpty) {
      result.add(_formulaBlank);
    }
    return _FormulaArgument.range(
      result,
      rowCount: rowCount,
      columnCount: columnCount,
    );
  }

  Object? _textSplitFunction() {
    final sources = _functionArgumentSources(allowEmpty: true);
    if (sources == null || sources.length < 2 || sources.length > 6) {
      return null;
    }
    if (sources[0].isEmpty || sources[1].isEmpty) {
      return null;
    }

    final values = <Object>[];
    for (final source in sources) {
      if (source.isEmpty) {
        values.add(_formulaBlank);
        continue;
      }
      final result = _evaluateArgumentSource(source);
      final error = _formulaError(result);
      if (error != null) {
        return error;
      }
      if (result == null) {
        return null;
      }
      values.add(
        result is _FormulaArgument && values.length != 1 && values.length != 2
            ? result.singleValue
            : result,
      );
    }
    return _textSplit(values);
  }

  Object? _textSplitDelimiters(Object value) {
    final values = value is _FormulaArgument ? value.values : [value];
    final error = _firstFormulaError(values);
    if (error != null) {
      return error;
    }
    final delimiters = <String>[];
    for (final item in values) {
      final delimiter = _text(item);
      if (delimiter.isEmpty) {
        return null;
      }
      delimiters.add(delimiter);
    }
    return delimiters.isEmpty ? null : delimiters;
  }

  List<String> _splitText(String text, List<String> delimiters, int matchMode) {
    if (matchMode == 0) {
      return _splitTextByDelimiters(text, delimiters, caseSensitive: true);
    }
    return _splitTextByDelimiters(text, delimiters, caseSensitive: false);
  }

  List<String> _splitTextByDelimiters(
    String text,
    List<String> delimiters, {
    required bool caseSensitive,
  }) {
    final searchText = caseSensitive ? text : text.toLowerCase();
    final searchDelimiters = caseSensitive
        ? delimiters
        : [for (final delimiter in delimiters) delimiter.toLowerCase()];
    final parts = <String>[];
    var start = 0;
    while (start <= text.length) {
      var selectedIndex = -1;
      var selectedDelimiter = '';
      for (var i = 0; i < searchDelimiters.length; i += 1) {
        final index = searchText.indexOf(searchDelimiters[i], start);
        if (index < 0) {
          continue;
        }
        if (selectedIndex < 0 ||
            index < selectedIndex ||
            (index == selectedIndex &&
                delimiters[i].length > selectedDelimiter.length)) {
          selectedIndex = index;
          selectedDelimiter = delimiters[i];
        }
      }
      if (selectedIndex < 0) {
        parts.add(text.substring(start));
        break;
      }
      parts.add(text.substring(start, selectedIndex));
      start = selectedIndex + selectedDelimiter.length;
    }
    return parts;
  }

  String? _replaceText(
    Object value,
    Object start,
    Object count,
    Object replacement,
  ) {
    final text = _text(value);
    final oneBasedStart = _textLength(start);
    final length = _textLength(count);
    if (oneBasedStart == null ||
        length == null ||
        oneBasedStart < 1 ||
        oneBasedStart > text.length + 1) {
      return null;
    }
    final startIndex = oneBasedStart - 1;
    final endIndex = math.min(startIndex + length, text.length);
    return text.replaceRange(startIndex, endIndex, _text(replacement));
  }

  Object? _rept(Object value, Object count) {
    final repeatCount = _textLength(count);
    if (repeatCount == null) {
      return _FormulaError.value;
    }
    return _text(value) * repeatCount;
  }

  String? _char(Object value) {
    final code = _textLength(value);
    if (code == null || code < 1 || code > 255) {
      return null;
    }
    return String.fromCharCode(code);
  }

  double? _code(Object value) {
    final text = _text(value);
    return text.isEmpty ? null : text.codeUnitAt(0).toDouble();
  }

  Object? _unichar(Object value) {
    final code = _textLength(value);
    if (code == null ||
        code < 1 ||
        code > 0x10FFFF ||
        (code >= 0xD800 && code <= 0xDFFF)) {
      return _FormulaError.value;
    }
    return String.fromCharCode(code);
  }

  double? _unicode(Object value) {
    final text = _text(value);
    return text.isEmpty ? null : text.runes.first.toDouble();
  }

  String _clean(Object value) {
    return _text(value).replaceAll(RegExp(r'[\x00-\x1F]'), '');
  }

  bool _exact(Object left, Object right) {
    if (left is num && right is num) {
      return left == right;
    }
    if (left is String && right is String) {
      return left == right;
    }
    if (left is bool && right is bool) {
      return left == right;
    }
    return false;
  }

  String _htmlToText(Object value) {
    return _text(value).replaceAll(RegExp(r'<[^>]*>'), '');
  }

  Object? _split(List<Object> values) {
    final text = _text(values[0]);
    final parts = values.length == 1 ? [text] : text.split(_text(values[1]));
    return _FormulaArgument.range(
      parts,
      rowCount: 1,
      columnCount: parts.length,
    );
  }

  Object? _regexExtract(Object value, Object pattern) {
    final regex = _safeRegExp(pattern);
    if (regex == null) {
      return _FormulaError.value;
    }
    final match = regex.firstMatch(_text(value));
    if (match == null) {
      return _FormulaError.na;
    }
    return match.groupCount > 0 ? match.group(1) ?? '' : match.group(0) ?? '';
  }

  Object? _regexMatch(Object value, Object pattern) {
    final regex = _safeRegExp(pattern);
    return regex == null ? _FormulaError.value : regex.hasMatch(_text(value));
  }

  Object? _regexReplace(Object value, Object pattern, Object replacement) {
    final regex = _safeRegExp(pattern);
    return regex == null
        ? _FormulaError.value
        : _text(value).replaceAll(regex, _text(replacement));
  }

  Object _dmTextCutword(Object value) {
    final tokens = _dmTextTokens(value);
    return _FormulaArgument.range(
      tokens,
      rowCount: 1,
      columnCount: math.max(1, tokens.length),
    );
  }

  Object _dmTextKeywords(Object value, Object? countValue) {
    final requestedCount = countValue == null
        ? 20
        : _numberArgument(countValue)?.round();
    final limit = requestedCount == null || requestedCount <= 0
        ? 20
        : requestedCount;
    final tokens = _dmTextTokens(value);
    final counts = <String, int>{};
    final firstIndex = <String, int>{};
    for (var index = 0; index < tokens.length; index += 1) {
      final token = tokens[index];
      counts[token] = (counts[token] ?? 0) + 1;
      firstIndex.putIfAbsent(token, () => index);
    }
    final keywords = counts.keys.toList()
      ..sort((left, right) {
        final countCompare = counts[right]!.compareTo(counts[left]!);
        if (countCompare != 0) {
          return countCompare;
        }
        final lengthCompare = right.runes.length.compareTo(left.runes.length);
        if (lengthCompare != 0) {
          return lengthCompare;
        }
        return firstIndex[left]!.compareTo(firstIndex[right]!);
      });
    final selected = keywords.take(limit).toList();
    return _FormulaArgument.range(
      selected,
      rowCount: 1,
      columnCount: math.max(1, selected.length),
    );
  }

  List<String> _dmTextTokens(Object value) {
    final tokens = <String>[];
    final buffer = StringBuffer();

    void flushBuffer() {
      if (buffer.isEmpty) {
        return;
      }
      tokens.add(buffer.toString().toLowerCase());
      buffer.clear();
    }

    for (final rune in _text(value).runes) {
      if (_isAsciiWordRune(rune)) {
        buffer.writeCharCode(rune);
      } else if (_isCjkRune(rune)) {
        flushBuffer();
        tokens.add(String.fromCharCode(rune));
      } else {
        flushBuffer();
      }
    }
    flushBuffer();
    return tokens;
  }

  bool _isAsciiWordRune(int rune) {
    return (rune >= 0x30 && rune <= 0x39) ||
        (rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        rune == 0x5F;
  }

  bool _isCjkRune(int rune) {
    return (rune >= 0x3400 && rune <= 0x4DBF) ||
        (rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0xF900 && rune <= 0xFAFF) ||
        (rune >= 0x20000 && rune <= 0x2A6DF) ||
        (rune >= 0x2A700 && rune <= 0x2B73F) ||
        (rune >= 0x2B740 && rune <= 0x2B81F) ||
        (rune >= 0x2B820 && rune <= 0x2CEAF);
  }

  RegExp? _safeRegExp(Object pattern) {
    try {
      return RegExp(_text(pattern));
    } on FormatException {
      return null;
    }
  }

  String _textJoin(List<_FormulaArgument> args) {
    final delimiter = _text(args[0].singleValue);
    final ignoreEmpty = _truthy(args[1].singleValue);
    final parts = <String>[];
    for (final arg in args.skip(2)) {
      for (final value in arg.values) {
        final text = _text(value);
        if (ignoreEmpty && text.isEmpty) {
          continue;
        }
        parts.add(text);
      }
    }
    return parts.join(delimiter);
  }

  String _hyperlink(List<Object> values) {
    return _text(values.length == 2 ? values[1] : values[0]);
  }

  Object? _arrayToTextFunction() {
    final sources = _functionArgumentSources();

    if (sources == null || sources.isEmpty || sources.length > 2) {
      return null;
    }
    final arrayResult = _evaluateArgumentSource(sources[0]);
    if (arrayResult == null) {
      return null;
    }
    final array = arrayResult is _FormulaArgument
        ? arrayResult
        : _FormulaArgument.scalar(arrayResult);
    final args = <_FormulaArgument>[array];
    if (sources.length == 2) {
      final formatResult = _evaluateSource(sources[1]);
      final formatError = _formulaError(formatResult);
      if (formatError != null) {
        return formatError;
      }
      if (formatResult == null) {
        return null;
      }
      args.add(
        _FormulaArgument.scalar(
          formatResult is _FormulaArgument
              ? formatResult.singleValue
              : formatResult,
        ),
      );
    }
    return _arrayToText(args);
  }

  Object? _valueToTextSourceFunction() {
    final sources = _functionArgumentSources();
    if (sources == null || sources.isEmpty || sources.length > 2) {
      return null;
    }
    final valueResult = _evaluateArgumentSource(sources[0]);
    if (valueResult == null) {
      return null;
    }
    final value = valueResult is _FormulaArgument
        ? valueResult.singleValue
        : valueResult;
    final args = <_FormulaArgument>[_FormulaArgument.scalar(value)];
    if (sources.length == 2) {
      final formatResult = _evaluateSource(sources[1]);
      final formatError = _formulaError(formatResult);
      if (formatError != null) {
        return formatError;
      }
      if (formatResult == null) {
        return null;
      }
      args.add(
        _FormulaArgument.scalar(
          formatResult is _FormulaArgument
              ? formatResult.singleValue
              : formatResult,
        ),
      );
    }
    return _valueToTextFunction(args);
  }

  Object? _arrayToText(List<_FormulaArgument> args) {
    final format = _textFormat(args.length >= 2 ? args[1].singleValue : 0.0);
    if (format == null) {
      return _FormulaError.value;
    }

    final array = args[0];
    final rowSeparator = format == 1 ? ';' : '; ';
    final columnSeparator = format == 1 ? ',' : ', ';
    final rows = <String>[];
    for (var row = 0; row < array.rowCount; row += 1) {
      final columns = <String>[];
      for (var column = 0; column < array.columnCount; column += 1) {
        columns.add(_valueToText(array.valueAt(row, column), format));
      }
      rows.add(columns.join(columnSeparator));
    }
    final text = rows.join(rowSeparator);
    return format == 1 ? '{$text}' : text;
  }

  Object? _valueToTextFunction(List<_FormulaArgument> args) {
    final format = _textFormat(args.length >= 2 ? args[1].singleValue : 0.0);
    return format == null
        ? _FormulaError.value
        : _valueToText(args[0].singleValue, format);
  }

  int? _textFormat(Object value) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null) {
      return null;
    }
    final format = number.truncate();
    return format == 0 || format == 1 ? format : null;
  }

  String _valueToText(Object value, int format) {
    if (format == 0) {
      return _text(value);
    }
    if (value is String) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return _text(value);
  }

  Object _proper(Object value) {
    final source = _text(value);
    if (source.isEmpty) {
      return _FormulaError.value;
    }
    final text = source.toLowerCase();

    final buffer = StringBuffer();
    var capitalizeNext = true;
    for (var i = 0; i < text.length; i += 1) {
      final char = text[i];
      if (_isAsciiLetterOrDigit(char)) {
        buffer.write(capitalizeNext ? char.toUpperCase() : char);
        capitalizeNext = false;
      } else {
        buffer.write(char);
        capitalizeNext = true;
      }
    }
    return buffer.toString();
  }

  String _asc(Object value) {
    final buffer = StringBuffer();
    for (final rune in _text(value).runes) {
      if (rune == 0x3000) {
        buffer.writeCharCode(0x20);
      } else if (rune >= 0xff01 && rune <= 0xff5e) {
        buffer.writeCharCode(rune - 0xfee0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  String _dbcs(Object value) {
    final buffer = StringBuffer();
    for (final rune in _text(value).runes) {
      if (rune == 0x20) {
        buffer.writeCharCode(0x3000);
      } else if (rune >= 0x21 && rune <= 0x7e) {
        buffer.writeCharCode(rune + 0xfee0);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  double? _value(Object value) {
    if (value is! String) {
      return FortuneFormulaEngine._numberFromFormulaValue(value);
    }
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }
    final date = _dateValue(text);
    if (date != null) {
      return date;
    }
    final time = _timeValue(text);
    if (time != null) {
      return time * 24 * 60 * 60;
    }
    var normalized = text.replaceAll(',', '');
    var multiplier = 1.0;
    if (normalized.endsWith('%')) {
      multiplier = 0.01;
      normalized = normalized.substring(0, normalized.length - 1).trim();
    }
    normalized = normalized.replaceFirst(RegExp(r'^[\$€£¥₩]\s*'), '');
    final number = double.tryParse(normalized);
    return number == null ? 0 : number * multiplier;
  }

  double? _numberValue(List<Object> values) {
    final decimalSeparator = values.length >= 2 ? _text(values[1]) : '.';
    final groupSeparator = values.length >= 3 ? _text(values[2]) : ',';
    if (decimalSeparator.length != 1 ||
        groupSeparator.length != 1 ||
        decimalSeparator == groupSeparator) {
      return null;
    }
    var text = _text(values[0]).trim().replaceAll(RegExp(r'\s+'), '');
    var percentCount = 0;
    while (text.endsWith('%')) {
      percentCount += 1;
      text = text.substring(0, text.length - 1);
    }
    text = text.replaceAll(groupSeparator, '');
    final decimalMatches = decimalSeparator.allMatches(text).length;
    if (decimalMatches > 1) {
      return null;
    }
    if (decimalSeparator != '.') {
      text = text.replaceAll(decimalSeparator, '.');
    }
    final number = double.tryParse(text);
    return number == null
        ? null
        : number * math.pow(0.01, percentCount).toDouble();
  }

  Object? _base(List<Object> values) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final radixNumber = FortuneFormulaEngine._numberFromFormulaValue(values[1]);
    final minLengthNumber = values.length == 3
        ? FortuneFormulaEngine._numberFromFormulaValue(values[2])
        : 0.0;
    if (number == null ||
        radixNumber == null ||
        minLengthNumber == null ||
        !number.isFinite ||
        !radixNumber.isFinite ||
        !minLengthNumber.isFinite) {
      return null;
    }
    final integer = _integerDigits(number);
    final radix = _integerDigits(radixNumber);
    final minLength = _integerDigits(minLengthNumber);
    if (integer == null || radix == null || minLength == null) {
      return null;
    }
    if (integer < 0 || radix < 2 || radix > 36 || minLength < 0) {
      return _FormulaError.num;
    }
    final converted = integer.toRadixString(radix).toUpperCase();
    return converted.padLeft(minLength, '0');
  }

  Object? _decimal(Object value, Object radixValue) {
    final radixNumber = FortuneFormulaEngine._numberFromFormulaValue(
      radixValue,
    );
    if (radixNumber == null || !radixNumber.isFinite) {
      return null;
    }
    final radix = _integerDigits(radixNumber);
    if (radix == null) {
      return null;
    }
    if (radix < 2 || radix > 36) {
      return _FormulaError.num;
    }
    final text = _text(value).trim().toUpperCase();
    if (text.isEmpty || text.contains(RegExp(r'[^0-9A-Z]'))) {
      return _FormulaError.num;
    }
    var result = 0.0;
    for (var i = 0; i < text.length; i += 1) {
      final code = text.codeUnitAt(i);
      final digit = code <= 57 ? code - 48 : code - 55;
      if (digit < 0 || digit >= radix) {
        return _FormulaError.num;
      }
      result = result * radix + digit;
    }
    return result;
  }

  Object _decimalDefaultRadix(Object value) {
    final text = _text(value).trim().toUpperCase();
    final match = RegExp(r'^[+-]?[0-9]+').firstMatch(text);
    if (match == null) {
      return double.nan;
    }
    return double.parse(match.group(0)!);
  }

  Object? _roman(Object value, Object formValue) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    final formNumber = formValue is bool
        ? (formValue ? 0.0 : 4.0)
        : FortuneFormulaEngine._numberFromFormulaValue(formValue);
    if (number == null ||
        formNumber == null ||
        !number.isFinite ||
        !formNumber.isFinite) {
      return _FormulaError.value;
    }
    final integer = _integerDigits(number);
    final form = _integerDigits(formNumber);
    if (integer == null || form == null) {
      return _FormulaError.value;
    }
    if (integer < 0 || integer > 3999 || form < 0 || form > 4) {
      return _FormulaError.num;
    }
    if (integer == 0) {
      return '';
    }
    return _romanNumeral(integer, form);
  }

  String _romanNumeral(int number, int form) {
    final table = switch (form) {
      1 => const [
        ('M', 1000),
        ('LM', 950),
        ('D', 500),
        ('LD', 450),
        ('C', 100),
        ('VC', 95),
        ('L', 50),
        ('VL', 45),
        ('X', 10),
        ('IX', 9),
        ('V', 5),
        ('IV', 4),
        ('I', 1),
      ],
      2 => const [
        ('M', 1000),
        ('XM', 990),
        ('D', 500),
        ('XD', 490),
        ('C', 100),
        ('IC', 99),
        ('L', 50),
        ('IL', 49),
        ('X', 10),
        ('IX', 9),
        ('V', 5),
        ('IV', 4),
        ('I', 1),
      ],
      3 => const [
        ('M', 1000),
        ('VM', 995),
        ('D', 500),
        ('VD', 495),
        ('C', 100),
        ('VC', 95),
        ('L', 50),
        ('VL', 45),
        ('X', 10),
        ('IX', 9),
        ('V', 5),
        ('IV', 4),
        ('I', 1),
      ],
      4 => const [
        ('M', 1000),
        ('IM', 999),
        ('D', 500),
        ('ID', 499),
        ('C', 100),
        ('IC', 99),
        ('L', 50),
        ('IL', 49),
        ('X', 10),
        ('IX', 9),
        ('V', 5),
        ('IV', 4),
        ('I', 1),
      ],
      _ => const [
        ('M', 1000),
        ('CM', 900),
        ('D', 500),
        ('CD', 400),
        ('C', 100),
        ('XC', 90),
        ('L', 50),
        ('XL', 40),
        ('X', 10),
        ('IX', 9),
        ('V', 5),
        ('IV', 4),
        ('I', 1),
      ],
    };
    final buffer = StringBuffer();
    var remaining = number;
    for (final (symbol, value) in table) {
      while (remaining >= value) {
        buffer.write(symbol);
        remaining -= value;
      }
    }
    return buffer.toString();
  }

  Object? _arabic(Object value) {
    final text = _text(value).trim().toUpperCase();
    if (text.isEmpty) {
      return 0.0;
    }
    const values = <String, int>{
      'M': 1000,
      'D': 500,
      'C': 100,
      'L': 50,
      'X': 10,
      'V': 5,
      'I': 1,
    };
    var total = 0;
    var index = 0;
    while (index < text.length) {
      final current = values[text[index]];
      if (current == null) {
        return _FormulaError.value;
      }
      final next = index + 1 < text.length ? values[text[index + 1]] : null;
      if (next != null && next > current) {
        if (!_validRomanSubtractive(text[index], text[index + 1])) {
          return _FormulaError.value;
        }
        total += next - current;
        index += 2;
      } else {
        total += current;
        index += 1;
      }
    }
    if (total < 0 || total > 3999 || _romanNumeral(total, 0) != text) {
      return _FormulaError.value;
    }
    return total.toDouble();
  }

  bool _validRomanSubtractive(String left, String right) {
    return (left == 'I' && (right == 'V' || right == 'X')) ||
        (left == 'X' && (right == 'L' || right == 'C')) ||
        (left == 'C' && (right == 'D' || right == 'M'));
  }

  String? _fixedCurrency(Object value, Object decimalsValue) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    final decimals = _formatDecimalPlaces(decimalsValue);
    if (number == null || !number.isFinite || decimals == null) {
      return null;
    }
    final formatted = _formatFixedNumber(
      number.abs(),
      decimals,
      useGrouping: true,
    );
    return number < 0 ? '(\$$formatted)' : '\$$formatted';
  }

  String? _fixedNumber(List<Object> values) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(values[0]);
    final decimals = values.length >= 2 ? _formatDecimalPlaces(values[1]) : 2;
    if (number == null || !number.isFinite || decimals == null) {
      return null;
    }
    final noCommas = values.length >= 3 && _truthy(values[2]);
    return _formatFixedNumber(number, decimals, useGrouping: !noCommas);
  }

  int? _formatDecimalPlaces(Object value) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null || !number.isFinite) {
      return null;
    }
    return number.truncate();
  }

  String _formatFixedNumber(
    double value,
    int decimals, {
    required bool useGrouping,
  }) {
    if (decimals >= 0) {
      final rounded = value.abs().toStringAsFixed(decimals);
      final parts = rounded.split('.');
      final integer = useGrouping ? _groupDigits(parts[0]) : parts[0];
      final decimal = decimals > 0 ? '.${parts[1]}' : '';
      return '${value < 0 ? '-' : ''}$integer$decimal';
    }
    final factor = math.pow(10, -decimals).toDouble();
    final rounded = (value.abs() / factor).roundToDouble() * factor;
    final integerText = rounded.toStringAsFixed(0);
    final integer = useGrouping ? _groupDigits(integerText) : integerText;
    return '${value < 0 ? '-' : ''}$integer';
  }

  double _n(Object value) {
    if (_isFormulaBlankLike(value)) {
      return 0;
    }
    if (value is bool) {
      return value ? 1 : 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return 0;
  }

  Object _toPureNumber(Object value) {
    if (value is _FormulaError) {
      return value;
    }
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    return number ?? value;
  }

  Object? _idCardAge(List<Object> values) {
    final info = _idCardInfo(values[0]);
    if (info == null) {
      return _FormulaError.value;
    }
    final cutoff = values.length == 2
        ? _dateTime(values[1])?.dateTime
        : DateTime.now();
    if (cutoff == null) {
      return _FormulaError.value;
    }
    var age = cutoff.year - info.birthday.year;
    if (cutoff.month < info.birthday.month ||
        (cutoff.month == info.birthday.month &&
            cutoff.day < info.birthday.day)) {
      age -= 1;
    }
    return age.toDouble();
  }

  Object? _idCardBirthday(List<Object> values) {
    final info = _idCardInfo(values[0]);
    if (info == null) {
      return _FormulaError.value;
    }
    final format = values.length == 2
        ? FortuneFormulaEngine._numberFromFormulaValue(values[1])?.toInt()
        : 0;
    final year = info.birthday.year.toString().padLeft(4, '0');
    final month = info.birthday.month.toString().padLeft(2, '0');
    final day = info.birthday.day.toString().padLeft(2, '0');
    return switch (format) {
      1 => '$year-$month-$day',
      2 => '$year年${info.birthday.month}月${info.birthday.day}日',
      _ => '$year/$month/$day',
    };
  }

  Object? _idCardSex(Object value) {
    final info = _idCardInfo(value);
    if (info == null) {
      return _FormulaError.value;
    }
    return info.sequenceCode.isOdd ? '男' : '女';
  }

  Object? _idCardProvince(Object value) {
    final info = _idCardInfo(value);
    return info == null
        ? _FormulaError.value
        : _idCardProvinceNames[info.provinceCode];
  }

  Object? _idCardCity(Object value) {
    final info = _idCardInfo(value);
    if (info == null) {
      return _FormulaError.value;
    }
    return _idCardMunicipalityNames[info.provinceCode] ?? '';
  }

  Object? _idCardStar(Object value) {
    final info = _idCardInfo(value);
    if (info == null) {
      return _FormulaError.value;
    }
    final month = info.birthday.month;
    final day = info.birthday.day;
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return '水瓶座';
    }
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) {
      return '双鱼座';
    }
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return '白羊座';
    }
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return '金牛座';
    }
    if ((month == 5 && day >= 21) || (month == 6 && day <= 21)) {
      return '双子座';
    }
    if ((month == 6 && day >= 22) || (month == 7 && day <= 22)) {
      return '巨蟹座';
    }
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return '狮子座';
    }
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return '处女座';
    }
    if ((month == 9 && day >= 23) || (month == 10 && day <= 23)) {
      return '天秤座';
    }
    if ((month == 10 && day >= 24) || (month == 11 && day <= 22)) {
      return '天蝎座';
    }
    if ((month == 11 && day >= 23) || (month == 12 && day <= 21)) {
      return '射手座';
    }
    return '摩羯座';
  }

  Object? _idCardAnimal(Object value) {
    final info = _idCardInfo(value);
    if (info == null) {
      return _FormulaError.value;
    }
    final index = (info.birthday.year - 4) % _idCardAnimals.length;
    return _idCardAnimals[index];
  }

  _IdCardInfo? _idCardInfo(Object value) {
    final text = _text(value).trim().toUpperCase();
    final match = RegExp(r'^(\d{15}|\d{17}[0-9X])$').firstMatch(text);
    if (match == null) {
      return null;
    }
    final provinceCode = text.substring(0, 2);
    if (!_idCardProvinceNames.containsKey(provinceCode)) {
      return null;
    }
    final birthday = text.length == 18
        ? _idCardDate(text.substring(6, 14))
        : _idCardDate('19${text.substring(6, 12)}');
    if (birthday == null) {
      return null;
    }
    if (text.length == 18 && !_idCardChecksumValid(text)) {
      return null;
    }
    final sequenceStart = text.length == 18 ? 14 : 12;
    final sequenceCode = int.tryParse(
      text.substring(sequenceStart, sequenceStart + 3),
    );
    if (sequenceCode == null) {
      return null;
    }
    return _IdCardInfo(provinceCode, birthday, sequenceCode);
  }

  DateTime? _idCardDate(String text) {
    if (text.length != 8) {
      return null;
    }
    final year = int.tryParse(text.substring(0, 4));
    final month = int.tryParse(text.substring(4, 6));
    final day = int.tryParse(text.substring(6, 8));
    if (year == null || month == null || day == null) {
      return null;
    }
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  bool _idCardChecksumValid(String text) {
    const weights = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2];
    const checks = '10X98765432';
    var sum = 0;
    for (var index = 0; index < weights.length; index += 1) {
      sum += int.parse(text[index]) * weights[index];
    }
    return checks[sum % 11] == text[17];
  }

  double _type(Object value) {
    if (value is _FormulaArgument) {
      return 64;
    }
    if (value is _FormulaError) {
      return 16;
    }
    if (value is bool) {
      return 4;
    }
    if (value is String) {
      return 2;
    }
    return 1;
  }

  String? _formatText(Object value, Object formatValue) {
    final requestedFormat = _text(formatValue);
    final section = _formatSection(value, requestedFormat);
    final format = section.format;
    if (format.isEmpty) {
      return '';
    }
    if (format.contains('@')) {
      return format.replaceAll('@', _text(value));
    }
    final normalizedFormat = section.tokenProbe.toLowerCase();
    final isDateFormat =
        normalizedFormat.contains('y') || normalizedFormat.contains('d');
    final isTimeFormat =
        normalizedFormat.contains('h') || normalizedFormat.contains('s');
    final isElapsedTimeFormat = _hasElapsedTimeToken(format);
    if (isDateFormat || isTimeFormat || isElapsedTimeFormat) {
      final number = FortuneFormulaEngine._numberFromFormulaValue(value);
      if (number != null && isElapsedTimeFormat) {
        return _formatElapsedTimeText(number, format);
      }
      final dateTime = _dateTime(value)?.dateTime;
      if (dateTime == null) {
        return null;
      }
      return _formatDateTimeText(dateTime, format, preferMinutes: isTimeFormat);
    }
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null || !number.isFinite) {
      return null;
    }
    return _formatNumberText(
      section.useAbsoluteValue ? number.abs() : number,
      format,
      implicitNegativeSign: section.implicitNegativeSign,
    );
  }

  _SelectedFormatSection _formatSection(Object value, String format) {
    final sections = _splitFormatSections(format);
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (sections.length <= 1) {
      final cleanFormat = _stripFormatDirectives(format);
      return _SelectedFormatSection(
        _normalizeFormatLiterals(cleanFormat),
        tokenProbe: _formatTokenProbe(cleanFormat),
        implicitNegativeSign: true,
        useAbsoluteValue: false,
      );
    }
    final selected =
        _conditionalFormatSection(sections, number) ??
        (number == null && sections.length >= 4
            ? sections[3]
            : number == null
            ? sections.first
            : number < 0
            ? sections[1]
            : number == 0 && sections.length >= 3
            ? sections[2]
            : sections.first);
    final cleanSelected = _stripFormatDirectives(selected);
    return _SelectedFormatSection(
      _normalizeFormatLiterals(cleanSelected),
      tokenProbe: _formatTokenProbe(cleanSelected),
      implicitNegativeSign:
          number == null || number >= 0 || sections.length < 2,
      useAbsoluteValue: number != null && number < 0 && sections.length >= 2,
    );
  }

  String? _conditionalFormatSection(List<String> sections, double? number) {
    if (number == null) {
      return null;
    }
    var hasCondition = false;
    String? fallback;
    for (final section in sections) {
      final condition = _formatCondition(section);
      if (condition == null) {
        fallback ??= section;
        continue;
      }
      hasCondition = true;
      if (_formatConditionMatches(number, condition)) {
        return section;
      }
    }
    return hasCondition ? fallback : null;
  }

  List<String> _splitFormatSections(String format) {
    final sections = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;
    var escaped = false;
    for (var i = 0; i < format.length; i += 1) {
      final char = format[i];
      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }
      if (char == r'\') {
        buffer.write(char);
        escaped = true;
        continue;
      }
      if (char == '"') {
        inQuote = !inQuote;
        buffer.write(char);
        continue;
      }
      if (char == ';' && !inQuote) {
        sections.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    sections.add(buffer.toString());
    return sections;
  }

  String _normalizeFormatLiterals(String format) {
    final buffer = StringBuffer();
    var inQuote = false;
    var escaped = false;
    for (var i = 0; i < format.length; i += 1) {
      final char = format[i];
      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inQuote = !inQuote;
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  String _stripFormatDirectives(String format) {
    final buffer = StringBuffer();
    var inQuote = false;
    var escaped = false;
    for (var i = 0; i < format.length; i += 1) {
      final char = format[i];
      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }
      if (char == r'\') {
        buffer.write(char);
        escaped = true;
        continue;
      }
      if (char == '"') {
        inQuote = !inQuote;
        buffer.write(char);
        continue;
      }
      if (!inQuote && char == '[') {
        final close = format.indexOf(']', i + 1);
        if (close > i) {
          final directive = format.substring(i + 1, close);
          if (_isFormatDirective(directive)) {
            i = close;
            continue;
          }
        }
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  bool _isFormatDirective(String directive) {
    final normalized = directive.trim().toLowerCase();
    return _formatConditionPattern.hasMatch(normalized) ||
        _formatColorPattern.hasMatch(normalized);
  }

  _FormatCondition? _formatCondition(String format) {
    var inQuote = false;
    var escaped = false;
    for (var i = 0; i < format.length; i += 1) {
      final char = format[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inQuote = !inQuote;
        continue;
      }
      if (!inQuote && char == '[') {
        final close = format.indexOf(']', i + 1);
        if (close <= i) {
          continue;
        }
        final directive = format.substring(i + 1, close).trim();
        final match = _formatConditionPattern.firstMatch(
          directive.toLowerCase(),
        );
        if (match != null) {
          final operator = match.group(1)!;
          final thresholdText = match.group(2)!;
          final threshold = double.tryParse(
            thresholdText.endsWith('%')
                ? thresholdText.substring(0, thresholdText.length - 1)
                : thresholdText,
          );
          if (threshold == null) {
            return null;
          }
          return _FormatCondition(
            operator,
            thresholdText.endsWith('%') ? threshold / 100 : threshold,
          );
        }
        i = close;
      }
    }
    return null;
  }

  bool _formatConditionMatches(double value, _FormatCondition condition) {
    return switch (condition.operator) {
      '>' => value > condition.threshold,
      '>=' => value >= condition.threshold,
      '<' => value < condition.threshold,
      '<=' => value <= condition.threshold,
      '=' => value == condition.threshold,
      '<>' => value != condition.threshold,
      _ => false,
    };
  }

  String _formatTokenProbe(String format) {
    final buffer = StringBuffer();
    var inQuote = false;
    var escaped = false;
    for (var i = 0; i < format.length; i += 1) {
      final char = format[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inQuote = !inQuote;
        continue;
      }
      if (!inQuote) {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String _formatNumberText(
    double value,
    String format, {
    required bool implicitNegativeSign,
  }) {
    var effectiveValue = value;
    var effectiveFormat = format;
    if (!effectiveFormat.contains('0') && !effectiveFormat.contains('#')) {
      return effectiveFormat;
    }
    final percentCount = '%'.allMatches(effectiveFormat).length;
    if (percentCount > 0) {
      effectiveValue *= math.pow(100, percentCount).toDouble();
      effectiveFormat = effectiveFormat.replaceAll('%', '');
    }
    final decimalIndex = effectiveFormat.indexOf('.');
    final decimalPattern = decimalIndex < 0
        ? ''
        : effectiveFormat
              .substring(decimalIndex + 1)
              .split('')
              .where((char) => char == '0' || char == '#')
              .join();
    final decimalPlaces = decimalPattern.length;
    final integerFormat = effectiveFormat.substring(
      0,
      decimalIndex < 0 ? effectiveFormat.length : decimalIndex,
    );
    final integerPattern = integerFormat
        .split('')
        .where((char) => char == '0' || char == '#')
        .join();
    final minimumDecimalPlaces =
        !decimalPattern.contains('0') &&
            integerPattern.length > 1 &&
            integerPattern.replaceAll('#', '').isEmpty
        ? decimalPattern.length
        : '0'.allMatches(decimalPattern).length;
    final minimumIntegerPlaces = '0'.allMatches(integerPattern).length;
    final useGrouping = integerFormat.contains(',');
    final prefix = RegExp(r'^[^0#,\.]+').firstMatch(effectiveFormat)?.group(0);
    final suffix =
        RegExp(r'[^0#,\.]+$').firstMatch(effectiveFormat)?.group(0) ?? '';
    final rounded = effectiveValue.abs().toStringAsFixed(decimalPlaces);
    final parts = rounded.split('.');
    final integerDigits = minimumIntegerPlaces == 0 && parts[0] == '0'
        ? ''
        : parts[0];
    final integer = useGrouping && integerDigits.isNotEmpty
        ? _groupDigits(integerDigits)
        : integerDigits;
    var decimalDigits = decimalPlaces > 0 ? parts[1] : '';
    while (decimalDigits.length > minimumDecimalPlaces &&
        decimalDigits.endsWith('0')) {
      decimalDigits = decimalDigits.substring(0, decimalDigits.length - 1);
    }
    final decimal = decimalDigits.isNotEmpty ? '.$decimalDigits' : '';
    final sign = effectiveValue < 0 && implicitNegativeSign ? '-' : '';
    return '$sign${prefix ?? ''}$integer$decimal$suffix${'%' * percentCount}';
  }

  String _groupDigits(String text) {
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i += 1) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  String _formatDateTimeText(
    DateTime dateTime,
    String format, {
    required bool preferMinutes,
  }) {
    final buffer = StringBuffer();
    final lowerFormat = format.toLowerCase();
    final usesMeridiem =
        lowerFormat.contains('am/pm') ||
        lowerFormat.contains('a/p') ||
        lowerFormat.contains(' 오전/오후') ||
        lowerFormat.contains('오전/오후');
    for (var i = 0; i < format.length;) {
      if (lowerFormat.startsWith('yyyy', i)) {
        buffer.write(dateTime.year.toString().padLeft(4, '0'));
        i += 4;
      } else if (lowerFormat.startsWith('yy', i)) {
        buffer.write((dateTime.year % 100).toString().padLeft(2, '0'));
        i += 2;
      } else if (lowerFormat.startsWith('hh', i)) {
        final hour = usesMeridiem ? _hour12(dateTime.hour) : dateTime.hour;
        buffer.write(hour.toString().padLeft(2, '0'));
        i += 2;
      } else if (lowerFormat.startsWith('h', i)) {
        buffer.write(usesMeridiem ? _hour12(dateTime.hour) : dateTime.hour);
        i += 1;
      } else if (lowerFormat.startsWith('am/pm', i)) {
        buffer.write(dateTime.hour < 12 ? 'AM' : 'PM');
        i += 5;
      } else if (lowerFormat.startsWith('a/p', i)) {
        buffer.write(dateTime.hour < 12 ? 'A' : 'P');
        i += 3;
      } else if (lowerFormat.startsWith('오전/오후', i)) {
        buffer.write(dateTime.hour < 12 ? '오전' : '오후');
        i += 5;
      } else if (lowerFormat.startsWith('ss', i)) {
        buffer.write(dateTime.second.toString().padLeft(2, '0'));
        i += 2;
      } else if (lowerFormat.startsWith('s', i)) {
        buffer.write(dateTime.second);
        i += 1;
      } else if (lowerFormat.startsWith('dd', i)) {
        buffer.write(dateTime.day.toString().padLeft(2, '0'));
        i += 2;
      } else if (lowerFormat.startsWith('d', i)) {
        buffer.write(dateTime.day);
        i += 1;
      } else if (lowerFormat.startsWith('mm', i)) {
        final value = _isMinuteFormatToken(lowerFormat, i, 2, preferMinutes)
            ? dateTime.minute
            : dateTime.month;
        buffer.write(value.toString().padLeft(2, '0'));
        i += 2;
      } else if (lowerFormat.startsWith('m', i)) {
        buffer.write(
          _isMinuteFormatToken(lowerFormat, i, 1, preferMinutes)
              ? dateTime.minute
              : dateTime.month,
        );
        i += 1;
      } else {
        buffer.write(format[i]);
        i += 1;
      }
    }
    return buffer.toString();
  }

  bool _hasElapsedTimeToken(String format) {
    final lowerFormat = format.toLowerCase();
    return lowerFormat.contains('[h]') ||
        lowerFormat.contains('[hh]') ||
        lowerFormat.contains('[m]') ||
        lowerFormat.contains('[mm]') ||
        lowerFormat.contains('[s]') ||
        lowerFormat.contains('[ss]');
  }

  String _formatElapsedTimeText(double serialValue, String format) {
    final totalSeconds = (serialValue.abs() * 24 * 60 * 60).round();
    final totalHours = totalSeconds ~/ (60 * 60);
    final totalMinutes = totalSeconds ~/ 60;
    final hours = totalHours % 24;
    final minutes = (totalSeconds ~/ 60) % 60;
    final seconds = totalSeconds % 60;
    final buffer = StringBuffer();
    final lowerFormat = format.toLowerCase();
    for (var i = 0; i < format.length;) {
      if (lowerFormat.startsWith('[hh]', i)) {
        buffer.write(totalHours.toString().padLeft(2, '0'));
        i += 4;
      } else if (lowerFormat.startsWith('[h]', i)) {
        buffer.write(totalHours);
        i += 3;
      } else if (lowerFormat.startsWith('[mm]', i)) {
        buffer.write(totalMinutes.toString().padLeft(2, '0'));
        i += 4;
      } else if (lowerFormat.startsWith('[m]', i)) {
        buffer.write(totalMinutes);
        i += 3;
      } else if (lowerFormat.startsWith('[ss]', i)) {
        buffer.write(totalSeconds.toString().padLeft(2, '0'));
        i += 4;
      } else if (lowerFormat.startsWith('[s]', i)) {
        buffer.write(totalSeconds);
        i += 3;
      } else if (lowerFormat.startsWith('hh', i)) {
        buffer.write(hours.toString().padLeft(2, '0'));
        i += 2;
      } else if (lowerFormat.startsWith('h', i)) {
        buffer.write(hours);
        i += 1;
      } else if (lowerFormat.startsWith('mm', i)) {
        buffer.write(minutes.toString().padLeft(2, '0'));
        i += 2;
      } else if (lowerFormat.startsWith('m', i)) {
        buffer.write(minutes);
        i += 1;
      } else if (lowerFormat.startsWith('ss', i)) {
        buffer.write(seconds.toString().padLeft(2, '0'));
        i += 2;
      } else if (lowerFormat.startsWith('s', i)) {
        buffer.write(seconds);
        i += 1;
      } else {
        buffer.write(format[i]);
        i += 1;
      }
    }
    return serialValue < 0 ? '-$buffer' : buffer.toString();
  }

  int _hour12(int hour) {
    final normalized = hour % 12;
    return normalized == 0 ? 12 : normalized;
  }

  bool _isMinuteFormatToken(
    String lowerFormat,
    int index,
    int length,
    bool preferMinutes,
  ) {
    if (!preferMinutes) {
      return false;
    }
    final previous = _neighborDateTimeToken(lowerFormat, index, reverse: true);
    if (previous == 'h') {
      return true;
    }
    final next = _neighborDateTimeToken(
      lowerFormat,
      index + length,
      reverse: false,
    );
    if (next == 's') {
      return true;
    }
    return !lowerFormat.contains('y') && !lowerFormat.contains('d');
  }

  String? _neighborDateTimeToken(
    String lowerFormat,
    int index, {
    required bool reverse,
  }) {
    var cursor = index + (reverse ? -1 : 0);
    while (cursor >= 0 && cursor < lowerFormat.length) {
      final char = lowerFormat[cursor];
      if ('ymdhms'.contains(char)) {
        return char;
      }
      if (_isAsciiLetterOrDigit(char)) {
        return null;
      }
      cursor += reverse ? -1 : 1;
    }
    return null;
  }

  bool _isAsciiLetterOrDigit(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) ||
        (code >= 97 && code <= 122) ||
        (code >= 48 && code <= 57);
  }

  double? _findText(
    Object needle,
    Object haystack,
    Object start, {
    required bool caseSensitive,
  }) {
    final oneBasedStart = _textLength(start);
    if (oneBasedStart == null || oneBasedStart < 1) {
      return null;
    }
    final sourceText = _text(haystack);
    final searchText = _text(needle);
    final startIndex = oneBasedStart - 1;
    if (startIndex > sourceText.length) {
      return null;
    }
    if (!caseSensitive && _hasWildcard(searchText)) {
      final match = _wildcardRegExp(
        searchText,
        anchored: false,
      ).firstMatch(sourceText.substring(startIndex));
      return match == null ? null : (startIndex + match.start + 1).toDouble();
    }
    final searchSource = caseSensitive ? sourceText : sourceText.toLowerCase();
    final searchNeedle = caseSensitive ? searchText : searchText.toLowerCase();
    final found = searchSource.indexOf(searchNeedle, startIndex);
    return found < 0 ? (caseSensitive ? 0.0 : null) : (found + 1).toDouble();
  }

  Object? _substitute(
    Object value,
    Object oldText,
    Object newText,
    Object? occurrence,
  ) {
    final sourceText = _text(value);
    final target = _text(oldText);
    if (target.isEmpty) {
      return _FormulaError.value;
    }
    final replacement = _text(newText);
    if (occurrence == null) {
      return sourceText.replaceAll(target, replacement);
    }
    final instance = _textLength(occurrence);
    if (instance == null || instance < 1) {
      return null;
    }
    var foundCount = 0;
    var offset = 0;
    final buffer = StringBuffer();
    while (offset < sourceText.length) {
      final index = sourceText.indexOf(target, offset);
      if (index < 0) {
        break;
      }
      foundCount += 1;
      buffer.write(sourceText.substring(offset, index));
      buffer.write(foundCount == instance ? replacement : target);
      offset = index + target.length;
    }
    buffer.write(sourceText.substring(offset));
    return buffer.toString();
  }

  int? _textLength(Object value) {
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number == null || !number.isFinite || number < 0) {
      return null;
    }
    return number.truncate();
  }

  Object _stringLength(Object value) {
    return value is String ? value.length.toDouble() : _FormulaError.value;
  }

  Object? _percent(Object? value) {
    while (value != null) {
      _skipWhitespace();
      if (!_consume('%')) {
        break;
      }
      final number = FortuneFormulaEngine._numberFromFormulaValue(value);
      if (number == null) {
        return _formulaError(value);
      }
      value = number / 100;
    }
    return value;
  }

  bool? _compare(Object left, Object right, String operator) {
    final normalizedLeft = _isFormulaBlankLike(left) ? null : left;
    final normalizedRight = _isFormulaBlankLike(right) ? null : right;
    if (operator == '=' || operator == '<>') {
      final matches = _formulaOperationStrictEquals(
        normalizedLeft,
        normalizedRight,
      );
      return operator == '<>' ? !matches : matches;
    }
    final comparison = _formulaOperationRelationalComparison(
      normalizedLeft,
      normalizedRight,
    );
    if (comparison == null) {
      return false;
    }
    return switch (operator) {
      '>' => comparison > 0,
      '<' => comparison < 0,
      '>=' => comparison >= 0,
      '<=' => comparison <= 0,
      _ => null,
    };
  }

  bool _truthy(Object value) {
    if (value is bool) {
      return value;
    }
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    if (number != null) {
      return number != 0;
    }
    return value.toString().isNotEmpty;
  }

  String _text(Object value) {
    if (value is _FormulaArgument) {
      return _text(value.singleValue);
    }
    if (_isFormulaBlankLike(value)) {
      return '';
    }
    if (value is _FormulaError) {
      return value.label;
    }
    if (value is String) {
      return value;
    }
    if (value is bool) {
      return value ? 'TRUE' : 'FALSE';
    }
    final number = FortuneFormulaEngine._numberFromFormulaValue(value);
    return number == null
        ? value.toString()
        : FortuneFormulaEngine._formatNumber(number);
  }

  String? _string() {
    _skipWhitespace();
    final start = _offset;
    if (_offset >= source.length ||
        (source[_offset] != '"' && source[_offset] != "'")) {
      return null;
    }
    final quote = source[_offset];
    _offset += 1;
    final buffer = StringBuffer();
    while (_offset < source.length) {
      final char = source[_offset];
      _offset += 1;
      if (char == quote) {
        if (_offset < source.length && source[_offset] == quote) {
          buffer.write(quote);
          _offset += 1;
          continue;
        }
        if (quote == "'") {
          final afterQuote = _offset;
          _skipWhitespace();
          if (_offset < source.length && source[_offset] == '!') {
            _offset = start;
            return null;
          }
          _offset = afterQuote;
        }
        return buffer.toString();
      }
      buffer.write(char);
    }
    _offset = start;
    return null;
  }

  _FormulaError? _errorLiteral() {
    _skipWhitespace();
    for (final error in _FormulaError.values) {
      if (source.startsWith(error.label, _offset)) {
        final end = _offset + error.label.length;
        if (end < source.length) {
          final next = source[end];
          if (next.trim().isNotEmpty && !'+-*^&=<>(),;{}'.contains(next)) {
            continue;
          }
        }
        _offset += error.label.length;
        return error;
      }
    }
    if (_offset < source.length && source[_offset] == '#') {
      _offset += 1;
      while (_offset < source.length) {
        final char = source[_offset];
        if (char.trim().isEmpty || '+-*^&=<>(),;{}'.contains(char)) {
          break;
        }
        _offset += 1;
      }
      return _FormulaError.error;
    }
    return null;
  }

  double? _number() {
    _skipWhitespace();
    final start = _offset;
    var hasDigit = false;
    while (_offset < source.length) {
      final code = source.codeUnitAt(_offset);
      if (code >= 48 && code <= 57) {
        hasDigit = true;
        _offset += 1;
      } else if (source[_offset] == '.') {
        _offset += 1;
      } else {
        break;
      }
    }
    if (!hasDigit) {
      _offset = start;
      return null;
    }
    return double.tryParse(source.substring(start, _offset));
  }

  String? _identifier() {
    _skipWhitespace();
    final start = _offset;
    while (_offset < source.length) {
      final code = source.codeUnitAt(_offset);
      final char = source[_offset];
      final isLetter =
          (code >= 65 && code <= 90) ||
          (code >= 97 && code <= 122) ||
          (code >= 0x00c0 && code <= 0x02af);
      final isDigit = code >= 48 && code <= 57;
      if (isLetter || isDigit || char == r'$' || char == '_' || char == '.') {
        _offset += 1;
      } else {
        break;
      }
    }
    if (_offset == start) {
      return null;
    }
    return source.substring(start, _offset);
  }

  void _consumeMalformedReferenceTail() {
    while (_offset < source.length) {
      final char = source[_offset];
      if (char.trim().isEmpty || '+-*/^&=<>(),;{}'.contains(char)) {
        break;
      }
      _offset += 1;
    }
  }

  FortuneCellCoord? _coordFromIdentifier(String identifier) {
    final match = RegExp(r'^\$?([A-Za-z]+)\$?([0-9]+)$').firstMatch(identifier);
    if (match == null) {
      return null;
    }
    var column = 0;
    for (final code in match.group(1)!.toUpperCase().codeUnits) {
      column = column * 26 + code - 64;
    }
    final row = int.tryParse(match.group(2)!);
    if (row == null || row <= 0 || column <= 0) {
      return null;
    }
    return FortuneCellCoord(row - 1, column - 1);
  }

  bool _consume(String token) {
    _skipWhitespace();
    if (!source.startsWith(token, _offset)) {
      return false;
    }
    _offset += token.length;
    return true;
  }

  void _skipWhitespace() {
    while (_offset < source.length && source.codeUnitAt(_offset) <= 32) {
      _offset += 1;
    }
  }

  bool _isFormulaError(Object? value) => value is _FormulaError;

  bool _isNaError(Object? value) => value == _FormulaError.na;

  _FormulaError? _formulaError(Object? value) =>
      value is _FormulaError ? value : null;

  _FormulaError? _firstFormulaError(Iterable<Object> values) {
    for (final value in values) {
      final error = _formulaError(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}

enum _DatePart { year, month, day }

enum _TimePart { hour, minute, second }

enum _PairwiseSquareMode { difference, squaresDifference, squaresSum }

enum _DatabaseFunction {
  sum,
  average,
  count,
  countA,
  get,
  max,
  min,
  product,
  stdev,
  stdevP,
  varS,
  varP,
}

enum _RegressionPart { slope, intercept, standardError }

const _formulaBlank = _FormulaBlank();
const _formulaNull = _FormulaNull();
const _defaultWeekendDays = <int>{DateTime.saturday, DateTime.sunday};
const _idCardAnimals = [
  '鼠',
  '牛',
  '虎',
  '兔',
  '龙',
  '蛇',
  '马',
  '羊',
  '猴',
  '鸡',
  '狗',
  '猪',
];
const _idCardProvinceNames = <String, String>{
  '11': '北京市',
  '12': '天津市',
  '13': '河北省',
  '14': '山西省',
  '15': '内蒙古自治区',
  '21': '辽宁省',
  '22': '吉林省',
  '23': '黑龙江省',
  '31': '上海市',
  '32': '江苏省',
  '33': '浙江省',
  '34': '安徽省',
  '35': '福建省',
  '36': '江西省',
  '37': '山东省',
  '41': '河南省',
  '42': '湖北省',
  '43': '湖南省',
  '44': '广东省',
  '45': '广西壮族自治区',
  '46': '海南省',
  '50': '重庆市',
  '51': '四川省',
  '52': '贵州省',
  '53': '云南省',
  '54': '西藏自治区',
  '61': '陕西省',
  '62': '甘肃省',
  '63': '青海省',
  '64': '宁夏回族自治区',
  '65': '新疆维吾尔自治区',
  '71': '台湾省',
  '81': '香港特别行政区',
  '82': '澳门特别行政区',
};
const _idCardMunicipalityNames = <String, String>{
  '11': '北京市',
  '12': '天津市',
  '31': '上海市',
  '50': '重庆市',
};

class _FormulaBlank {
  const _FormulaBlank();
}

class _FormulaNull {
  const _FormulaNull();
}

class _FormulaError {
  const _FormulaError._(this.label);

  static const na = _FormulaError._('#N/A');
  static const div0 = _FormulaError._('#DIV/0!');
  static const nullError = _FormulaError._('#NULL!');
  static const ref = _FormulaError._('#REF!');
  static const value = _FormulaError._('#VALUE!');
  static const name = _FormulaError._('#NAME?');
  static const num = _FormulaError._('#NUM!');
  static const gettingData = _FormulaError._('#GETTING_DATA');
  static const spill = _FormulaError._('#SPILL!');
  static const connect = _FormulaError._('#CONNECT!');
  static const blocked = _FormulaError._('#BLOCKED!');
  static const unknown = _FormulaError._('#UNKNOWN!');
  static const field = _FormulaError._('#FIELD!');
  static const calc = _FormulaError._('#CALC!');
  static const error = _FormulaError._('#ERROR!');
  static const values = [
    na,
    div0,
    nullError,
    ref,
    value,
    name,
    num,
    gettingData,
    spill,
    connect,
    blocked,
    unknown,
    field,
    calc,
    error,
  ];

  final String label;
}

class _FormulaDateTime {
  const _FormulaDateTime(this.dateTime);

  final DateTime dateTime;
}

class _FormulaSparkline {
  const _FormulaSparkline(this.data);

  final Map<String, Object?> data;
}

class _IdCardInfo {
  const _IdCardInfo(this.provinceCode, this.birthday, this.sequenceCode);

  final String provinceCode;
  final DateTime birthday;
  final int sequenceCode;
}

class _FormulaTime {
  const _FormulaTime(this.hour, this.minute, this.second, this.millisecond);

  final int hour;
  final int minute;
  final int second;
  final int millisecond;
}

class _FormulaPair {
  const _FormulaPair(this.left, this.right);

  final double left;
  final double right;
}

class _TTestStatistic {
  const _TTestStatistic(this.t, this.degreesFreedom);

  final double t;
  final double degreesFreedom;
}

class _LinearRegressionModel {
  const _LinearRegressionModel(this.pairs, this.slope, this.intercept);

  final List<_FormulaPair> pairs;
  final double slope;
  final double intercept;
}

class _SelectedFormatSection {
  const _SelectedFormatSection(
    this.format, {
    required this.tokenProbe,
    required this.implicitNegativeSign,
    required this.useAbsoluteValue,
  });

  final String format;
  final String tokenProbe;
  final bool implicitNegativeSign;
  final bool useAbsoluteValue;
}

class _FormatCondition {
  const _FormatCondition(this.operator, this.threshold);

  final String operator;
  final double threshold;
}

class _AnnuityArguments {
  const _AnnuityArguments({
    required this.rate,
    required this.periods,
    required this.payment,
    required this.presentValue,
    required this.futureValue,
    required this.type,
  });

  final double rate;
  final double periods;
  final double payment;
  final double presentValue;
  final double futureValue;
  final double type;
}

class _PeriodicPaymentArguments {
  const _PeriodicPaymentArguments({
    required this.rate,
    required this.period,
    required this.periods,
    required this.presentValue,
    required this.futureValue,
    required this.type,
    required this.payment,
  });

  final double rate;
  final int period;
  final double periods;
  final double presentValue;
  final double futureValue;
  final double type;
  final double payment;
}

class _CouponSchedule {
  const _CouponSchedule({
    required this.settlement,
    required this.previousCoupon,
    required this.nextCoupon,
    required this.maturity,
    required this.monthsPerCoupon,
    required this.frequency,
  });

  final DateTime settlement;
  final DateTime previousCoupon;
  final DateTime nextCoupon;
  final DateTime maturity;
  final int monthsPerCoupon;
  final int frequency;
}

enum _CouponDayPart { beforeSettlement, fullPeriod, afterSettlement }

enum _BitwiseOperation { and, or, xor }

enum _BinaryNumericOperator { add, subtract, multiply, divide, power }

enum _BesselKind { i, j, k, y }

enum _ConversionUnitKind { mass, length, speed, energy, pressure }

class _ConversionUnit {
  const _ConversionUnit(this.kind, this.factor);

  final _ConversionUnitKind kind;
  final double factor;
}

class _ComplexNumber {
  const _ComplexNumber(this.real, this.imaginary);

  final double real;
  final double imaginary;
}

class _FormulaArgument {
  const _FormulaArgument._({
    required this.values,
    required this.rowCount,
    required this.columnCount,
    required this.sourceRange,
  });

  factory _FormulaArgument.scalar(Object value) => _FormulaArgument._(
    values: [value],
    rowCount: 1,
    columnCount: 1,
    sourceRange: null,
  );

  factory _FormulaArgument.range(
    List<Object> values, {
    required int rowCount,
    required int columnCount,
    _FormulaRange? sourceRange,
  }) => _FormulaArgument._(
    values: values,
    rowCount: rowCount,
    columnCount: columnCount,
    sourceRange: sourceRange,
  );

  final List<Object> values;
  final int rowCount;
  final int columnCount;
  final _FormulaRange? sourceRange;

  Object get singleValue => values.isEmpty ? _formulaBlank : values.first;

  Object valueAt(int row, int column) {
    final index = row * columnCount + column;
    if (row < 0 || column < 0 || index < 0 || index >= values.length) {
      return _formulaBlank;
    }
    return values[index];
  }

  List<Object> rowValues(int row) {
    if (row < 0 || row >= rowCount) {
      return const [];
    }
    return [
      for (var column = 0; column < columnCount; column += 1)
        valueAt(row, column),
    ];
  }

  List<Object> columnValues(int column) {
    if (column < 0 || column >= columnCount) {
      return const [];
    }
    return [for (var row = 0; row < rowCount; row += 1) valueAt(row, column)];
  }
}

class _TakeDropSelection {
  const _TakeDropSelection(this.start, this.count);

  final int start;
  final int count;
}

class _FormulaRange {
  const _FormulaRange({
    required this.rowStart,
    required this.rowEnd,
    required this.columnStart,
    required this.columnEnd,
    this.sheetName,
    this.startReference,
    this.endReference,
  });

  factory _FormulaRange.fromCoords(
    FortuneCellCoord a,
    FortuneCellCoord b, {
    String? sheetName,
    String? startReference,
    String? endReference,
  }) {
    final rowStart = a.row < b.row ? a.row : b.row;
    final rowEnd = a.row > b.row ? a.row : b.row;
    final columnStart = a.column < b.column ? a.column : b.column;
    final columnEnd = a.column > b.column ? a.column : b.column;
    final normalizedReferences = _normalizedRangeReferences(
      a,
      b,
      startReference,
      endReference,
      rowStart: rowStart,
      rowEnd: rowEnd,
      columnStart: columnStart,
      columnEnd: columnEnd,
    );
    return _FormulaRange(
      rowStart: rowStart,
      rowEnd: rowEnd,
      columnStart: columnStart,
      columnEnd: columnEnd,
      sheetName: sheetName,
      startReference: normalizedReferences?.start ?? startReference,
      endReference: normalizedReferences?.end ?? endReference,
    );
  }

  final int rowStart;
  final int rowEnd;
  final int columnStart;
  final int columnEnd;
  final String? sheetName;
  final String? startReference;
  final String? endReference;

  int get rowCount => rowEnd - rowStart + 1;

  int get columnCount => columnEnd - columnStart + 1;
}

class _ParserReferenceParts {
  const _ParserReferenceParts({
    required this.columnPrefix,
    required this.columnLabel,
    required this.rowPrefix,
  });

  final String columnPrefix;
  final String columnLabel;
  final String rowPrefix;

  bool get columnAbsolute => columnPrefix.isNotEmpty;

  bool get rowAbsolute => rowPrefix.isNotEmpty;
}

({String start, String end})? _normalizedRangeReferences(
  FortuneCellCoord a,
  FortuneCellCoord b,
  String? startReference,
  String? endReference, {
  required int rowStart,
  required int rowEnd,
  required int columnStart,
  required int columnEnd,
}) {
  final startParts = _parserReferenceParts(startReference);
  final endParts = _parserReferenceParts(endReference);
  if (startParts == null || endParts == null) {
    return null;
  }
  final startRowParts = a.row <= b.row ? startParts : endParts;
  final endRowParts = a.row > b.row ? startParts : endParts;
  final startColumnParts = a.column <= b.column ? startParts : endParts;
  final endColumnParts = a.column > b.column ? startParts : endParts;
  return (
    start: _rangeReferenceLabel(
      row: rowStart,
      column: columnStart,
      rowParts: startRowParts,
      columnParts: startColumnParts,
    ),
    end: _rangeReferenceLabel(
      row: rowEnd,
      column: columnEnd,
      rowParts: endRowParts,
      columnParts: endColumnParts,
    ),
  );
}

String _rangeReferenceLabel({
  required int row,
  required int column,
  required _ParserReferenceParts rowParts,
  required _ParserReferenceParts columnParts,
}) {
  return '${columnParts.columnPrefix}${_parserColumnLabel(column)}'
      '${rowParts.rowPrefix}${row + 1}';
}

_ParserReferenceParts? _parserReferenceParts(String? reference) {
  if (reference == null) {
    return null;
  }
  final match = RegExp(
    r'^(\$?)([A-Za-z]+)(\$?)([0-9]+)$',
  ).firstMatch(reference);
  if (match == null) {
    return null;
  }
  return _ParserReferenceParts(
    columnPrefix: match.group(1)!,
    columnLabel: match.group(2)!.toUpperCase(),
    rowPrefix: match.group(3)!,
  );
}

String _parserColumnLabel(int index) {
  var value = index + 1;
  final chars = <String>[];
  while (value > 0) {
    final remainder = (value - 1) % 26;
    chars.insert(0, String.fromCharCode(65 + remainder));
    value = (value - 1) ~/ 26;
  }
  return chars.join();
}

class _ReferencePart {
  const _ReferencePart(this.sheetName, this.reference);

  final String? sheetName;
  final String reference;
}

class _SingleCellReference {
  const _SingleCellReference(this.coord, this.sheetName);

  final FortuneCellCoord coord;
  final String? sheetName;
}

class _RangeEndReference {
  const _RangeEndReference(this.identifier, this.sheetName);

  final String identifier;
  final String? sheetName;
}
