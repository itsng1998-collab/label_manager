import 'package:flutter/material.dart';
import 'package:label_manager/features/login/domain/user_access_serial.dart';

Future<bool> showUserAccessSerialDialog(
  BuildContext context,
  String temporaryNumber,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _UserAccessSerialDialog(
      temporaryNumber: temporaryNumber,
    ),
  );
  return result == true;
}

class _UserAccessSerialDialog extends StatefulWidget {
  const _UserAccessSerialDialog({required this.temporaryNumber});

  final String temporaryNumber;

  @override
  State<_UserAccessSerialDialog> createState() =>
      _UserAccessSerialDialogState();
}

class _UserAccessSerialDialogState extends State<_UserAccessSerialDialog> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim() !=
        userAccessSerialNumber(widget.temporaryNumber)) {
      setState(() => _errorText = '시리얼 번호가 올바르지 않습니다.');
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('시리얼 인증'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '등록된 사용자 PC 정보가 일치하지 않습니다.\n'
              '다른 PC에서 사용 중인 아이디일 수 있습니다.\n'
              'PC 정보를 변경하려면 02)3274-1776으로 문의해주세요.',
            ),
            const SizedBox(height: 20),
            Text('임시 번호', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SelectableText(
              widget.temporaryNumber,
              key: const Key('userAccessTemporaryNumber'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('userAccessSerialField'),
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '시리얼 번호',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('입력')),
      ],
    );
  }
}