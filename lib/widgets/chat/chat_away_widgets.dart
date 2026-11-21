import 'package:torn_pda/l10n/pda_text.dart';
import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_away.dart';

class ChatAwayCard extends StatelessWidget {
  const ChatAwayCard({super.key, required this.away, required this.onJump});

  final ChatAway away;
  final void Function(String messageId) onJump;

  static MaterialColor _tone(ChatAwayKind kind) => switch (kind) {
    ChatAwayKind.mentions => Colors.pink,
    ChatAwayKind.leaders => Colors.blue,
    ChatAwayKind.attacks => Colors.amber,
    ChatAwayKind.words => Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return Semantics(
      container: true,
      label: context.interfaceText("While you were away, {0} in {1}", [away.totalLabel, ChatAway.span(away.away)]),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: PdaText(
                    'While you were away',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            PdaText(
              "{0} in {1}", values: [away.totalLabel, ChatAway.span(away.away)],
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in away.shown)
                  Semantics(
                    button: true,
                    excludeSemantics: true,
                    label: context.interfaceText("{0}, jump to the first", [ChatAway.chipLabel(kind, away.counts[kind]!)]),
                    onTap: () => onJump(away.firsts[kind]!),
                    child: Material(
                      color: _tone(kind).withValues(alpha: dark ? 0.24 : 0.18),
                      shape: const StadiumBorder(),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => onJump(away.firsts[kind]!),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                ChatAway.chipLabel(kind, away.counts[kind]!),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: dark ? _tone(kind).shade200 : _tone(kind).shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            PdaText(
              'Tap one to jump to it. Only you see this',
              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
