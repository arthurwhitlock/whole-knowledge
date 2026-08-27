import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/presentation/components/compact_editing_context_menu.dart';

void main() {
  test('keeps only the four compact editing actions', () {
    final filtered = compactEditingButtonItems([
      ContextMenuButtonItem(type: ContextMenuButtonType.cut, onPressed: () {}),
      ContextMenuButtonItem(type: ContextMenuButtonType.copy, onPressed: () {}),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {},
      ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {},
      ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.searchWeb,
        onPressed: () {},
      ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.custom,
        onPressed: () {},
      ),
    ]);

    expect(filtered.map((item) => item.type), [
      ContextMenuButtonType.cut,
      ContextMenuButtonType.copy,
      ContextMenuButtonType.paste,
      ContextMenuButtonType.selectAll,
    ]);
  });
}
