// Dart imports:
import 'package:torn_pda/l10n/app_language.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:io';

// Flutter imports:
import 'package:android_intent_plus/android_intent.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dart_ping/dart_ping.dart';
// Package imports:
import 'package:device_info_plus/device_info_plus.dart';
import 'package:expandable/expandable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/oc/ts_members_model.dart';
import 'package:torn_pda/models/profile/own_profile_basic.dart';
import 'package:torn_pda/pages/profile/shortcuts_page.dart';
import 'package:torn_pda/pages/settings/app_icon_menu_page.dart';
import 'package:torn_pda/pages/settings/alternative_keys_page.dart';
import 'package:torn_pda/pages/chat/chat_settings_page.dart';
import 'package:torn_pda/pages/settings/drawer_sections_page.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';
import 'package:torn_pda/widgets/player_notes_list_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_local/prefs_backup_section.dart';
import 'package:torn_pda/pages/settings/settings_browser.dart';
import 'package:torn_pda/pages/settings/split_links_examples_page.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';
import 'package:torn_pda/providers/inventory_provider.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/models/discreet_schedule.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/torn-pda-native/auth/native_login_widget.dart';
import 'package:torn_pda/torn-pda-native/stats/stats_controller.dart';
import 'package:torn_pda/utils/appwidget/pda_widget.dart';
import 'package:torn_pda/utils/firebase_auth.dart';
import 'package:torn_pda/utils/firebase_firestore.dart';
import 'package:torn_pda/utils/notification.dart';
import 'package:torn_pda/utils/alarm_kit_service_ios.dart';
import 'package:torn_pda/utils/time_formatter.dart';
import 'package:torn_pda/models/chaining/war_settings.dart';
import 'package:torn_pda/models/drawer_section.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/alerts/discreet_info.dart';
import 'package:torn_pda/widgets/settings/api_auth_widget.dart';
import 'package:torn_pda/widgets/settings/api_error_history_dialog.dart';
import 'package:torn_pda/widgets/settings/applinks_browser_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_delete_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_restore_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_save_dialog.dart';
import 'package:torn_pda/widgets/settings/backup_online/backup_share_dialog.dart';
import 'package:torn_pda/widgets/settings/browser_info_dialog.dart';
import 'package:torn_pda/widgets/settings/reviving_services_dialog.dart';
import 'package:torn_pda/widgets/spies/spies_management_dialog.dart';
import 'package:torn_pda/widgets/stats/ffscouter_info.dart';
import 'package:torn_pda/providers/ffscouter_cache_controller.dart';
import 'package:torn_pda/providers/ffscouter_notes_controller.dart';
import 'package:torn_pda/providers/ffscouter_premium_controller.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:vibration/vibration.dart';

class SettingsPage extends StatefulWidget {
  final StatsController statsController;

  const SettingsPage({
    required this.statsController,
    super.key,
  });

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  Timer? _ticker;

  bool _apiError = false;
  String _errorReason = '';
  String _errorDetails = '';
  bool _apiIsLoading = false;
  OwnProfileBasic? _userProfile;

  Future? _preferencesRestored;

  String? _openSectionValue;
  String? _onAppExitValue;
  String? _openBrowserValue;
  String? _timeFormatValue;
  String? _timeZoneValue;
  String? _vibrationValue;
  late bool _manualAlarmSound;
  late bool _manualAlarmVibration;
  late bool _removeNotificationsLaunch;

  late SettingsProvider _settingsProvider;

  late ThemeProvider _themeProvider;
  late ShortcutsProvider _shortcutsProvider;
  late WebViewProvider _webViewProvider;
  final ApiCallerController _apiController = Get.find<ApiCallerController>();
  final SpiesController _spyController = Get.find<SpiesController>();

  final _expandableController = ExpandableController();

  final _apiKeyInputController = TextEditingController();

  String? _appBarPosition = "top";

  int _androidSdk = 0;

  double _extraMargin = 0.0;

  final _apiFormKey = GlobalKey<FormState>();

  // Refresh rate control
  Map<String, dynamic> _refreshRateInfo = {};
  bool _isUpdatingRefreshRate = false;

  Future<List<Map<String, dynamic>>>? _iosAlarmsFuture;

