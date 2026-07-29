import 'package:flutter/material.dart';
import 'package:label_manager/core/app_menu_command.dart';

class AppMenuBar extends StatefulWidget {
  const AppMenuBar({
    super.key,
    required this.title,
    required this.commandStates,
    required this.onCommandSelected,
    this.trailing,
    this.trailingWidth = 0,
    this.searchPrintModeActive = false,
    this.onMenuOpenChanged,
  });

  static const double _minimumTitleWidth = 400;
  static const double _groupButtonWidth = 48;
  static const double _menuGap = 8;
  static const double _menuItemHeight = 28;
  static const double _menuDividerHeight = 9;
  static final ButtonStyle _menuItemStyle = MenuItemButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    minimumSize: const Size(64, _menuItemHeight),
    visualDensity: VisualDensity.standard,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  final Widget title;
  final Map<AppMenuCommandId, AppMenuCommandState> commandStates;
  final ValueChanged<AppMenuCommandId> onCommandSelected;
  final Widget? trailing;
  final double trailingWidth;
  final bool searchPrintModeActive;
  final ValueChanged<bool>? onMenuOpenChanged;

  @override
  State<AppMenuBar> createState() => _AppMenuBarState();
}

class _AppMenuBarState extends State<AppMenuBar> {
  final Map<AppMenuGroup, MenuController> _groupControllers = {
    for (final group in AppMenuGroup.values) group: MenuController(),
  };
  final MenuController _overflowController = MenuController();
  final Set<MenuController> _openControllers = {};
  bool _menuOpenReported = false;
  int _closeReportGeneration = 0;

  void _handleMenuOpened(MenuController controller) {
    _closeReportGeneration += 1;
    _openControllers.add(controller);
    for (final other in _openControllers.toList(growable: false)) {
      if (!identical(other, controller) && other.isOpen) {
        other.close();
      }
    }
    if (!_menuOpenReported) {
      _menuOpenReported = true;
      widget.onMenuOpenChanged?.call(true);
    }
  }

  void _handleMenuClosed(MenuController controller) {
    _openControllers.remove(controller);
    if (_openControllers.isNotEmpty) return;
    final generation = ++_closeReportGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _closeReportGeneration) return;
      if (_openControllers.isEmpty) _reportAllMenusClosed();
    });
  }

  void _reportAllMenusClosed() {
    if (!_menuOpenReported) return;
    _menuOpenReported = false;
    widget.onMenuOpenChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    final visibleGroups = AppMenuGroup.values
        .where((group) => _visibleCommands(group).isNotEmpty)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideMenuWidth =
          visibleGroups.length * AppMenuBar._groupButtonWidth +
          AppMenuBar._menuGap +
          widget.trailingWidth;
        final showWideMenu =
            constraints.maxWidth >=
            AppMenuBar._minimumTitleWidth + wideMenuWidth;

        return Row(
          children: [
            Expanded(
              child: DefaultTextStyle.merge(
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: widget.title,
              ),
            ),
            const SizedBox(width: AppMenuBar._menuGap),
            if (showWideMenu)
              for (final group in visibleGroups) _buildGroupAnchor(group)
            else if (visibleGroups.isNotEmpty)
              _buildOverflowAnchor(visibleGroups),
            if (widget.trailing case final trailing?)
              SizedBox(width: widget.trailingWidth, child: trailing),
          ],
        );
      },
    );
  }

  Widget _buildGroupAnchor(AppMenuGroup group) {
    final presentation = _groupPresentation(group);
    final controller = _groupControllers[group]!;
    final enabled = _visibleCommands(group).any(
      (command) => widget.commandStates[command.id]?.enabled == true,
    );
    return MenuAnchor(
      controller: controller,
      useRootOverlay: true,
      onOpen: () => _handleMenuOpened(controller),
      onClose: () => _handleMenuClosed(controller),
      menuChildren: _buildCommandMenu(group),
      builder: (context, menuController, child) => IconButton(
        key: ValueKey('app-menu-group-${group.name}'),
        tooltip: presentation.label,
        icon: Icon(presentation.icon),
        onPressed: !enabled
            ? null
            : menuController.isOpen
            ? menuController.close
            : menuController.open,
      ),
    );
  }

  Widget _buildOverflowAnchor(List<AppMenuGroup> visibleGroups) {
    final enabled = visibleGroups.any(
      (group) => _visibleCommands(group).any(
        (command) => widget.commandStates[command.id]?.enabled == true,
      ),
    );
    return MenuAnchor(
      controller: _overflowController,
      useRootOverlay: true,
      onOpen: () => _handleMenuOpened(_overflowController),
      onClose: () => _handleMenuClosed(_overflowController),
      menuChildren: [
        for (final group in visibleGroups)
          SubmenuButton(
            key: ValueKey('app-menu-overflow-group-${group.name}'),
            style: AppMenuBar._menuItemStyle,
            menuChildren: _buildCommandMenu(group),
            child: Text(_groupPresentation(group).label),
          ),
      ],
      builder: (context, menuController, child) => IconButton(
        key: const ValueKey('app-menu-overflow'),
        tooltip: '메뉴',
        icon: const Icon(Icons.more_vert),
        onPressed: !enabled
            ? null
            : menuController.isOpen
            ? menuController.close
            : menuController.open,
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
        children.add(const Divider(height: AppMenuBar._menuDividerHeight));
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
              style: AppMenuBar._menuItemStyle,
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
    final state = widget.commandStates[command.id]!;
    final checked = command.id == AppMenuCommandId.searchPrintMode &&
        widget.searchPrintModeActive;
    final leadingIcon = checked
        ? const Icon(Icons.check)
        : command.icon == null
        ? null
        : Icon(command.icon);
    final onPressed = state.enabled
        ? () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onCommandSelected(command.id);
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
        style: AppMenuBar._menuItemStyle,
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
                widget.commandStates[command.id]?.visible == true,
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