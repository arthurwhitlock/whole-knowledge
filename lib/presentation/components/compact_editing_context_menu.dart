import 'package:flutter/material.dart';

Widget compactEditingContextMenu(
  BuildContext context,
  EditableTextState editableTextState,
) {
  final buttons = compactEditingButtonItems(
    editableTextState.contextMenuButtonItems,
  );
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: editableTextState.contextMenuAnchors,
    buttonItems: buttons,
  );
}

List<ContextMenuButtonItem> compactEditingButtonItems(
  Iterable<ContextMenuButtonItem> items,
) {
  const allowed = {
    ContextMenuButtonType.cut,
    ContextMenuButtonType.copy,
    ContextMenuButtonType.paste,
    ContextMenuButtonType.selectAll,
  };
  return items
      .where((item) => allowed.contains(item.type))
      .toList(growable: false);
}
