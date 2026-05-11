// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppL10nZh extends AppL10n {
  AppL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Seoul Vista';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonOk => '好';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '关闭';

  @override
  String get commonLater => '稍后';

  @override
  String get settingsAppLanguageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageChangedTitle => '已更改语言';

  @override
  String get languageChangedBody => '要完全应用新语言,需要重启应用。现在重启吗?';

  @override
  String get languageRestartNow => '重启';

  @override
  String get languageRestartLater => '稍后';
}
