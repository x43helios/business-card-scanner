import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class TagFilterBar extends StatelessWidget {
  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selected,
    required this.onSelected,
  });

  final Set<String> tags;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sorted = tags.toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.allTags),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...sorted.map(
            (t) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(t),
                selected: selected == t,
                onSelected: (_) => onSelected(selected == t ? null : t),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditableTags extends StatelessWidget {
  const EditableTags({
    super.key,
    required this.tags,
    required this.onChanged,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  Future<void> _add(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addTag),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.tags),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && !tags.contains(result)) {
      onChanged([...tags, result]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tags.map(
          (t) => InputChip(
            label: Text(t),
            onDeleted: () => onChanged(tags.where((x) => x != t).toList()),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.addTag),
          onPressed: () => _add(context),
        ),
      ],
    );
  }
}
