import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/models/notice.dart';
import 'package:label_manager/models/user.dart';
import 'package:label_manager/widgets/blocking_modeless_dialog.dart';
import 'package:label_manager/widgets/notice_display.dart';

enum UpdateNoticeSaveTarget {
  selectedUsers,
  allCooperators,
  currentCooperator,
  currentUser,
}

UpdateNoticeSaveTarget resolveUpdateNoticeSaveTarget({
  required UserGrade grade,
  required bool selectUsers,
  required bool allCooperators,
}) {
  if (grade != UserGrade.SYSTEM_ADMIN_USER &&
      grade != UserGrade.COOP_ADMIN_USER) {
    return UpdateNoticeSaveTarget.currentUser;
  }
  if (selectUsers) return UpdateNoticeSaveTarget.selectedUsers;
  if (grade == UserGrade.SYSTEM_ADMIN_USER && allCooperators) {
    return UpdateNoticeSaveTarget.allCooperators;
  }
  return UpdateNoticeSaveTarget.currentCooperator;
}

class UpdateNoticeSaveRequest {
  const UpdateNoticeSaveRequest({
    required this.target,
    required this.message,
    required this.selectedUserIds,
    required this.dontShowAgain,
  });

  final UpdateNoticeSaveTarget target;
  final String? message;
  final List<String> selectedUserIds;
  final bool dontShowAgain;
}

class UpdateNoticeDialog extends StatefulWidget {
  const UpdateNoticeDialog({
    super.key,
    required this.user,
    required this.notice,
    required this.targetUsers,
    required this.onSave,
    required this.onClose,
  });

  final User user;
  final Notice notice;
  final List<NoticeTargetUser> targetUsers;
  final Future<void> Function(UpdateNoticeSaveRequest request) onSave;
  final VoidCallback onClose;

  @override
  State<UpdateNoticeDialog> createState() => _UpdateNoticeDialogState();
}

class _UpdateNoticeDialogState extends State<UpdateNoticeDialog> {
  late String _version = appVersion;
  late String _message = widget.notice.message;
  bool _selectUsers = false;
  bool _allCooperators = false;
  bool _dontShowAgain = false;
  bool _saving = false;
  String? _error;
  final Set<String> _selectedUserIds = <String>{};

  bool get _isAdministrator =>
      widget.user.grade == UserGrade.SYSTEM_ADMIN_USER ||
      widget.user.grade == UserGrade.COOP_ADMIN_USER;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.enter ||
        _saving) {
      return false;
    }
    _save();
    return true;
  }

  Future<void> _save() async {
    if (_saving) return;
    final target = resolveUpdateNoticeSaveTarget(
      grade: widget.user.grade,
      selectUsers: _selectUsers,
      allCooperators: _allCooperators,
    );
    if (target == UpdateNoticeSaveTarget.selectedUsers &&
        _selectedUserIds.isEmpty) {
      setState(() => _error = '사용자를 선택해주세요.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
        UpdateNoticeSaveRequest(
          target: target,
          message: _isAdministrator ? _message : null,
          selectedUserIds: _selectedUserIds.toList(growable: false),
          dontShowAgain: _dontShowAgain,
        ),
      );
      widget.onClose();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BlockingModelessDialogFrame(
      title: '업데이트 메시지',
      width: size.width * 0.8,
      height: size.height * 0.8,
      closeEnabled: !_saving,
      onClose: widget.onClose,
      footer: _buildFooter(),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: NoticeDisplayPanel(
                version: _version,
                content: _message,
                editable: _isAdministrator,
                onVersionChanged: (value) => _version = value,
                onContentChanged: (value) => _message = value,
              ),
            ),
            if (_isAdministrator) ...[
              const SizedBox(width: 12),
              SizedBox(width: 300, child: _buildTargetPanel()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: _selectUsers,
          title: const Text('사용자 선택'),
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: _saving
              ? null
              : (value) {
                  setState(() {
                    _selectUsers = value ?? false;
                    if (!_selectUsers) _selectedUserIds.clear();
                  });
                },
        ),
        if (widget.user.grade == UserGrade.SYSTEM_ADMIN_USER)
          CheckboxListTile(
            value: _allCooperators,
            title: const Text('전체 협력업체'),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: _saving
                ? null
                : (value) =>
                      setState(() => _allCooperators = value ?? false),
          ),
        const Divider(),
        Expanded(
          child: !_selectUsers
              ? const SizedBox.shrink()
              : ListView.builder(
                  itemCount: widget.targetUsers.length,
                  itemBuilder: (context, index) {
                    final target = widget.targetUsers[index];
                    return CheckboxListTile(
                      value: _selectedUserIds.contains(target.userId),
                      title: Text(target.userId),
                      subtitle: Text(target.customerName),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: _saving
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected ?? false) {
                                  _selectedUserIds.add(target.userId);
                                } else {
                                  _selectedUserIds.remove(target.userId);
                                }
                              });
                            },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          Checkbox(
            value: _dontShowAgain,
            onChanged: _saving
                ? null
                : (value) => setState(() => _dontShowAgain = value ?? false),
          ),
          const Text('다시 보지 않기'),
          const SizedBox(width: 12),
          if (_error != null)
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Spacer(),
          TextButton(onPressed: _saving ? null : widget.onClose, child: const Text('취소')),
          const SizedBox(width: 8),
          FilledButton(onPressed: _saving ? null : _save, child: const Text('저장')),
        ],
      ),
    );
  }
}