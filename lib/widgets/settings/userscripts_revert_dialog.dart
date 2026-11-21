// Flutter imports:
import 'package:torn_pda/l10n/pda_text.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';

class UserScriptsRevertDialog extends StatefulWidget {
  @override
  UserScriptsRevertDialogState createState() => UserScriptsRevertDialogState();
}

class UserScriptsRevertDialogState extends State<UserScriptsRevertDialog> {
  late ThemeProvider _themeProvider;
  late UserScriptsProvider _userScriptsProvider;

  bool _loading = false;
  bool _overwrite = false;

  @override
  void initState() {
    super.initState();
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: const EdgeInsets.only(top: 15),
                decoration: BoxDecoration(
                  color: _themeProvider.secondBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the card compact
                  children: <Widget>[
                    const SizedBox(height: 10),
                    Flexible(
                      child: Text(
                        _overwrite
                            ? context.interfaceText("This will REMOVE all example scripts and re-download fresh copies.\n\nLocal modifications will be lost!")
                            : context.interfaceText("This will re-add any of the example userscripts that you may have deleted.\n\nExisting scripts will be kept."),
                        style: TextStyle(
                          fontSize: 12,
                          color: _overwrite ? Colors.orange[800] : _themeProvider.mainText,
                          fontWeight: _overwrite ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: PdaText(
                            "Overwrite existing (also if modified)",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        Switch(
                          value: _overwrite,
                          onChanged: (value) {
                            setState(() {
                              _overwrite = value;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: Text(_overwrite ? context.interfaceText("Reset!") : context.interfaceText("Do it!")),
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _loading = true;
                                  });
                                  _userScriptsProvider
                                      .addDefaultScripts(overwriteExisting: _overwrite)
                                      .then((r) => BotToast.showText(
                                            text: context.interfaceText("{0} script{1} removed\n{2} script{3} added\n\n{4} script{5} failed to load", [r.removed, r.removed == 1 ? "" : "s", r.added, r.added == 1 ? "" : "s", r.failed, r.failed == 1 ? "" : "s"]),
                                            textStyle: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ))
                                      .whenComplete(() {
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        _loading = false;
                                      });
                                    }
                                  });
                                },
                        ),
                        TextButton(
                          child: const PdaText("Better not!"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: _themeProvider.secondBackground,
                child: CircleAvatar(
                  backgroundColor: _themeProvider.secondBackground,
                  radius: 22,
                  child: const SizedBox(
                    height: 34,
                    width: 34,
                    child: Icon(MdiIcons.backupRestore),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
