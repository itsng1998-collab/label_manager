import 'package:flutter_test/flutter_test.dart';
import 'package:label_manager/features/label_column/domain/column_text_template.dart';

void main() {
  test('templates substitute exact longest tokens without cascading replacements', () {
    expect(
      replaceLabelColumnTextTokens(
        '#TEXT1 + #TEXT2 + #TEXT10 = 6\n#ITEMNAME / #품목 / #UNKNOWN',
        {
          '#TEXT1': '1',
          'TEXT2': '#TEXT1',
          'TEXT10': '3',
          'ITEMNAME': '품목 A',
          '품목': '품목 A',
        },
      ),
      '1 + #TEXT1 + 3 = 6\n품목 A / 품목 A / #UNKNOWN',
    );
  });

  test('reference colors use the same exact token boundaries as output', () {
    expect(
      labelColumnTextReferences(
        '#TEXT10 #TEXT1_SUFFIX #TEXT100 #TEXT1 #한글 #A.B',
        ['TEXT1', 'TEXT10', '한글', 'A.B'],
      ),
      {'#TEXT10', '#TEXT1', '#한글', '#A.B'},
    );
    expect(
      replaceLabelColumnTextTokens(
        '#TEXT10 #TEXT1_SUFFIX #TEXT100 #TEXT1 #한글 #A.B',
        {'TEXT1': '1', 'TEXT10': '10', '한글': '국문', 'A.B': '점'},
      ),
      '10 #TEXT1_SUFFIX #TEXT100 1 국문 점',
    );
  });

  test('empty templates and dictionaries preserve literals including whitespace', () {
    expect(replaceLabelColumnTextTokens('', {'A': '1'}), '');
    expect(replaceLabelColumnTextTokens(' 사용자정의 \n', {}), ' 사용자정의 \n');
    expect(labelColumnTextReferences('literal', []), isEmpty);
    expect(replaceLabelColumnTextTokens('#A / #', {' A ': '1', ' ': 'ignore'}), '1 / #');
  });

  test('self and mutual references use original item values once', () {
    const values = {'A': '#B', 'B': '17'};
    expect(replaceLabelColumnTextTokens('#A #B', values), '#B 17');
    expect(replaceLabelColumnTextTokens('#B #A', values), '17 #B');
    expect(values, {'A': '#B', 'B': '17'});
  });
}
