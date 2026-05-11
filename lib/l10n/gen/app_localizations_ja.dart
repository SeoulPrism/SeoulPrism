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
  String get languageChangedTitle => '言語を保存しました';

  @override
  String get languageChangedBody =>
      '新しい言語を完全に適用するには、Appスイッチャーで上にスワイプしてアプリを閉じ、もう一度開いてください。';

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
  String get whatsNewPage9Title => '経路をひとまとめに';

  @override
  String get whatsNewPage9Body =>
      '地下鉄・バス・徒歩をひとつに。\n乗り換え、リアルタイム到着、駅の出口まで\n同じ画面で。';

  @override
  String get whatsNewPage10Title => '一日プラン、自動で';

  @override
  String get whatsNewPage10Body =>
      '保存した場所から一日コースを作成。\n効率重視・のんびり・グルメ中心、\n3つのスタイルから。';

  @override
  String get whatsNewPage11Title => 'あなたの言葉で';

  @override
  String get whatsNewPage11Body =>
      '韓国語・英語・日本語・中国語。\nAIアシスタントも同じ言語で。\n端末の言語に自動で合わせます。';

  @override
  String get whatsNewPage12Title => '声でたずねる';

  @override
  String get whatsNewPage12Body =>
      'AIアシスタントと声で自然に。\n検索・経路・おすすめも声で。\nGemini Live が聞いてその場で答えます。';

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
  String get settingsThemeChangedTitle => 'テーマを保存しました';

  @override
  String settingsThemeChangedBody(String theme) {
    return '$theme モードを完全に適用するには、Appスイッチャーで上にスワイプしてアプリを閉じ、もう一度開いてください。';
  }

  @override
  String get settingsRestartConfirm => 'OK';

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

  @override
  String get searchRouteNotFound => '経路が見つかりませんでした。出発地/到着地をご確認ください。';

  @override
  String get searchLocationUnavailable =>
      '現在地を取得できませんでした。位置情報の権限と GPS をご確認ください。';

  @override
  String get searchTabRoute => 'ルート';

  @override
  String get searchTabProfile => 'プロフィール';

  @override
  String get searchPathTypeOptimal => '最適';

  @override
  String get searchPathTypeShortest => '最短';

  @override
  String get searchPathTypeMinTransfer => '乗換最小';

  @override
  String get searchOutsideServiceTitle => 'サービスエリア外です';

  @override
  String get searchOutsideServiceBody =>
      '現在のルート機能はソウル・仁川・京畿の首都圏のみ対応しています。出発または到着地を首都圏内で選び直してください。';

  @override
  String get searchDepartureFieldHint => '出発地';

  @override
  String get searchArrivalFieldHint => '到着地';

  @override
  String get searchSwapDepArr => '出発地と到着地を入れ替え';

  @override
  String get searchCloseTooltip => 'ルート画面を閉じる';

  @override
  String get searchPlaceholder => '場所・バス・地下鉄を検索';

  @override
  String get searchClearLabel => '検索をクリア';

  @override
  String get searchRecentTitle => '最近の検索';

  @override
  String get searchRecentClearAll => 'すべて削除';

  @override
  String get searchRecentRoutesTitle => '最近のルート';

  @override
  String get searchBusTypeTrunk => '幹線';

  @override
  String get searchBusTypeBranch => '支線';

  @override
  String get searchBusTypeCircular => '循環';

  @override
  String get searchBusTypeMetro => '広域';

  @override
  String get searchBusTypeIncheon => '仁川';

  @override
  String get searchBusTypeGyeonggi => '京畿';

  @override
  String get searchBusTypeDefault => 'バス';

  @override
  String get searchCatFood => '飲食';

  @override
  String get searchCatCafe => 'カフェ';

  @override
  String get searchCatPark => '公園';

  @override
  String get searchCatShopping => 'ショッピング';

  @override
  String get searchCatMedical => '医療';

  @override
  String get searchCatEducation => '教育';

  @override
  String get searchCatLodging => '宿泊';

  @override
  String get searchCatFinance => '金融';

  @override
  String get searchCatTransit => '交通';

  @override
  String get searchCatAddress => '住所';

  @override
  String get searchCatCity => '都市';

  @override
  String get searchCatNeighborhood => '町';

  @override
  String get searchCatRoad => '道路';

  @override
  String liveBadgePeerTrack(String nickname, String track) {
    return '$nickname さんが $track を聴いています';
  }

  @override
  String liveBadgeSharing(int count) {
    return '$count 人と位置共有中';
  }

  @override
  String get liveBadgeStopped => '位置共有を停止しました';

  @override
  String get seoulLiveStartTitle => 'Seoul Live 開始';

  @override
  String get seoulLiveStartBody => 'マップが世界に広がりました';

  @override
  String get seoulLiveStep2Title => '友だちのピンがマップに表示';

  @override
  String get seoulLiveStep2Body =>
      '同じルームのメンバーがピン (ニックネーム + 絵文字) でリアルタイム表示されます。友だちが動くとピンも一緒に動きます。';

  @override
  String get seoulLiveStep3Title => 'ルームコードで集合';

  @override
  String get seoulLiveStep3Body =>
      'プロフィール → Seoul Live → ルームで新しいルームを作るか、6 桁の招待コードで参加しましょう。定員は 8 人です。';

  @override
  String get seoulLiveStep4Title => '50m 以内で出会い通知';

  @override
  String get seoulLiveStep4Body => '友だちと近づくとハプティックと通知が鳴ります。チャットにも自動で記録されます。';

  @override
  String get seoulLiveStep5Title => 'いつでも非公開モード';

  @override
  String get seoulLiveStep5Body =>
      '上部の「位置共有中」バッジをタップすると、すぐに ghost モードに切り替わります。ルームを出ると自動で送信が止まります。';

  @override
  String get seoulLivePermTitle => '通知を受け取る';

  @override
  String get seoulLivePermBody =>
      '友だち申請 / 新メッセージ / 出会いが発生したらプッシュ通知でお知らせします。下の「許可」を押してください。';

  @override
  String get seoulLivePermAllowed => '✓ 通知を許可しました';

  @override
  String get seoulLivePermDenied => '拒否されました — 設定から手動で許可できます';

  @override
  String get seoulLivePermRequesting => 'リクエスト中…';

  @override
  String get seoulLivePermAllow => '通知を許可';

  @override
  String get roomMembersEmpty => '一緒にいる友だちがいません';

  @override
  String roomMembersWithCount(int count) {
    return '一緒にいる友だち $count 人';
  }

  @override
  String get roomMembersGhost => '非公開';

  @override
  String get roomMembersDisconnected => '未接続';

  @override
  String get roomMembersRealtime => 'リアルタイム';

  @override
  String get roomMembersStale => '少し離れています';

  @override
  String get dmListAgoJust => 'たった今';

  @override
  String dmListAgoMin(int min) {
    return '$min 分';
  }

  @override
  String dmListAgoHour(int hour) {
    return '$hour 時間';
  }

  @override
  String dmListAgoDay(int day) {
    return '$day 日';
  }

  @override
  String get dmListKindVoice => '🎙 音声';

  @override
  String get dmListKindImage => '🖼 写真';

  @override
  String get dmListKindPlace => '📍 場所';

  @override
  String get dmListKindSpotify => '🎵 曲';

  @override
  String get dmListEmpty => 'まだ DM がありません';

  @override
  String get dmListEmptyHint => '友だち画面でメッセージボタンから開始';

  @override
  String get friendGroupsNewTitle => '新しいグループ';

  @override
  String get friendGroupsNewTooltip => '新しいグループ';

  @override
  String get friendGroupsEmpty => 'まだグループがありません';

  @override
  String get friendGroupsEmptyHint => '上の + でグループを作成しましょう';

  @override
  String get friendGroupsEmptyHintAlt => '右上の + ボタンでグループを作って友だちを分類しましょう。';

  @override
  String get friendGroupsNamePlaceholder => '例: 家族・会社・サークル';

  @override
  String get friendGroupsCreate => '作成';

  @override
  String get friendGroupsCreated => 'グループを作成しました';

  @override
  String friendGroupsFailure(String error) {
    return '失敗: $error';
  }

  @override
  String friendGroupsDeleteTitle(String emoji, String name) {
    return '$emoji $name を削除';
  }

  @override
  String get friendGroupsDeleteBody => 'グループのみ削除されます。友だちは残ります。';

  @override
  String get friendGroupsDelete => '削除';

  @override
  String get friendGroupsName => '名前';

  @override
  String get friendGroupsIcon => 'アイコン';

  @override
  String friendGroupsMemberCount(int count) {
    return '$count 人';
  }

  @override
  String get friendGroupsNoFriendsPrompt => 'まず友だちを追加してください。';

  @override
  String get friendGroupsVisibilityHint => 'グループ別の公開範囲 / チャットに使えます';

  @override
  String friendGroupsMembersTitle(String emoji, String name) {
    return '$emoji $name のメンバー';
  }

  @override
  String get friendGroupsEditMembers => 'メンバーを編集';

  @override
  String get friendGroupsEmptyFriendsBox => 'まだ友だちがいません';

  @override
  String get loginRequiredTitle => 'ログインが必要です';

  @override
  String get loginRequiredBody =>
      'マルチプレイは正式ログインユーザーのみ利用できます。\nゲスト (匿名) アカウントは 30 日未使用で自動削除されるため、\n友だち・ルーム情報が失われる可能性があります。';

  @override
  String get loginRequiredCta => 'ログイン';

  @override
  String get reportReasonSpam => 'スパム/広告';

  @override
  String get reportReasonHate => '暴言/ヘイト表現';

  @override
  String get reportReasonSexual => '性的/不快なコンテンツ';

  @override
  String get reportReasonHarass => '嫌がらせ/ストーキング';

  @override
  String get reportReasonFakeLocation => '偽の位置/なりすまし';

  @override
  String get reportReasonMinorAbuse => '未成年者保護違反';

  @override
  String get reportReasonOther => 'その他';

  @override
  String get reportSelectReason => '理由を選択してください。';

  @override
  String get reportSubmitted => '報告を受け付けました。24 時間以内に審査します。';

  @override
  String reportTitleUser(String label) {
    return '$label を報告';
  }

  @override
  String get reportTitleMessage => 'メッセージを報告';

  @override
  String get reportNote => '運営チームが審査後 24 時間以内に対応します。';

  @override
  String get reportExtraPlaceholder => '詳細 (任意)';

  @override
  String get reportSubmit => '報告する';

  @override
  String get reportSubmitting => '送信中…';

  @override
  String get reportFallbackUser => 'ユーザー';

  @override
  String get blockedUsersTitle => 'ブロックリスト';

  @override
  String get blockedUsersEmpty => 'ブロック中のユーザーはいません';

  @override
  String blockedUsersUnblockTitle(String name) {
    return '$name のブロックを解除';
  }

  @override
  String get blockedUsersUnblockBody => '解除すると再び出会えるようになり、メッセージも表示されます。';

  @override
  String get blockedUsersUnblockConfirm => '解除';

  @override
  String get activityTitle => 'アクティビティ';

  @override
  String get activityCatMeetup => '🎉 出会い';

  @override
  String get activityCatFriend => '🤝 友だち';

  @override
  String get activityCatRoomJoined => '🚪 ルーム参加';

  @override
  String get activityCatPlaceShared => '📍 場所共有';

  @override
  String get activityCatDestination => '🎯 目的地';

  @override
  String get activityAgoJust => 'たった今';

  @override
  String activityAgoMin(int min) {
    return '$min 分前';
  }

  @override
  String activityAgoHour(int hour) {
    return '$hour 時間前';
  }

  @override
  String activityAgoDay(int day) {
    return '$day 日前';
  }

  @override
  String get activityRanking => '友だちランキング';

  @override
  String get activityRecent => '最近のアクティビティ';

  @override
  String get activityEmpty => 'まだ記録された活動がありません';

  @override
  String activityCode(String code) {
    return 'コード $code';
  }

  @override
  String get activityThisWeek => '今週のアクティビティ';

  @override
  String activityTotalCount(int count) {
    return '計 $count 件';
  }

  @override
  String get activityWeekdayMon => '月';

  @override
  String get activityWeekdayTue => '火';

  @override
  String get activityWeekdayWed => '水';

  @override
  String get activityWeekdayThu => '木';

  @override
  String get activityWeekdayFri => '金';

  @override
  String get activityWeekdaySat => '土';

  @override
  String get activityWeekdaySun => '日';

  @override
  String get peerNowPlayingBtnFriend => '友だちです ✓';

  @override
  String get peerNowPlayingBtnRequested => '申請済';

  @override
  String get peerNowPlayingBtnAccept => '友だち申請を承認';

  @override
  String get peerNowPlayingBtnSendRequest => '友だち申請を送る';

  @override
  String get peerNowPlayingOpenInSpotify => 'Spotify で聴く';

  @override
  String get mapNoLocationPermission =>
      '位置情報の権限がないため、友だちにピンが見えません。設定 → 位置情報 で許可してください。';

  @override
  String get mapLeftRoom => 'ルームから退出しました';

  @override
  String mapShowOnMap(String name) {
    return 'マップで \"$name\" を見る';
  }

  @override
  String mapBuildingInside(String name) {
    return '🏢 $name の中にいます';
  }

  @override
  String get mapLocationChecking => '位置確認中…';

  @override
  String get mapLocationPermissionDenied =>
      '位置情報の権限が拒否されています → iOS 設定 → Seoul Vista → 位置情報';

  @override
  String get mapLocationServiceOff => 'iOS 設定 → プライバシー → 位置情報サービスがオフです';

  @override
  String get mapMyLocationMoved => '現在地に移動しました';

  @override
  String mapLocationFetchFailed(String error) {
    return '位置取得に失敗: $error';
  }

  @override
  String get mapMapAppUnavailable => 'マップアプリを開けませんでした';

  @override
  String get mapTabRecommend => 'おすすめ';

  @override
  String get mapTabSave => '保存';

  @override
  String get mapTabMap => 'マップ';

  @override
  String get mapTabWorld => '世界';

  @override
  String get mapTabTrip => '旅';

  @override
  String get mapDirectionsRoadFetching => '車のルートを取得中…';

  @override
  String get mapDirectionsWalkFetching => '徒歩のルートを取得中…';

  @override
  String get mapNoCoords => '出発/到着の座標が見つかりません';

  @override
  String get mapDirectionsFailed => 'ルートを取得できませんでした';

  @override
  String mapInsufficientSavedPlaces(int min) {
    return '場所がもっと必要です — お気に入り/訪問履歴が $min 件以上になると自動生成されます';
  }

  @override
  String get subwayPanelExpand => 'パネルを展開';

  @override
  String get subwayPanelCollapse => 'パネルを折りたたむ';

  @override
  String subwayPanelDelayedTrains(int count) {
    return '遅延列車 $count 本';
  }

  @override
  String subwayPanelMinutes(int min) {
    return '$min 分';
  }

  @override
  String subwayPanelOthersCount(int count) {
    return 'ほか $count 本…';
  }

  @override
  String get subwayPanelOffTapToStart => 'OFF — タップで開始';

  @override
  String get subwayPanelMode => 'モード';

  @override
  String get subwayPanelDemoLabel => 'デモ (API 不使用)';

  @override
  String get subwayPanelLiveLabel => 'リアルタイム';

  @override
  String get subwayPanelTrainsLabel => '列車数';

  @override
  String subwayPanelTrainsValue(int count) {
    return '$count 本';
  }

  @override
  String get subwayPanelUpdate => '更新';

  @override
  String get subwayPanelToggleRoutes => '路線';

  @override
  String get subwayPanelToggleTrains => '列車位置';

  @override
  String get subwayPanelToggleStations => '駅表示';

  @override
  String get subwayPanelToggleCongestion => '混雑度';

  @override
  String get subwayPanelRouteFilter => '路線フィルター';

  @override
  String get subwayPanelAll => 'すべて';

  @override
  String get subwayPanelToggleOn => '地下鉄ビジュアライゼーションをオン';

  @override
  String get subwayPanelToggleOff => '地下鉄ビジュアライゼーションをオフ';

  @override
  String get subwayPanelNoArrivalInfo => '到着情報なし';

  @override
  String subwayPanelTrainDirection(String destination, String type) {
    return '$destination行 $type';
  }

  @override
  String get subwayPanelCloseDetail => '列車詳細を閉じる';

  @override
  String subwayPanelTrainNo(String no) {
    return '列車 #$no';
  }

  @override
  String subwayPanelDelayedBadge(int min) {
    return '$min 分遅延';
  }

  @override
  String get subwayPanelLastTrainBadge => '最終列車';

  @override
  String subwayPanelTerminalDestination(String terminal) {
    return '$terminal行';
  }

  @override
  String get subwayPanelPrevStation => '前の駅';

  @override
  String get subwayPanelDepartureStation => '始発駅';

  @override
  String get subwayPanelCurrentStation => '現在駅';

  @override
  String get subwayPanelNextStation => '次の駅';

  @override
  String get subwayPanelStateArriving => 'まもなく到着';

  @override
  String get subwayPanelStateStopped => '停車中';

  @override
  String get subwayPanelStateDeparted => '出発';

  @override
  String get subwayPanelStateMoving => '走行中';

  @override
  String get subwayPanelStateOperating => '運行中';

  @override
  String get subwayPanelDirInnerLoop => '内回り';

  @override
  String get subwayPanelDirOuterLoop => '外回り';

  @override
  String get subwayPanelDirUp => '上り';

  @override
  String get subwayPanelDirDown => '下り';

  @override
  String get subwayPanelTrainTypeExpress => '急行';

  @override
  String get subwayPanelTrainTypeSpecial => '特急';

  @override
  String get subwayPanelTrainTypeRegular => '普通';

  @override
  String get searchTileSubway => '地下鉄';

  @override
  String get profileEditNicknameInvalid => 'ニックネームは 1〜20 文字で入力してください。';

  @override
  String get profileEditBirthInvalid => '生年 (YYYY) を正しく入力してください。';

  @override
  String get profileEditAgeRestriction => '14 歳未満はマルチプレイを利用できません。';

  @override
  String get profileEditTitle => 'プロフィール設定';

  @override
  String get profileEditSubtitle => 'ルームで他の人に表示される姿を決めましょう。';

  @override
  String get profileEditNicknameLabel => 'ニックネーム (重複可)';

  @override
  String get profileEditNicknamePlaceholder => '例: ソウル探検家';

  @override
  String get profileEditBirthLabel => '生年 (満 14 歳以上のみ加入)';

  @override
  String get profileEditBirthPlaceholder => '例: 2000';

  @override
  String get profileEditAvatarLabel => 'プロフィール写真';

  @override
  String get profileEditAvatarTapHint => 'タップして変更';

  @override
  String get profileEditAvatarChoose => 'ライブラリから選択';

  @override
  String get profileEditAvatarCamera => 'カメラで撮影';

  @override
  String get profileEditAvatarRemove => '現在の写真を削除';

  @override
  String get profileEditAvatarUploading => 'アップロード中...';

  @override
  String get profileEditAvatarRemoveConfirmTitle => '写真を削除しますか?';

  @override
  String get profileEditAvatarRemoveConfirmBody => 'プロフィール写真が消え、絵文字で再表示されます。';

  @override
  String get profileEditAvatarFailed => '写真のアップロードに失敗しました。後でもう一度お試しください。';

  @override
  String get profileEditEmojiLabel => 'ピン絵文字';

  @override
  String get profileEditColorLabel => 'ピン色';

  @override
  String get profileEditVisibilityLabel => '位置情報の公開範囲';

  @override
  String get profileEditVisibilityGhost => '非公開';

  @override
  String get profileEditVisibilityFriends => 'ルーム';

  @override
  String get profileEditVisibilityGroup => 'グループのみ';

  @override
  String get profileEditVisibilityPublic => '全体';

  @override
  String get profileEditSaving => '保存中…';

  @override
  String get profileEditSave => '保存';

  @override
  String get profileEditPublicDialogTitle => '全体公開に切替';

  @override
  String get profileEditPublicDialogBody =>
      'あなたの位置情報が知らない人を含むすべての Seoul Live ユーザーにリアルタイムで表示されます。\n\n• 不適切な出会い / ストーキングのリスクにご注意ください\n• いつでも非公開/ルームに戻せます\n• ブロック/通報は友だちプロフィールまたはチャットメニューから';

  @override
  String get profileEditPublicDialogConfirm => '続行';

  @override
  String get profileEditVisibilityGhostDesc => '位置情報を送信しません。他の人の位置も見えません。';

  @override
  String get profileEditVisibilityFriendsDesc =>
      'ルームに参加している間のみ、同じルームのメンバーに位置情報が表示されます。';

  @override
  String get profileEditVisibilityGroupDesc => '下で選択したグループの友だちのみ位置情報を見られます。';

  @override
  String get profileEditVisibilityPublicDesc =>
      '⚠️ Seoul Live ユーザー誰でもあなたの位置情報を見られます。ルームでも同じです。';

  @override
  String get profileEditNoGroups => 'グループがありません。友だち → グループ から作成してください。';

  @override
  String get adminMonitorTitle => '運営モニター';

  @override
  String get adminRefresh => '更新';

  @override
  String get adminTabMetrics => '指標';

  @override
  String get adminTabAbuse => '不正';

  @override
  String get adminTabReports => '報告';

  @override
  String get adminMetricAllProfiles => '全プロフィール';

  @override
  String get adminMetricActiveRooms => 'アクティブなルーム';

  @override
  String get adminMetricTodayMeetups => '今日の出会い';

  @override
  String get adminMetricTodayBlocks => '今日のブロック';

  @override
  String get adminMetricTodayReports => '今日の報告';

  @override
  String get adminNoSuspiciousSignals =>
      '不審なシグナルなし (24 時間以内に 3 件以上ブロックされたユーザー X)';

  @override
  String adminRecentBlockCount(int count) {
    return '24h 以内に $count 人にブロックされました';
  }

  @override
  String get adminReportStatusPending => '待機';

  @override
  String get adminReportStatusReviewed => 'レビュー済';

  @override
  String get adminReportStatusActioned => '対応済';

  @override
  String get adminReportStatusDismissed => '却下';

  @override
  String get adminNoReports => '表示する報告がありません';

  @override
  String get adminReportTypeMessage => 'メッセージ報告';

  @override
  String get adminReportTypeUser => 'ユーザー報告';

  @override
  String get adminReportActionReview => 'レビュー';

  @override
  String get adminReportActionAction => '対応';

  @override
  String get adminReportActionDismiss => '却下';

  @override
  String adminAgoMin(int min) {
    return '$min 分前';
  }

  @override
  String adminAgoHour(int hour) {
    return '$hour 時間前';
  }

  @override
  String adminAgoDay(int day) {
    return '$day 日前';
  }

  @override
  String get liveDiagTitle => 'リアルタイム診断';

  @override
  String get liveDiagMyId => 'マイ ID';

  @override
  String get liveDiagVisibility => '公開範囲';

  @override
  String get liveDiagRoom => 'ルーム';

  @override
  String get liveDiagPeers => '受信ピア';

  @override
  String liveDiagPeersValue(int count) {
    return '$count 人';
  }

  @override
  String get liveDiagPresenceStatus => 'Presence 状態';

  @override
  String get liveDiagWorldStatus => 'World 状態';

  @override
  String get liveDiagLastSent => '最終送信';

  @override
  String get liveDiagSendError => '送信エラー';

  @override
  String get liveDiagGps => 'GPS';

  @override
  String get liveDiagPaused => '一時停止';

  @override
  String get liveDiagActivityFailCount => '活動記録失敗';

  @override
  String liveDiagActivityFailValue(int count) {
    return '$count 回';
  }

  @override
  String get liveDiagLastActivityError => '直近の活動エラー';

  @override
  String get liveDiagFooter => '問題があればこの画面をキャプチャして共有してください';

  @override
  String get liveDiagClose => '閉じる';

  @override
  String get liveDiagNoProfile => '(プロフィールなし)';

  @override
  String get liveDiagNone => '(なし)';

  @override
  String get liveDiagNotConnected => '(未接続)';

  @override
  String get liveDiagNotUsed => '(未使用)';

  @override
  String get liveDiagNotSent => '未送信';

  @override
  String liveDiagSecondsAgo(int sec) {
    return '$sec 秒前';
  }

  @override
  String liveDiagRoomLabel(String code, int count) {
    return '$code ($count 人)';
  }

  @override
  String get liveDiagGpsHas => 'あり';

  @override
  String get liveDiagGpsNo => 'なし';

  @override
  String get mpConsentLocationDenied => '設定 > 位置情報 で位置情報の権限を許可してください。';

  @override
  String get mpConsentTitle => 'マルチプレイ開始前のご案内';

  @override
  String get mpConsentHeading => 'Seoul Live 同意';

  @override
  String get mpConsentBody =>
      '友だちと位置を共有するために、以下の項目への同意が必要です。各項目は個別に同意/拒否でき、いつでも設定から撤回できます。';

  @override
  String get mpConsentItem1Title => '[必須] プロフィール情報の処理';

  @override
  String get mpConsentItem1Detail =>
      'ニックネーム、ピンの色/絵文字、生年。サービスの識別および 14 歳未満の登録防止のため。アカウント削除時まで保有、退会時に即時破棄。';

  @override
  String get mpConsentItem2Title => '[必須] 位置情報の処理 (LBS 法 §18)';

  @override
  String get mpConsentItem2Detail =>
      'GPS 座標・移動方向。ルームのメンバー、または全体公開を選択した場合はすべての Seoul Live ユーザーにリアルタイムで共有。永続保存なし — Realtime チャネルで一時的に送信。公開範囲は プロフィールから 非公開/ルーム/全体公開 をいつでも変更できます。';

  @override
  String get mpConsentItem3Title => '[必須] 位置基盤サービス利用規約';

  @override
  String get mpConsentItem3Detail => '放送通信委員会届出事業者が提供。14 歳未満は利用不可。';

  @override
  String get mpConsentItem3Link => '規約全文を見る';

  @override
  String get mpConsentDeclineNote => '拒否してもマルチプレイのみ無効になり、その他の機能は通常通り利用可能です。';

  @override
  String get mpConsentBackgroundNote =>
      'アプリがバックグラウンドになると位置共有は自動で一時停止されます (バッテリー保護)。';

  @override
  String get mpConsentSubmit => '同意して開始';

  @override
  String get mpConsentLaterButton => 'あとで';

  @override
  String get mpConsentSubmitBusy => '処理中…';

  @override
  String get mpConsentLbsTermsBody =>
      '本規約は Seoul Vista が提供する Seoul Live (以下「本サービス」) の位置基盤サービス利用に関する事項を定めるものです。';

  @override
  String get optTitle => 'あなたの端末に合わせて';

  @override
  String get optSubtitle => 'リアルタイムビジュアライズは GPU 負荷が高めです。\n端末に合わせてお選びください。';

  @override
  String get optPresetHighTitle => '高画質';

  @override
  String get optPresetHighDetail => '60fps · 5 秒更新 · アンチエイリアシング ON';

  @override
  String get optPresetSmoothTitle => 'なめらか';

  @override
  String get optPresetSmoothDetail => '30fps · 10 秒更新';

  @override
  String get optPresetBatteryTitle => 'バッテリー節約';

  @override
  String get optPresetBatteryDetail => '20fps · 30 秒更新 · エフェクト OFF';

  @override
  String get optAdvancedTitle => '詳細 — 表示するレイヤーを選択';

  @override
  String get optLayerSubway => '地下鉄 (リアルタイム列車位置)';

  @override
  String get optLayerSubwaySub => 'ソウル地下鉄 + 広域鉄道。GPU 負荷が最大';

  @override
  String get optLayerBus => '市バス';

  @override
  String get optLayerBusSub => 'ソウル + 京畿の市バスのリアルタイム位置';

  @override
  String get optLayerRiverBus => '漢江バス';

  @override
  String get optLayerRiverBusSub => '漢江を運航する船舶';

  @override
  String get optLayerFlights => '航空機';

  @override
  String get optLayerFlightsSub => '仁川空港周辺のリアルタイム航空機';

  @override
  String optDetectedTier(String tier) {
    return '$tier 等級として検出されました';
  }

  @override
  String get optRecommended => '推奨';

  @override
  String get vehicleCongestion => '混雑度';

  @override
  String get vehicleCongestionNone => '情報なし';

  @override
  String get vehicleCongestionFree => '余裕';

  @override
  String get vehicleCongestionNormal => '普通';

  @override
  String get vehicleCongestionBusy => '混雑';

  @override
  String get vehicleCongestionPacked => '非常に混雑';

  @override
  String get vehicleCongestionFull => '満員';

  @override
  String get vehicleStatus => '状態';

  @override
  String get vehicleStopped => '停車中';

  @override
  String get vehicleRunning => '運行中';

  @override
  String get vehicleSection => '区間';

  @override
  String vehicleSectionOrd(int ord) {
    return '$ord番目';
  }

  @override
  String get vehicleBusLowFloor => '低床バス';

  @override
  String get vehicleBusRegular => '一般バス';

  @override
  String get vehiclePhaseAscent => '上昇';

  @override
  String get vehiclePhaseCruise => '巡航';

  @override
  String get vehiclePhaseDescent => '降下';

  @override
  String get vehiclePhaseTakeoff => '離着陸';

  @override
  String get vehiclePhaseGround => '地上';

  @override
  String get vehicleAltitude => '高度';

  @override
  String get vehicleAltitudeOnGround => '地上';

  @override
  String get vehicleSpeed => '速度';

  @override
  String get vehicleHeading => '方向';

  @override
  String vehicleRiverBusRoute(String name) {
    return 'ハンガンバス $name';
  }

  @override
  String get vehicleRiverDirNormal => '正方向';

  @override
  String get vehicleRiverDirReverse => '逆方向';

  @override
  String get vehicleRiverPhaseStop => '停泊';

  @override
  String get vehicleNext => '次';

  @override
  String get vehicleProgress => '進行';

  @override
  String get deepLinkRoomLoginRequired => 'ログイン後にルームへ入れます';

  @override
  String deepLinkRoomEntered(String code) {
    return 'ルーム入場 — コード $code';
  }

  @override
  String deepLinkRoomFailure(String error) {
    return 'ルーム入場失敗: $error';
  }

  @override
  String get snsAnalysisTitle => '分析結果';

  @override
  String get snsAnalysisEmpty => '抽出された場所がありません';

  @override
  String snsAnalysisCreatePlans(int count) {
    return 'プラン作成 ($count件)';
  }

  @override
  String snsAnalysisPlanFailure(String error) {
    return 'プラン作成失敗: $error';
  }

  @override
  String snsAnalysisNearestStation(String station, int minutes) {
    return '📍 $station駅 · $minutes分';
  }

  @override
  String get avatarMyPin => '私のピン';

  @override
  String get avatarNoRoomHint => '友だちルームに参加すると友だちが表示されます';

  @override
  String get avatarNoRoomMembers => 'まだ一緒にいる友だちがいません';

  @override
  String avatarRoomMembersCount(int count) {
    return '一緒の友だち $count人';
  }

  @override
  String get avatarNoTrack => '再生中の曲はありません';

  @override
  String get qrScanTitle => 'QR スキャン';

  @override
  String qrScanCameraError(String error) {
    return 'カメラを使用できません\n$error';
  }

  @override
  String get qrScanHint => '友だちの QR をフレームに合わせてください';

  @override
  String get buildingOccupantsFallbackName => '建物';

  @override
  String buildingOccupantsInside(int count) {
    return '$count人が中にいます';
  }

  @override
  String get buildingOccupantsEmpty => '建物から出ました';

  @override
  String buildingOccupantsListening(String name, String artist) {
    return '🎵 $name · $artist を聴いています';
  }

  @override
  String get buildingOccupantsInBuilding => '🏢 建物の中にいます';

  @override
  String get weatherWeeklyLabel => '週間';

  @override
  String get weatherToday => '今日';

  @override
  String get weatherDayMon => '月';

  @override
  String get weatherDayTue => '火';

  @override
  String get weatherDayWed => '水';

  @override
  String get weatherDayThu => '木';

  @override
  String get weatherDayFri => '金';

  @override
  String get weatherDaySat => '土';

  @override
  String get weatherDaySun => '日';

  @override
  String get locPermTitle => '位置情報の許可が必要です';

  @override
  String get locPermBody => '現在地を地図に表示し、周辺情報や経路を正確に案内するために\n位置情報の許可が必要です。';

  @override
  String get locPermRequesting => 'リクエスト中...';

  @override
  String get locPermRequest => '位置情報を許可';

  @override
  String get locPermGranted => '✓ 位置情報を許可済み';

  @override
  String get locPermDenied => '拒否されました — 設定から直接許可できます';

  @override
  String get locPermRetry => '再試行';

  @override
  String get groupEditorTitle => '友だちグループ';

  @override
  String get groupEditorNew => '新規グループ';

  @override
  String get groupEditorEmpty => 'まだグループがありません';

  @override
  String get groupEditorEmptyHint => '右上の + ボタンでグループを作成して友だちを分類しましょう。';

  @override
  String get groupEditorHelper => 'グループ別の公開範囲 / チャットに使えます';

  @override
  String get groupEditorNamePlaceholder => '例: 家族、仕事、サークル';

  @override
  String get groupEditorCreate => '作成';

  @override
  String groupEditorFailure(String error) {
    return '失敗: $error';
  }

  @override
  String groupEditorMemberCount(int count) {
    return '$count人';
  }

  @override
  String groupEditorDeleteTitle(String name) {
    return '$name グループ削除';
  }

  @override
  String get groupEditorDeleteBody => 'グループのみ削除され、友だちは保持されます。';

  @override
  String get groupEditorDelete => '削除';

  @override
  String get groupEditorAddFriendsHint => '先に友だちを追加してください。';

  @override
  String get peerPinDestinationFallback => '目的地';

  @override
  String peerPinDestinationLabel(String name) {
    return '🎯 $name';
  }

  @override
  String get stationDetailCloseLabel => '駅の詳細を閉じる';

  @override
  String get stationDetailDeparture => '出発';

  @override
  String get stationDetailArrival => '到着';

  @override
  String get stationDetailLiveArrivals => 'リアルタイム発車情報';

  @override
  String get stationDetailLoading => '読み込み中...';

  @override
  String get stationDetailNoArrivals => '到着情報なし';

  @override
  String get stationDetailCrowdVery => '非常に混雑';

  @override
  String get stationDetailCrowdBusy => '混雑';

  @override
  String get stationDetailCrowdNormal => '普通';

  @override
  String get stationDetailCrowdFree => '余裕';

  @override
  String stationDetailBoardingCount(String count) {
    return '乗車 $count人';
  }

  @override
  String stationDetailAlightingCount(String count) {
    return '降車 $count人';
  }

  @override
  String stationDetailClosureCount(int count) {
    return '施設閉鎖 $count件';
  }

  @override
  String get visitTimelineTitle => 'わたしの足あと';

  @override
  String visitTimelineSummary(int count, String ago) {
    return '$count件 · 直近 $ago';
  }

  @override
  String get visitTimelineEmpty => '訪問記録がありません。';

  @override
  String get visitTimelineClose => '閉じる';

  @override
  String visitTimelineExpand(int count) {
    return '$count件 もっと見る';
  }

  @override
  String get visitTimelineCollapse => '閉じる';

  @override
  String get visitTimelineDateToday => '今日';

  @override
  String get visitTimelineDateYesterday => '昨日';

  @override
  String visitTimelineDateDaysAgo(int days) {
    return '$days日前';
  }

  @override
  String visitTimelineDateMonthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String get visitTimelineAgoNone => 'なし';

  @override
  String visitTimelineAgoMin(int min) {
    return '$min分前';
  }

  @override
  String visitTimelineAgoHour(int hour) {
    return '$hour時間前';
  }

  @override
  String visitTimelineAgoDay(int day) {
    return '$day日前';
  }

  @override
  String visitTimelineVisitCount(int count) {
    return '$count回';
  }

  @override
  String get permPageTitle => '権限設定';

  @override
  String get permPageBody => '事前に権限を許可すれば\nアプリ使用中に止まることがありません。';

  @override
  String get permPageFooter => '拒否してもアプリは動作します。該当機能のみ制限されます。';

  @override
  String get permPageRequesting => 'リクエスト中...';

  @override
  String get permPageAllGranted => '✓ すべて許可済み';

  @override
  String get permPageRequestAll => '一括許可';

  @override
  String get permItemLocation => '位置情報';

  @override
  String get permItemLocationDesc => '地図に現在地表示 + 友だちルームでリアルタイム共有';

  @override
  String get permItemNotification => '通知';

  @override
  String get permItemNotificationDesc => '友だち申請 / チャット / 待ち合わせ通知';

  @override
  String get permItemCamera => 'カメラ';

  @override
  String get permItemCameraDesc => '場所写真の分析 + 友だちチャットの写真';

  @override
  String get permItemPhotos => '写真';

  @override
  String get permItemPhotosDesc => 'ギャラリーの写真をチャットで共有';

  @override
  String get permItemMicrophone => 'マイク';

  @override
  String get permItemMicrophoneDesc => 'AI 音声会話 + 音声メッセージ';

  @override
  String permTapToSettings(String desc) {
    return '$desc (タップで設定を開く)';
  }

  @override
  String get livingCityTitle => 'ソウルが息づく';

  @override
  String get livingCityBody => 'アイコンを押すとカメラがそのシーンへ飛びます。';

  @override
  String get livingCityVehSubway => '地下鉄';

  @override
  String get livingCityVehBus => 'バス';

  @override
  String get livingCityVehRiverBus => 'ハンガンバス';

  @override
  String get livingCityVehFlight => '航空機';

  @override
  String get infoBarsTierFlagship => 'フラッグシップ';

  @override
  String get infoBarsTierHigh => 'ハイエンド';

  @override
  String get infoBarsTierMid => 'ミドル';

  @override
  String get infoBarsTierLow => 'ローエンド';

  @override
  String infoBarsProfileToast(String model, String tier, int fps, int pollMs) {
    return '$model · $tier\n${fps}fps · ポーリング ${pollMs}ms 最適化適用';
  }

  @override
  String get navBannerNext => '次へ';

  @override
  String navBannerWalkTo(String station) {
    return '$stationまで徒歩';
  }

  @override
  String navBannerBoardAt(String station, String line) {
    return '$stationで $line に乗車';
  }

  @override
  String navBannerWalkDetail(int min) {
    return '$min分 移動';
  }

  @override
  String navBannerTransitDetail(String station, int min) {
    return '$station方面 · $min分';
  }

  @override
  String get readyPageTitle => '準備完了';

  @override
  String get readyPageBody => '下のスタートボタンを押すと\nリアルタイムのソウルが広がります。';

  @override
  String get welcomePageSubtitle => 'ソウルを新しい視点で';

  @override
  String get pathfindingPageTitle => '今日はどんな旅?';

  @override
  String get pathfindingPageBody =>
      'AI アシスタントが気分に合わせてコースを組みます。\nあとでいつでも変えられます。';

  @override
  String riverBusStopLabel(String name) {
    return '$name 船着場';
  }

  @override
  String get riverBusRouteEnded => '運航終了';

  @override
  String riverBusNextTime(String time) {
    return '次 $time';
  }

  @override
  String get riverBusMaintenance => '整備中';

  @override
  String get riverBusDeparture => '出発';

  @override
  String get riverBusArrival => '到着';

  @override
  String get qualityPreviewDemoLabel => 'DEMO · 地下鉄';

  @override
  String get qualityPresetHigh => '高品質';

  @override
  String get qualityPresetMedium => 'なめらか';

  @override
  String get qualityPresetLow => '省電力';

  @override
  String get qualityPresetHighDetail => '60 fps · 効果 ON';

  @override
  String get qualityPresetMediumDetail => '30 fps · 効果 一部';

  @override
  String get qualityPresetLowDetail => '10 fps · 効果 OFF';
}
