import 'package:torn_pda/l10n/app_language.dart';
import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/providers/inventory_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class ApiKeySectionWidget extends StatefulWidget {
  final bool apiIsLoading;
  final OwnProfileBasic? userProfile;
  final bool apiError;
  final String errorReason;
  final String errorDetails;

  final GlobalKey<FormState> formKey;
  final GlobalKey<FormState> apiFormKey;
  final TextEditingController apiKeyInputController;
  final ExpandableController expandableController;

  final Future<void> Function({required bool userTriggered, required String currentKey}) getApiDetails;
  final void Function() setStateOnParent;

  final void Function(bool) changeApiError;
  final void Function(dynamic) changeUserProfile;

  const ApiKeySectionWidget({
    super.key,
    required this.apiIsLoading,
    required this.userProfile,
    required this.apiError,
    required this.errorReason,
    required this.errorDetails,
    required this.formKey,
    required this.apiFormKey,
    required this.apiKeyInputController,
    required this.expandableController,
    required this.getApiDetails,
    required this.setStateOnParent,
    required this.changeApiError,
    required this.changeUserProfile,
  });

  @override
  State<ApiKeySectionWidget> createState() => _ApiKeySectionWidgetState();
}

class _ApiKeySectionWidgetState extends State<ApiKeySectionWidget> {
  final ExpandableController _tosExpandableController = ExpandableController();
  bool _removingUser = false;

