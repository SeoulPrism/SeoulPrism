// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppL10nKo extends AppL10n {
  AppL10nKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Seoul Vista';

  @override
  String get commonCancel => '취소';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonOk => '확인';

  @override
  String get commonSave => '저장';

  @override
  String get commonClose => '닫기';

  @override
  String get commonLater => '나중에';

  @override
  String get settingsAppLanguageTitle => '언어';

  @override
  String get languageSystem => '시스템 설정';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageChangedTitle => '언어가 변경되었어요';

  @override
  String get languageChangedBody => '새 언어를 완전히 적용하려면 앱을 재시작해야 해요. 지금 재시작할까요?';

  @override
  String get languageRestartNow => '재시작';

  @override
  String get languageRestartLater => '나중에';
}
