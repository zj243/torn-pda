import 'package:flutter/material.dart';

import 'catalog/catalog.dart';

/// ZJ：只翻译界面文案。[message] 中的编号对应 [values] 的顺序。
/// 玩家名称、金额等运行时数据在查找译文后原样填入，不参与词条匹配。
extension PdaInterfaceLanguage on BuildContext {
  String interfaceText(String message, [List<Object?> values = const []]) {
    final chinese = Localizations.maybeLocaleOf(this)?.languageCode == 'zh';
    final template = chinese ? chineseInterfaceMessages[message] ?? message : message;
    if (values.isEmpty) return template;
    return template.replaceAllMapped(_placeholder, (match) {
      final index = int.parse(match.group(1)!);
      return index < values.length ? '${values[index]}' : match.group(0)!;
    });
  }
}

/// ZJ：仅对 API 的旅行目的地 [destination] 使用地名译表；未知目的地保留原名。
extension TravelDestinationLanguage on BuildContext {
  String destinationName(String? destination) {
    final name = destination ?? 'Unknown';
    if (Localizations.maybeLocaleOf(this)?.languageCode != 'zh') return name;
    return const <String, String>{
      'Argentina': '阿根廷',
      'Canada': '加拿大',
      'Cayman Islands': '开曼群岛',
      'China': '中国',
      'Hawaii': '夏威夷',
      'Japan': '日本',
      'Mexico': '墨西哥',
      'South Africa': '南非',
      'Switzerland': '瑞士',
      'UAE': '阿联酋',
      'United Arab Emirates': '阿拉伯联合酋长国',
      'United Kingdom': '英国',
      'Torn': 'Torn 城',
      'Unknown': '未知',
    }[name] ?? name;
  }
}

final _placeholder = RegExp(r'\{(\d+)\}');

/// ZJ：在构建时取得界面语言，使常量按钮、菜单等也能响应语言切换。
class PdaText extends StatelessWidget {
  const PdaText(
    this.message, {
    this.values = const [],
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap,
    this.semanticsLabel,
  });

  final String message;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool? softWrap;
  final String? semanticsLabel;

  final List<Object?> values;

  /// ZJ：返回使用当前 [context] 语言的文字，继承原控件的排版和无障碍设置。
  @override
  Widget build(BuildContext context) => Text(
    context.interfaceText(message, values),
    style: style,
    textAlign: textAlign,
    overflow: overflow,
    maxLines: maxLines,
    softWrap: softWrap,
    semanticsLabel: semanticsLabel,
  );
}
