// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppL10nJa extends AppL10n {
  AppL10nJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Seoul Vista';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonLater => 'あとで';

  @override
  String get settingsAppLanguageTitle => '言語';

  @override
  String get languageSystem => 'システム設定';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageChangedTitle => '言語を変更しました';

  @override
  String get languageChangedBody =>
      '新しい言語を完全に適用するにはアプリを再起動する必要があります。今すぐ再起動しますか?';

  @override
  String get languageRestartNow => '再起動';

  @override
  String get languageRestartLater => 'あとで';
}
