bool itemManagerCanPersistDynamicCell({
  required bool canManageItemStructure,
  required bool commandBusy,
  required bool hasDraftRow,
}) {
  return canManageItemStructure && !commandBusy && hasDraftRow;
}

String itemManagerDeleteConfirmationMessage({
  required String firstItemName,
  required int selectedCount,
}) {
  assert(selectedCount > 0);
  if (selectedCount == 1) {
    return "선택한 '$firstItemName'를 삭제하시겠습니까?";
  }
  return "선택한 '$firstItemName' 외 ${selectedCount - 1}개 항목을 모두 삭제하시겠습니까?";
}

String itemManagerSaveConfirmationMessage({required bool hasDeletedItems}) {
  const prompt = '품목관리 변경 사항을 저장할까요?';
  return hasDeletedItems
      ? '$prompt\n\n삭제한 품목은 같은 고객의 다른 market 품목관리에서도 보이지 않을 수 있습니다.'
      : prompt;
}