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
}
