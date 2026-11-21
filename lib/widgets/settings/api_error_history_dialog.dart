import 'package:torn_pda/l10n/pda_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:torn_pda/providers/api/api_caller.dart';

class ApiErrorDialog extends StatefulWidget {
  @override
  ApiErrorDialogState createState() => ApiErrorDialogState();
}

class ApiErrorDialogState extends State<ApiErrorDialog> {
  final ApiCallerController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      title: const PdaText('API Error Log'),
      content: Obx(() {
        final errors = controller.apiErrors;
        if (errors.isEmpty) {
          return const Center(child: PdaText('No errors recorded.'));
        }
        final recentFirst = errors.reversed.toList();
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PdaText(
                "Note: be careful if taking screenshots, as some of these errors might contain your API key in plain text. "
                "Make sure that you only share this with Torn PDA developers.",
                style: TextStyle(fontSize: 12, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: recentFirst.map((err) {
                  final tct = formatter.format(err.timestamp.toUtc());
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ExpansionTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const PdaText(
                                  'Time (TCT): ',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(tct, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const PdaText(
                                  'API Version: ',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(err.apiVersion.toLowerCase(), style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const PdaText(
                              'Error:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(err.message, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: PdaText(
                                    "DETAILS\n{0}", values: [err.trace],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const PdaText('Close')),
      ],
    );
  }
}
