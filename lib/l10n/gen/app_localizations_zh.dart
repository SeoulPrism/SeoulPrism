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

  @override
  String get routeUnitHour => '小时';

  @override
  String get routeUnitMin => '分钟';

  @override
  String routeTransfersCount(int count) {
    return '换乘 $count 次';
  }

  @override
  String get routeDeparture => '出发';

  @override
  String get routeArrival => '到达';

  @override
  String get routeTransfer => '换乘';

  @override
  String routeTransferDetail(String line, int min) {
    return '$line · $min 分钟';
  }

  @override
  String routeBoardLine(String line) {
    return '乘坐 $line';
  }

  @override
  String routeSegmentBus(String from, String to, int count, int min) {
    return '$from → $to · $count 个站 · $min 分钟';
  }

  @override
  String routeSegmentTrain(String from, String to, int count, int min) {
    return '$from → $to · $count 个站 · $min 分钟';
  }

  @override
  String routeSegmentShort(String from, int min) {
    return '$from · $min 分钟';
  }

  @override
  String get routeShowStops => '查看站点 ▼';

  @override
  String get routeCollapse => '收起 ▲';

  @override
  String get snsTitle => 'AI 行程';

  @override
  String get snsSubtitle => '用社交内容生成首尔一日行程';

  @override
  String get snsSectionPhotos => '照片';

  @override
  String get snsSectionDescription => '说明';

  @override
  String get snsSectionLink => '社交链接';

  @override
  String get snsTextHint => '写下你想去的地方、想做的事';

  @override
  String get snsUrlHint => 'Instagram、TikTok URL';

  @override
  String get snsAnalyzeButton => '开始分析';

  @override
  String snsAnalyzeError(String error) {
    return '分析失败:$error';
  }

  @override
  String get snsImageGallery => '相册';

  @override
  String get snsImageCamera => '相机';

  @override
  String get dayPlanTitle => '一日行程';

  @override
  String get dayPlanNavigateAll => '全程导航';

  @override
  String dayPlanTransitSummary(int min) {
    return '🚇 $min 分钟';
  }

  @override
  String dayPlanTransfersSummary(int count) {
    return '🔄 $count 次';
  }

  @override
  String dayPlanStyleStats(int count, int min) {
    return '$count 个地点 · $min 分钟';
  }

  @override
  String get dayPlanNavigateStop => '导航';

  @override
  String get whatsNewClose => '关闭';

  @override
  String get whatsNewSkip => '跳过';

  @override
  String get whatsNewStart => '开始体验';

  @override
  String get whatsNewNext => '下一步';

  @override
  String whatsNewPage1Title(String version) {
    return 'v$version — 欢迎回来';
  }

  @override
  String get whatsNewPage1Body => '这次旅行更有你的味道。\n从旅行心情到朋友与回忆,\n来看 14 项新功能。';

  @override
  String get whatsNewPage2Title => '你的旅行心情';

  @override
  String get whatsNewPage2Body =>
      '在「放松·玩乐·历史·混合」中选一个,\nAI 语气、推荐路线和旅行选项卡\n都会随之改变。';

  @override
  String get whatsNewPage3Title => '一起出发';

  @override
  String get whatsNewPage3Body => '在好友房间设定共同目的地,\n每个成员的距离实时显示,\n地图上自动落下橙色图钉。';

  @override
  String get whatsNewPage4Title => '1:1 私信 + 语音/照片';

  @override
  String get whatsNewPage4Body =>
      '不用建房间也能与好友直接聊。\n🎙 长按麦克风录语音,📷 从相册选照片,\n📍 位置也能一并发送。';

  @override
  String get whatsNewPage5Title => 'Spotify 分享';

  @override
  String get whatsNewPage5Body =>
      '把正在听的歌发给好友。\n聊天里点 🎵,正在播放的\nSpotify 曲目就会以卡片分享出去。';

  @override
  String get whatsNewPage6Title => '扩展好友';

  @override
  String get whatsNewPage6Body => '好友页推荐「朋友的朋友」,\n用 QR 码即时添加,\n房间邀请链接一键加入。';

  @override
  String get whatsNewPage7Title => '活动变积分';

  @override
  String get whatsNewPage7Body =>
      '添加好友、相遇、连续打卡都能得分和徽章。\n和好友在排行榜里比一比,\n用每周活动图回顾。';

  @override
  String get whatsNewPage8Title => '由你决定';

  @override
  String get whatsNewPage8Body => '按类型开关通知,\n位置只分享给特定群组。\n安全与隐私由你掌控。';

  @override
  String get profileCategoryFavorites => '收藏';

  @override
  String get profileCategoryRecent => '最近到访';

  @override
  String get profileCategoryFrequent => '常去';

  @override
  String get profileGuestName => '访客';

  @override
  String get profileDefaultName => '用户';

  @override
  String get profileSyncCta => '登录后可在其他设备同步';

  @override
  String profileAgoDays(int days) {
    return '$days 天前';
  }

  @override
  String profileAgoHours(int hours) {
    return '$hours 小时前';
  }

  @override
  String get profileAgoNow => '刚刚';

  @override
  String profileVisitCount(int count) {
    return '到访 $count 次';
  }

  @override
  String get profileEmptyFavorites => '暂无收藏';

  @override
  String get profileEmptyVisits => '暂无访问记录';

  @override
  String get profileCollapse => '收起';

  @override
  String profileMoreCount(int count) {
    return '再看 $count 项';
  }

  @override
  String get profileLiveShareBeta => '与好友实时共享位置/聊天 (Beta)';

  @override
  String get profileTimeline => '我的时间线';

  @override
  String profilePlaceCount(int count) {
    return '$count 个地点';
  }

  @override
  String get profileEmptyVisitsCta => '暂无访问记录。去探索地点、试试导航吧。';

  @override
  String get profileToday => '今天';

  @override
  String get profileYesterday => '昨天';

  @override
  String profileMonthDay(int month, int day) {
    return '$month月$day日';
  }

  @override
  String profileVisitTimes(int count) {
    return '$count 次';
  }

  @override
  String get profileEditName => '修改名字';

  @override
  String get profileNewNameHint => '输入新名字';

  @override
  String get profileTagline => '记录首尔的每个瞬间';

  @override
  String get profileMore => '更多';

  @override
  String get profileEmptyMapPlaces => '访问积累后,会显示在这张地图上';

  @override
  String profileRecentPlaceCount(int count) {
    return '最近 $count 个地点';
  }

  @override
  String chatSendFailed(String error) {
    return '发送失败:$error';
  }

  @override
  String get chatRoomDestSet => '🎯 已设为房间目的地';

  @override
  String chatActionFailed(String error) {
    return '失败:$error';
  }

  @override
  String get chatMapAppUnavailable => '无法打开地图应用';

  @override
  String get chatMicPermissionRequired => '需要麦克风权限';

  @override
  String chatRecordStartFailed(String error) {
    return '录音开始失败:$error';
  }

  @override
  String get chatRecordTooShort => '太短了 — 长按以录音';

  @override
  String chatRecordStopFailed(String error) {
    return '录音结束失败:$error';
  }

  @override
  String chatPhotoSendFailed(String error) {
    return '照片发送失败:$error';
  }

  @override
  String get chatSpotifyClientIdMissing =>
      'Spotify 未配置 — 开发者需添加 SPOTIFY_CLIENT_ID';

  @override
  String get chatSpotifyAuthRetryHint => 'Spotify 认证后请再点一次';

  @override
  String chatSpotifyAuthFailed(String error) {
    return 'Spotify 连接失败:$error';
  }

  @override
  String get chatMyLocation => '我的位置';

  @override
  String get chatLocationUnavailable => '无法获取位置';

  @override
  String get chatDefaultRoomName => '好友房间';

  @override
  String chatMembersInRoom(int count) {
    return '$count 人在房间';
  }

  @override
  String get chatRecordingHint => '录音中… 松开发送,向上拖动取消';

  @override
  String get chatRecordingPlaceholder => '🎙 录音中';

  @override
  String get chatMessageHint => '输入消息';

  @override
  String get chatActionMap => '地图';

  @override
  String get chatActionDirections => '导航';

  @override
  String get chatActionRoomDest => '🎯 设为房间目的地';

  @override
  String chatVoiceLabel(int seconds) {
    return '$seconds 秒 语音';
  }

  @override
  String chatPlaybackFailed(String error) {
    return '播放失败:$error';
  }

  @override
  String chatEmptyTitleNamed(String roomName) {
    return '$roomName 已开启';
  }

  @override
  String get chatEmptyTitleDefault => '好友房间已开启';

  @override
  String get chatEmptyBody => '在这里和朋友打招呼、共享位置,\n一起定下要去的地方吧。';

  @override
  String get chatStart => '开始聊天';

  @override
  String get chatReport => '举报此消息';

  @override
  String chatBlockDialogTitle(String nickname) {
    return '屏蔽 $nickname';
  }

  @override
  String get chatBlockDialogBody => '屏蔽后会被踢出同一房间,且消息也不可见。';

  @override
  String get chatBlockConfirm => '屏蔽';

  @override
  String get chatUnknownUser => '用户';

  @override
  String get spotifyOpenInApp => '在 Spotify 中打开';

  @override
  String spotifyShareFailed(String error) {
    return '分享失败:$error';
  }

  @override
  String get spotifyNoTrack => '目前没有正在播放的曲目';

  @override
  String get dmAccessDenied => '无法访问此对话';

  @override
  String dmSendFailed(String error) {
    return '发送失败:$error';
  }

  @override
  String get dmDefaultPeer => '好友';

  @override
  String get dmEmptyHint => '发送第一条消息吧';

  @override
  String get dmMessageHint => '消息';

  @override
  String get friendCodeLengthError => '请输入 8 位代码。';

  @override
  String get friendCodeNotFound => '找不到对应代码的用户。';

  @override
  String friendRequestSent(String nickname) {
    return '已向 $nickname 发送好友申请。';
  }

  @override
  String get friendShareSubject => 'Seoul Live 加好友';

  @override
  String friendShareBody(String nickname, String code) {
    return '$nickname 给你发来 Seoul Live 好友代码!\n\n代码:$code\n直接添加:com.seoul.prism://friend/$code';
  }

  @override
  String get friendShareCopied => '已复制分享文本';

  @override
  String get friendCodeTitle => '好友代码';

  @override
  String get friendCodeSubtitle => '分享你的代码,或者用好友代码加好友。';

  @override
  String get friendMyCode => '我的好友代码';

  @override
  String get friendCodeCopied => '已复制代码';

  @override
  String get friendQrHint => '好友用相机扫描就能直接添加';

  @override
  String get friendShareButton => '分享';

  @override
  String get friendAddByCodeTitle => '通过代码加好友';

  @override
  String get friendAddByCodeHint => '输入收到的 8 位代码或扫描 QR';

  @override
  String get friendCodePlaceholder => '例如:AB12CD34';

  @override
  String get friendSendRequest => '发送好友申请';

  @override
  String peerFriendCode(String code) {
    return '好友代码 $code';
  }

  @override
  String get peerOwnPin => '这是你自己的图钉';

  @override
  String get peerReport => '举报';

  @override
  String peerBlockDialogTitle(String nickname) {
    return '屏蔽 $nickname';
  }

  @override
  String get peerBlockDialogBody => '屏蔽后会被踢出同一房间,消息和图钉都不再显示。';

  @override
  String get peerBlockConfirm => '屏蔽';

  @override
  String get peerBlock => '屏蔽';

  @override
  String get peerIsFriend => '已是好友 ✓';

  @override
  String get peerCancelRequest => '取消申请';

  @override
  String peerRequestCanceled(String nickname) {
    return '已取消向 $nickname 发送的申请';
  }

  @override
  String get peerAcceptRequest => '接受好友申请';

  @override
  String peerNowFriend(String nickname) {
    return '已和 $nickname 成为好友';
  }

  @override
  String peerCanRequestInDays(int days) {
    return '$days 天后可再申请';
  }

  @override
  String peerCanRequestInHours(int hours) {
    return '$hours 小时后可再申请';
  }

  @override
  String get peerSendRequest => '发送好友申请';

  @override
  String peerRequestSent(String nickname) {
    return '已向 $nickname 发送申请';
  }

  @override
  String peerDistanceMeters(int meters) {
    return '${meters}m';
  }

  @override
  String peerDistanceKm(String km) {
    return '${km}km';
  }

  @override
  String get spotifyRoomRequired => '请进入好友房间后再试';

  @override
  String get spotifyShareSuccess => '🎵 已分享到房间';

  @override
  String get spotifyDisconnectTitle => '断开 Spotify';

  @override
  String get spotifyDisconnectBody => '将删除已保存的令牌,并停止向好友分享曲目。';

  @override
  String get spotifyDisconnectConfirm => '断开';

  @override
  String get spotifyDisconnected => '已断开 Spotify';

  @override
  String get spotifyAuthRetryHint => 'Spotify 认证后会自动返回';

  @override
  String spotifyConnectFailed(String error) {
    return '连接失败:$error';
  }

  @override
  String get spotifyClientIdMissing => '开发者未设置 SPOTIFY_CLIENT_ID';

  @override
  String get spotifyTokenExpired => '连接已过期。请重新登录。';

  @override
  String get spotifyReconnect => '重新连接 Spotify';

  @override
  String get spotifyConnect => '连接 Spotify';

  @override
  String get spotifyConnectDescription => '连接后可以在好友房间聊天里分享正在听的歌,\n好友也能看到你在听什么。';

  @override
  String get spotifyLoginButton => '用 Spotify 登录';

  @override
  String get spotifyShareToRoom => '分享到房间';

  @override
  String get spotifyDisconnect => '断开连接';

  @override
  String get spotifyConnectedNoTrack => 'Spotify 已连接 (无播放)';

  @override
  String get spotifyNowPlaying => '正在播放';

  @override
  String get departureTimePickerTitle => '出发时间';

  @override
  String get departureTimePickerHint => '将以指定时间为基础计算到达时间。';

  @override
  String get departureTimeNow => '现在';

  @override
  String get departureTime30min => '30 分钟后';

  @override
  String get departureTime1hour => '1 小时后';

  @override
  String get departureTimeCustom => '自定义';

  @override
  String get placeActionDepart => '出发';

  @override
  String get placeActionArrive => '到达';

  @override
  String get placeActionInfo => '信息';

  @override
  String get placeDetailTapHint => '点击查看照片·评价·营业时间';

  @override
  String get savedPanelTitle => '已保存';

  @override
  String get savedEmptyFavorites => '暂无已保存的地点';

  @override
  String get savedRemoveFavoriteTooltip => '取消收藏';

  @override
  String get travelThemeTitle => '主题推荐';

  @override
  String get travelThemeSubtitle => '一键自动生成路线';

  @override
  String get travelTitle => '旅行';

  @override
  String get travelSubtitle => '从景福宫到汉江夜景,为你规划一日行程';

  @override
  String get travelEventsTitle => '本周活动';

  @override
  String get travelEventsSubtitle => '首尔进行中的文化活动';

  @override
  String travelEventsCount(int count) {
    return '$count 个';
  }

  @override
  String get travelEventsLoadError => '无法加载活动信息。向下拉动重试。';

  @override
  String get travelAiTitle => 'AI 为你安排日程';

  @override
  String get travelAiSubtitle => '自动考虑时间·天气·动线';

  @override
  String get travelFromSavedTitle => '用已保存的地点生成';

  @override
  String get travelFromSavedSubtitle => '基于收藏 + 访问记录的路线';

  @override
  String get travelYourTheme => '你的主题';

  @override
  String get travelStartWithMood => '用这个心情开始路线';

  @override
  String get travelEventBadgeOngoing => '进行中';

  @override
  String get travelEventBadgeFree => '免费';

  @override
  String travelThemeStops(int count) {
    return '$count 个地点';
  }

  @override
  String get travelMoodAnalyzing => '正在分析曲目氛围……';

  @override
  String get travelMoodExcited => '嗨翻的氛围里';

  @override
  String get travelMoodToday => '今天这样的日子';

  @override
  String get travelMoodIntense => '强烈的节拍里';

  @override
  String get travelMoodCalm => '宁静的氛围里';

  @override
  String get travelTodayMoodLabel => '今天的心情';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEmptyTitle => '暂无通知';

  @override
  String get notificationsEmptySubtitle => '有新消息时会显示在这里';
}