  @override
  Widget build(BuildContext context) {
    if (widget.apiIsLoading || _removingUser) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      );
    }

    if (widget.userProfile != null) {
      return Padding(
        key: widget.apiFormKey,
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
        child: Card(
          child: ExpandablePanel(
            theme: ExpandableThemeData(iconColor: context.read<ThemeProvider>().mainText),
            controller: widget.expandableController,
            collapsed: Container(),
            header: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        context.l10n.labelTornApiUserLoaded,
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      "${widget.userProfile!.name} [${widget.userProfile!.playerId}]",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            expanded: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _apiKeyForm(enabled: false),
                          const Padding(
                            padding: EdgeInsetsDirectional.only(top: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: Text(
                                  context.l10n.labelCopy,
                                  style: TextStyle(fontSize: 13),
                                ),
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: widget.userProfile!.userApiKey.toString()),
                                  );
                                  BotToast.showText(
                                    text: context.l10n.labelApiKeyCopiedToTheClipboardBe,
                                    textStyle: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    contentColor: Colors.blue,
                                    duration: const Duration(seconds: 4),
                                    contentPadding: const EdgeInsets.all(10),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ElevatedButton(
                                  child: Text(
                                    context.l10n.labelReload,
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  onPressed: widget.apiKeyInputController.text.trim().isEmpty
                                      ? null
                                      : () {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          if (widget.formKey.currentState!.validate()) {
                                            String myCurrentKey = widget.apiKeyInputController.text.trim();
                                            myCurrentKey = _sanitizeApiKey(myCurrentKey);
                                            widget.getApiDetails(
                                              userTriggered: true,
                                              currentKey: myCurrentKey,
                                            );
                                          }
                                        },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ElevatedButton(
                                  child: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    FocusScope.of(context).requestFocus(FocusNode());
                                    // Removes the form error
                                    widget.formKey.currentState!.reset();
                                    widget.apiKeyInputController.clear();
                                    UserHelper.removeUser();
                                    context.read<InventoryProvider>().clear();
                                    setState(() => _removingUser = !Platform.isWindows);
                                    widget.setStateOnParent();
                                    widget.changeUserProfile(null);
                                    widget.changeApiError(false);

                                    if (!Platform.isWindows) {
                                      await FirestoreHelper().deleteProfileAndSignOut();
                                      if (mounted) setState(() => _removingUser = false);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          _bottomExplanatory(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      widget.expandableController.expanded = true;
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
        child: Card(
          child: ExpandablePanel(
            collapsed: Container(),
            controller: widget.expandableController,
            header: Padding(
              padding: EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        context.l10n.labelNoUserLoaded,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      context.l10n.labelExpandForDetails,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            expanded: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: <Widget>[
                          _apiKeyForm(enabled: true),
                          const Padding(
                            padding: EdgeInsetsDirectional.only(top: 10),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              ElevatedButton(
                                child: Text(context.l10n.labelLoad),
                                onPressed: widget.apiKeyInputController.text.trim().isEmpty
                                    ? null
                                    : () {
                                        FocusScope.of(context).requestFocus(FocusNode());
                                        if (widget.formKey.currentState!.validate()) {
                                          String myCurrentKey = widget.apiKeyInputController.text.trim();
                                          myCurrentKey = _sanitizeApiKey(myCurrentKey);
                                          widget.getApiDetails(
                                            userTriggered: true,
                                            currentKey: myCurrentKey,
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                          _bottomExplanatory(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }

  SizedBox _apiKeyForm({required bool enabled}) {
    return SizedBox(
      width: 300,
      child: Form(
        key: widget.formKey,
        child: TextFormField(
          enabled: enabled,
          validator: (value) {
            if (value!.isEmpty) {
              return context.l10n.labelTheApiKeyIsEmpty;
            }
            return null;
          },
          controller: widget.apiKeyInputController,
          maxLength: 30,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: context.l10n.labelPleaseInsertYourTornApiKey,
            hintStyle: const TextStyle(fontSize: 14),
            counterText: "",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: const BorderSide(
                color: Colors.amber,
              ),
            ),
          ),
          // This is here in case the user submits from the keyboard
          // and not hitting the "Load" button
          onEditingComplete: () {
            FocusScope.of(context).requestFocus(FocusNode());
            if (widget.formKey.currentState!.validate()) {
              String myCurrentKey = widget.apiKeyInputController.text.trim();
              myCurrentKey = _sanitizeApiKey(myCurrentKey);
              widget.getApiDetails(userTriggered: true, currentKey: myCurrentKey);
            }
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _bottomExplanatory() {
    if (widget.apiError) {
      return Padding(
        padding: const EdgeInsets.only(top: 25),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: 15),
              child: Text(
                context.l10n.labelErrorLoadingUser,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text("Error: ${widget.errorReason}"),
            if (widget.errorDetails.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  widget.errorDetails,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      );
    } else if (widget.userProfile == null) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 30, 0, 0),
        child: Column(
          children: <Widget>[
            Text(
              context.l10n.apiUse,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ToS Compliance Table
                      const SizedBox(
                        height: 10,
                      ),
                      Card(
                        shadowColor: Colors.blueGrey,
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ExpandablePanel(
                            theme: ExpandableThemeData(iconColor: context.read<ThemeProvider>().mainText),
                            controller: _tosExpandableController,
                            header: Text(
                              context.l10n.apiTerms,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            collapsed: Text(
                              context.l10n.apiTermsHint,
                            ),
                            expanded: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  child: Table(
                                    border: TableBorder.all(
                                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                                    ),
                                    columnWidths: const <int, TableColumnWidth>{
                                      0: FlexColumnWidth(1),
                                      1: FlexColumnWidth(2),
                                    },
                                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                                    children: <TableRow>[
                                      TableRow(
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                                        ),
                                        children: <Widget>[
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(context.l10n.labelCategory, style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(context.l10n.labelDescription, style: TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      _buildTosTableRow(context.l10n.labelDataStorage,
                                          context.l10n.apiStorage),
                                      _buildTosTableRow(context.l10n.labelDataSharing,
                                          context.l10n.apiSharing),
                                      _buildTosTableRow(context.l10n.labelPurposeOfUse,
                                          context.l10n.apiPurpose),
                                      _buildTosTableRow(context.l10n.labelKeyStorageSharing,
                                          context.l10n.apiKeyStorage),
                                      _buildTosTableRow(context.l10n.labelKeyAccessLevel, context.l10n.labelLimitedAccess),
                                    ],
                                  ),
                                ),
                                Text(
                                  context.l10n.apiPrivacy,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Text(
                        context.l10n.apiInstructions,
                      ),
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: <InlineSpan>[
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () {
                                  const url = 'https://www.torn.com/preferences.php#tab=api';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                                onLongPress: () {
                                  const url = 'https://www.torn.com/preferences.php#tab=api';
                                  context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.long,
                                      );
                                },
                                child: Text(
                                  context.l10n.labelTapHere,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: context.l10n.labelToBeRedirected,
                              style: DefaultTextStyle.of(context).style,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(context.l10n.apiProtect),
            Text(context.l10n.apiRemove),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: <Widget>[
            Text(
              "${widget.userProfile!.name} [${widget.userProfile!.playerId}]",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text("Gender: ${widget.userProfile!.gender}"),
            Text("Level: ${widget.userProfile!.level}"),
            Text("Life: ${widget.userProfile!.life!.current}"),
            Text("Status: ${widget.userProfile!.status!.description}"),
            Text("Last action: ${widget.userProfile!.lastAction!.relative}"),
            Text("Rank: ${widget.userProfile!.rank}"),
          ],
        ),
      );
    }
  }

  String _sanitizeApiKey(String myCurrentKey) {
    String allowedChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    myCurrentKey = myCurrentKey.replaceAll(RegExp('[^$allowedChars]+'), '');
    return myCurrentKey;
  }

  TableRow _buildTosTableRow(String title, String content) {
    return TableRow(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(content),
        ),
      ],
    );
  }
}