  // SEARCH ##########
  bool _isSearching = false;
  bool _inventoryAutoLoad = false;
  String _searchText = '';
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  List<Widget> buildFilteredSections() {
    List<Widget> sections = [
      buildSectionWithRows(
        title: context.l10n.appLanguage,
        searchText: _searchText,
        rows: [
          SearchableRow(
            label: '${context.l10n.appLanguage} Language 简体中文 English',
            searchText: _searchText,
            child: const AppLanguageTile(),
          ),
        ],
      ),
      _browserSection(),
      _chatSection(),
      _shortcutsSection(),
      _timeSection(),
      _notificationsSection(),
      if (Platform.isAndroid || Platform.isIOS) _appWidgetSection(),
      if (Platform.isAndroid && Get.find<PipController>().supported) _floatingWindowSection(),
      _spiesSection(),
      _playerNotesSection(),
      _ffScouterSection(),
      _yataSection(),
      _ocSection(),
      _revivingServicesSection(),
      _screenConfigurationSection(),
      _themeSection(),
      if (Platform.isIOS) _appIconSection(),
      _miscSection(),
      _externalPartnersSection(),
      _apiRateSection(),
      _saveSettingsOnlineSection(),
      _saveSettingsLocalSection(),
      _troubleshootingSection(),
    ];

    // Filter out empty sections
    sections = sections.where((widget) => widget is! SizedBox).toList();

    if (sections.isEmpty) return sections;

    // If only one section is visible, return it without any divider
    if (sections.length == 1) return sections;

    List<Widget> finalSections = [];
    for (int i = 0; i < sections.length; i++) {
      if (i > 0) {
        finalSections.add(
          const Column(
            children: [
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 10),
            ],
          ),
        );
      }

      finalSections.add(sections[i]);
    }
    return finalSections;
  }
  // SEARCH ENDS ##########

  @override
  void initState() {
    super.initState();

    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    _preferencesRestored = _restorePreferences();
    _loadRefreshRateInfo();

    routeWithDrawer = true;
    routeName = "settings";
  }

  void _refreshIosAlarms() {
    setState(() {
      _iosAlarmsFuture = AlarmKitServiceIos.listAlarms();
    });
  }

  Future<void> _clearAllIosAlarms() async {
    await AlarmKitServiceIos.cancelAllAlarms();
    _refreshIosAlarms();
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      leadingWidth: _isSearching ? 56 : (_webViewProvider.appCanOpenBrowser ? 88 : 50),
      leading: !_isSearching
          ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
                    if (scaffoldState != null) {
                      if (_webViewProvider.splitScreenAndBrowserLeft()) {
                        scaffoldState.openEndDrawer();
                      } else {
                        scaffoldState.openDrawer();
                      }
                    }
                  },
                ),
                if (_webViewProvider.appCanOpenBrowser) const PdaBrowserIcon(),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchText = '';
                  FocusScope.of(context).unfocus();
                });
              },
            ),
      title: _isSearching
          ? Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: context.l10n.searchSettings,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (text) {
                  setState(() {
                    _searchText = text;
                  });
                },
              ),
            )
          : Text(context.l10n.settings, style: TextStyle(color: Colors.white)),
      actions: _isSearching
          ? [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                  },
                ),
            ]
          : [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });
                  Future.delayed(const Duration(milliseconds: 50), () {
                    FocusScope.of(context).requestFocus(_searchFocusNode);
                  });
                },
              ),
            ],
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _expandableController.dispose();
    _apiKeyInputController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: FutureBuilder(
          future: _preferencesRestored,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      SizedBox(height: _extraMargin),
                      if (!_isSearching)
                        ApiKeySectionWidget(
                          apiIsLoading: _apiIsLoading,
                          userProfile: _userProfile,
                          apiError: _apiError,
                          errorReason: _errorReason,
                          errorDetails: _errorDetails,
                          formKey: _formKey,
                          apiFormKey: _apiFormKey,
                          apiKeyInputController: _apiKeyInputController,
                          expandableController: _expandableController,
                          getApiDetails: _getApiDetails,
                          setStateOnParent: () => setState(() {}),
                          changeApiError: (val) => setState(() => _apiError = val),
                          changeUserProfile: (val) => setState(() => _userProfile = val),
                        ),
                      //if (_userProfile != null && !_isSearching)
                      const Column(
                        children: [
                          NativeLoginWidget(),
                          SizedBox(height: 15),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ...buildFilteredSections(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _browserSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelWebBrowser,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(context.l10n.labelWebBrowser)),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      showDialog(
                        useRootNavigator: false,
                        context: context,
                        builder: (BuildContext context) {
                          return BrowserInfoDialog();
                        },
                      );
                    },
                  ),
                ],
              ),
              _openBrowserDropdown(),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelAdvancedBrowserSettings,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.labelAdvancedBrowserSettings),
              IconButton(
                icon: const Icon(MdiIcons.web),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'settings_browser'),
                      builder: (BuildContext context) => const SettingsBrowserPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: context.l10n.browserGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _chatSection() {
    if (!NativeChat.compiled) return const SizedBox.shrink();
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelChatSettings,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.labelChatSettings),
              IconButton(
                icon: const Icon(Icons.forum_rounded),
                onPressed: () => showChatSettingsFrom(context),
              ),
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: context.l10n.chatGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _shortcutsSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelConfigureShortcuts,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.labelConfigureShortcuts),
              IconButton(
                icon: const Icon(Icons.switch_access_shortcut_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'shortcuts'),
                      builder: (BuildContext context) => ShortcutsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelAppIconMenu,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.labelAppIconMenu),
              IconButton(
                icon: const Icon(Icons.apps_rounded),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'app_icon_menu'),
                      builder: (BuildContext context) => const AppIconMenuPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelUseProfileSectionShortcuts,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.labelUseProfileSectionShortcuts),
                  Switch(
                    value: _settingsProvider.shortcutsEnabledProfile,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.shortcutsEnabledProfile = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.shortcutDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      if (_settingsProvider.shortcutsEnabledProfile)
        SearchableRow(
          label: context.l10n.labelProfileShortcutsMenu,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(context.l10n.labelProfileShortcutsMenu)),
                Flexible(child: _shortcutMenuDropdown()),
              ],
            ),
          ),
        ),
      if (_settingsProvider.shortcutsEnabledProfile)
        SearchableRow(
          label: context.l10n.labelProfileTileType,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(context.l10n.labelProfileTileType)),
                Flexible(child: _shortcutTileDropdown()),
              ],
            ),
          ),
        ),
      if (_settingsProvider.shortcutsEnabledProfile)
        SearchableRow(
          label: context.l10n.labelShowShortcutsEditIcon,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 30, right: 20, top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelShowShortcutsEditIcon)),
                    Switch(
                      value: _settingsProvider.showShortcutEditIcon,
                      onChanged: (value) {
                        setState(() {
                          _settingsProvider.showShortcutEditIcon = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  context.l10n.shortcutEditDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: context.l10n.shortcutsGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _timeSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelTimeFormat,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelTimeFormat)),
              Flexible(child: _timeFormatDropdown()),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelTimeZone,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelTimeZone)),
              Flexible(flex: 2, child: _timeZoneDropdown()),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelShowDateInClock,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelShowDateInClock)),
                  Flexible(flex: 2, child: _dateInClockDropdown()),
                ],
              ),
              Text(
                context.l10n.clockDateDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelSecondsInClock,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelSecondsInClock)),
              Flexible(flex: 2, child: _secondsInClockDropdown()),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelHighlightEvents,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelHighlightEvents)),
                  Switch(
                    value: _settingsProvider.tctClockHighlightsEvents,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.tctClockHighlightsEvents = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.clockEventDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: context.l10n.timeGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  bool get _h12 => _settingsProvider.currentTimeFormat == TimeFormatSetting.h12;

  Widget _discreetHourLabel(int minutes) {
    final at = DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60);
    return Text(DateFormat(_h12 ? 'h:mm a' : 'HH:mm').format(at));
  }

  Future<void> _pickDiscreetHour({required bool from}) async {
    final current = _settingsProvider.discreetSchedule;
    final minutes = from ? current.from : current.to;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: !_h12),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final value = picked.hour * 60 + picked.minute;
    setState(() {
      _settingsProvider.discreetSchedule = DiscreetSchedule(
        enabled: current.enabled,
        from: from ? value : current.from,
        to: from ? current.to : value,
      );
    });
  }

  Widget _notificationsSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelDiscreetLocalNotifications,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Flexible(child: Text(context.l10n.labelDiscreetLocalNotifications)),
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        showDialog(
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) {
                            return DiscreetInfo();
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              Switch(
                value: _settingsProvider.discreetNotificationsOption,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.discreetNotifications = value;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelDiscreetSchedule,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelSchedule)),
                  Switch(
                    value: _settingsProvider.discreetSchedule.enabled,
                    onChanged: (value) {
                      final current = _settingsProvider.discreetSchedule;
                      setState(() {
                        _settingsProvider.discreetSchedule = DiscreetSchedule(
                          enabled: value,
                          from: current.from,
                          to: current.to,
                        );
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              if (_settingsProvider.discreetSchedule.enabled) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.l10n.labelFrom),
                    TextButton(
                      onPressed: () => _pickDiscreetHour(from: true),
                      child: _discreetHourLabel(_settingsProvider.discreetSchedule.from),
                    ),
                    Text(context.l10n.labelTo),
                    TextButton(
                      onPressed: () => _pickDiscreetHour(from: false),
                      child: _discreetHourLabel(_settingsProvider.discreetSchedule.to),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    context.l10n.discreetScope,
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      if (Platform.isAndroid)
        SearchableRow(
          label: context.l10n.labelRemoveNotificationsOnLaunch,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelRemoveNotificationsOnLaunch)),
                    Switch(
                      value: _removeNotificationsLaunch,
                      onChanged: (value) {
                        _settingsProvider.changeRemoveNotificationsOnLaunch = value;
                        setState(() {
                          _removeNotificationsLaunch = value;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  context.l10n.clearNotificationsDescription,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                )
              ],
            ),
          ),
        ),
      if (Platform.isAndroid)
        SearchableRow(
          label: context.l10n.labelAlertsVibration,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelAlertsVibration)),
                    Flexible(flex: 2, child: _vibrationDropdown()),
                  ],
                ),
                Text(
                  context.l10n.vibrationDescription,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      if (Platform.isAndroid)
        SearchableRow(
          label: context.l10n.labelManualAlarmSound,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.labelManualAlarmSound),
                Switch(
                  value: _manualAlarmSound,
                  onChanged: (value) {
                    setState(() {
                      _manualAlarmSound = value;
                    });
                    Prefs().setManualAlarmSound(value);
                  },
                  activeTrackColor: Colors.lightGreenAccent,
                  activeThumbColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      if (Platform.isAndroid)
        SearchableRow(
          label: context.l10n.labelManualAlarmVibration,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.l10n.labelManualAlarmVibration),
                    Switch(
                      value: _manualAlarmVibration,
                      onChanged: (value) {
                        setState(() {
                          _manualAlarmVibration = value;
                        });
                        Prefs().setManualAlarmVibration(value);
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    text:
                        context.l10n.alarmClockDescription,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                    children: <TextSpan>[
                      TextSpan(
                        text: context.l10n.googleClock,
                        style: const TextStyle(color: Colors.blue),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const AndroidIntent intent = AndroidIntent(
                              action: 'action_view',
                              data: 'https://play.google.com/store/apps/details?id=com.google.android.deskclock',
                            );
                            await intent.launch();
                          },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      if (Platform.isIOS)
        SearchableRow(
          label: context.l10n.labelActiveAlarms,
          searchText: _searchText,
          child: FutureBuilder<bool>(
            future: AlarmKitServiceIos.isAvailable(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!) {
                return const SizedBox.shrink();
              }
              _iosAlarmsFuture ??= AlarmKitServiceIos.listAlarms();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(context.l10n.labelActiveAlarms, style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          tooltip: context.l10n.labelWhatIsThis,
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(context.l10n.labelActiveAlarmsSetting),
                                content: Text(
                                  context.l10n.alarmListDescription,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text(context.l10n.labelGotIt),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.refresh, size: 18),
                          tooltip: context.l10n.labelRefresh,
                          onPressed: _refreshIosAlarms,
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          tooltip: context.l10n.labelClearAll,
                          onPressed: () async {
                            await _clearAllIosAlarms();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _iosAlarmsFuture,
                      builder: (context, alarmSnapshot) {
                        if (alarmSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!alarmSnapshot.hasData || alarmSnapshot.data!.isEmpty) {
                          return Text(context.l10n.labelNoActiveAlarms);
                        }
                        return Column(
                          children: alarmSnapshot.data!.map((alarm) {
                            final display = AlarmKitServiceIos.displayInfoFromAlarm(alarm);
                            final scheduledMillis = alarm['scheduledMillis'] as int?;
                            DateTime? scheduledTime;
                            if (scheduledMillis != null) {
                              scheduledTime = DateTime.fromMillisecondsSinceEpoch(scheduledMillis);
                            } else {
                              final hour = alarm['hour'] as int?;
                              final minute = alarm['minute'] as int?;
                              if (hour != null && minute != null) {
                                final now = DateTime.now();
                                scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
                                if (scheduledTime.isBefore(DateTime.now())) {
                                  scheduledTime = scheduledTime.add(const Duration(days: 1));
                                }
                              }
                            }

                            String timeString = '';
                            if (scheduledTime != null) {
                              timeString = TimeFormatter(
                                inputTime: scheduledTime,
                                timeFormatSetting: _settingsProvider.currentTimeFormat,
                                timeZoneSetting: _settingsProvider.currentTimeZone,
                              ).formatHourWithSeconds();
                            }

                            String? detailsText = display.details;
                            if (detailsText != null && detailsText.toLowerCase().startsWith('triggers at')) {
                              detailsText = null; // Avoid repeating the scheduled time twice
                            }

                            return Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.green[700],
                                  child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                                ),
                                title: Text(display.label),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (timeString.isNotEmpty)
                                      Text(
                                        timeString,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    if (detailsText != null)
                                      Text(
                                        detailsText,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await AlarmKitServiceIos.cancelAlarm(alarm['id']);
                                    _refreshIosAlarms();
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ];
    return buildSectionWithRows(
      title: context.l10n.notificationsGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _appWidgetSection() {
    final destinationRow = SearchableRow(
      label: context.l10n.labelCooldownTapDestination,
      searchText: _searchText,
      child: _appWidgetCooldownTapDestinationSelector(),
    );
    if (Platform.isIOS) {
      return buildSectionWithRows(title: context.l10n.homeWidgetGroup, rows: [destinationRow], searchText: _searchText);
    }

    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelDarkMode,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelDarkMode)),
              Switch(
                value: _settingsProvider.appwidgetDarkMode,
                onChanged: (value) {
                  setState(() {
                    _settingsProvider.appwidgetDarkMode = value;
                    HomeWidget.saveWidgetData<bool>('darkMode', value);
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelRemoveShortcutsFromShortLayout,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelRemoveShortcutsFromShortLayout)),
                  Switch(
                    value: _settingsProvider.appwidgetRemoveShortcutsOneRowLayout,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.appwidgetRemoveShortcutsOneRowLayout = value;
                        HomeWidget.saveWidgetData<bool>('removeShortcutsOneRowLayout', value);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.compactWidgetDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelShowWalletMoney,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelShowWalletMoney)),
                  Switch(
                    value: _settingsProvider.appwidgetMoneyEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.appwidgetMoneyEnabled = value;
                        HomeWidget.saveWidgetData<bool>('money_enabled', value);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                'This is only applicable for the tall widget layout',
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelCooldownTapLaunchesBrowser,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelCooldownTapLaunchesBrowser)),
                  Switch(
                    value: _settingsProvider.appwidgetCooldownTapOpenBrowser,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.appwidgetCooldownTapOpenBrowser = value;
                        HomeWidget.saveWidgetData<bool>('cooldown_tap_opens_browser', value);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.cooldownWidgetDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.appwidgetCooldownTapOpenBrowser) destinationRow,
      SearchableRow(
        label: context.l10n.labelRacingTapOpensBrowser,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelRacingTapOpensBrowser)),
                  Switch(
                    value: _settingsProvider.appwidgetRacingTapOpenBrowser,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.appwidgetRacingTapOpenBrowser = value;
                        HomeWidget.saveWidgetData<bool>('racing_tap_opens_browser', value);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.racingWidgetDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: context.l10n.homeWidgetGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _floatingWindowSection() {
    SearchableRow row(String label, String hint, bool value, void Function(bool)? onChanged, {double indent = 20}) {
      return SearchableRow(
        label: label,
        searchText: _searchText,
        child: Padding(
          padding: EdgeInsets.only(left: indent, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(label)),
                  Switch(
                    value: value,
                    onChanged: onChanged == null
                        ? null
                        : (on) {
                            setState(() => onChanged(on));
                            Get.find<PipController>().syncAutoEnter();
                          },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              if (hint.isNotEmpty)
                Text(hint, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      );
    }

    final enabled = _settingsProvider.pipEnabled;
    List<SearchableRow> rows = [
      row(
        context.l10n.labelFloatingWindow,
        context.l10n.labelOffHidesEveryFloatingWindowButton,
        enabled,
        (value) => _settingsProvider.pipEnabled = value,
      ),
      row(
        context.l10n.labelChainWidgetButton,
        "",
        _settingsProvider.pipChainButton,
        enabled ? (value) => _settingsProvider.pipChainButton = value : null,
        indent: 40,
      ),
      row(
        context.l10n.labelPlayerListsButton,
        context.l10n.labelTargetsWarRetalsAttacksFfscouter,
        _settingsProvider.pipPlayerButtons,
        enabled ? (value) => _settingsProvider.pipPlayerButtons = value : null,
        indent: 40,
      ),
      row(
        context.l10n.labelStakeoutsButton,
        "",
        _settingsProvider.pipStakeoutsButton,
        enabled ? (value) => _settingsProvider.pipStakeoutsButton = value : null,
        indent: 40,
      ),
      row(
        context.l10n.labelOpenWhenLeavingTheAppWithThe,
        context.l10n.labelNoButtonNeeded,
        _settingsProvider.pipAutoEnter,
        enabled ? (value) => _settingsProvider.pipAutoEnter = value : null,
        indent: 40,
      ),
    ];
    return buildSectionWithRows(
      title: context.l10n.floatingGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _spiesSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelSpiesSource,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelSpiesSource)),
                  Flexible(flex: 2, child: _spiesSourceDropdown()),
                ],
              ),
              Text(
                context.l10n.spiesDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelSpies,
        searchText: _searchText,
        child: GetBuilder<SpiesController>(
          builder: (s) {
            String lastUpdated = "Never updated";
            int lastUpdatedTs = 0;
            if (_spyController.spiesSource == SpiesSource.yata && _spyController.yataSpiesTime != null) {
              lastUpdatedTs = _spyController.yataSpiesTime!.millisecondsSinceEpoch;
              if (lastUpdatedTs > 0) {
                lastUpdated = _spyController.statsOld((lastUpdatedTs / 1000).round());
              }
            } else if (_spyController.spiesSource == SpiesSource.tornStats &&
                _spyController.tornStatsSpiesTime != null) {
              lastUpdatedTs = _spyController.tornStatsSpiesTime!.millisecondsSinceEpoch;
              if (lastUpdatedTs > 0) {
                lastUpdated = _spyController.statsOld((lastUpdatedTs / 1000).round());
              }
            }
            Color spiesUpdateColor = Colors.blue;
            if (lastUpdatedTs > 0) {
              final currentTime = DateTime.now().millisecondsSinceEpoch;
              final oneMonthAgo = currentTime - (30.44 * 24 * 60 * 60 * 1000).round();
              spiesUpdateColor = (lastUpdatedTs < oneMonthAgo) ? Colors.red : context.read<ThemeProvider>().mainText;
            }
            return Padding(
              padding: const EdgeInsets.only(top: 15, left: 40),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(MdiIcons.accountMultipleOutline, size: 18),
                      ),
                      Text(
                        "${s.spiesSource == SpiesSource.yata ? 'YATA' : 'Torn Stats'} database: ${s.spiesSource == SpiesSource.yata ? s.yataSpies.length : s.tornStatsSpies.spies.length} spies",
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(MdiIcons.clockOutline, size: 18),
                      ),
                      Text(lastUpdated, style: TextStyle(color: spiesUpdateColor)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      SearchableRow(
        label: context.l10n.labelManageSpies,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelManageSpies)),
              IconButton(
                icon: const Icon(MdiIcons.incognito),
                onPressed: () {
                  showDialog(
                    barrierDismissible: false,
                    useRootNavigator: false,
                    context: context,
                    builder: (BuildContext context) {
                      return SpiesManagementDialog();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelAllowMixedSources,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelAllowMixedSources)),
                  Switch(
                    value: _spyController.allowMixedSpiesSources,
                    onChanged: (enabled) {
                      setState(() {
                        _spyController.allowMixedSpiesSources = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.mixedSourcesDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelDeleteSpies,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelDeleteSpies)),
                  ElevatedButton(
                    child: const Icon(Icons.delete_outlined),
                    onPressed: () async {
                      _spyController.deleteSpies();
                      BotToast.showText(
                        text: "Spies deleted!",
                        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                        contentColor: Colors.blue,
                        duration: const Duration(seconds: 1),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    },
                  ),
                ],
              ),
              Text(
                context.l10n.deleteSpiesDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: context.l10n.spiesGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  void _showFFScouterPremiumFeaturesDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.l10n.labelFfscouterPremiumFeatures, style: TextStyle(fontSize: 16)),
          content: GetBuilder<FFScouterPremiumController>(
            builder: (p) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.labelStatDistribution),
                  value: p.distributionEnabled,
                  onChanged: (v) => p.distributionEnabled = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.labelTravelLandingTimers),
                  value: p.flightsEnabled,
                  onChanged: (v) => p.flightsEnabled = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.labelActivityTracker),
                  value: p.activityEnabled,
                  onChanged: (v) => p.activityEnabled = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.labelHitCalling),
                  subtitle: Text(context.l10n.labelCallWarTargetsForYourFaction, style: TextStyle(fontSize: 12)),
                  value: p.hitCallingEnabled,
                  onChanged: (v) => p.hitCallingEnabled = v,
                ),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(context.l10n.labelClose))],
        );
      },
    );
  }

  Widget _playerNotesSection() {
    List<SearchableRow> rows = [];

    // Player Notes Manager
    rows.add(
      SearchableRow(
        label: context.l10n.labelPlayerNotes,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.labelPlayerNotesDatabase,
                      style: TextStyle(
                        color: _themeProvider.mainText,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const PlayerNotesListDialog(),
                      );
                    },
                    child: Text(context.l10n.labelManageNotes),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.playerNotesDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return buildSectionWithRows(
      title: context.l10n.playerNotesGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _ffScouterSection() {
    List<SearchableRow> rows = [];

    // FFScouter Block
    if (_settingsProvider.ffScouterEnabledStatusRemoteConfig) {
      rows.add(
        SearchableRow(
          label: context.l10n.labelUseFfscouter,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(child: Text(context.l10n.labelUseFfscouter)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            child: const Icon(Icons.info_outline, size: 18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FFScouterInfoPage(
                                    settingsProvider: _settingsProvider,
                                    themeProvider: _themeProvider,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _settingsProvider.ffScouterEnabledStatus == 1,
                      onChanged: (enabled) async {
                        if (_settingsProvider.ffScouterEnabledStatus != 1) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FFScouterInfoPage(
                                settingsProvider: _settingsProvider,
                                themeProvider: _themeProvider,
                              ),
                            ),
                          );
                          if (_settingsProvider.ffScouterEnabledStatus == 1) {
                            setState(() {}); // Force update
                          }
                        } else {
                          setState(() {
                            _settingsProvider.ffScouterEnabledStatus = 0;
                          });
                        }
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  context.l10n.scouterDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (_settingsProvider.ffScouterEnabledStatus == 1) ...[
                  _ffScouterStatusLine(),
                  const FFScouterPolicyNotice(),
                ],
              ],
            ),
          ),
        ),
      );
    } else {
      rows.add(
        SearchableRow(
          label: context.l10n.labelUseFfscouter,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Text(
              context.l10n.labelFfscouterTemporarilyDeactivated,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    // FFScouter premium features, opened via a sync/check
    if (_settingsProvider.ffScouterEnabledStatusRemoteConfig && _settingsProvider.ffScouterEnabledStatus == 1) {
      rows.add(
        SearchableRow(
          label: context.l10n.labelFfscouterPremiumFeatures,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 32, top: 0, right: 20, bottom: 5),
            child: GetBuilder<FFScouterPremiumController>(
              builder: (ffsPremium) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelPremiumFeatures)),
                  if (ffsPremium.isPremium)
                    OutlinedButton.icon(
                      onPressed: _showFFScouterPremiumFeaturesDialog,
                      icon: const Icon(Icons.tune, size: 16),
                      label: Text(context.l10n.labelSelect),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ffsPremium.refreshPremiumStatus(force: true);
                        if (!mounted) return;
                        if (ffsPremium.isPremium) {
                          _showFFScouterPremiumFeaturesDialog();
                        } else {
                          BotToast.showText(text: "No active FFScouter premium found for your key");
                        }
                      },
                      icon: const Icon(Icons.sync, size: 16),
                      label: Text(context.l10n.labelSync),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // FFScouter shared notes
    if (_settingsProvider.ffScouterEnabledStatusRemoteConfig &&
        _settingsProvider.ffScouterEnabledStatus == 1 &&
        Get.find<FFScouterNotesController>().remoteConfigEnabled) {
      rows.add(
        SearchableRow(
          label: context.l10n.labelFfscouterSharedNotes,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 32, top: 0, right: 20, bottom: 5),
            child: GetBuilder<FFScouterNotesController>(
              builder: (notes) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text(context.l10n.labelSharedNotes)),
                      Switch(
                        value: notes.enabled,
                        onChanged: (enabled) {
                          notes.enabled = enabled;
                          if (enabled) notes.resetKeyProblem();
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeThumbColor: Colors.green,
                      ),
                    ],
                  ),
                  Text(
                    context.l10n.scouterNotesDescription,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (notes.enabled) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text(context.l10n.labelNoteShownOnCards)),
                        DropdownButton<bool>(
                          value: notes.preferOnCards,
                          items: const [
                            DropdownMenuItem(value: false, child: Text("Torn PDA", style: TextStyle(fontSize: 14))),
                            DropdownMenuItem(value: true, child: Text("FFScouter", style: TextStyle(fontSize: 14))),
                          ],
                          onChanged: (value) => notes.preferOnCards = value ?? false,
                        ),
                      ],
                    ),
                    Text(
                      context.l10n.preferredNotesDescription,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // FFScouter Bounty Board
    if (_settingsProvider.ffScouterEnabledStatusRemoteConfig &&
        _settingsProvider.ffScouterEnabledStatus == 1 &&
        _settingsProvider.ffScouterBountiesEnabledRemoteConfig) {
      rows.add(
        SearchableRow(
          label: context.l10n.labelFfscouterBountyBoard,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 32, top: 0, right: 20, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelBountyBoard)),
                    Switch(
                      value: _settingsProvider.ffScouterBountiesEnabled,
                      onChanged: (enabled) {
                        setState(() {
                          _settingsProvider.ffScouterBountiesEnabled = enabled;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  context.l10n.bountyBoardDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // FFScouter: prefer BS estimates over range-based estimates
    if (_settingsProvider.ffScouterEnabledStatusRemoteConfig && _settingsProvider.ffScouterEnabledStatus == 1) {
      rows.add(
        SearchableRow(
          label: context.l10n.labelPreferFfscouterBattleScore,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 32, top: 0, right: 20, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(context.l10n.labelPreferFfscouterBattleScore),
                    ),
                    Switch(
                      value: _settingsProvider.preferFFScouterOverEstimated,
                      onChanged: (enabled) {
                        setState(() {
                          _settingsProvider.preferFFScouterOverEstimated = enabled;
                          if (!enabled) {
                            Get.find<FFScouterCacheController>().clearCache();
                          }
                          if (Get.isRegistered<WarController>()) {
                            Get.find<WarController>().reloadFFScouterSettings();
                          }
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  context.l10n.battleScoreDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (_settingsProvider.preferFFScouterOverEstimated) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _settingsProvider.ffsOverrideSpyMonths == 0
                              ? "Override old spies: Off"
                              : "Override spies older than ${_settingsProvider.ffsOverrideSpyMonths} month${_settingsProvider.ffsOverrideSpyMonths == 1 ? '' : 's'}",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _settingsProvider.ffsOverrideSpyMonths.toDouble(),
                    min: 0,
                    max: 12,
                    divisions: 12,
                    label: _settingsProvider.ffsOverrideSpyMonths == 0
                        ? context.l10n.labelOff
                        : "${_settingsProvider.ffsOverrideSpyMonths}m",
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.ffsOverrideSpyMonths = value.round();
                        if (Get.isRegistered<WarController>()) {
                          Get.find<WarController>().reloadFFScouterSettings();
                        }
                      });
                    },
                  ),
                  Text(
                    context.l10n.staleSpiesDescription,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return buildSectionWithRows(
      title: "FFSCOUTER",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _ffScouterStatusLine() {
    return GetBuilder<FFScouterPremiumController>(
      builder: (premium) {
        final dedicatedKey = Get.find<UserController>().alternativeFFScouterKeyEnabled;
        final keyProblem =
            Get.find<FFScouterCacheController>().keyNotRegistered || Get.find<FFScouterNotesController>().keyProblem;
        final status = [
          dedicatedKey ? context.l10n.labelDedicatedFfscouterKey : context.l10n.labelUsingYourTornPdaKey,
          if (premium.isPremium) context.l10n.labelPremium,
        ].join(" · ");
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(
                keyProblem ? Icons.error_outline : Icons.check_circle_outline,
                size: 14,
                color: keyProblem ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  keyProblem ? context.l10n.labelYourKeyIsNotRegisteredWithFfscouter : status,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (keyProblem)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FFScouterInfoPage(
                        settingsProvider: _settingsProvider,
                        themeProvider: _themeProvider,
                        jumpToKeySetup: true,
                      ),
                    ),
                  ),
                  child: Text(context.l10n.labelRegister, style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _yataSection() {
    List<SearchableRow> rows = [];

    // YATA Block
    if (_settingsProvider.yataStatsEnabledStatusRemoteConfig) {
      rows.add(
        SearchableRow(
          label: context.l10n.labelUseYataStatsEstimates,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Flexible(child: Text(context.l10n.labelUseYataStatsEstimates)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _settingsProvider.yataStatsEnabledStatus == 1,
                      onChanged: (enabled) async {
                        setState(() {
                          _settingsProvider.yataStatsEnabledStatus = enabled ? 1 : 0;
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                Text(
                  context.l10n.yataEstimateDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      rows.add(
        SearchableRow(
          label: context.l10n.labelUseYataStatsEstimates,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Text(
              context.l10n.labelYataStatsTemporarilyDeactivated,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    return buildSectionWithRows(
      title: "YATA",
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _ocSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelNerveBarSource,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelNerveBarSource)),
                  Flexible(flex: 2, child: _naturalNerveBarSourceDropdown()),
                ],
              ),
              Text(
                context.l10n.nerveSourceDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelOrganizedCrimesV2InUse,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [Flexible(child: Text(context.l10n.labelOrganizedCrimesV2InUse))],
                    ),
                  ),
                  Switch(
                    value: _settingsProvider.playerInOCv2,
                    onChanged: (enabled) async {
                      setState(() {
                        _settingsProvider.playerInOCv2 = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.organizedCrimesDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: context.l10n.crimesGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _revivingServicesSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelChooseRevivingProviders,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.labelChooseRevivingProviders),
                  IconButton(
                    icon: const Icon(MdiIcons.hospitalBoxOutline),
                    color: _themeProvider.getTextColor(Colors.red.shade600),
                    onPressed: () {
                      showDialog(
                        useRootNavigator: false,
                        context: context,
                        builder: (BuildContext context) {
                          return RevivingServicesDialog();
                        },
                      );
                    },
                  ),
                ],
              ),
              Text(
                context.l10n.revivingDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: context.l10n.reviveGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _screenConfigurationSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelAllowAutoRotation,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelAllowAutoRotation)),
                  Switch(
                    value: _settingsProvider.allowScreenRotation,
                    onChanged: (value) {
                      setState(() {
                        _settingsProvider.changeAllowScreenRotation = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.rotationDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelSplitScreen,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelSplitScreen)),
                  Flexible(flex: 2, child: _splitScreenDropdown()),
                ],
              ),
              Text(
                context.l10n.splitScreenDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (!_settingsProvider.allowScreenRotation &&
                  _webViewProvider.splitScreenPosition != WebViewSplitPosition.off)
                Text(
                  context.l10n.splitRotationDescription,
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelSplitRevertsTo,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelSplitRevertsTo)),
                  Flexible(flex: 2, child: _splitScreenRevertionDropdown()),
                ],
              ),
              Text(
                context.l10n.splitExitDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.useTabsFullBrowser &&
          _webViewProvider.splitBrowsersAllowedRC &&
          _webViewProvider.splitScreenPosition != WebViewSplitPosition.off)
        SearchableRow(
          label: context.l10n.labelLinksFromTheAppInSplitScreen,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelLinksFromTheAppInSplitScreen)),
                    DropdownButton<SplitAppLinkTarget>(
                      value: _settingsProvider.splitAppLinkTarget,
                      items: [
                        for (final (target, label) in [
                          (SplitAppLinkTarget.browserTab, context.l10n.labelCurrentTab),
                          (SplitAppLinkTarget.browserNewTab, context.l10n.labelNewTab),
                          (SplitAppLinkTarget.appSideTab, context.l10n.labelTabBehindApp),
                          (SplitAppLinkTarget.appSideNewTab, context.l10n.labelNewTabAppSide),
                        ])
                          DropdownMenuItem(
                            value: target,
                            child: SizedBox(
                              width: 110,
                              child: Text(label, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _settingsProvider.splitAppLinkTarget = value;
                        });
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    context.l10n.splitLinksDescription,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: Text(context.l10n.labelSeeExamples),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (BuildContext context) => const SplitLinksExamplesPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: context.l10n.labelHighRefreshRate,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.l10n.labelHighRefreshRate),
                        if (_refreshRateInfo.isNotEmpty)
                          Text(
                            'Current: ${_refreshRateInfo['currentRefreshRate']?.round().toString() ?? 'Unknown'} Hz',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        if (_refreshRateInfo.isNotEmpty && _refreshRateInfo['maximumFramesPerSecond'] != null)
                          Text(
                            'Max: ${_refreshRateInfo['maximumFramesPerSecond']?.toString() ?? 'Unknown'} Hz',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _isUpdatingRefreshRate
                      ? const SizedBox(
                          width: 48,
                          height: 28,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      : Switch(
                          value: _settingsProvider.highRefreshRateEnabled,
                          onChanged: (value) {
                            setState(() {
                              _settingsProvider.changeHighRefreshRateEnabled = value;
                            });
                            _updateRefreshRateAfterChange();
                          },
                          activeTrackColor: Colors.lightGreenAccent,
                          activeThumbColor: Colors.green,
                        ),
                ],
              ),
              Text(
                context.l10n.refreshRateDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: context.l10n.screenGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _themeSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelThemeDescription,
        searchText: _searchText,
        filterable: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Text(
            context.l10n.themeDescription,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelUseMaterialTheme,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelUseMaterialTheme)),
              Switch(
                value: _themeProvider.useMaterial3,
                onChanged: (enabled) async {
                  _themeProvider.useMaterial3 = enabled;
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelSyncAppWithDeviceTheme,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelSyncAppWithDeviceTheme)),
              Switch(
                value: _settingsProvider.syncDeviceTheme,
                onChanged: (enabled) async {
                  setState(() {
                    _settingsProvider.syncDeviceTheme = enabled;
                    if (enabled) {
                      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
                      if (brightness == Brightness.dark && _themeProvider.currentTheme == AppTheme.light) {
                        _themeProvider.changeTheme = AppTheme.dark;
                      } else if (brightness == Brightness.light && _themeProvider.currentTheme != AppTheme.light) {
                        _themeProvider.changeTheme = AppTheme.light;
                      }
                    }
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelSyncAppAndWebThemes,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelSyncAppAndWebThemes)),
              Switch(
                value: _settingsProvider.syncTornWebTheme,
                onChanged: (enabled) async {
                  setState(() {
                    _settingsProvider.syncTornWebTheme = enabled;
                  });
                },
                activeTrackColor: Colors.lightGreenAccent,
                activeThumbColor: Colors.green,
              ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.syncTornWebTheme)
        SearchableRow(
          label: context.l10n.labelDarkThemeEquivalent,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelDarkThemeEquivalent)),
                    Flexible(flex: 2, child: _themeToSyncDropdown()),
                  ],
                ),
                Text(
                  context.l10n.darkThemeDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      SearchableRow(
        label: context.l10n.labelAccesibleTextColors,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelAccesibleTextColors)),
                  Switch(
                    value: _themeProvider.accesibilityNoTextColors,
                    onChanged: (enabled) async {
                      _themeProvider.accesibilityNoTextColors = enabled;
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.accessibleColorsDescription,
                style: TextStyle(
                  color: _themeProvider.mainText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: context.l10n.themeGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _appIconSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelDynamicAppIcons,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelDynamicAppIcons)),
                  Switch(
                    value: !_settingsProvider.dynamicAppIconEnabledRemoteConfig
                        ? false
                        : _settingsProvider.dynamicAppIcons,
                    onChanged: !_settingsProvider.dynamicAppIconEnabledRemoteConfig
                        ? null
                        : (enabled) async {
                            setState(() {
                              _settingsProvider.dynamicAppIcons = enabled;
                            });
                            if (enabled) {
                              _settingsProvider.appIconChangeBasedOnCondition();
                            } else {
                              _settingsProvider.appIconResetDefault();
                            }
                          },
                    activeTrackColor: _settingsProvider.dynamicAppIconEnabledRemoteConfig
                        ? Colors.lightGreenAccent
                        : Colors.grey[700],
                    activeThumbColor:
                        _settingsProvider.dynamicAppIconEnabledRemoteConfig ? Colors.green : Colors.grey[700],
                    inactiveThumbColor: !_settingsProvider.dynamicAppIconEnabledRemoteConfig ? Colors.grey[800] : null,
                  ),
                ],
              ),
              Text(
                context.l10n.dynamicIconDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (!_settingsProvider.dynamicAppIconEnabledRemoteConfig)
                Text(
                  context.l10n.labelDeactivatedRemotelyForTheTimeBeing,
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (_settingsProvider.dynamicAppIconEnabledRemoteConfig && _settingsProvider.dynamicAppIcons)
        SearchableRow(
          label: context.l10n.labelOverrideIcon,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.l10n.labelOverrideIcon),
                    Flexible(child: _manualAppIconDropdown()),
                  ],
                ),
                Text(
                  context.l10n.overrideIconDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (!_settingsProvider.dynamicAppIconEnabledRemoteConfig)
                  Text(
                    context.l10n.labelDeactivatedRemotelyForTheTimeBeing,
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
    ];

    return buildSectionWithRows(
      title: context.l10n.iconGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _miscSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelShowStatusColorCounter,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelShowStatusColorCounter)),
                  Switch(
                    value: Get.find<ChainStatusController>().statusColorWidgetEnabled,
                    onChanged: (value) {
                      setState(() {
                        Get.find<ChainStatusController>().statusColorWidgetEnabled = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.statusCounterDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelAppBarPosition,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelAppBarPosition)),
                  Flexible(flex: 2, child: _appBarPositionDropdown()),
                ],
              ),
              Text(
                context.l10n.appBarDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelDefaultLaunchSection,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelDefaultLaunchSection)),
              Flexible(child: _openSectionDropdown()),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelDrawerSections,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(context.l10n.labelDrawerSections)),
              Flexible(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => DrawerSectionsPage(),
                      ),
                    );
                  },
                  child: Text(context.l10n.labelConfigure),
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelBackButtonExitsApp,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelBackButtonExitsApp)),
                  Flexible(child: _backButtonAppExitDropdown()),
                ],
              ),
              Text(
                context.l10n.backButtonDescription,
                style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelDisableUpdateNotification,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelDisableUpdateNotification)),
                  Switch(
                    value: _settingsProvider.disableUpdateDialog,
                    onChanged: (enabled) {
                      setState(() {
                        _settingsProvider.disableUpdateDialog = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.updateDialogDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: context.l10n.miscGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _externalPartnersSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelAlternativeApiKeys,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.labelAlternativeApiKeys),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_right_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (BuildContext context) => const AlternativeKeysPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Text(
                context.l10n.alternativeKeyDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
    ];
    return buildSectionWithRows(
      title: context.l10n.partnerGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _apiRateSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelDisplayApiCallRate,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelDisplayApiCallRate)),
                  Switch(
                    value: _apiController.showApiRateInDrawer.value,
                    onChanged: (enabled) async {
                      setState(() {
                        _apiController.showApiRateInDrawer = RxBool(enabled);
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.apiRateDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelWarnMaxCallRate,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelWarnMaxCallRate)),
                  Switch(
                    value: _apiController.showApiMaxCallWarning,
                    onChanged: (enabled) async {
                      setState(() {
                        _apiController.showApiMaxCallWarning = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.apiRateWarningDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelDelayApiCalls,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelDelayApiCalls)),
                  Switch(
                    value: _apiController.delayCalls,
                    onChanged: (enabled) async {
                      setState(() {
                        _apiController.delayCalls = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.apiDelayDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelLoadInventoryAutomatically,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelLoadInventoryAutomatically)),
                  Switch(
                    value: _inventoryAutoLoad,
                    onChanged: (enabled) {
                      setState(() {
                        _inventoryAutoLoad = enabled;
                      });
                      Prefs().setInventoryAutoLoad(enabled);
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.inventoryDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: context.l10n.apiGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _saveSettingsOnlineSection() {
    List<SearchableRow> rows = [
      if (!_settingsProvider.backupPrefsEnabledStatusRemoteConfig)
        SearchableRow(
          label: context.l10n.labelBackup,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      context.l10n.backupDisabled,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (_settingsProvider.backupPrefsEnabledStatusRemoteConfig) ...[
        SearchableRow(
          label: context.l10n.labelUploadSettings,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelUploadSettings)),
                    ElevatedButton(
                      child: const Icon(Icons.upload),
                      onPressed: _userProfile == null
                          ? null
                          : () {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return BackupSaveDialog(userProfile: _userProfile!);
                                },
                              );
                            },
                    ),
                  ],
                ),
                Text(
                  context.l10n.backupSettingsDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
          ),
        ),
        SearchableRow(
          label: context.l10n.labelRestoreSettings,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelRestoreSettings)),
                    ElevatedButton(
                      child: const Icon(Icons.download),
                      onPressed: _userProfile == null
                          ? null
                          : () {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return BackupRestoreDialog(userProfile: _userProfile!);
                                },
                              );
                            },
                    ),
                  ],
                ),
                Text(
                  context.l10n.restoreDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
          ),
        ),
        SearchableRow(
          label: context.l10n.labelShareSettings,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelShareSettings)),
                    ElevatedButton(
                      child: const Icon(Icons.share),
                      onPressed: _userProfile == null
                          ? null
                          : () {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return BackupShareDialog(
                                    userProfile: _userProfile!,
                                    themeProvider: _themeProvider,
                                  );
                                },
                              );
                            },
                    ),
                  ],
                ),
                Text(
                  context.l10n.shareDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                )
              ],
            ),
          ),
        ),
        SearchableRow(
          label: context.l10n.labelClearBackup,
          searchText: _searchText,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: Text(context.l10n.labelClearBackup)),
                    ElevatedButton(
                      child: const Icon(Icons.delete_outline),
                      onPressed: _userProfile == null
                          ? null
                          : () async {
                              showDialog(
                                useRootNavigator: false,
                                context: context,
                                builder: (BuildContext context) {
                                  return BackupDeleteDialog(userProfile: _userProfile!);
                                },
                              );
                            },
                    ),
                  ],
                ),
                Text(
                  context.l10n.clearBackupDescription,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ];
    return buildSectionWithRows(
      title: context.l10n.cloudBackupGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _saveSettingsLocalSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelSaveSettingsLocally,
        searchText: _searchText,
        child: const Padding(
          padding: EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: PrefsBackupWidget(),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: context.l10n.localBackupGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  Widget _troubleshootingSection() {
    List<SearchableRow> rows = [
      SearchableRow(
        label: context.l10n.labelMemoryMenu,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.memory),
                        SizedBox(width: 5),
                        Flexible(child: Text(context.l10n.labelShowMemoryInDrawerMenu)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _settingsProvider.showMemoryInDrawer,
                    onChanged: (enabled) async {
                      setState(() {
                        _settingsProvider.showMemoryInDrawer = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.drawerMemoryDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelMemoryBrowser,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(Icons.memory),
                        SizedBox(width: 5),
                        Flexible(child: Text(context.l10n.labelShowMemoryInBrowser)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _settingsProvider.showMemoryInWebview,
                    onChanged: (enabled) async {
                      setState(() {
                        _settingsProvider.showMemoryInWebview = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.browserMemoryDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (_webViewProvider.bottomBarStyleEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    context.l10n.defaultStyleOnly,
                    style: TextStyle(
                      color: _themeProvider.getTextColor(Colors.red),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelTestApi,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelTestApi)),
                  ElevatedButton(
                    child: Text(context.l10n.labelPing),
                    onPressed: () async {
                      BotToast.showText(
                        text: "Please wait...",
                        textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                        contentColor: Colors.blue,
                        duration: const Duration(seconds: 1),
                        contentPadding: const EdgeInsets.all(10),
                      );
                      final ping = Ping('api.torn.com', count: 4);
                      ping.stream.listen((event) {
                        if (event.summary != null || event.error != null) {
                          String message = "";
                          if (event.error != null) {
                            message = "CONNECTION PROBLEM\n\n${event.error}";
                          } else {
                            if (event.summary!.transmitted == event.summary!.received) {
                              message = "SUCCESS\n\n${event.summary}";
                            } else {
                              message = "CONNECTION PROBLEM\n\n${event.summary}";
                            }
                          }
                          BotToast.showText(
                            clickClose: true,
                            text: message,
                            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                            contentColor: Colors.blue,
                            duration: const Duration(seconds: 10),
                            contentPadding: const EdgeInsets.all(10),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              Text(
                context.l10n.testApiDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelApiErrorLog,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelApiErrorLog)),
                  ElevatedButton.icon(
                    label: Text(context.l10n.labelView),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => ApiErrorDialog(),
                      );
                    },
                  ),
                ],
              ),
              Text(
                context.l10n.errorLogDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelEnableDebugMessages,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelEnableDebugMessages)),
                  Switch(
                    value: _settingsProvider.debugMessages,
                    onChanged: (enabled) async {
                      setState(() {
                        _settingsProvider.debugMessages = enabled;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              Text(
                context.l10n.debugMessagesDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelResetTutorials,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 10, right: 20, bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelResetTutorials)),
                  ElevatedButton(
                    child: Text(context.l10n.labelClear),
                    onPressed: () async {
                      _settingsProvider.clearShowCases();
                    },
                  ),
                ],
              ),
              Text(
                context.l10n.resetTutorialDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              )
            ],
          ),
        ),
      ),
      SearchableRow(
        label: context.l10n.labelResetChainingSettings,
        searchText: _searchText,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(context.l10n.labelResetChainingSettings)),
                  ElevatedButton(
                    child: Text(context.l10n.labelReset, style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(context.l10n.labelResetChainingSettings),
                            content: Text(context.l10n.resetChainingDescription),
                            actions: [
                              TextButton(
                                child: Text(context.l10n.labelCancel),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: Text(context.l10n.labelResetSetting, style: TextStyle(color: Colors.red)),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  var defaultSettings = WarSettings();
                                  await Prefs().setWarSettings(defaultSettings);

                                  try {
                                    if (Get.isRegistered<WarController>()) {
                                      var warController = Get.find<WarController>();
                                      warController.warSettings = defaultSettings;
                                      warController.update();
                                    }
                                  } catch (e) {
                                    //
                                  }

                                  BotToast.showText(
                                    text: "Chaining settings reset to defaults",
                                    textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                                    contentColor: Colors.green,
                                    duration: const Duration(seconds: 3),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              Text(
                context.l10n.chainingFiltersDescription,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    return buildSectionWithRows(
      title: context.l10n.troubleshootingGroup,
      rows: rows,
      searchText: _searchText,
    );
  }

  DropdownButton _splitScreenDropdown() {
    return DropdownButton<WebViewSplitPosition>(
      value: _webViewProvider.splitScreenPosition,
      items: [
        DropdownMenuItem(
          value: WebViewSplitPosition.off,
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelOff,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        DropdownMenuItem(
          value: WebViewSplitPosition.left,
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelBrowserLeft,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: WebViewSplitPosition.right,
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelBrowserRight,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _webViewProvider.splitScreenPosition = value!;
          if (value == WebViewSplitPosition.off) {
            _webViewProvider.browserShowInForeground = false;
          } else {
            if (MediaQuery.sizeOf(context).width >= kSplitScreenMinWidth) {
              _webViewProvider.webViewSplitActive = true;

              // Force stackview convertion from Container if it still hasn't happened
              _webViewProvider.browserForegroundWithSplitTransition();
            }
          }
        });
      },
    );
  }

  DropdownButton _manualAppIconDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.dynamicAppIconsManual,
      items: [
        DropdownMenuItem(
          value: "off",
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelOff,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "awareness",
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelAwareness,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "halloween",
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelHalloween,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "christmas",
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelChristmas,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "stvalentine",
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelValentineSDay,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "stpatrick",
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelStPatrickSDay,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "easter",
          child: SizedBox(
            width: 120,
            child: Text(
              context.l10n.labelEasterEggHunt,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _settingsProvider.dynamicAppIconsManual = value;
          _settingsProvider.appIconChangeBasedOnCondition();
        });
      },
    );
  }

  DropdownButton _splitScreenRevertionDropdown() {
    return DropdownButton<bool>(
      value: _webViewProvider.splitScreenRevertsToApp,
      items: [
        DropdownMenuItem(
          value: true,
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelApp,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
        DropdownMenuItem(
          value: false,
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelBrowser,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _webViewProvider.splitScreenRevertsToApp = value!;
        });
      },
    );
  }

  DropdownButton _openSectionDropdown() {
    return DropdownButton<String>(
      value: _openSectionValue,
      items: [
        DropdownMenuItem(
          value: "browser",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelBrowser,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "browser_full",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelBrowserFullScreen,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ),
        ...DrawerSection.values.map((section) {
          return DropdownMenuItem(
            value: section.name,
            child: SizedBox(
              width: 80,
              child: Text(
                section.localizedTitle(context.l10n),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          );
        }),
      ],
      onChanged: (value) {
        Prefs().setDefaultSection(value!);
        setState(() {
          _openSectionValue = value;
        });
      },
    );
  }

  DropdownButton _backButtonAppExitDropdown() {
    return DropdownButton<String>(
      value: _onAppExitValue,
      items: [
        DropdownMenuItem(
          value: "stay",
          child: SizedBox(
            width: 60,
            child: Text(
              context.l10n.labelStay,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "exit",
          child: SizedBox(
            width: 60,
            child: Text(
              context.l10n.labelExit,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        _settingsProvider.changeOnAppExit = value;
        setState(() {
          _onAppExitValue = value;
        });
      },
    );
  }

  DropdownButton _openBrowserDropdown() {
    return DropdownButton<String>(
      value: _openBrowserValue,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 65,
            child: Text(
              context.l10n.labelInApp,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 65,
            child: Text(
              context.l10n.labelExternal,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) async {
        if (value == '0') {
          _settingsProvider.changeBrowser = BrowserSetting.app;
        } else {
          _settingsProvider.changeBrowser = BrowserSetting.external;

          if (Platform.isAndroid) {
            await showDialog(
              useRootNavigator: false,
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AppLinksBrowserDialog();
              },
            );
          }
        }
        setState(() {
          _openBrowserValue = value;
        });
      },
    );
  }

  DropdownButton _timeFormatDropdown() {
    return DropdownButton<String>(
      value: _timeFormatValue,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 60,
            child: Text(
              context.l10n.label24Hours,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 60,
            child: Text(
              context.l10n.label12Hours,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == '0') {
          _settingsProvider.changeTimeFormat = TimeFormatSetting.h24;
        } else {
          _settingsProvider.changeTimeFormat = TimeFormatSetting.h12;
        }
        setState(() {
          _timeFormatValue = value;
        });
      },
    );
  }

  DropdownButton _timeZoneDropdown() {
    return DropdownButton<String>(
      value: _timeZoneValue,
      items: [
        DropdownMenuItem(
          value: "0",
          child: SizedBox(
            width: 135,
            child: Text(
              context.l10n.labelLocalTimeLt,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "1",
          child: SizedBox(
            width: 135,
            child: Text(
              context.l10n.labelTornCityTimeTct,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == '0') {
          _settingsProvider.changeTimeZone = TimeZoneSetting.localTime;
        } else {
          _settingsProvider.changeTimeZone = TimeZoneSetting.tornTime;
        }
        setState(() {
          _timeZoneValue = value;
        });
      },
    );
  }

  DropdownButton _dateInClockDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.showDateInClock,
      items: [
        DropdownMenuItem(
          value: "off",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelOff,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "dayfirst",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelOnDM,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "monthfirst",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelOnMD,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.changeShowDateInClock = value!;
        });
      },
    );
  }

  DropdownButton _secondsInClockDropdown() {
    return DropdownButton<bool>(
      value: _settingsProvider.showSecondsInClock,
      items: [
        DropdownMenuItem(
          value: true,
          child: SizedBox(
            width: 60,
            child: Text(
              context.l10n.labelShow,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: false,
          child: SizedBox(
            width: 60,
            child: Text(
              context.l10n.labelHide,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _settingsProvider.changeShowSecondsInClock = value!;
        });
      },
    );
  }

  Widget _vibrationDropdown() {
    if (_androidSdk < 26) {
      return const Text(
        'This functionality is only available in Android 8 (API 26 - Oreo) or higher, sorry!',
        style: TextStyle(
          color: Colors.red,
          fontSize: 10,
        ),
      );
    }

    return DropdownButton<String>(
      value: _vibrationValue,
      items: [
        DropdownMenuItem(
          value: "no-vib",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelOff,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "short",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelShort,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "medium",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelMedium,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "long",
          child: SizedBox(
            width: 80,
            child: Text(
              context.l10n.labelLong,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) async {
        // Deletes current channels and create new ones
        reconfigureNotificationChannels(mod: value);
        // Update channel preferences
        FirestoreHelper().setVibrationPattern(value);
        Prefs().setVibrationPattern(value!);
        setState(() {
          _vibrationValue = value;
        });

        if ((await Vibration.hasVibrator())) {
          if (value == 'short') {
            Vibration.vibrate(pattern: [0, 400]);
          } else if (value == 'medium') {
            Vibration.vibrate(pattern: [0, 400, 400, 400, 400]);
          } else if (value == 'long') {
            Vibration.vibrate(pattern: [0, 400, 400, 600, 400, 800, 400, 1000]);
          }
        }
      },
    );
  }

  DropdownButton _spiesSourceDropdown() {
    return DropdownButton<SpiesSource>(
      value: _spyController.spiesSource,
      items: const [
        DropdownMenuItem(
          value: SpiesSource.yata,
          child: SizedBox(
            width: 85,
            child: Text(
              "YATA",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: SpiesSource.tornStats,
          child: SizedBox(
            width: 85,
            child: Text(
              "Torn Stats",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          if (value == SpiesSource.yata) {
            _spyController.spiesSource = SpiesSource.yata;
          } else {
            _spyController.spiesSource = SpiesSource.tornStats;
          }
        });
      },
    );
  }

  DropdownButton _naturalNerveBarSourceDropdown() {
    return DropdownButton<NaturalNerveBarSource>(
      value: _settingsProvider.naturalNerveBarSource,
      items: [
        DropdownMenuItem(
          value: NaturalNerveBarSource.off,
          child: SizedBox(
            width: 85,
            child: Text(
              context.l10n.labelDisabled,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: NaturalNerveBarSource.yata,
          child: SizedBox(
            width: 85,
            child: Text(
              "YATA",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: NaturalNerveBarSource.tornStats,
          child: SizedBox(
            width: 85,
            child: Text(
              "Torn Stats",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          if (value == NaturalNerveBarSource.yata) {
            _settingsProvider.naturalNerveBarSource = NaturalNerveBarSource.yata;
          } else if (value == NaturalNerveBarSource.tornStats) {
            _settingsProvider.naturalNerveBarSource = NaturalNerveBarSource.tornStats;
          } else {
            _settingsProvider.naturalNerveBarSource = NaturalNerveBarSource.off;
          }
        });
      },
    );
  }

  DropdownButton _themeToSyncDropdown() {
    return DropdownButton<String>(
      value: _settingsProvider.darkThemeToSyncFromWeb,
      items: [
        DropdownMenuItem(
          value: "dark",
          child: SizedBox(
            width: 100,
            child: Text(
              context.l10n.labelDark,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "extraDark",
          child: SizedBox(
            width: 100,
            child: Text(
              context.l10n.labelExtraDark,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _settingsProvider.darkThemeToSyncFromWeb = value;
        });
      },
    );
  }

  DropdownButton _appBarPositionDropdown() {
    return DropdownButton<String>(
      value: _appBarPosition,
      items: [
        DropdownMenuItem(
          value: "top",
          child: SizedBox(
            width: 58,
            child: Text(
              context.l10n.labelTop,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "bottom",
          child: SizedBox(
            width: 58,
            child: Text(
              context.l10n.labelBottom,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == "top") {
          _settingsProvider.changeAppBarTop = true;
        } else {
          _settingsProvider.changeAppBarTop = false;
        }
        setState(() {
          _appBarPosition = value;
          if (value == "bottom") {
            _extraMargin = 50;
          }
        });
      },
    );
  }

  Future<void> _getApiDetails({required bool userTriggered, required String currentKey}) async {
    final InventoryProvider inventoryProvider = context.read<InventoryProvider>();
    int errorPlayerId = 0;
    dynamic firebaseErrorUser;

    try {
      setState(() {
        _apiIsLoading = true;
      });

      final dynamic myProfile = await ApiCallsV1.getOwnProfileBasic(forcedApiKey: currentKey);
      if (myProfile is OwnProfileBasic) {
        myProfile
          ..userApiKey = currentKey
          ..userApiKeyValid = true;
        UserHelper.setUserDetails(userDetails: myProfile);
        if (userTriggered) inventoryProvider.clear();

        setState(() {
          _apiIsLoading = false;
          _apiError = false;
          _userProfile = myProfile;
        });

        final uc = Get.find<UserController>();
        if (uc.playerId == 0 && myProfile.playerId != null) {
          uc.playerId = myProfile.playerId!;
          uc.apiKey = myProfile.userApiKey;
          uc.playerName = myProfile.name!;
          uc.factionId = myProfile.faction?.factionId ?? 0;
          uc.companyId = myProfile.job?.companyId ?? 0;
        }

        errorPlayerId = uc.playerId;

        // Firestore uploading, but only if "Load" pressed by user
        if (userTriggered) {
          setState(() {
            _expandableController.expanded = false;
          });

          if (!Platform.isWindows) analytics?.logEvent(name: "api_key_loaded");

          if (!Platform.isWindows) {
            try {
              // See note in [firebase_auth.dart]
              final reusedSession = await FirestoreHelper().waitForKeyRemoval();
              final firebaseUser = firebaseErrorUser = await firebaseAuth.getUID();
              bool newSession = reusedSession;
              // Only sign in if there is currently no user registered (to avoid duplicates)
              if (firebaseUser == null || (firebaseUser is User && firebaseUser.uid.isEmpty)) {
                final User? newFirebaseUser = await (firebaseAuth.signInAnon());

                if (newFirebaseUser == null) {
                  log("Settings: Firebase anonymous sign-in failed, continuing without Firebase");
                } else {
                  newSession = true;
                  FirestoreHelper().markSignedIn();
                  log("Settings: signed in with UID ${newFirebaseUser.uid}");
                }
              } else {
                log("Settings: existing user UID ${firebaseUser.uid}");
              }

              final restored = await FirestoreHelper().restoreAlertsFromLocalSnapshot(
                myProfile.playerId,
                newSession: newSession,
              );
              if (restored != null && restored.activeAlerts.isNotEmpty) {
                BotToast.showText(
                  text: "Your alerts have been restored",
                  textStyle: const TextStyle(fontSize: 14, color: Colors.white),
                  contentColor: Colors.green,
                  duration: const Duration(seconds: 5),
                  contentPadding: const EdgeInsets.all(10),
                );
              }

              await FirestoreHelper().uploadUsersProfileDetail(myProfile, userTriggered: true);
              await FirestoreHelper().uploadLastActiveTimeAndTokensToFirebase(DateTime.now().millisecondsSinceEpoch);
              if (Platform.isAndroid) {
                FirestoreHelper().setVibrationPattern(_vibrationValue);
              }
            } catch (firebaseError) {
              log("Settings: Firebase/Firestore operations failed, continuing: $firebaseError");
            }
          } else {
            log("Windows: skipping Firestore sign up!");
          }

          // Signal stat counter initialization
          widget.statsController.logFirstLoginEver();

          // Update the home widget if it's installed
          if (Platform.isAndroid) {
            if ((await pdaWidget_numberInstalled()).isNotEmpty) {
              fetchAndPersistWidgetData();
            }
          } else if (Platform.isIOS) {
            refreshIosWidget();
          }
        }
      } else if (myProfile is ApiError) {
        setState(() {
          _apiIsLoading = false;
          _userProfile = null;
          _apiError = true;
          _errorReason = myProfile.errorReason;
          _errorDetails = myProfile.pdaErrorDetails;
          _expandableController.expanded = true;
        });
        // We'll only remove the user if the key is invalid, otherwise we
        // risk removing it if we access the Settings page with no internet
        // connectivity
        if (myProfile.errorId == 2) {
          UserHelper.removeUser();
          inventoryProvider.clear();
        }
      }
    } catch (e, stack) {
      if (!Platform.isWindows) {
        FirebaseCrashlytics.instance.log("PDA Crash at LOAD API KEY. Error: $e. Stack: $stack");
        FirebaseCrashlytics.instance.recordError(
          e,
          stack,
          information: ['ID: $errorPlayerId', 'Firebase User UID: ${firebaseErrorUser?.uid}'],
        );
      }
    }
  }

  Future _restorePreferences() async {
    if (Platform.isAndroid) {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _androidSdk = androidInfo.version.sdkInt;
    }

    await Prefs().getDefaultSection().then((onValue) {
      // Migrate old numeric default section to symbolic names
      String migrated = onValue;
      final numericTry = int.tryParse(onValue);
      if (numericTry != null) {
        migrated = DrawerSection.fromIndex(numericTry).name;
      }
      setState(() {
        _openSectionValue = migrated;
      });
    });

    if (UserHelper.isApiKeyValid) {
      String savedKey = UserHelper.apiKey;
      setState(() {
        _apiKeyInputController.text = UserHelper.apiKey;
        _apiIsLoading = true;
      });
      _getApiDetails(userTriggered: false, currentKey: savedKey);
    }

    final onAppExit = _settingsProvider.onBackButtonAppExit;
    setState(() {
      switch (onAppExit) {
        case 'exit':
          _onAppExitValue = 'exit';
        case 'stay':
          _onAppExitValue = 'stay';
      }
    });

    final browser = _settingsProvider.currentBrowser;
    setState(() {
      switch (browser) {
        case BrowserSetting.app:
          _openBrowserValue = '0';
        case BrowserSetting.external:
          _openBrowserValue = '1';
      }
    });

    final timeFormat = _settingsProvider.currentTimeFormat;
    setState(() {
      switch (timeFormat) {
        case TimeFormatSetting.h24:
          _timeFormatValue = '0';
        case TimeFormatSetting.h12:
          _timeFormatValue = '1';
      }
    });

    final timeZone = _settingsProvider.currentTimeZone;
    setState(() {
      switch (timeZone) {
        case TimeZoneSetting.localTime:
          _timeZoneValue = '0';
        case TimeZoneSetting.tornTime:
          _timeZoneValue = '1';
      }
    });

    final appBarPosition = _settingsProvider.appBarTop;
    setState(() {
      appBarPosition ? _appBarPosition = 'top' : _appBarPosition = 'bottom';
    });

    final alertsVibration = await Prefs().getVibrationPattern();
    final manualAlarmSound = await Prefs().getManualAlarmSound();
    final manualAlarmVibration = await Prefs().getManualAlarmVibration();
    final inventoryAutoLoad = await Prefs().getInventoryAutoLoad();

    setState(() {
      _inventoryAutoLoad = inventoryAutoLoad;
      _removeNotificationsLaunch = _settingsProvider.removeNotificationsOnLaunch;
      _vibrationValue = alertsVibration;
      _manualAlarmSound = manualAlarmSound;
      _manualAlarmVibration = manualAlarmVibration;
    });
  }

  DropdownButton _shortcutTileDropdown() {
    return DropdownButton<String>(
      value: _shortcutsProvider.shortcutTile,
      items: [
        DropdownMenuItem(
          value: "both",
          child: SizedBox(
            width: 90,
            child: Text(
              context.l10n.labelIconAndText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "icon",
          child: SizedBox(
            width: 90,
            child: Text(
              context.l10n.labelOnlyIcon,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "text",
          child: SizedBox(
            width: 90,
            child: Text(
              context.l10n.labelOnlyText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _shortcutsProvider.changeShortcutTile(value!);
        });
      },
    );
  }

  DropdownButton _shortcutMenuDropdown() {
    return DropdownButton<String>(
      value: _shortcutsProvider.shortcutMenu,
      items: [
        DropdownMenuItem(
          value: "carousel",
          child: SizedBox(
            width: 67,
            child: Text(
              context.l10n.labelCarousel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "grid",
          child: SizedBox(
            width: 67,
            child: Text(
              context.l10n.labelGrid,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "gridcarousel",
          child: SizedBox(
            width: 100,
            child: Text(
              context.l10n.labelGridCarousel,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _shortcutsProvider.changeShortcutMenu(value!);
        });
      },
    );
  }

  Widget _appWidgetCooldownTapDestinationSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Row(
              children: [
                Icon(Icons.keyboard_arrow_right_outlined),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      context.l10n.labelCooldownTapOpens,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _settingsProvider.appwidgetCooldownTapOpenBrowserDestination,
            items: [
              DropdownMenuItem(
                value: "own",
                child: SizedBox(
                  width: 110,
                  child: Text(
                    context.l10n.labelOwnItems,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              DropdownMenuItem(
                value: "faction",
                child: SizedBox(
                  width: 110,
                  child: Text(
                    context.l10n.labelFactionItems,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
            onChanged: (value) async {
              setState(() {
                _settingsProvider.appwidgetCooldownTapOpenBrowserDestination = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadRefreshRateInfo() async {
    try {
      final info = await _settingsProvider.getRefreshRateInfo();
      if (mounted) {
        setState(() {
          _refreshRateInfo = info;
        });
      }
    } catch (e) {
      log('Error loading refresh rate info: $e');
    }
  }

  Future<void> _updateRefreshRateAfterChange() async {
    setState(() {
      _isUpdatingRefreshRate = true;
    });

    // Wait for the settings to take effect
    await Future.delayed(const Duration(milliseconds: 1000));
    await _loadRefreshRateInfo();

    if (mounted) {
      setState(() {
        _isUpdatingRefreshRate = false;
      });
    }
  }
}

class SearchableRow extends StatelessWidget {
  // [filterable] allows certain rows (such as explanatory text)
  // to be excluded from filtering, so they only show when there's no active query
  final String label;
  final bool filterable;
  final Widget child;
  final String searchText;

  const SearchableRow({
    super.key,
    required this.label,
    required this.child,
    required this.searchText,
    this.filterable = true,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

Widget buildSectionWithRows({
  required String title,
  required List<SearchableRow> rows,
  required String searchText,
}) {
  // "showAll" forces all rows to be visible if the section title matches the search text
  // This ensures a search for the section name displays all rows in that section.
  bool showAll = searchText.isNotEmpty && title.toLowerCase().contains(searchText.toLowerCase());

  // For each filterable row, we show it if there's no search query,
  // or if its label contains the search text, or if showAll is true
  List<bool> isVisible = List.filled(rows.length, false);
  for (int i = 0; i < rows.length; i++) {
    SearchableRow row = rows[i];
    if (row.filterable) {
      isVisible[i] = searchText.isEmpty || row.label.toLowerCase().contains(searchText.toLowerCase()) || showAll;
    } else {
      isVisible[i] = searchText.isEmpty || (i > 0 && isVisible[i - 1]);
    }
  }

  List<Widget> visibleWidgets = [];
  for (int i = 0; i < rows.length; i++) {
    if (isVisible[i]) {
      visibleWidgets.add(rows[i].child);
    }
  }

  if (visibleWidgets.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Section title is always displayed when the section has visible content
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10)),
        ],
      ),
      ...visibleWidgets,
    ],
  );
}
