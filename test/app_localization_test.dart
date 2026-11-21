import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/l10n/app_language.dart';
import 'package:torn_pda/l10n/catalog/catalog.dart';
import 'package:torn_pda/l10n/generated/app_localizations.dart';
import 'package:torn_pda/models/drawer_section.dart';
import 'package:torn_pda/l10n/pda_text.dart';

/// ZJ：验证切换语言后显示文本、后台通知默认值和未知状态的回退行为。
void main() {
  test('中文帮助中的网址和可复制的聊天指令保持有效', () {
    // ZJ：网页链接必须保留原地址，帮派聊天只识别原样发送的英文指令。
    final links = RegExp(r'''(?:https?://|tornpda://|www\.)[^\s"'()<>]+''');
    final commands = RegExp(r'"(\[PDA\][^"]+)"');
    for (final entry in chineseInterfaceMessages.entries) {
      final originalTokens = [
        for (final link in links.allMatches(entry.key))
          link.group(0)!.replaceFirst(RegExp(r'[.,]+$'), ''),
        for (final command in commands.allMatches(entry.key)) command.group(1)!,
      ];
      for (final token in originalTokens) {
        expect(entry.value, contains(token), reason: entry.key);
      }
    }
  });

  testWidgets('切换语言刷新侧栏并保留 Torn 状态值', (tester) async {
    for (final language in ['en', 'zh']) {
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(builder: (context) {
          final strings = context.l10n;
          // ZJ：让各条测试文本沿用正文样式，较小的测试视窗也能完整布局。
          return Scaffold(body: SingleChildScrollView(child: Column(children: [
            Text(DrawerSection.travel.localizedTitle(strings)),
            Text(strings.playerState('Hospital')),
            Text(strings.playerState('Unknown state')),
            Text(strings.fullAt('18:00')),
            Text(strings.unreadMessagesSince(2, '18:00')),
            Text(strings.unreadEvents(0)),
            Text(context.destinationName('Cayman Islands')),
            Text(strings.travelNotificationBody),
            const PdaText('Level: {0}', values: [42]),
            const PdaText('Untranslated {0}', values: ['player {0}']),
          ])));
        }),
      ));
      await tester.pumpAndSettle();
      final chinese = language == 'zh';
      expect(find.text(chinese ? '旅行' : 'Travel'), findsOneWidget);
      expect(find.text(chinese ? '住院中' : 'Hospital'), findsOneWidget);
      expect(find.text(chinese ? '18:00 回满' : 'Full at 18:00'), findsOneWidget);
      expect(find.text(chinese ? '即将抵达目的地！' : 'Arriving at your destination!'), findsOneWidget);
      expect(find.text('Unknown state'), findsOneWidget);
      expect(find.text(chinese ? '有 2 条未读消息（自 18:00 起）' : '2 unread messages (since 18:00)'), findsOneWidget);
      expect(find.text(chinese ? '没有未读事件' : 'No unread events'), findsOneWidget);
      expect(find.text(chinese ? '开曼群岛' : 'Cayman Islands'), findsOneWidget);
      expect(find.text(chinese ? '等级：42' : 'Level: 42'), findsOneWidget);
      expect(find.text('Untranslated player {0}'), findsOneWidget);
      expect(DrawerSection.travel.name, 'travel');
    }
  });
}
