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

  @override
  String get routeUnitHour => '時間';

  @override
  String get routeUnitMin => '分';

  @override
  String routeTransfersCount(int count) {
    return '乗換 $count回';
  }

  @override
  String get routeDeparture => '出発';

  @override
  String get routeArrival => '到着';

  @override
  String get routeTransfer => '乗換';

  @override
  String routeTransferDetail(String line, int min) {
    return '$line · $min分';
  }

  @override
  String routeBoardLine(String line) {
    return '$line 乗車';
  }

  @override
  String routeSegmentBus(String from, String to, int count, int min) {
    return '$from → $to · $count停留所 · $min分';
  }

  @override
  String routeSegmentTrain(String from, String to, int count, int min) {
    return '$from → $to · $count駅 · $min分';
  }

  @override
  String routeSegmentShort(String from, int min) {
    return '$from · $min分';
  }

  @override
  String get routeShowStops => '停留所を表示 ▼';

  @override
  String get routeCollapse => '折りたたむ ▲';

  @override
  String get snsTitle => 'AI プラン';

  @override
  String get snsSubtitle => 'SNS コンテンツでソウル 1 日プランを作成';

  @override
  String get snsSectionPhotos => '写真';

  @override
  String get snsSectionDescription => '説明';

  @override
  String get snsSectionLink => 'SNS リンク';

  @override
  String get snsTextHint => '行きたい場所、やりたいことを書いてください';

  @override
  String get snsUrlHint => 'Instagram、TikTok の URL';

  @override
  String get snsAnalyzeButton => '分析する';

  @override
  String snsAnalyzeError(String error) {
    return '分析に失敗しました: $error';
  }

  @override
  String get snsImageGallery => 'ギャラリー';

  @override
  String get snsImageCamera => 'カメラ';

  @override
  String get dayPlanTitle => '1 日プラン';

  @override
  String get dayPlanNavigateAll => '全体ルート';

  @override
  String dayPlanTransitSummary(int min) {
    return '🚇 $min分';
  }

  @override
  String dayPlanTransfersSummary(int count) {
    return '🔄 $count回';
  }

  @override
  String dayPlanStyleStats(int count, int min) {
    return '$countヶ所 · $min分';
  }

  @override
  String get dayPlanNavigateStop => 'ルート';

  @override
  String get whatsNewClose => '閉じる';

  @override
  String get whatsNewSkip => 'スキップ';

  @override
  String get whatsNewStart => 'はじめる';

  @override
  String get whatsNewNext => '次へ';

  @override
  String whatsNewPage1Title(String version) {
    return 'v$version — おかえりなさい';
  }

  @override
  String get whatsNewPage1Body =>
      '今回は旅があなたらしくなりました。\n旅のムードから友だち・記録まで、\n14 個の新機能をご覧ください。';

  @override
  String get whatsNewPage2Title => 'あなたの旅のムード';

  @override
  String get whatsNewPage2Body =>
      'ゆったり・遊ぶ・歴史・ミックスから選ぶと、\nAI のトーン、おすすめコース、Trip タブが\nそのムードに合わせて変わります。';

  @override
  String get whatsNewPage3Title => '一緒に行く';

  @override
  String get whatsNewPage3Body =>
      'ルームで共通の目的地を決めると、\nメンバー別の距離がリアルタイムで表示。\nマップにはオレンジのピンが自動で。';

  @override
  String get whatsNewPage4Title => '1:1 DM + 音声/写真';

  @override
  String get whatsNewPage4Body =>
      'ルームなしで友だちと直接トーク。\n🎙 マイク長押しで音声、📷 ギャラリーで写真、\n📍 位置情報まで 1 つのチャットで。';

  @override
  String get whatsNewPage5Title => 'Spotify シェア';

  @override
  String get whatsNewPage5Body =>
      '今聴いている曲を友だちに。\nチャットで 🎵 を押すと、再生中の\nSpotify トラックがカードで共有されます。';

  @override
  String get whatsNewPage6Title => '友だちを増やす';

  @override
  String get whatsNewPage6Body =>
      '友だち画面に「友だちの友だち」のおすすめ、\nQR コードで即追加、\nルーム招待リンクでワンタップ参加。';

  @override
  String get whatsNewPage7Title => '活動がスコアに';

  @override
  String get whatsNewPage7Body =>
      '友だち追加・出会い・連続出席でポイントとバッジ。\n友だちと順位を比べたり、\n週間アクティビティで振り返ったり。';

  @override
  String get whatsNewPage8Title => 'あなた次第';

  @override
  String get whatsNewPage8Body =>
      '通知は種類ごとにオン/オフ、\n位置情報は特定のグループにだけ。\n安全とプライバシーはあなたの手に。';

  @override
  String get profileCategoryFavorites => 'お気に入り';

  @override
  String get profileCategoryRecent => '最近の訪問';

  @override
  String get profileCategoryFrequent => 'よく行く';

  @override
  String get profileGuestName => 'ゲスト';

  @override
  String get profileDefaultName => 'ユーザー';

  @override
  String get profileSyncCta => 'ログインすると別の端末でも同期されます';

  @override
  String profileAgoDays(int days) {
    return '$days日前';
  }

  @override
  String profileAgoHours(int hours) {
    return '$hours時間前';
  }

  @override
  String get profileAgoNow => 'たった今';

  @override
  String profileVisitCount(int count) {
    return '$count回 訪問';
  }

  @override
  String get profileEmptyFavorites => 'お気に入りはまだありません';

  @override
  String get profileEmptyVisits => '訪問履歴はまだありません';

  @override
  String get profileCollapse => '閉じる';

  @override
  String profileMoreCount(int count) {
    return 'あと $count 件';
  }

  @override
  String get profileLiveShareBeta => '友だちと位置/チャットをリアルタイム共有 (ベータ)';

  @override
  String get profileTimeline => 'マイタイムライン';

  @override
  String profilePlaceCount(int count) {
    return '$countヶ所';
  }

  @override
  String get profileEmptyVisitsCta => '訪問履歴がありません。場所を探してルートを試してみましょう。';

  @override
  String get profileToday => '今日';

  @override
  String get profileYesterday => '昨日';

  @override
  String profileMonthDay(int month, int day) {
    return '$month月$day日';
  }

  @override
  String profileVisitTimes(int count) {
    return '$count回';
  }

  @override
  String get profileEditName => '名前を変更';

  @override
  String get profileNewNameHint => '新しい名前を入力';

  @override
  String get profileTagline => 'ソウルのすべての瞬間を';

  @override
  String get profileMore => 'もっと見る';

  @override
  String get profileEmptyMapPlaces => '訪問が貯まると、ここのマップに表示されます';

  @override
  String profileRecentPlaceCount(int count) {
    return '最近の $count ヶ所';
  }

  @override
  String chatSendFailed(String error) {
    return '送信に失敗しました: $error';
  }

  @override
  String get chatRoomDestSet => '🎯 ルームの目的地に設定しました';

  @override
  String chatActionFailed(String error) {
    return '失敗: $error';
  }

  @override
  String get chatMapAppUnavailable => 'マップアプリを開けませんでした';

  @override
  String get chatMicPermissionRequired => 'マイクの権限が必要です';

  @override
  String chatRecordStartFailed(String error) {
    return '録音を開始できませんでした: $error';
  }

  @override
  String get chatRecordTooShort => '短すぎます — 長押しで録音';

  @override
  String chatRecordStopFailed(String error) {
    return '録音を終了できませんでした: $error';
  }

  @override
  String chatPhotoSendFailed(String error) {
    return '写真を送信できませんでした: $error';
  }

  @override
  String get chatSpotifyClientIdMissing =>
      'Spotify 未設定 — 開発者が SPOTIFY_CLIENT_ID を追加する必要があります';

  @override
  String get chatSpotifyAuthRetryHint => 'Spotify 認証後にもう一度押してください';

  @override
  String chatSpotifyAuthFailed(String error) {
    return 'Spotify 接続に失敗: $error';
  }

  @override
  String get chatMyLocation => '現在地';

  @override
  String get chatLocationUnavailable => '位置情報を取得できませんでした';

  @override
  String get chatDefaultRoomName => 'ルーム';

  @override
  String chatMembersInRoom(int count) {
    return '$count 人が参加中';
  }

  @override
  String get chatRecordingHint => '録音中… 離すと送信、上にドラッグでキャンセル';

  @override
  String get chatRecordingPlaceholder => '🎙 録音中';

  @override
  String get chatMessageHint => 'メッセージを入力';

  @override
  String get chatActionMap => 'マップ';

  @override
  String get chatActionDirections => 'ルート';

  @override
  String get chatActionRoomDest => '🎯 ルームの目的地';

  @override
  String chatVoiceLabel(int seconds) {
    return '$seconds秒 音声';
  }

  @override
  String chatPlaybackFailed(String error) {
    return '再生に失敗: $error';
  }

  @override
  String chatEmptyTitleNamed(String roomName) {
    return '$roomName が始まりました';
  }

  @override
  String get chatEmptyTitleDefault => 'ルームが始まりました';

  @override
  String get chatEmptyBody => 'ここで友だちにあいさつしたり、位置を共有したり、\n行き先を一緒に決めたりしましょう。';

  @override
  String get chatStart => '会話を始める';

  @override
  String get chatReport => 'このメッセージを報告';

  @override
  String chatBlockDialogTitle(String nickname) {
    return '$nickname をブロック';
  }

  @override
  String get chatBlockDialogBody => 'ブロックすると、同じルームから即時退出させられ、メッセージも見えなくなります。';

  @override
  String get chatBlockConfirm => 'ブロック';

  @override
  String get chatUnknownUser => 'ユーザー';

  @override
  String get spotifyOpenInApp => 'Spotify で開く';

  @override
  String spotifyShareFailed(String error) {
    return '共有に失敗: $error';
  }

  @override
  String get spotifyNoTrack => '再生中の曲はありません';

  @override
  String get dmAccessDenied => 'この会話にアクセスできません';

  @override
  String dmSendFailed(String error) {
    return '送信に失敗: $error';
  }

  @override
  String get dmDefaultPeer => '友だち';

  @override
  String get dmEmptyHint => '最初のメッセージを送ってみましょう';

  @override
  String get dmMessageHint => 'メッセージ';

  @override
  String get friendCodeLengthError => '8 桁のコードを入力してください。';

  @override
  String get friendCodeNotFound => 'コードに一致するユーザーが見つかりません。';

  @override
  String friendRequestSent(String nickname) {
    return '$nickname さんに友だち申請を送りました。';
  }

  @override
  String get friendShareSubject => 'Seoul Live で友だち追加';

  @override
  String friendShareBody(String nickname, String code) {
    return '$nickname さんから Seoul Live の友だちコードが届きました!\n\nコード: $code\nそのまま追加: com.seoul.prism://friend/$code';
  }

  @override
  String get friendShareCopied => '共有テキストをコピーしました';

  @override
  String get friendCodeTitle => '友だちコード';

  @override
  String get friendCodeSubtitle => '自分のコードを共有するか、友だちのコードで追加できます。';

  @override
  String get friendMyCode => 'マイ友だちコード';

  @override
  String get friendCodeCopied => 'コードをコピーしました';

  @override
  String get friendQrHint => '友だちがカメラでスキャンするとすぐ追加できます';

  @override
  String get friendShareButton => '共有する';

  @override
  String get friendAddByCodeTitle => 'コードで友だち追加';

  @override
  String get friendAddByCodeHint => '受け取った 8 桁のコードを入力するか QR をスキャン';

  @override
  String get friendCodePlaceholder => '例: AB12CD34';

  @override
  String get friendSendRequest => '友だち申請を送る';

  @override
  String peerFriendCode(String code) {
    return '友だちコード $code';
  }

  @override
  String get peerOwnPin => '自分のピンです';

  @override
  String get peerReport => '報告';

  @override
  String peerBlockDialogTitle(String nickname) {
    return '$nickname をブロック';
  }

  @override
  String get peerBlockDialogBody => 'ブロックすると同じルームから退出させられ、メッセージとピンが表示されなくなります。';

  @override
  String get peerBlockConfirm => 'ブロック';

  @override
  String get peerBlock => 'ブロック';

  @override
  String get peerIsFriend => '友だちです ✓';

  @override
  String get peerCancelRequest => '申請を取り消す';

  @override
  String peerRequestCanceled(String nickname) {
    return '$nickname への申請を取り消しました';
  }

  @override
  String get peerAcceptRequest => '友だち申請を承認';

  @override
  String peerNowFriend(String nickname) {
    return '$nickname と友だちになりました';
  }

  @override
  String peerCanRequestInDays(int days) {
    return '$days 日後に再申請可能';
  }

  @override
  String peerCanRequestInHours(int hours) {
    return '$hours 時間後に再申請可能';
  }

  @override
  String get peerSendRequest => '友だち申請を送る';

  @override
  String peerRequestSent(String nickname) {
    return '$nickname に申請を送りました';
  }

  @override
  String peerDistanceMeters(int meters) {
    return '${meters}m 先';
  }

  @override
  String peerDistanceKm(String km) {
    return '${km}km 先';
  }

  @override
  String get spotifyRoomRequired => 'ルームに参加してからもう一度お試しください';

  @override
  String get spotifyShareSuccess => '🎵 ルームに共有しました';

  @override
  String get spotifyDisconnectTitle => 'Spotify 連携を解除';

  @override
  String get spotifyDisconnectBody => '保存されたトークンを削除し、友だちへの曲の共有が止まります。';

  @override
  String get spotifyDisconnectConfirm => '解除';

  @override
  String get spotifyDisconnected => 'Spotify を解除しました';

  @override
  String get spotifyAuthRetryHint => 'Spotify 認証後、自動的に戻ります';

  @override
  String spotifyConnectFailed(String error) {
    return '接続に失敗: $error';
  }

  @override
  String get spotifyClientIdMissing => '開発者の SPOTIFY_CLIENT_ID 未設定';

  @override
  String get spotifyTokenExpired => '接続の有効期限が切れました。再度ログインしてください。';

  @override
  String get spotifyReconnect => 'Spotify を再接続';

  @override
  String get spotifyConnect => 'Spotify を接続';

  @override
  String get spotifyConnectDescription =>
      '接続すると、ルームのチャットで\n聴いている曲を共有でき、友だちが聴いている曲も見られます。';

  @override
  String get spotifyLoginButton => 'Spotify でログイン';

  @override
  String get spotifyShareToRoom => 'ルームに共有';

  @override
  String get spotifyDisconnect => '連携を解除';

  @override
  String get spotifyConnectedNoTrack => 'Spotify 接続中 (再生なし)';

  @override
  String get spotifyNowPlaying => '再生中の曲';

  @override
  String get departureTimePickerTitle => '出発時刻';

  @override
  String get departureTimePickerHint => '指定した時刻を基準に到着時刻を計算します。';

  @override
  String get departureTimeNow => '今すぐ';

  @override
  String get departureTime30min => '30 分後';

  @override
  String get departureTime1hour => '1 時間後';

  @override
  String get departureTimeCustom => '時刻を指定';

  @override
  String get placeActionDepart => '出発';

  @override
  String get placeActionArrive => '到着';

  @override
  String get placeActionInfo => '詳細';

  @override
  String get placeDetailTapHint => 'タップして写真・レビュー・営業時間を見る';

  @override
  String get savedPanelTitle => '保存';

  @override
  String get savedEmptyFavorites => '保存された場所はありません';

  @override
  String get savedRemoveFavoriteTooltip => 'お気に入りから外す';

  @override
  String get travelThemeTitle => 'テーマのおすすめ';

  @override
  String get travelThemeSubtitle => 'ワンタップでコースを自動生成';

  @override
  String get travelTitle => '旅';

  @override
  String get travelSubtitle => '景福宮から漢江の夜景まで、1 日のコースをご提案';

  @override
  String get travelEventsTitle => '今週のイベント';

  @override
  String get travelEventsSubtitle => 'ソウルで開催中の文化イベント';

  @override
  String travelEventsCount(int count) {
    return '$count件';
  }

  @override
  String get travelEventsLoadError => 'イベント情報を取得できませんでした。下に引いて再試行してください。';

  @override
  String get travelAiTitle => 'AI がスケジュールを組みます';

  @override
  String get travelAiSubtitle => '時間・天気・動線を自動考慮';

  @override
  String get travelFromSavedTitle => '保存した場所からつくる';

  @override
  String get travelFromSavedSubtitle => 'お気に入り + 訪問履歴ベースの動線';

  @override
  String get travelYourTheme => 'あなたのテーマ';

  @override
  String get travelStartWithMood => 'このムードでコース開始';

  @override
  String get travelEventBadgeOngoing => '開催中';

  @override
  String get travelEventBadgeFree => '無料';

  @override
  String travelThemeStops(int count) {
    return '$countヶ所';
  }

  @override
  String get travelMoodAnalyzing => '曲の雰囲気を分析中…';

  @override
  String get travelMoodExcited => 'ノリノリな雰囲気には';

  @override
  String get travelMoodToday => 'こんな日には';

  @override
  String get travelMoodIntense => '激しいビートには';

  @override
  String get travelMoodCalm => '落ち着いた雰囲気には';

  @override
  String get travelTodayMoodLabel => '今日の気分';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEmptyTitle => '通知はありません';

  @override
  String get notificationsEmptySubtitle => '新しいお知らせはここに表示されます';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSectionRealtime => 'リアルタイム表示';

  @override
  String get settingsLineSubway => '地下鉄路線';

  @override
  String get settingsTrainPos => '地下鉄列車位置';

  @override
  String get settingsStations => '地下鉄駅';

  @override
  String get settingsBuses => '市バス';

  @override
  String get settingsRiverBus => '漢江バス';

  @override
  String get settingsFlights => '航空機';

  @override
  String get settingsSectionDataSource => 'データソース';

  @override
  String get settingsSubwayMode => '地下鉄モード';

  @override
  String get settingsSubwayModeLive => 'リアルタイム';

  @override
  String get settingsSubwayModeDemo => 'デモ';

  @override
  String get settingsSeoulApi => 'ソウル市公開 API (60s)';

  @override
  String get settingsNaverApi => 'Naver API (5s 補正)';

  @override
  String get settingsSectionLighting => 'ライティング';

  @override
  String get settingsAutoLighting => '自動 (時間帯 + 天気)';

  @override
  String get settingsLightPreset => 'ライトプリセット';

  @override
  String get settingsLightAuto => '自動';

  @override
  String get settingsLightDawn => '夜明け';

  @override
  String get settingsLightDay => '昼';

  @override
  String get settingsLightDusk => '夕方';

  @override
  String get settingsLightNight => '夜';

  @override
  String settingsCountValue(int count) {
    return '$count件';
  }

  @override
  String get settingsLabelFavorites => 'お気に入り';

  @override
  String get settingsLabelVisits => '訪問履歴';

  @override
  String get settingsLabelRecentSearches => '最近の検索';

  @override
  String get settingsAiAssistantLanguage => 'AI アシスタントの言語';

  @override
  String get settingsThemeMode => '画面テーマ';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeChangedTitle => 'テーマを変更';

  @override
  String settingsThemeChangedBody(String theme) {
    return '$theme モードを完全に適用するには再起動が必要です。今すぐ再起動しますか?';
  }

  @override
  String get settingsRestartConfirm => '再起動';

  @override
  String get settingsMapHome => 'マップのホーム起点';

  @override
  String get settingsMapHomeDefault => 'デフォルト';

  @override
  String get settingsMapHomeMyLocation => '現在地';

  @override
  String get settingsMapHomeRecent => '最近の検索';

  @override
  String get settingsKeepScreenOn => '画面の自動ロックをオフ';

  @override
  String get settingsAutoRotate => '画面の自動回転';

  @override
  String get settingsAlwaysMyLocation => 'ルートの出発地を常に現在地に';

  @override
  String get settingsClearHistory => '利用履歴をすべて削除';

  @override
  String get settingsClearSearchHistory => '最近の検索を削除';

  @override
  String get settingsConvertAccount => '正式アカウントに切り替え';

  @override
  String get settingsEditNameItem => '名前を変更';

  @override
  String get settingsChangePassword => 'パスワードを変更';

  @override
  String get settingsLogout => 'ログアウト';

  @override
  String get settingsDeleteAccount => 'アカウント削除';

  @override
  String get settingsMapDataLabel => 'マップ表示とデータ';

  @override
  String get settingsSectionDeveloper => '開発者';

  @override
  String get settingsDebugLogs => 'デバッグログ出力';

  @override
  String get settingsResetTutorial => 'チュートリアルを再生';

  @override
  String get settingsReplayWhatsNew => '新機能の案内をもう一度';

  @override
  String get settingsWhatsNewToast => '次回のアプリ起動時に新機能の案内が表示されます';

  @override
  String get settingsAppVersion => 'アプリのバージョン';

  @override
  String get settingsPrivacy => 'プライバシーポリシー';

  @override
  String get settingsLicenses => 'オープンソースライセンス';

  @override
  String get settingsClearHistoryTitle => '利用履歴を削除';

  @override
  String get settingsClearHistoryBody => 'すべての利用履歴が削除されます。\nこの操作は元に戻せません。';

  @override
  String get commonDelete => '削除';

  @override
  String get settingsClearedHistoryToast => 'すべての利用履歴を削除しました';

  @override
  String get settingsClearSearchTitle => '検索履歴を削除';

  @override
  String get settingsClearSearchBody => '最近の検索履歴がすべて削除されます。';

  @override
  String get settingsClearedSearchToast => '検索履歴を削除しました';

  @override
  String get settingsEditNameDialogTitle => '名前を変更';

  @override
  String get settingsEditNameDialogBody => '新しい名前を入力してください。';

  @override
  String get settingsEditNameConfirm => '変更';

  @override
  String get settingsNewNameDialogTitle => '新しい名前';

  @override
  String get settingsChangePasswordTitle => 'パスワード変更';

  @override
  String settingsChangePasswordBody(String email) {
    return '$email にパスワード再設定リンクを送ります。';
  }

  @override
  String get settingsSendButton => '送信';

  @override
  String get settingsPasswordResetSent => '再設定メールを送信しました';

  @override
  String get settingsLogoutTitle => 'ログアウト';

  @override
  String get settingsLogoutBody => 'ログアウトしますか?';

  @override
  String get settingsLogoutConfirm => 'ログアウト';

  @override
  String get settingsDeleteAccountTitle => 'アカウント削除';

  @override
  String get settingsDeleteAccountBody =>
      'アカウントとすべてのデータが完全に削除されます。\nこの操作は元に戻せません。';

  @override
  String get settingsDeleteAccountConfirm => '削除';

  @override
  String get settingsDeleteError => '削除処理中にエラーが発生しました';

  @override
  String get settingsResetTutorialTitle => 'チュートリアルを再生';

  @override
  String get settingsResetTutorialBody =>
      '保存された進行状況を消去し、次回のアプリ起動時にチュートリアルを最初から表示します。';

  @override
  String get settingsResetTutorialConfirm => '再生';

  @override
  String get settingsMapDisplayTitle => 'マップ表示とデータ';

  @override
  String get settingsSectionMapDisplay => 'マップ表示';

  @override
  String get aiStatusSearchingCourse => 'コースを検索中…';

  @override
  String aiPlacesFound(int count) {
    return '$count件の場所が見つかりました。下からご確認ください。';
  }

  @override
  String get aiStatusFindingInfo => '情報を検索中…';

  @override
  String get aiStatusAnalyzingImage => '画像を分析中…';

  @override
  String get aiNoPlacesFound => '場所が見つかりませんでした。';

  @override
  String aiAnalysisError(String error) {
    return '分析エラー: $error';
  }

  @override
  String get aiSelectPhotoHint => '写真を選択してください';

  @override
  String get aiPhotoShoot => '撮影';

  @override
  String get aiStatusConnecting => '接続中…';

  @override
  String get aiStatusListening => '聞いています';

  @override
  String get aiStatusThinking => '考え中…';

  @override
  String get aiStatusSpeaking => '話しています';

  @override
  String get aiStatusIdle => '待機中';

  @override
  String get aiStatusReady => '準備中';

  @override
  String aiFoundPlacesHeader(int count) {
    return '見つかった場所 ($count)';
  }

  @override
  String get aiVoiceCommandHint => '「カフェを追加して」「景福宮を外して」「これで確定」など、話しかけてください';

  @override
  String aiPlaceStationDistance(String station, int minutes) {
    return '$station駅 · $minutes分';
  }

  @override
  String get aiDefaultSearch => 'ソウル旅行のおすすめコース';

  @override
  String get recommendTitle => 'おすすめ';

  @override
  String recommendSubtitleNearbyArea(String area) {
    return '$area 近くで今人気のスポット';
  }

  @override
  String get recommendSubtitleNearbyDefault => '今近くで人気のスポット';

  @override
  String get recommendRefresh => '更新';

  @override
  String get recommendNoResults => '周辺に結果がありません。\n少し時間をおいて再度お試しください。';

  @override
  String recommendRank(int rank) {
    return '$rank位';
  }

  @override
  String get recommendEventsLoadError =>
      '文化イベント情報を取得できませんでした。\n少し時間をおいて再度お試しください。';

  @override
  String get recommendStatusUpcoming => '予定';

  @override
  String get recommendBadgePaid => '有料';

  @override
  String get recommendUniqueMood => '✨ あなたの';

  @override
  String get recommendTabFood => '🍜 グルメ';

  @override
  String get recommendTabCafe => '☕️ カフェ';

  @override
  String get recommendTabShopping => '🛍 ショッピング';

  @override
  String get recommendTabOutdoor => '🌳 公園・夜景';

  @override
  String get recommendTabEvents => '🎭 カルチャー';

  @override
  String get authTabSignUp => '新規登録';

  @override
  String get authTabSignIn => 'ログイン';

  @override
  String get authProcessing => '処理中…';

  @override
  String get authSignIn => 'ログイン';

  @override
  String get authSignUp => '新規登録';

  @override
  String get authLabelEmail => 'メールアドレス';

  @override
  String get authHintEmail => 'メールアドレスを入力してください';

  @override
  String get authLabelPassword => 'パスワード';

  @override
  String get authHintPassword => 'パスワードを入力してください';

  @override
  String get authFindId => 'ID を探す';

  @override
  String get authFindPassword => 'パスワードを探す';

  @override
  String get authLabelUsername => 'ID';

  @override
  String get authHintUsername => 'ID を入力してください';

  @override
  String get authLabelConfirmPassword => 'パスワード確認';

  @override
  String get authHintConfirmPassword => 'パスワードを再入力してください';

  @override
  String get authSnsLogin => 'SNS アカウントでログイン';

  @override
  String get authGoogleAuthFailed => 'Google 認証に失敗しました';

  @override
  String get authGoogleSignInFailed => 'Google ログインに失敗しました';

  @override
  String get authGuestSignInFailed => 'ゲストログインに失敗しました';

  @override
  String get authAppleAuthFailed => 'Apple 認証に失敗しました';

  @override
  String get authAppleSignInCanceled => 'Apple ログインがキャンセルされました';

  @override
  String get authAppleSignInFailed => 'Apple ログインに失敗しました';

  @override
  String get authEmailAndPasswordRequired => 'メールアドレスとパスワードを入力してください';

  @override
  String get authUsernameRequired => 'ID を入力してください';

  @override
  String get authPasswordMismatch => 'パスワードが一致しません';

  @override
  String get authPasswordTooShort => 'パスワードは 6 文字以上である必要があります';

  @override
  String get authGenericError => 'エラーが発生しました';

  @override
  String get authErrorInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get authErrorEmailExists => '既に登録されているメールアドレスです';

  @override
  String get authErrorInvalidEmail => '正しいメールアドレス形式を入力してください';

  @override
  String get authErrorEmailNotConfirmed => 'メール認証が完了していません。メールボックスをご確認ください。';

  @override
  String get authEmailConfirmRequiredTitle => 'メール認証が必要';

  @override
  String authEmailConfirmRequiredBody(String email) {
    return '$email に認証メールを送信しました。\nメールボックスを確認し、認証を完了してからログインしてください。';
  }

  @override
  String get authFindIdResultTitle => 'ID 検索結果';

  @override
  String get authFindIdResultBefore => 'あなたの ID は ';

  @override
  String get authFindIdResultAfter => ' です。';

  @override
  String get authFindIdEmailRequired => 'メールアドレスを入力してください';

  @override
  String get authFindIdNotFound => 'そのメールアドレスで登録されたアカウントが見つかりません';

  @override
  String get authPasswordResetSent => 'パスワード再設定リンクをメールで送信しました';

  @override
  String get authFindIdFailed => 'ID 検索に失敗しました';

  @override
  String get authEmailSendFailed => 'メール送信に失敗しました';

  @override
  String get authFindIdTitle => 'ID を探す';

  @override
  String get authFindPasswordTitle => 'パスワードを探す';

  @override
  String get authFindIdBody => '登録時に使用したメールアドレスを入力すると\nID をお知らせします。';

  @override
  String get authFindPasswordBody => 'メールアドレスを入力すると\nパスワード再設定リンクをお送りします。';

  @override
  String get authFindIdEmailHint => '登録したメールアドレスを入力してください';

  @override
  String get authFindIdSubmit => 'ID を探す';

  @override
  String get authFindPasswordSubmit => '再設定リンクを受け取る';

  @override
  String get hubSettingsTooltip => '設定';

  @override
  String get hubAuthExploreSeoulTitle => '友だちと一緒にソウルを探検';

  @override
  String get hubAuthCreateProfileSubtitle => 'ニックネームとピンを作って始めましょう。';

  @override
  String get hubAuthCreateProfileButton => 'プロフィール作成';

  @override
  String get hubPausedNotice => 'Seoul Live 一時停止中 — 位置・通知ブロック、チャットは可能';

  @override
  String get hubResumeButton => '再開';

  @override
  String get hubRoomTitle => 'ルーム';

  @override
  String get hubRoomEmpty => '新しいルームを作る、またはコードで参加';

  @override
  String hubRoomCurrent(String code) {
    return '参加中 · コード $code';
  }

  @override
  String get hubFriendsTitle => '友だち';

  @override
  String hubFriendsSubtitle(int count, int requests) {
    return '$count人 · 申請 $requests件';
  }

  @override
  String get hubDmSubtitle => '友だちと 1:1 トーク';

  @override
  String get hubFriendCodeTitle => '友だちコード';

  @override
  String hubFriendCodeSubtitle(String code) {
    return 'マイコード $code を共有 / 入力';
  }

  @override
  String get hubFriendGroupsTitle => '友だちグループ';

  @override
  String hubFriendGroupsSubtitle(int count) {
    return '$countグループ';
  }

  @override
  String get hubSpotifyConnectedNoPlayback => '接続中 — 再生なし';

  @override
  String get hubSpotifyShareSubtitle => '聴いている曲を友だちに共有';

  @override
  String get hubVisibilityGhost => '非公開 — 送受信どちらも不可';

  @override
  String get hubVisibilityFriends => 'ルーム内 — 同じルームのメンバーのみ';

  @override
  String get hubVisibilityPublic => '全体公開 — すべての Seoul Live ユーザー';

  @override
  String get hubActivityTitle => 'マイアクティビティ';

  @override
  String get hubStatMeetups => '出会い';

  @override
  String get hubStatFriends => '友だち';

  @override
  String get hubStatStreak => '連続';

  @override
  String hubStatStreakValue(int days) {
    return '$days日';
  }

  @override
  String hubStatStreakBest(int days) {
    return '最高 $days';
  }

  @override
  String get hubBadgesEmptyHint => '初めての友だちや初めての出会いでバッジを集めましょう';

  @override
  String get hubAgoJust => 'たった今';

  @override
  String hubAgoMin(int min) {
    return '$min分前';
  }

  @override
  String hubAgoHour(int hour) {
    return '$hour時間前';
  }

  @override
  String hubAgoDay(int day) {
    return '$day日前';
  }

  @override
  String get hubRecentMeetupsTitle => '🎉 最近の出会い';

  @override
  String hubRecentMeetupsCount(int count) {
    return '$count回';
  }

  @override
  String get roomCodeRequired => '6 桁のコードを入力してください。';

  @override
  String get roomLeaveTitle => 'ルームから退出';

  @override
  String get roomLeaveBody => '退出すると位置共有とチャットが終了します。';

  @override
  String get roomLeaveConfirm => '退出';

  @override
  String get roomTitle => 'ルーム';

  @override
  String get roomDescription => 'リアルタイムで友だちと位置/チャットを共有します。';

  @override
  String get roomCapacityNote => 'ルームは 24 時間後に自動失効、定員 8 名。';

  @override
  String get roomCreateButton => '新しいルームを作成';

  @override
  String get roomCodeEntryTitle => '招待コードで参加 (6 桁)';

  @override
  String get roomJoinButton => '参加';

  @override
  String roomExpiresInMin(int min) {
    return '$min 分後に失効';
  }

  @override
  String get roomDefaultName => '名前のないルーム';

  @override
  String get roomInviteCode => '招待コード';

  @override
  String get roomCodeCopied => 'コードをコピーしました';

  @override
  String roomExpiresInHours(int hour) {
    return '$hour 時間後に失効';
  }

  @override
  String roomMembers(int current, int max) {
    return 'メンバー ($current/$max)';
  }

  @override
  String roomChatOpenWithUnread(int count) {
    return 'チャットを開く ($count)';
  }

  @override
  String get roomChatOpen => 'チャットを開く';

  @override
  String get roomLeaveButton => 'ルームから退出';

  @override
  String get roomEditNameTitle => 'ルーム名を変更';

  @override
  String get roomEditNameBody => 'メンバーに表示される名前です';

  @override
  String get roomEditNamePlaceholder => '例: 光化門の集まり';

  @override
  String roomGenericError(String error) {
    return '失敗: $error';
  }

  @override
  String get roomShareSubject => 'Seoul Live ルーム招待';

  @override
  String roomShareBody(String nickname, String code) {
    return '$nickname さんから Seoul Live ルームに招待が届きました!\n\nコード: $code\nそのまま参加: com.seoul.prism://room/$code';
  }

  @override
  String get roomInviteTextCopied => '招待テキストをコピーしました';

  @override
  String get roomRefreshCodeTitle => '招待コードを更新';

  @override
  String get roomRefreshCodeBody => '既存のコードは直ちに無効になります。続行しますか?';

  @override
  String get roomRefreshCodeConfirm => '更新';

  @override
  String get roomCodeRefreshed => 'コードを更新しました';

  @override
  String roomKickTitle(String nickname) {
    return '$nickname をキック';
  }

  @override
  String get roomKickBody => 'ルームからすぐに退出させられます。';

  @override
  String get roomKickConfirm => 'キック';

  @override
  String get roomKickFallbackName => 'メンバー';

  @override
  String roomNameMe(String name) {
    return '$name (自分)';
  }

  @override
  String get roomMeetupBadge => '出会い';

  @override
  String get roomKickTooltip => 'キック';

  @override
  String get roomUnknownUser => '誰か';

  @override
  String roomDestTitle(String name) {
    return '🎯 一緒に行く — $name';
  }

  @override
  String roomDestSetBy(String name) {
    return '$name さんが設定';
  }

  @override
  String get roomDestDefault => '目的地';

  @override
  String get roomDestViewMap => 'マップで見る';

  @override
  String get roomDestClear => '目的地を解除';

  @override
  String get mpSettingsTitle => 'Seoul Live 設定';

  @override
  String get mpSectionMyStatus => '私の状態';

  @override
  String get mpPause => 'Seoul Live を一時停止';

  @override
  String get mpPauseHint =>
      '✓ チャット / ルーム参加 / 友だち申請 — 可能\n✗ 位置送信 / 出会い通知 / ピン表示 — ブロック\nデータはそのまま保持';

  @override
  String get mpSectionBattery => 'バッテリーモード';

  @override
  String get mpBatteryHint => '位置送信の間隔 — 正確なほど消費電力が大';

  @override
  String get mpSectionNotifications => '通知';

  @override
  String mpNotificationsFail(String error) {
    return '失敗: $error';
  }

  @override
  String get mpNotificationsHint => 'システム通知権限とは別 — ここで切るとプッシュは送信されてもサイレントに。';

  @override
  String get mpSectionTutorial => 'チュートリアル';

  @override
  String get mpReplayTutorial => 'Seoul Live チュートリアルをもう一度';

  @override
  String get mpTutorialToast => '次回入った時にチュートリアルが再表示されます';

  @override
  String get mpReplayWhatsNew => '新機能の案内をもう一度';

  @override
  String mpReplayWhatsNewHint(String version) {
    return 'v$version の更新内容';
  }

  @override
  String get mpSectionSafety => 'セーフティ';

  @override
  String get mpBlockList => 'ブロックリスト';

  @override
  String get mpBlockListHint => 'ブロック中のユーザーを表示/解除';

  @override
  String get mpSectionConsent => '同意とデータ';

  @override
  String get mpRevokeConsent => '位置情報同意を撤回';

  @override
  String get mpRevokeConsentHint => '同意を撤回するとマルチプレイが無効になり、すべてのデータが削除されます';

  @override
  String get mpDownloadMyData => 'マイデータをダウンロード';

  @override
  String get mpDownloadMyDataHint => 'PIPA データポータビリティ — メールで依頼';

  @override
  String get mpDownloadMyDataToast =>
      'rush94434@gmail.com にお問い合わせください (10 日以内に対応)';

  @override
  String get mpSectionOps => '運営チーム';

  @override
  String get mpOpsMonitor => '運営モニター';

  @override
  String get mpOpsMonitorHint => '日次指標 · 不正シグナル · 報告対応';

  @override
  String get mpSectionDanger => '危険ゾーン';

  @override
  String get mpLeaveSeoulLive => 'Seoul Live を退会';

  @override
  String get mpLeaveSeoulLiveHint => 'プロフィール・友だち・ルーム・チャットなどマルチプレイデータを一括削除';

  @override
  String get mpFootnote => '※ Seoul Vista 本アカウントは保持されます。マルチプレイ関連データのみ削除されます。';

  @override
  String get mpRevokeDialogTitle => '同意を撤回';

  @override
  String get mpRevokeDialogBody =>
      '位置情報処理の同意を撤回するとマルチプレイが無効になり、\nプロフィール・友だち・ルーム・チャットがすべて削除されます。\n続行しますか?';

  @override
  String get mpRevokeDialogConfirm => '撤回';

  @override
  String get mpRevokedToast => '同意を撤回しデータを削除しました';

  @override
  String get mpLeaveDialogTitle => 'Seoul Live 退会';

  @override
  String get mpLeaveDialogBody =>
      'すべてのマルチプレイデータが完全に削除されます。\n再加入できますが、友だち・ルーム・チャット履歴は復元されません。';

  @override
  String get mpLeaveConfirm => '退会';

  @override
  String get mpLeftToast => 'Seoul Live から退会しました';

  @override
  String get mpNotifCatFriendRequest => '友だち申請';

  @override
  String get mpNotifCatFriendAccept => '友だち承認';

  @override
  String get mpNotifCatRoomMessage => 'チャットメッセージ';

  @override
  String get mpNotifCatMeetup => '出会い検知';

  @override
  String get mpNotifCatDestination => '目的地の変更';

  @override
  String get mpNotifCatWelcome => 'ようこそ';

  @override
  String get panelSubway => '地下鉄';

  @override
  String get panelBus => 'バス';

  @override
  String get panelFlights => '航空機';

  @override
  String get panelDisplay => '表示';

  @override
  String get panelLineFilter => '路線フィルター';

  @override
  String get panelPerformance => 'パフォーマンス';

  @override
  String get panelLighting => 'ライティング';

  @override
  String get panelInfo => '情報';

  @override
  String get panelDeveloper => '開発者';

  @override
  String get panelDemoRunning => 'DEMO 実行中';

  @override
  String get panelLiveRunning => 'LIVE 実行中';

  @override
  String get panelOff => 'オフ';

  @override
  String get panelSwitchToLive => 'LIVE モードに切替';

  @override
  String get panelSwitchToDemo => 'DEMO モードに切替';

  @override
  String get panelSubwayOn => '地下鉄をオン';

  @override
  String get panelSubwayOff => '地下鉄をオフ';

  @override
  String panelTrainCount(int count) {
    return '列車 $count 本';
  }

  @override
  String panelLastUpdate(String time) {
    return '更新 $time';
  }

  @override
  String panelBusActive(int count) {
    return 'バス $count 台表示中';
  }

  @override
  String get panelSelectRoutes => '路線を選んでください';

  @override
  String get panelTurnAllOff => 'すべてオフ';

  @override
  String get panelBusPosition => 'バス位置';

  @override
  String get panelHanRiverBus => '🚢 漢江バス';

  @override
  String get panelAddRoute => '路線を追加';

  @override
  String panelFlightCount(String mode, int count) {
    return '$mode $count 機';
  }

  @override
  String get panelFlightFallback => '航空機';

  @override
  String get panelFlightLegendClimb => '上昇';

  @override
  String get panelFlightLegendCruise => '巡航';

  @override
  String get panelFlightLegendDescend => '下降';

  @override
  String get panelFlightLegendTakeoffLanding => '離着陸';

  @override
  String get panelRouteLines => '路線経路';

  @override
  String get panelTrainPosition => '列車位置';

  @override
  String get panelStationDisplay => '駅表示';

  @override
  String get panelSelectRoutesToShow => '表示する路線を選択';

  @override
  String get panelAll => 'すべて';

  @override
  String get panelPresetHigh => '高';

  @override
  String get panelPresetMedium => '中';

  @override
  String get panelPresetLow => '低';

  @override
  String get panelFps => 'FPS';

  @override
  String get panelNaverPolling => 'Naver ポーリング';

  @override
  String panelRenderInfo(String engine) {
    return 'レンダリング: $engine · GeoJSON キャッシュ';
  }

  @override
  String get panelLightAuto => '自動';

  @override
  String get panelLightDay => '昼';

  @override
  String get panelLightNight => '夜';

  @override
  String get panelLightDawn => '夜明け';

  @override
  String get panelLightDusk => '夕暮れ';

  @override
  String get panelTierFlagship => 'フラッグシップ';

  @override
  String get panelTierHigh => 'ハイ';

  @override
  String get panelTierMid => 'ミドル';

  @override
  String get panelTierLow => 'ロー';

  @override
  String get panelMapEngine => 'マップエンジン';

  @override
  String get panelDevice => 'デバイス';

  @override
  String get panelPerfTier => 'パフォーマンスティア';

  @override
  String get mapDisplay3D => '3D 建物表示';

  @override
  String get mapDisplayPois => 'POI アイコン表示';

  @override
  String get mapDisplayWeather => '天気エフェクト (霧/雨)';

  @override
  String get mapDisplayLiveSubway => 'リアルタイム地下鉄';

  @override
  String get friendsGroupTooltip => '友だちグループ';

  @override
  String get friendsCodeTooltip => '友だちコード';

  @override
  String get friendsAddByNickname => 'ニックネームで友だち追加';

  @override
  String get friendsSearchPlaceholder => 'ニックネームを入力して検索';

  @override
  String get friendsSearching => '検索中…';

  @override
  String get friendsSearch => '検索';

  @override
  String friendsNotFound(String query) {
    return '\"$query\" に一致するユーザーが見つかりません';
  }

  @override
  String get friendsSearchHint => 'ニックネームは完全一致が必要です。友だちコード (8 桁) もお試しください。';

  @override
  String friendsReceivedRequests(int count) {
    return '受信した申請 ($count)';
  }

  @override
  String get friendsAccept => '承認';

  @override
  String get friendsReject => '拒否';

  @override
  String friendsMyFriends(int count) {
    return '私の友だち ($count)';
  }

  @override
  String get friendsEmpty => '友だちはまだいません。ニックネームで追加してみてください。';

  @override
  String get friendsCooldownTooltip => '拒否された申請は 7 日後に再送信できます';

  @override
  String friendsCooldownDays(int days) {
    return '$days 日後に再申請';
  }

  @override
  String friendsCooldownHours(int hours) {
    return '$hours 時間後';
  }

  @override
  String get friendsBadgeFriend => '友だち';

  @override
  String get friendsBadgeRequested => '申請済';

  @override
  String get friendsApply => '申請';

  @override
  String friendsSendingRequestHint(String nickname) {
    return '$nickname さんに友だち申請 — 承認されると通知が届きます';
  }

  @override
  String friendsDmStartFailed(String error) {
    return 'DM 開始に失敗: $error';
  }

  @override
  String get friendsUnfriend => '友だち解除';

  @override
  String get friendsReport => '通報';

  @override
  String get friendsBlock => 'ブロック';

  @override
  String get friendsBlockDialogTitleFallback => 'このユーザーをブロック';

  @override
  String friendsBlockDialogTitle(String nickname) {
    return '$nickname をブロック';
  }

  @override
  String get friendsBlockDialogBody => 'ブロックすると同じルームに入れず、メッセージも表示されません。';

  @override
  String get friendsBlockConfirm => 'ブロック';

  @override
  String get friendsUnknown => '不明';

  @override
  String friendsRequestSent(String nickname) {
    return '$nickname さんに友だち申請を送りました';
  }

  @override
  String friendsFailure(String error) {
    return '失敗: $error';
  }

  @override
  String get friendsSuggestionsTitle => 'おすすめの友だち (友だちの友だち)';

  @override
  String friendsMutualCount(int count) {
    return '共通の友だち $count 人';
  }

  @override
  String get friendsAddShort => '追加';
}
