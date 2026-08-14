import 'dart:async';

import 'package:flutter/material.dart';
import 'package:label_manager/core/app.dart';
import 'package:label_manager/widgets/app_menu_bar.dart';
import 'package:url_launcher/url_launcher.dart';

typedef HelpUrlLauncher = Future<bool> Function(Uri uri);

class HelpMenuButton extends StatefulWidget {
  const HelpMenuButton({
    super.key,
    this.onMenuOpenChanged,
    this.urlLauncher = launchUrl,
  });

  final ValueChanged<bool>? onMenuOpenChanged;
  final HelpUrlLauncher urlLauncher;

  @override
  State<HelpMenuButton> createState() => _HelpMenuButtonState();
}

class _HelpMenuButtonState extends State<HelpMenuButton> {
  final MenuController _controller = MenuController();

  Future<void> _openUrl(String value) async {
    final launched = await widget.urlLauncher(Uri.parse(value));
    if (!launched && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('연결된 페이지를 열 수 없습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      useRootOverlay: true,
      onOpen: () => widget.onMenuOpenChanged?.call(true),
      onClose: () => widget.onMenuOpenChanged?.call(false),
      menuChildren: [
        MenuItemButton(
          key: const ValueKey('helpAbout'),
          style: AppMenuBar.menuItemStyle,
          leadingIcon: const Icon(Icons.info_outline),
          onPressed: () => unawaited(
            showDialog<void>(
              context: context,
              builder: (_) => const AppAboutDialog(),
            ),
          ),
          child: const Text('라벨매니저 정보'),
        ),
        const Divider(height: AppMenuBar.menuDividerHeight),
        MenuItemButton(
          key: const ValueKey('helpShop'),
          style: AppMenuBar.menuItemStyle,
          onPressed: () => unawaited(
            _openUrl('https://itsngshop.com/index.html'),
          ),
          child: const Text('라벨지, 프린터 구매하기'),
        ),
        MenuItemButton(
          key: const ValueKey('helpRemoteSupport'),
          style: AppMenuBar.menuItemStyle,
          onPressed: () => unawaited(
            _openUrl(
              'https://itsng.co.kr/%ED%8C%80%EB%B7%B0%EC%96%B412_QS.exe',
            ),
          ),
          child: const Text('원격 지원 프로그램 다운로드'),
        ),
        MenuItemButton(
          key: const ValueKey('helpDownloads'),
          style: AppMenuBar.menuItemStyle,
          onPressed: () => unawaited(
            _openUrl(
              'https://itsng.co.kr/board/bbs/board.php?bo_table=down',
            ),
          ),
          child: const Text('ITSNG 자료실 바로가기'),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        key: const ValueKey('helpMenuButton'),
        tooltip: '도움말',
        icon: const Icon(Icons.help_outline),
        onPressed: controller.isOpen ? controller.close : controller.open,
      ),
    );
  }
}

class AppAboutDialog extends StatelessWidget {
  const AppAboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Label Manager 정보'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, size: 40),
              const SizedBox(width: 12),
              Text('Label Manager 버전 $appVersion'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Copyright (C) 2006-2016 ITSNG Corporation. All rights reserved',
          ),
          const SizedBox(height: 8),
          const Text('전화번호 : 02-3274-1776'),
          const Text('주소 : 서울시 용산구 효창동 5-240 ITSNG'),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
