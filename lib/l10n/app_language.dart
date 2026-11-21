import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/l10n/generated/app_localizations.dart';
import 'package:torn_pda/utils/sembast_db.dart';

/// ZJ：界面及手动旅行通知共用的语言选项，持久化枚举名。
enum AppLanguage { system, en, zh }

/// ZJ：加载和保存本机语言，在写入成功后刷新应用。
class AppLanguageController extends ChangeNotifier {
  AppLanguageController._(this.choice);

  static const _key = 'pda_appLanguage';
  AppLanguage choice;
  bool saving = false;

  /// ZJ：读取本机设置，遇到旧版或无效值时返回跟随系统的控制器。
  static Future<AppLanguageController> load() async {
    final stored = await PrefsDatabase.getString(_key, AppLanguage.system.name);
    final choice = AppLanguage.values.asNameMap()[stored] ?? AppLanguage.system;
    return AppLanguageController._(choice);
  }

  /// ZJ：返回 Flutter 使用的语言，空值表示跟随设备。
  Locale? get locale => choice == AppLanguage.system ? null : Locale(choice.name);

  /// ZJ：保存用户选择的 [next]，返回是否成功写入。
  Future<bool> select(AppLanguage next) async {
    if (saving) return false;
    if (next == choice) return true;
    saving = true;
    notifyListeners();
    try {
      await PrefsDatabase.setString(_key, next.name);
      choice = next;
      log('界面语言已切换为 ${next.name}', name: 'AppLanguage');
      return true;
    } catch (error, stack) {
      log('保存界面语言失败', name: 'AppLanguage', error: error, stackTrace: stack);
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}

/// ZJ：通过当前界面的 BuildContext 获取随应用语言更新的译文。
extension PdaLocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// ZJ：仅翻译 Torn 返回的已知状态；未知 [state] 原样显示。
extension PlayerStateLabel on AppLocalizations {
  String playerState(String state) => switch (state) {
    'Okay' => stateOkay,
    'Hospital' => stateHospital,
    'Jail' => stateJail,
    'Traveling' => stateTraveling,
    'Abroad' => stateAbroad,
    'Federal' => stateFederal,
    'Fallen' => stateFallen,
    _ => state,
  };
}

/// ZJ：设置首页的语言选择器；保存失败时保留原选项并显示原因提示。
class AppLanguageTile extends StatelessWidget {
  const AppLanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppLanguageController>();
    return ListTile(
      title: Text(context.l10n.appLanguage),
      trailing: DropdownButton<AppLanguage>(
        value: controller.choice,
        items: [
          DropdownMenuItem(value: AppLanguage.system, child: Text(context.l10n.systemLanguage)),
          const DropdownMenuItem(value: AppLanguage.zh, child: Text('简体中文')),
          const DropdownMenuItem(value: AppLanguage.en, child: Text('English')),
        ],
        onChanged: controller.saving ? null : (next) async {
          if (next == null) return;
          final saved = await controller.select(next);
          if (!saved && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.languageSaveError)));
          }
        },
      ),
    );
  }
}
