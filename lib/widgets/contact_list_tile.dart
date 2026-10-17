import 'package:flutter/material.dart';

import '../models/contact.dart';

class ContactListTile extends StatelessWidget {
  const ContactListTile({
    super.key,
    required this.contact,
    required this.onTap,
    this.selected = false,
    this.onLongPress,
    this.selectMode = false,
  });

  final Contact contact;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: selectMode
          ? Checkbox(value: selected, onChanged: (_) => onTap())
          : CircleAvatar(
              child: Text(
                contact.displayName.isNotEmpty
                    ? String.fromCharCodes(contact.displayName.runes.take(1))
                    : '?',
              ),
            ),
      title: Text(contact.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contact.subtitle != null) Text(contact.subtitle!),
          if (contact.primaryFields.displayPhone != null)
            Text(contact.primaryFields.displayPhone!),
          if (contact.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                children: contact.tags
                    .map(
                      (t) => Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: Text(
        '${contact.cards.length}',
        style: theme.textTheme.bodySmall,
      ),
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
