// Flutter imports:
import 'package:torn_pda/l10n/pda_text.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/utils/script_storage.dart';

Future<bool> showScriptStorageQuotaDialog(BuildContext context, String sid) async {
  const int mb = 1024 * 1024;
  final defaultMb = ScriptStorage.defaultQuotaBytes ~/ mb;
  final maxMb = ScriptStorage.maxQuotaBytes ~/ mb;
  final override = await ScriptStorage.quotaOverride(sid);
  final used = await ScriptStorage.namespaceUsage(sid);
  if (!context.mounted) return false;

  double value = (override > 0 ? override ~/ mb : defaultMb).toDouble();
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const PdaText("Native storage"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PdaText(
              "This script keeps its data with Torn PDA instead of the browser, so it is more stable and does not "
              "compete for the browser's space.",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            const PdaText(
              "Great job by the script author for using this feature!",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFB8860B)),
            ),
            const SizedBox(height: 12),
            PdaText("Currently using {0}", values: [_formatBytes(used)], style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            const PdaText("Storage limit", style: TextStyle(fontWeight: FontWeight.bold)),
            Center(
              child: PdaText("{0} MB", values: [value.round()], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Slider(
              value: value,
              min: defaultMb.toDouble(),
              max: maxMb.toDouble(),
              divisions: maxMb - defaultMb,
              label: "${value.round()} MB",
              onChanged: (v) => setDialogState(() => value = v),
            ),
            PdaText(
              "Default is {0} MB, up to {1} MB.", values: [defaultMb, maxMb],
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const PdaText("Cancel")),
          TextButton(
            onPressed: () async {
              await ScriptStorage.setQuota(sid, value.round() == defaultMb ? 0 : value.round() * mb);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
            },
            child: const PdaText("Save"),
          ),
        ],
      ),
    ),
  );
  return saved ?? false;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return "$bytes B";
  if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
  return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
}
