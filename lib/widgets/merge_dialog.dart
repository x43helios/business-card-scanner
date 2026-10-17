import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/contact_matcher.dart';

Future<MatchCandidate?> showMergeDialog({
  required BuildContext context,
  required List<MatchCandidate> candidates,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<MatchCandidate?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        title: Text(l10n.mergeTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.mergeMessage),
              const SizedBox(height: 12),
              ...candidates.take(5).map((m) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(m.contact.displayName),
                  subtitle: Text(
                    '${l10n.matchReasons}: ${m.reasons.join(", ")} '
                    '(${(m.score * 100).round()}%)',
                  ),
                  trailing: TextButton(
                    onPressed: () => Navigator.pop(ctx, m),
                    child: Text(l10n.mergeYes),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l10n.mergeNo),
          ),
        ],
      );
    },
  );
}
