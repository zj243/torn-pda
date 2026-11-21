import 'actions.dart';
import 'release_notes_3.dart';
import 'release_notes_2.dart';
import 'release_notes_1.dart';
import 'help_and_settings_1.dart';
import 'alerts.dart';
import 'chaining.dart';
import 'chat_1.dart';
import 'chat_2.dart';
import 'common_1.dart';
import 'common_2.dart';
import 'ffscouter.dart';
import 'profile.dart';
import 'quick_items.dart';
import 'settings_1.dart';
import 'settings_2.dart';
import 'stats.dart';
import 'trades.dart';
import 'travel.dart';
import 'webviews.dart';

/// ZJ：合并各功能的简体中文文案，供应用显示文字时查找。
const chineseInterfaceMessages = <String, String>{
  ...messagesActions,
  ...messagesAlerts,
  ...messagesChaining,
  ...messagesChat1,
  ...messagesChat2,
  ...messagesCommon1,
  ...messagesCommon2,
  ...messagesFfscouter,
  ...messagesProfile,
  ...messagesQuickItems,
  ...messagesSettings1,
  ...messagesSettings2,
  ...messagesStats,
  ...messagesTrades,
  ...messagesTravel,
  ...messagesWebviews,
  ...messagesHelpAndSettings1,
  ...messagesReleaseNotes1,
  ...messagesReleaseNotes2,
  ...messagesReleaseNotes3,
};
