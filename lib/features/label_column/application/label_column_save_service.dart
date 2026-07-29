import 'package:label_manager/database/drivers/db_driver.dart';
import 'package:label_manager/features/label_column/data/label_column_save.dart';
import 'package:label_manager/features/label_column/domain/label_column_edit.dart';

typedef LabelColumnDialogSaver =
    Future<void> Function(LabelColumnDialogSaveCommand command);

Future<void> executeLabelColumnSaveAndReload(
  LabelColumnDialogSaveCommand command, {
  LabelColumnDialogSaver save = LabelColumnSaveDao.saveDialog,
  required Future<bool> Function() reload,
}) async {
  try {
    await save(command);
  } on DbCommitOutcomeUnknown catch (error) {
    throw LabelColumnSaveCommittedException(
      'DB 커밋 결과를 확인할 수 없습니다. 중복 저장을 막기 위해 '
      '다이얼로그를 닫습니다. 연결을 확인한 뒤 최신 정보를 다시 불러오세요.\n$error',
      outcomeUnknown: true,
    );
  }
  try {
    if (!await reload()) {
      throw StateError('현재 라벨 정보를 다시 불러오지 못했습니다.');
    }
  } catch (error) {
    throw LabelColumnSaveCommittedException(
      '저장은 완료됐지만 화면 갱신에 실패했습니다. 중복 저장을 막기 위해 '
      '다이얼로그를 닫습니다. 최신 정보를 다시 불러오세요.\n$error',
    );
  }
}
