// Flutter imports:
import 'package:torn_pda/l10n/pda_text.dart';
import 'dart:io';

import 'package:flutter/material.dart';

class DiscreetInfo extends StatefulWidget {
  @override
  DiscreetInfoState createState() => DiscreetInfoState();
}

class DiscreetInfoState extends State<DiscreetInfo> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String discreetText = "Discreet notifications are designed for environments (work, school...) where the standard "
        "notification text (i.e.: referencing loot, drugs, etc.) would not be appropriate."
        "\n\nInstead, you will receive a much shorter text, as explained below."
        "\n\nBe aware that you might lose some key information in the notification "
        "(e.g.: event or message details). Applies both for manual notifications and automatic alerts."
        "\n\nThey can also be discreet only during some hours: turn on Schedule under Discreet local "
        "notifications in Settings. The schedule applies to automatic alerts too.";

    if (Platform.isIOS) {
      discreetText += "\n\nNOTE: Torn private messages that arrive while the app is in the background or closed "
          "come directly from Apple and can't be made discreet.";
    }

    if (Platform.isAndroid) {
      discreetText += "\n\nNOTE: This setting also applies to titles for alarms and timers.";
    }

    return AlertDialog(
      title: const PdaText("Discreet notifications"),
      content: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discreetText,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    const PdaText(
                      "Examples notification titles and bodies if discreet notifications are enabled:",
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Column(
                  children: [
                    Column(
                      children: [
                        PdaText(
                          "Travel",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: T",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Flight departure",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Scheduled",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Departure",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Energy",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: E",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Full",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Nerve",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: N",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Full",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Life",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Lf",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Full",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Hospital admission",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: H",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Adm",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Hospital release (approaching)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: H",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: App",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Hospital release (out)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: H",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Out",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Drug cooldown",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: D",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Exp",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Booster cooldown",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: B",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Exp",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Medical cooldown",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Med",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Exp",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Race start",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: R",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Start",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Race ending",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: R",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: End",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Message",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: M",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Manuito",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Event",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Event",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Trade",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Trade",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        )
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Foreign stock",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Stock",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Refills",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Refills",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Retaliation",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Retal",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Loot",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: L",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Body: Duke - 4",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        PdaText(
                          "Loot Rangers",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: LR",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Assist",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Assist",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "Level 20 - 200 days old",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Stock market",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: Shares",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "Ranked War",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: W",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "App",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      children: [
                        PdaText(
                          "War target notification",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        PdaText(
                          "Title: WT",
                          style: TextStyle(fontSize: 13),
                        ),
                        PdaText(
                          "(blank body)",
                          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const PdaText("Quiet!"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
