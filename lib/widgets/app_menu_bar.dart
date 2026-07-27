import 'package:flutter/material.dart';
import 'package:label_manager/models/app_menu_command.dart';

class AppMenuBar extends StatelessWidget {
  const AppMenuBar({
    super.key,
    required this.title,
    required this.commandStates,
    required this.onCommandSelected,
    this.searchPrintModeActive = false,
    this.onMenuOpenChanged,
  });

  static const double _minimumTitleWidth = 400;
  static const double _groupButtonWidth = 48;
  static const double _menuGap = 8;
  static final ButtonStyle _menuItemStyle = MenuItemButton.styleFrom(
    minimumSize: const Size(64, kMinInteractiveDimension),
    visualDensity: VisualDensity.standard,
    tapTargetSize: MaterialTapTargetSize.padded,
  );

  final Widget title;
  final Map<AppMenuCommandId, AppMenuCommandState> commandStates;
  final ValueChanged<AppMenuCommandId> onCommandSelected;
  final bool searchPrintModeActive;
  final ValueChanged<bool>? onMenuOpenChanged;

  @override
  Widget build(BuildContext context) {
    final visibleGroups = AppMenuGroup.values
        .where((group) => _visibleCommands(group).isNotEmpty)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideMenuWidth =
            visibleGroups.length * _groupButtonWidth + _menuGap;
        final showWideMenu =
            constraints.maxWidth >= _minimumTitleWidth + wideMenuWidth;

        return Row(
          children: [
            Expanded(
              child: DefaultTextStyle.merge(
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: title,
              ),
            ),
            const SizedBox(width: _menuGap),
            if (showWideMenu)
              for (final group in visibleGroups) _buildGroupAnchor(group)
            else if (visibleGroups.isNotEmpty)
              _buildOverflowAnchor(visibleGroups),
          ],
        );
      },
    );
  }

  Widget _buildGroupAnchor(AppMenuGroup group) {
    final presentation = _groupPresentation(group);
    return MenuAnchor(
      consumeOutsideTap: true,
      onOpen: () => onMenuOpenChanged?.call(true),
      onClose: () => onMenuOpenChanged?.call(false),
      menuChildren: _buildCommandMenu(group),
      builder: (context, controller, child) => IconButton(
        key: ValueKey('app-menu-group-${group.name}'),
        tooltip: presentation.label,
        icon: Icon(presentation.icon),
        onPressed: controller.isOpen ? controller.close : controller.open,
      ),
    );
  }

  Widget _buildOverflowAnchor(List<AppMenuGroup> visibleGroups) {
    return MenuAnchor(
      consumeOutsideTap: true,
      onOpen: () => onMenuOpenChanged?.call(true),
      onClose: () => onMenuOpenChanged?.call(false),
      menuChildren: [
        for (final group in visibleGroups)
          SubmenuButton(
            key: ValueKey('app-menu-overflow-group-${group.name}'),
            style: _menuItemStyle,
            menuChildren: _buildCommandMenu(group),
            child: Text(_groupPresentation(group).label),
          ),
      ],
      builder: (context, controller, child) => IconButton(
        key: const ValueKey('app-menu-overflow'),
        tooltip: '메뉴',
        icon: const Icon(Icons.more_vert),
        onPressed: controller.isOpen ? controller.close : controller.open,
      ),
    );
  }

  List<Widget> _buildCommandMenu(AppMenuGroup group) {
    final commands = _visibleCommands(group);
    final children = <Widget>[];
    int? previousSection;
    var searchPrintAdded = false;

    for (final command in commands) {
      if (previousSection != null && previousSection != command.section) {
        children.add(const Divider());
      }
      previousSection = command.section;

      if (command.submenu == AppMenuSubmenu.searchPrint) {
        if (!searchPrintAdded) {
          final submenuCommands = commands
              .where(
                (candidate) =>
                    candidate.submenu == AppMenuSubmenu.searchPrint,
              )
              .toList(growable: false);
          children.add(
            SubmenuButton(
              key: const ValueKey('app-menu-submenu-searchPrint'),
              style: _menuItemStyle,
              menuChildren: submenuCommands
                  .map(_buildCommandItem)
                  .toList(growable: false),
              child: const Text('검색출력'),
            ),
          );
          searchPrintAdded = true;
        }
        continue;
      }

      children.add(_buildCommandItem(command));
    }
    return children;
  }

  Widget _buildCommandItem(AppMenuCommandMetadata command) {
    final state = commandStates[command.id]!;
    final checked = command.id == AppMenuCommandId.searchPrintMode &&
        searchPrintModeActive;
    final leadingIcon = checked
        ? const Icon(Icons.check)
        : command.icon == null
        ? null
        : Icon(command.icon);
    final onPressed = state.enabled
        ? () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onCommandSelected(command.id);
            });
          }
        : null;

    return Semantics(
      key: ValueKey('app-menu-command-semantics-${command.id.name}'),
      container: true,
      button: true,
      enabled: state.enabled,
      label: command.shortcutLabel == null
          ? command.label
          : '${command.label} ${command.shortcutLabel}',
      onTap: onPressed,
      excludeSemantics: true,
      child: MenuItemButton(
        key: ValueKey('app-menu-command-${command.id.name}'),
        style: _menuItemStyle,
        onPressed: onPressed,
        leadingIcon: leadingIcon,
        trailingIcon: command.shortcutLabel == null
            ? null
            : Text(command.shortcutLabel!),
        child: _CommandLabel(
          label: command.label,
          disabledReason: state.disabledReason,
        ),
      ),
    );
  }

  List<AppMenuCommandMetadata> _visibleCommands(AppMenuGroup group) =>
      appMenuCommands
          .where(
            (command) =>
                command.group == group &&
                command.renderInPopup &&
                commandStates[command.id]?.visible == true,
          )
          .toList(growable: false);

  _GroupPresentation _groupPresentation(AppMenuGroup group) {
    switch (group) {
      case AppMenuGroup.file:
        return const _GroupPresentation('파일/관리', Icons.menu);
      case AppMenuGroup.search:
        return const _GroupPresentation('조회/이력', Icons.manage_search);
      case AppMenuGroup.settings:
        return const _GroupPresentation('설정', Icons.settings_outlined);
    }
  }
}

class _CommandLabel extends StatelessWidget {
  const _CommandLabel({required this.label, this.disabledReason});

  final String label;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final reason = disabledReason;
    if (reason == null) return Text(label);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Text(reason, maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _GroupPresentation {
  const _GroupPresentation(this.label, this.icon);

  final String label;
  final IconData icon;
}