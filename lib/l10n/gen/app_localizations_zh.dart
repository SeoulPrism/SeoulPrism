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
  String get languageChangedTitle => '已保存语言';

  @override
  String get languageChangedBody => '要完全应用新语言,请在应用切换器中向上滑动关闭应用,然后重新打开。';

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
  String get whatsNewPage9Title => '路线一站搞定';

  @override
  String get whatsNewPage9Body => '地铁、公交、步行合为一体。\n换乘、实时到达、车站出口\n都在同一个画面。';

  @override
  String get whatsNewPage10Title => '一日行程，自动生成';

  @override
  String get whatsNewPage10Body => '用收藏地点为你安排一天。\n高效路线、悠闲漫步、美食路线，\n三种风格任选。';

  @override
  String get whatsNewPage11Title => '支持四种语言';

  @override
  String get whatsNewPage11Body => '中文、韩文、英文、日文。\nAI 助手也用同一种语言回应。\n自动跟随设备语言。';

  @override
  String get whatsNewPage12Title => '用嘴问，用嘴答';

  @override
  String get whatsNewPage12Body =>
      '和 AI 助手自然语音对话。\n搜索、导航、推荐都能用语音。\nGemini Live 即听即答。';

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

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSectionRealtime => '实时可视化';

  @override
  String get settingsLineSubway => '地铁线路';

  @override
  String get settingsTrainPos => '地铁列车位置';

  @override
  String get settingsStations => '地铁站';

  @override
  String get settingsBuses => '市内公交';

  @override
  String get settingsRiverBus => '汉江公交';

  @override
  String get settingsFlights => '飞机';

  @override
  String get settingsSectionDataSource => '数据源';

  @override
  String get settingsSubwayMode => '地铁模式';

  @override
  String get settingsSubwayModeLive => '实时';

  @override
  String get settingsSubwayModeDemo => '演示';

  @override
  String get settingsSeoulApi => '首尔公开 API (60s)';

  @override
  String get settingsNaverApi => 'Naver API (5s 插值)';

  @override
  String get settingsSectionLighting => '光照';

  @override
  String get settingsAutoLighting => '自动 (时段 + 天气)';

  @override
  String get settingsLightPreset => '光照预设';

  @override
  String get settingsLightAuto => '自动';

  @override
  String get settingsLightDawn => '黎明';

  @override
  String get settingsLightDay => '白天';

  @override
  String get settingsLightDusk => '黄昏';

  @override
  String get settingsLightNight => '夜晚';

  @override
  String settingsCountValue(int count) {
    return '$count 个';
  }

  @override
  String get settingsLabelFavorites => '收藏';

  @override
  String get settingsLabelVisits => '访问记录';

  @override
  String get settingsLabelRecentSearches => '最近搜索';

  @override
  String get settingsAiAssistantLanguage => 'AI 助手语言';

  @override
  String get settingsThemeMode => '界面主题';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeChangedTitle => '已保存主题';

  @override
  String settingsThemeChangedBody(String theme) {
    return '要完全应用 $theme 模式,请在应用切换器中向上滑动关闭应用,然后重新打开。';
  }

  @override
  String get settingsRestartConfirm => '好';

  @override
  String get settingsMapHome => '地图首页起点';

  @override
  String get settingsMapHomeDefault => '默认';

  @override
  String get settingsMapHomeMyLocation => '我的位置';

  @override
  String get settingsMapHomeRecent => '最近搜索';

  @override
  String get settingsKeepScreenOn => '保持屏幕常亮';

  @override
  String get settingsAutoRotate => '屏幕自动旋转';

  @override
  String get settingsAlwaysMyLocation => '导航起点始终为我的位置';

  @override
  String get settingsClearHistory => '清空全部使用记录';

  @override
  String get settingsClearSearchHistory => '清空最近搜索';

  @override
  String get settingsConvertAccount => '转为正式账号';

  @override
  String get settingsEditNameItem => '修改名字';

  @override
  String get settingsChangePassword => '修改密码';

  @override
  String get settingsLogout => '退出登录';

  @override
  String get settingsDeleteAccount => '注销账号';

  @override
  String get settingsMapDataLabel => '地图显示与数据';

  @override
  String get settingsSectionDeveloper => '开发者';

  @override
  String get settingsDebugLogs => '调试日志输出';

  @override
  String get settingsResetTutorial => '重新查看引导';

  @override
  String get settingsReplayWhatsNew => '重新查看新功能';

  @override
  String get settingsWhatsNewToast => '下次启动应用时会再次显示新功能介绍';

  @override
  String get settingsAppVersion => '应用版本';

  @override
  String get settingsPrivacy => '隐私政策';

  @override
  String get settingsLicenses => '开源许可';

  @override
  String get settingsClearHistoryTitle => '清空使用记录';

  @override
  String get settingsClearHistoryBody => '所有使用记录将被删除。\n此操作无法撤销。';

  @override
  String get commonDelete => '删除';

  @override
  String get settingsClearedHistoryToast => '已删除所有使用记录';

  @override
  String get settingsClearSearchTitle => '清空搜索记录';

  @override
  String get settingsClearSearchBody => '最近搜索记录将被全部删除。';

  @override
  String get settingsClearedSearchToast => '已清空搜索记录';

  @override
  String get settingsEditNameDialogTitle => '修改名字';

  @override
  String get settingsEditNameDialogBody => '请输入新的名字。';

  @override
  String get settingsEditNameConfirm => '修改';

  @override
  String get settingsNewNameDialogTitle => '新名字';

  @override
  String get settingsChangePasswordTitle => '修改密码';

  @override
  String settingsChangePasswordBody(String email) {
    return '将向 $email 发送密码重置链接。';
  }

  @override
  String get settingsSendButton => '发送';

  @override
  String get settingsPasswordResetSent => '已发送重置邮件';

  @override
  String get settingsLogoutTitle => '退出登录';

  @override
  String get settingsLogoutBody => '确定要退出登录吗?';

  @override
  String get settingsLogoutConfirm => '退出';

  @override
  String get settingsDeleteAccountTitle => '注销账号';

  @override
  String get settingsDeleteAccountBody => '账号和所有数据将被永久删除。\n此操作无法撤销。';

  @override
  String get settingsDeleteAccountConfirm => '注销';

  @override
  String get settingsDeleteError => '注销过程中发生错误';

  @override
  String get settingsResetTutorialTitle => '重新查看引导';

  @override
  String get settingsResetTutorialBody => '将清除已保存的进度,下次启动应用时从头显示引导。';

  @override
  String get settingsResetTutorialConfirm => '重新查看';

  @override
  String get settingsMapDisplayTitle => '地图显示与数据';

  @override
  String get settingsSectionMapDisplay => '地图显示';

  @override
  String get aiStatusSearchingCourse => '正在搜索路线……';

  @override
  String aiPlacesFound(int count) {
    return '找到 $count 个地点!请在下方查看。';
  }

  @override
  String get aiStatusFindingInfo => '正在查找信息……';

  @override
  String get aiStatusAnalyzingImage => '正在分析图片……';

  @override
  String get aiNoPlacesFound => '未找到地点。';

  @override
  String aiAnalysisError(String error) {
    return '分析错误:$error';
  }

  @override
  String get aiSelectPhotoHint => '请选择照片';

  @override
  String get aiPhotoShoot => '拍摄';

  @override
  String get aiStatusConnecting => '连接中……';

  @override
  String get aiStatusListening => '正在听';

  @override
  String get aiStatusThinking => '思考中……';

  @override
  String get aiStatusSpeaking => '正在说';

  @override
  String get aiStatusIdle => '待机中';

  @override
  String get aiStatusReady => '准备中';

  @override
  String aiFoundPlacesHeader(int count) {
    return '找到的地点 ($count)';
  }

  @override
  String get aiVoiceCommandHint => '可以说「加个咖啡馆」「去掉景福宫」「就用这个」等';

  @override
  String aiPlaceStationDistance(String station, int minutes) {
    return '$station站 · $minutes 分钟';
  }

  @override
  String get aiDefaultSearch => '首尔旅行推荐路线';

  @override
  String get recommendTitle => '推荐';

  @override
  String recommendSubtitleNearbyArea(String area) {
    return '$area 附近现在最热门的地方';
  }

  @override
  String get recommendSubtitleNearbyDefault => '附近现在最热门的地方';

  @override
  String get recommendRefresh => '刷新';

  @override
  String get recommendNoResults => '周边暂无结果。\n请稍后再试。';

  @override
  String recommendRank(int rank) {
    return '第 $rank 名';
  }

  @override
  String get recommendEventsLoadError => '无法加载文化活动信息。\n请稍后再试。';

  @override
  String get recommendStatusUpcoming => '即将';

  @override
  String get recommendBadgePaid => '付费';

  @override
  String get recommendUniqueMood => '✨ 你自己的';

  @override
  String get recommendTabFood => '🍜 美食';

  @override
  String get recommendTabCafe => '☕️ 咖啡';

  @override
  String get recommendTabShopping => '🛍 购物';

  @override
  String get recommendTabOutdoor => '🌳 公园·夜景';

  @override
  String get recommendTabEvents => '🎭 文化';

  @override
  String get authTabSignUp => '注册';

  @override
  String get authTabSignIn => '登录';

  @override
  String get authProcessing => '处理中……';

  @override
  String get authSignIn => '登录';

  @override
  String get authSignUp => '注册';

  @override
  String get authLabelEmail => '邮箱';

  @override
  String get authHintEmail => '请输入邮箱';

  @override
  String get authLabelPassword => '密码';

  @override
  String get authHintPassword => '请输入密码';

  @override
  String get authFindId => '找回 ID';

  @override
  String get authFindPassword => '找回密码';

  @override
  String get authLabelUsername => 'ID';

  @override
  String get authHintUsername => '请输入 ID';

  @override
  String get authLabelConfirmPassword => '确认密码';

  @override
  String get authHintConfirmPassword => '请再次输入密码';

  @override
  String get authSnsLogin => '用社交账号登录';

  @override
  String get authGoogleAuthFailed => 'Google 认证失败';

  @override
  String get authGoogleSignInFailed => 'Google 登录失败';

  @override
  String get authGuestSignInFailed => '访客登录失败';

  @override
  String get authAppleAuthFailed => 'Apple 认证失败';

  @override
  String get authAppleSignInCanceled => 'Apple 登录已取消';

  @override
  String get authAppleSignInFailed => 'Apple 登录失败';

  @override
  String get authEmailAndPasswordRequired => '请输入邮箱和密码';

  @override
  String get authUsernameRequired => '请输入 ID';

  @override
  String get authPasswordMismatch => '密码不一致';

  @override
  String get authPasswordTooShort => '密码至少需要 6 位';

  @override
  String get authGenericError => '发生错误';

  @override
  String get authErrorInvalidCredentials => '邮箱或密码不正确';

  @override
  String get authErrorEmailExists => '该邮箱已注册';

  @override
  String get authErrorInvalidEmail => '请输入正确的邮箱格式';

  @override
  String get authErrorEmailNotConfirmed => '邮箱认证未完成。请查看邮箱。';

  @override
  String get authEmailConfirmRequiredTitle => '需要邮箱认证';

  @override
  String authEmailConfirmRequiredBody(String email) {
    return '已向 $email 发送认证邮件。\n请查看邮箱完成认证后再登录。';
  }

  @override
  String get authFindIdResultTitle => '找回 ID 结果';

  @override
  String get authFindIdResultBefore => '您的 ID 是 ';

  @override
  String get authFindIdResultAfter => ' 。';

  @override
  String get authFindIdEmailRequired => '请输入邮箱';

  @override
  String get authFindIdNotFound => '未找到该邮箱对应的账户';

  @override
  String get authPasswordResetSent => '密码重置链接已发送到您的邮箱';

  @override
  String get authFindIdFailed => '找回 ID 失败';

  @override
  String get authEmailSendFailed => '邮件发送失败';

  @override
  String get authFindIdTitle => '找回 ID';

  @override
  String get authFindPasswordTitle => '找回密码';

  @override
  String get authFindIdBody => '输入注册时使用的邮箱,\n我们将告诉您 ID。';

  @override
  String get authFindPasswordBody => '输入邮箱后,\n我们会向您发送密码重置链接。';

  @override
  String get authFindIdEmailHint => '请输入注册时的邮箱';

  @override
  String get authFindIdSubmit => '找回 ID';

  @override
  String get authFindPasswordSubmit => '获取重置链接';

  @override
  String get hubSettingsTooltip => '设置';

  @override
  String get hubAuthExploreSeoulTitle => '和朋友一起探索首尔';

  @override
  String get hubAuthCreateProfileSubtitle => '创建昵称和图钉开始体验。';

  @override
  String get hubAuthCreateProfileButton => '创建资料';

  @override
  String get hubPausedNotice => 'Seoul Live 已暂停 — 位置/通知已屏蔽,聊天仍可用';

  @override
  String get hubResumeButton => '恢复';

  @override
  String get hubRoomTitle => '好友房间';

  @override
  String get hubRoomEmpty => '新建房间或用代码加入';

  @override
  String hubRoomCurrent(String code) {
    return '已加入 · 代码 $code';
  }

  @override
  String get hubFriendsTitle => '好友';

  @override
  String hubFriendsSubtitle(int count, int requests) {
    return '$count 位 · 申请 $requests 条';
  }

  @override
  String get hubDmSubtitle => '与好友 1:1 私聊';

  @override
  String get hubFriendCodeTitle => '好友代码';

  @override
  String hubFriendCodeSubtitle(String code) {
    return '分享我的代码 $code / 输入代码';
  }

  @override
  String get hubFriendGroupsTitle => '好友分组';

  @override
  String hubFriendGroupsSubtitle(int count) {
    return '$count 个分组';
  }

  @override
  String get hubSpotifyConnectedNoPlayback => '已连接 — 无播放';

  @override
  String get hubSpotifyShareSubtitle => '把你听的歌分享给好友';

  @override
  String get hubVisibilityGhost => '隐身 — 不收发';

  @override
  String get hubVisibilityFriends => '好友房间 — 仅同房成员';

  @override
  String get hubVisibilityPublic => '完全公开 — 所有 Seoul Live 用户';

  @override
  String get hubActivityTitle => '我的动态';

  @override
  String get hubStatMeetups => '相遇';

  @override
  String get hubStatFriends => '好友';

  @override
  String get hubStatStreak => '连续';

  @override
  String hubStatStreakValue(int days) {
    return '$days 天';
  }

  @override
  String hubStatStreakBest(int days) {
    return '最高 $days';
  }

  @override
  String get hubBadgesEmptyHint => '通过第一位好友或第一次相遇收集徽章';

  @override
  String get hubAgoJust => '刚刚';

  @override
  String hubAgoMin(int min) {
    return '$min 分钟前';
  }

  @override
  String hubAgoHour(int hour) {
    return '$hour 小时前';
  }

  @override
  String hubAgoDay(int day) {
    return '$day 天前';
  }

  @override
  String get hubRecentMeetupsTitle => '🎉 最近的相遇';

  @override
  String hubRecentMeetupsCount(int count) {
    return '$count 次';
  }

  @override
  String get roomCodeRequired => '请输入 6 位代码。';

  @override
  String get roomLeaveTitle => '退出房间';

  @override
  String get roomLeaveBody => '退出后将结束位置共享与聊天。';

  @override
  String get roomLeaveConfirm => '退出';

  @override
  String get roomTitle => '好友房间';

  @override
  String get roomDescription => '实时与好友共享位置和聊天。';

  @override
  String get roomCapacityNote => '房间 24 小时后自动失效,容量 8 人。';

  @override
  String get roomCreateButton => '新建房间';

  @override
  String get roomCodeEntryTitle => '使用邀请码加入 (6 位)';

  @override
  String get roomJoinButton => '加入';

  @override
  String roomExpiresInMin(int min) {
    return '$min 分钟后失效';
  }

  @override
  String get roomDefaultName => '未命名房间';

  @override
  String get roomInviteCode => '邀请码';

  @override
  String get roomCodeCopied => '已复制代码';

  @override
  String roomExpiresInHours(int hour) {
    return '$hour 小时后失效';
  }

  @override
  String roomMembers(int current, int max) {
    return '成员 ($current/$max)';
  }

  @override
  String roomChatOpenWithUnread(int count) {
    return '打开聊天 ($count)';
  }

  @override
  String get roomChatOpen => '打开聊天';

  @override
  String get roomLeaveButton => '退出房间';

  @override
  String get roomEditNameTitle => '修改房间名';

  @override
  String get roomEditNameBody => '显示给房间成员';

  @override
  String get roomEditNamePlaceholder => '例如:光化门聚会';

  @override
  String roomGenericError(String error) {
    return '失败:$error';
  }

  @override
  String get roomShareSubject => 'Seoul Live 房间邀请';

  @override
  String roomShareBody(String nickname, String code) {
    return '$nickname 向你发送了 Seoul Live 房间邀请!\n\n代码:$code\n直接加入:com.seoul.prism://room/$code';
  }

  @override
  String get roomInviteTextCopied => '已复制邀请文本';

  @override
  String get roomRefreshCodeTitle => '更新邀请码';

  @override
  String get roomRefreshCodeBody => '旧代码会立即失效。继续吗?';

  @override
  String get roomRefreshCodeConfirm => '更新';

  @override
  String get roomCodeRefreshed => '代码已更新';

  @override
  String roomKickTitle(String nickname) {
    return '踢出 $nickname';
  }

  @override
  String get roomKickBody => '对方将立即被请出房间。';

  @override
  String get roomKickConfirm => '踢出';

  @override
  String get roomKickFallbackName => '成员';

  @override
  String roomNameMe(String name) {
    return '$name (我)';
  }

  @override
  String get roomMeetupBadge => '相遇';

  @override
  String get roomKickTooltip => '踢出';

  @override
  String get roomUnknownUser => '某人';

  @override
  String roomDestTitle(String name) {
    return '🎯 一起前往 — $name';
  }

  @override
  String roomDestSetBy(String name) {
    return '由 $name 设定';
  }

  @override
  String get roomDestDefault => '目的地';

  @override
  String get roomDestViewMap => '在地图中查看';

  @override
  String get roomDestClear => '取消目的地';

  @override
  String get mpSettingsTitle => 'Seoul Live 设置';

  @override
  String get mpSectionMyStatus => '我的状态';

  @override
  String get mpPause => '暂停 Seoul Live';

  @override
  String get mpPauseHint =>
      '✓ 聊天 / 加入房间 / 好友申请 — 允许\n✗ 位置发送 / 相遇通知 / 图钉显示 — 屏蔽\n数据将保留';

  @override
  String get mpSectionBattery => '省电模式';

  @override
  String get mpBatteryHint => '位置发送间隔 — 越精准,耗电越多';

  @override
  String get mpSectionNotifications => '通知';

  @override
  String mpNotificationsFail(String error) {
    return '失败:$error';
  }

  @override
  String get mpNotificationsHint => '与系统通知权限独立 — 这里关闭后推送仍发送但静音。';

  @override
  String get mpSectionTutorial => '引导';

  @override
  String get mpReplayTutorial => '重新查看 Seoul Live 引导';

  @override
  String get mpTutorialToast => '下次进入时会再次显示引导';

  @override
  String get mpReplayWhatsNew => '重新查看新功能';

  @override
  String mpReplayWhatsNewHint(String version) {
    return 'v$version 更新内容';
  }

  @override
  String get mpSectionSafety => '安全';

  @override
  String get mpBlockList => '屏蔽列表';

  @override
  String get mpBlockListHint => '查看/解除已屏蔽用户';

  @override
  String get mpSectionConsent => '同意与数据';

  @override
  String get mpRevokeConsent => '撤回位置信息同意';

  @override
  String get mpRevokeConsentHint => '撤回同意后将禁用多人功能并删除所有数据';

  @override
  String get mpDownloadMyData => '下载我的数据';

  @override
  String get mpDownloadMyDataHint => 'PIPA 数据可携权 — 通过邮件申请';

  @override
  String get mpDownloadMyDataToast => '请发送邮件到 rush94434@gmail.com (10 日内处理)';

  @override
  String get mpSectionOps => '运营组';

  @override
  String get mpOpsMonitor => '运营监控';

  @override
  String get mpOpsMonitorHint => '每日指标 · 滥用信号 · 举报处理';

  @override
  String get mpSectionDanger => '危险区';

  @override
  String get mpLeaveSeoulLive => '退出 Seoul Live';

  @override
  String get mpLeaveSeoulLiveHint => '一键删除资料·好友·房间·聊天等多人数据';

  @override
  String get mpFootnote => '※ Seoul Vista 主账号会保留。只删除多人相关数据。';

  @override
  String get mpRevokeDialogTitle => '撤回同意';

  @override
  String get mpRevokeDialogBody =>
      '撤回位置信息处理同意后将禁用多人功能,\n并删除资料·好友·房间·聊天数据。\n继续吗?';

  @override
  String get mpRevokeDialogConfirm => '撤回';

  @override
  String get mpRevokedToast => '已撤回同意并删除数据';

  @override
  String get mpLeaveDialogTitle => '退出 Seoul Live';

  @override
  String get mpLeaveDialogBody => '所有多人数据将被永久删除。\n可以重新加入,但好友·房间·聊天记录不会恢复。';

  @override
  String get mpLeaveConfirm => '退出';

  @override
  String get mpLeftToast => '已退出 Seoul Live';

  @override
  String get mpNotifCatFriendRequest => '好友申请';

  @override
  String get mpNotifCatFriendAccept => '好友接受';

  @override
  String get mpNotifCatRoomMessage => '聊天消息';

  @override
  String get mpNotifCatMeetup => '相遇检测';

  @override
  String get mpNotifCatDestination => '目的地变更';

  @override
  String get mpNotifCatWelcome => '欢迎';

  @override
  String get panelSubway => '地铁';

  @override
  String get panelBus => '公交';

  @override
  String get panelFlights => '飞机';

  @override
  String get panelDisplay => '显示';

  @override
  String get panelLineFilter => '线路筛选';

  @override
  String get panelPerformance => '性能';

  @override
  String get panelLighting => '光照';

  @override
  String get panelInfo => '信息';

  @override
  String get panelDeveloper => '开发者';

  @override
  String get panelDemoRunning => 'DEMO 运行中';

  @override
  String get panelLiveRunning => 'LIVE 运行中';

  @override
  String get panelOff => '已关闭';

  @override
  String get panelSwitchToLive => '切换到 LIVE 模式';

  @override
  String get panelSwitchToDemo => '切换到 DEMO 模式';

  @override
  String get panelSubwayOn => '开启地铁';

  @override
  String get panelSubwayOff => '关闭地铁';

  @override
  String panelTrainCount(int count) {
    return '列车 $count 列';
  }

  @override
  String panelLastUpdate(String time) {
    return '更新 $time';
  }

  @override
  String panelBusActive(int count) {
    return '正在显示 $count 辆公交';
  }

  @override
  String get panelSelectRoutes => '请选择线路';

  @override
  String get panelTurnAllOff => '全部关闭';

  @override
  String get panelBusPosition => '公交位置';

  @override
  String get panelHanRiverBus => '🚢 汉江公交';

  @override
  String get panelAddRoute => '添加线路';

  @override
  String panelFlightCount(String mode, int count) {
    return '$mode $count 架';
  }

  @override
  String get panelFlightFallback => '飞机';

  @override
  String get panelFlightLegendClimb => '爬升';

  @override
  String get panelFlightLegendCruise => '巡航';

  @override
  String get panelFlightLegendDescend => '下降';

  @override
  String get panelFlightLegendTakeoffLanding => '起降';

  @override
  String get panelRouteLines => '线路路径';

  @override
  String get panelTrainPosition => '列车位置';

  @override
  String get panelStationDisplay => '站点显示';

  @override
  String get panelSelectRoutesToShow => '选择要显示的线路';

  @override
  String get panelAll => '全部';

  @override
  String get panelPresetHigh => '高';

  @override
  String get panelPresetMedium => '中';

  @override
  String get panelPresetLow => '低';

  @override
  String get panelFps => '帧率';

  @override
  String get panelNaverPolling => 'Naver 轮询';

  @override
  String panelRenderInfo(String engine) {
    return '渲染:$engine · GeoJSON 缓存';
  }

  @override
  String get panelLightAuto => '自动';

  @override
  String get panelLightDay => '白天';

  @override
  String get panelLightNight => '夜晚';

  @override
  String get panelLightDawn => '黎明';

  @override
  String get panelLightDusk => '黄昏';

  @override
  String get panelTierFlagship => '旗舰';

  @override
  String get panelTierHigh => '高端';

  @override
  String get panelTierMid => '中端';

  @override
  String get panelTierLow => '入门';

  @override
  String get panelMapEngine => '地图引擎';

  @override
  String get panelDevice => '设备';

  @override
  String get panelPerfTier => '性能等级';

  @override
  String get mapDisplay3D => '3D 建筑显示';

  @override
  String get mapDisplayPois => 'POI 图标显示';

  @override
  String get mapDisplayWeather => '天气效果 (雾/雨)';

  @override
  String get mapDisplayLiveSubway => '实时地铁';

  @override
  String get friendsGroupTooltip => '好友分组';

  @override
  String get friendsCodeTooltip => '好友代码';

  @override
  String get friendsAddByNickname => '用昵称加好友';

  @override
  String get friendsSearchPlaceholder => '输入昵称后搜索';

  @override
  String get friendsSearching => '搜索中……';

  @override
  String get friendsSearch => '搜索';

  @override
  String friendsNotFound(String query) {
    return '没有与 \"$query\" 匹配的用户';
  }

  @override
  String get friendsSearchHint => '昵称需精确匹配。也可尝试好友代码 (8 位)。';

  @override
  String friendsReceivedRequests(int count) {
    return '收到的申请 ($count)';
  }

  @override
  String get friendsAccept => '接受';

  @override
  String get friendsReject => '拒绝';

  @override
  String friendsMyFriends(int count) {
    return '我的好友 ($count)';
  }

  @override
  String get friendsEmpty => '暂无好友。用昵称试着添加吧。';

  @override
  String get friendsCooldownTooltip => '被拒绝的申请 7 天后可再次发送';

  @override
  String friendsCooldownDays(int days) {
    return '$days 天后可再申请';
  }

  @override
  String friendsCooldownHours(int hours) {
    return '$hours 小时后';
  }

  @override
  String get friendsBadgeFriend => '好友';

  @override
  String get friendsBadgeRequested => '已申请';

  @override
  String get friendsApply => '申请';

  @override
  String friendsSendingRequestHint(String nickname) {
    return '向 $nickname 发送好友申请 — 接受后会收到推送通知';
  }

  @override
  String friendsDmStartFailed(String error) {
    return '私信开启失败:$error';
  }

  @override
  String get friendsUnfriend => '解除好友';

  @override
  String get friendsReport => '举报';

  @override
  String get friendsBlock => '屏蔽';

  @override
  String get friendsBlockDialogTitleFallback => '屏蔽该用户';

  @override
  String friendsBlockDialogTitle(String nickname) {
    return '屏蔽 $nickname';
  }

  @override
  String get friendsBlockDialogBody => '屏蔽后无法进入同一房间,消息也不再可见。';

  @override
  String get friendsBlockConfirm => '屏蔽';

  @override
  String get friendsUnknown => '未知';

  @override
  String friendsRequestSent(String nickname) {
    return '已向 $nickname 发送好友申请';
  }

  @override
  String friendsFailure(String error) {
    return '失败:$error';
  }

  @override
  String get friendsSuggestionsTitle => '推荐好友 (朋友的朋友)';

  @override
  String friendsMutualCount(int count) {
    return '共同好友 $count 人';
  }

  @override
  String get friendsAddShort => '添加';

  @override
  String get searchRouteNotFound => '未找到路线。请确认出发地/到达地。';

  @override
  String get searchLocationUnavailable => '无法获取当前位置。请检查定位权限和 GPS。';

  @override
  String get searchTabRoute => '导航';

  @override
  String get searchTabProfile => '我的';

  @override
  String get searchPathTypeOptimal => '最佳';

  @override
  String get searchPathTypeShortest => '最短';

  @override
  String get searchPathTypeMinTransfer => '最少换乘';

  @override
  String get searchOutsideServiceTitle => '在服务区域之外';

  @override
  String get searchOutsideServiceBody =>
      '当前导航仅支持首尔·仁川·京畿首都圈。请在首都圈内重新选择出发地或到达地。';

  @override
  String get searchDepartureFieldHint => '出发地';

  @override
  String get searchArrivalFieldHint => '到达地';

  @override
  String get searchSwapDepArr => '交换出发/到达';

  @override
  String get searchCloseTooltip => '关闭导航';

  @override
  String get searchPlaceholder => '搜索地点·公交·地铁';

  @override
  String get searchClearLabel => '清除搜索';

  @override
  String get searchRecentTitle => '最近搜索';

  @override
  String get searchRecentClearAll => '全部删除';

  @override
  String get searchRecentRoutesTitle => '最近导航';

  @override
  String get searchBusTypeTrunk => '干线';

  @override
  String get searchBusTypeBranch => '支线';

  @override
  String get searchBusTypeCircular => '环线';

  @override
  String get searchBusTypeMetro => '广域';

  @override
  String get searchBusTypeIncheon => '仁川';

  @override
  String get searchBusTypeGyeonggi => '京畿';

  @override
  String get searchBusTypeDefault => '公交';

  @override
  String get searchCatFood => '餐饮';

  @override
  String get searchCatCafe => '咖啡';

  @override
  String get searchCatPark => '公园';

  @override
  String get searchCatShopping => '购物';

  @override
  String get searchCatMedical => '医疗';

  @override
  String get searchCatEducation => '教育';

  @override
  String get searchCatLodging => '住宿';

  @override
  String get searchCatFinance => '金融';

  @override
  String get searchCatTransit => '交通';

  @override
  String get searchCatAddress => '地址';

  @override
  String get searchCatCity => '城市';

  @override
  String get searchCatNeighborhood => '街区';

  @override
  String get searchCatRoad => '道路';

  @override
  String liveBadgePeerTrack(String nickname, String track) {
    return '$nickname 正在听 $track';
  }

  @override
  String liveBadgeSharing(int count) {
    return '正在与 $count 人共享位置';
  }

  @override
  String get liveBadgeStopped => '已停止位置共享';

  @override
  String get seoulLiveStartTitle => 'Seoul Live 已开启';

  @override
  String get seoulLiveStartBody => '地图已扩展到世界';

  @override
  String get seoulLiveStep2Title => '好友的图钉出现在地图上';

  @override
  String get seoulLiveStep2Body => '同一房间的成员以图钉 (昵称 + 表情) 实时显示。好友移动时图钉也会跟着移动。';

  @override
  String get seoulLiveStep3Title => '用房间代码集合';

  @override
  String get seoulLiveStep3Body =>
      '在 资料 → Seoul Live → 房间 创建新房间或用 6 位邀请码加入。容量 8 人。';

  @override
  String get seoulLiveStep4Title => '50m 以内有相遇通知';

  @override
  String get seoulLiveStep4Body => '与好友靠近时会震动并通知。聊天也会自动记录。';

  @override
  String get seoulLiveStep5Title => '随时切换隐身模式';

  @override
  String get seoulLiveStep5Body => '点击顶部「位置共享」徽章可立即切换到 ghost 模式。退出房间也会自动停止发送。';

  @override
  String get seoulLivePermTitle => '接收通知';

  @override
  String get seoulLivePermBody => '当好友申请 / 新消息 / 相遇发生时,我们会通过推送通知告诉你。请点击下方「允许」。';

  @override
  String get seoulLivePermAllowed => '✓ 已允许通知';

  @override
  String get seoulLivePermDenied => '已拒绝 — 可在设置中手动允许';

  @override
  String get seoulLivePermRequesting => '请求中……';

  @override
  String get seoulLivePermAllow => '允许通知';

  @override
  String get roomMembersEmpty => '暂无在一起的好友';

  @override
  String roomMembersWithCount(int count) {
    return '一起的好友 $count 人';
  }

  @override
  String get roomMembersGhost => '隐身';

  @override
  String get roomMembersDisconnected => '未连接';

  @override
  String get roomMembersRealtime => '实时';

  @override
  String get roomMembersStale => '暂时离开';

  @override
  String get dmListAgoJust => '刚刚';

  @override
  String dmListAgoMin(int min) {
    return '$min 分';
  }

  @override
  String dmListAgoHour(int hour) {
    return '$hour 小时';
  }

  @override
  String dmListAgoDay(int day) {
    return '$day 天';
  }

  @override
  String get dmListKindVoice => '🎙 语音';

  @override
  String get dmListKindImage => '🖼 照片';

  @override
  String get dmListKindPlace => '📍 地点';

  @override
  String get dmListKindSpotify => '🎵 歌曲';

  @override
  String get dmListEmpty => '暂无私信';

  @override
  String get dmListEmptyHint => '在好友页点击消息按钮开始';

  @override
  String get friendGroupsNewTitle => '新建分组';

  @override
  String get friendGroupsNewTooltip => '新建分组';

  @override
  String get friendGroupsEmpty => '暂无分组';

  @override
  String get friendGroupsEmptyHint => '点击上方 + 把好友分组';

  @override
  String get friendGroupsEmptyHintAlt => '点击右上角的 + 按钮创建分组以管理好友。';

  @override
  String get friendGroupsNamePlaceholder => '例如:家人、公司、社团';

  @override
  String get friendGroupsCreate => '创建';

  @override
  String get friendGroupsCreated => '已创建分组';

  @override
  String friendGroupsFailure(String error) {
    return '失败:$error';
  }

  @override
  String friendGroupsDeleteTitle(String emoji, String name) {
    return '删除 $emoji $name';
  }

  @override
  String get friendGroupsDeleteBody => '只删除分组,好友保留。';

  @override
  String get friendGroupsDelete => '删除';

  @override
  String get friendGroupsName => '名称';

  @override
  String get friendGroupsIcon => '图标';

  @override
  String friendGroupsMemberCount(int count) {
    return '$count 人';
  }

  @override
  String get friendGroupsNoFriendsPrompt => '请先添加好友。';

  @override
  String get friendGroupsVisibilityHint => '用于分组可见性 / 聊天';

  @override
  String friendGroupsMembersTitle(String emoji, String name) {
    return '$emoji $name 的成员';
  }

  @override
  String get friendGroupsEditMembers => '编辑成员';

  @override
  String get friendGroupsEmptyFriendsBox => '暂无好友';

  @override
  String get loginRequiredTitle => '需要登录';

  @override
  String get loginRequiredBody =>
      '多人功能仅限正式登录用户使用。\n访客 (匿名) 账号 30 天未使用会自动删除,\n好友·房间信息可能丢失。';

  @override
  String get loginRequiredCta => '去登录';

  @override
  String get reportReasonSpam => '垃圾/广告';

  @override
  String get reportReasonHate => '辱骂/仇恨表达';

  @override
  String get reportReasonSexual => '色情/不适当内容';

  @override
  String get reportReasonHarass => '骚扰/跟踪';

  @override
  String get reportReasonFakeLocation => '虚假位置/冒充';

  @override
  String get reportReasonMinorAbuse => '侵犯未成年人保护';

  @override
  String get reportReasonOther => '其他';

  @override
  String get reportSelectReason => '请选择原因。';

  @override
  String get reportSubmitted => '已收到举报,将在 24 小时内审核。';

  @override
  String reportTitleUser(String label) {
    return '举报 $label';
  }

  @override
  String get reportTitleMessage => '举报消息';

  @override
  String get reportNote => '运营团队会在 24 小时内审核并处理。';

  @override
  String get reportExtraPlaceholder => '补充说明 (可选)';

  @override
  String get reportSubmit => '举报';

  @override
  String get reportSubmitting => '发送中……';

  @override
  String get reportFallbackUser => '用户';

  @override
  String get blockedUsersTitle => '屏蔽列表';

  @override
  String get blockedUsersEmpty => '暂无屏蔽用户';

  @override
  String blockedUsersUnblockTitle(String name) {
    return '取消屏蔽 $name';
  }

  @override
  String get blockedUsersUnblockBody => '取消屏蔽后可再次相遇,消息也会显示。';

  @override
  String get blockedUsersUnblockConfirm => '取消屏蔽';

  @override
  String get activityTitle => '活动分析';

  @override
  String get activityCatMeetup => '🎉 相遇';

  @override
  String get activityCatFriend => '🤝 好友';

  @override
  String get activityCatRoomJoined => '🚪 加入房间';

  @override
  String get activityCatPlaceShared => '📍 位置分享';

  @override
  String get activityCatDestination => '🎯 目的地';

  @override
  String get activityAgoJust => '刚刚';

  @override
  String activityAgoMin(int min) {
    return '$min 分钟前';
  }

  @override
  String activityAgoHour(int hour) {
    return '$hour 小时前';
  }

  @override
  String activityAgoDay(int day) {
    return '$day 天前';
  }

  @override
  String get activityRanking => '好友排名';

  @override
  String get activityRecent => '最近活动';

  @override
  String get activityEmpty => '暂无活动记录';

  @override
  String activityCode(String code) {
    return '代码 $code';
  }

  @override
  String get activityThisWeek => '本周活动';

  @override
  String activityTotalCount(int count) {
    return '共 $count 条';
  }

  @override
  String get activityWeekdayMon => '一';

  @override
  String get activityWeekdayTue => '二';

  @override
  String get activityWeekdayWed => '三';

  @override
  String get activityWeekdayThu => '四';

  @override
  String get activityWeekdayFri => '五';

  @override
  String get activityWeekdaySat => '六';

  @override
  String get activityWeekdaySun => '日';

  @override
  String get peerNowPlayingBtnFriend => '已是好友 ✓';

  @override
  String get peerNowPlayingBtnRequested => '已申请';

  @override
  String get peerNowPlayingBtnAccept => '接受好友申请';

  @override
  String get peerNowPlayingBtnSendRequest => '发送好友申请';

  @override
  String get peerNowPlayingOpenInSpotify => '在 Spotify 中收听';

  @override
  String get mapNoLocationPermission => '没有位置权限,好友看不到我的图钉。请在 设置 → 位置 中允许。';

  @override
  String get mapLeftRoom => '已退出好友房间';

  @override
  String mapShowOnMap(String name) {
    return '在地图查看 \"$name\"';
  }

  @override
  String mapBuildingInside(String name) {
    return '🏢 你正在 $name 内';
  }

  @override
  String get mapLocationChecking => '正在确认位置……';

  @override
  String get mapLocationPermissionDenied =>
      '位置权限被拒绝 → iOS 设置 → Seoul Vista → 位置';

  @override
  String get mapLocationServiceOff => 'iOS 设置 → 隐私 → 位置服务 已关闭';

  @override
  String get mapMyLocationMoved => '已移动到我的位置';

  @override
  String mapLocationFetchFailed(String error) {
    return '获取位置失败:$error';
  }

  @override
  String get mapMapAppUnavailable => '无法打开地图应用';

  @override
  String get mapTabRecommend => '推荐';

  @override
  String get mapTabSave => '保存';

  @override
  String get mapTabMap => '地图';

  @override
  String get mapTabWorld => '世界';

  @override
  String get mapTabTrip => '旅行';

  @override
  String get mapDirectionsRoadFetching => '正在加载驾车路线……';

  @override
  String get mapDirectionsWalkFetching => '正在加载步行路线……';

  @override
  String get mapNoCoords => '未能找到出发/到达坐标';

  @override
  String get mapDirectionsFailed => '未能加载路线';

  @override
  String mapInsufficientSavedPlaces(int min) {
    return '需要更多地点 — 收藏/访问记录达到 $min 个以上将自动生成路线';
  }

  @override
  String get subwayPanelExpand => '展开面板';

  @override
  String get subwayPanelCollapse => '收起面板';

  @override
  String subwayPanelDelayedTrains(int count) {
    return '延误列车 $count 列';
  }

  @override
  String subwayPanelMinutes(int min) {
    return '$min 分钟';
  }

  @override
  String subwayPanelOthersCount(int count) {
    return '另外 $count 列……';
  }

  @override
  String get subwayPanelOffTapToStart => 'OFF — 点击开始';

  @override
  String get subwayPanelMode => '模式';

  @override
  String get subwayPanelDemoLabel => '演示 (不使用 API)';

  @override
  String get subwayPanelLiveLabel => '实时';

  @override
  String get subwayPanelTrainsLabel => '列车数';

  @override
  String subwayPanelTrainsValue(int count) {
    return '$count 列';
  }

  @override
  String get subwayPanelUpdate => '更新';

  @override
  String get subwayPanelToggleRoutes => '线路';

  @override
  String get subwayPanelToggleTrains => '列车位置';

  @override
  String get subwayPanelToggleStations => '站点';

  @override
  String get subwayPanelToggleCongestion => '拥挤度';

  @override
  String get subwayPanelRouteFilter => '线路筛选';

  @override
  String get subwayPanelAll => '全部';

  @override
  String get subwayPanelToggleOn => '开启地铁可视化';

  @override
  String get subwayPanelToggleOff => '关闭地铁可视化';

  @override
  String get subwayPanelNoArrivalInfo => '无到达信息';

  @override
  String subwayPanelTrainDirection(String destination, String type) {
    return '开往 $destination · $type';
  }

  @override
  String get subwayPanelCloseDetail => '关闭列车详情';

  @override
  String subwayPanelTrainNo(String no) {
    return '列车 #$no';
  }

  @override
  String subwayPanelDelayedBadge(int min) {
    return '延误 $min 分钟';
  }

  @override
  String get subwayPanelLastTrainBadge => '末班车';

  @override
  String subwayPanelTerminalDestination(String terminal) {
    return '开往 $terminal';
  }

  @override
  String get subwayPanelPrevStation => '上一站';

  @override
  String get subwayPanelDepartureStation => '起点站';

  @override
  String get subwayPanelCurrentStation => '当前站';

  @override
  String get subwayPanelNextStation => '下一站';

  @override
  String get subwayPanelStateArriving => '即将到达';

  @override
  String get subwayPanelStateStopped => '停车中';

  @override
  String get subwayPanelStateDeparted => '已出发';

  @override
  String get subwayPanelStateMoving => '行驶中';

  @override
  String get subwayPanelStateOperating => '运营中';

  @override
  String get subwayPanelDirInnerLoop => '内环';

  @override
  String get subwayPanelDirOuterLoop => '外环';

  @override
  String get subwayPanelDirUp => '上行';

  @override
  String get subwayPanelDirDown => '下行';

  @override
  String get subwayPanelTrainTypeExpress => '急行';

  @override
  String get subwayPanelTrainTypeSpecial => '特快';

  @override
  String get subwayPanelTrainTypeRegular => '普通';

  @override
  String get searchTileSubway => '地铁';

  @override
  String get profileEditNicknameInvalid => '昵称请输入 1~20 个字符。';

  @override
  String get profileEditBirthInvalid => '请准确输入出生年份 (YYYY)。';

  @override
  String get profileEditAgeRestriction => '14 岁以下无法使用多人功能。';

  @override
  String get profileEditTitle => '资料设置';

  @override
  String get profileEditSubtitle => '决定在房间里向他人显示的样子。';

  @override
  String get profileEditNicknameLabel => '昵称 (允许重复)';

  @override
  String get profileEditNicknamePlaceholder => '例如:首尔探险家';

  @override
  String get profileEditBirthLabel => '出生年份 (满 14 岁以上)';

  @override
  String get profileEditBirthPlaceholder => '例如:2000';

  @override
  String get profileEditEmojiLabel => '图钉表情';

  @override
  String get profileEditColorLabel => '图钉颜色';

  @override
  String get profileEditVisibilityLabel => '位置公开范围';

  @override
  String get profileEditVisibilityGhost => '隐身';

  @override
  String get profileEditVisibilityFriends => '房间';

  @override
  String get profileEditVisibilityGroup => '仅分组';

  @override
  String get profileEditVisibilityPublic => '公开';

  @override
  String get profileEditSaving => '保存中……';

  @override
  String get profileEditSave => '保存';

  @override
  String get profileEditPublicDialogTitle => '切换到公开';

  @override
  String get profileEditPublicDialogBody =>
      '你的位置将实时显示给所有 Seoul Live 用户,包括陌生人。\n\n• 请注意不当相遇/跟踪风险\n• 随时可恢复为隐身/房间\n• 屏蔽/举报可在好友资料或聊天菜单中操作';

  @override
  String get profileEditPublicDialogConfirm => '继续';

  @override
  String get profileEditVisibilityGhostDesc => '不发送位置。也看不到其他人的位置。';

  @override
  String get profileEditVisibilityFriendsDesc => '仅在房间里时,同房成员可见你的位置。';

  @override
  String get profileEditVisibilityGroupDesc => '只有所选分组的好友能看到你的位置。';

  @override
  String get profileEditVisibilityPublicDesc =>
      '⚠️ 任何 Seoul Live 用户都能看到你的位置。房间里也会同样发送。';

  @override
  String get profileEditNoGroups => '暂无分组。请在 好友 → 分组 中创建。';

  @override
  String get adminMonitorTitle => '运营监控';

  @override
  String get adminRefresh => '刷新';

  @override
  String get adminTabMetrics => '指标';

  @override
  String get adminTabAbuse => '滥用';

  @override
  String get adminTabReports => '举报';

  @override
  String get adminMetricAllProfiles => '全部资料';

  @override
  String get adminMetricActiveRooms => '活跃房间';

  @override
  String get adminMetricTodayMeetups => '今日相遇';

  @override
  String get adminMetricTodayBlocks => '今日屏蔽';

  @override
  String get adminMetricTodayReports => '今日举报';

  @override
  String get adminNoSuspiciousSignals => '无可疑信号 (24 小时内被 3 次以上屏蔽的用户 X)';

  @override
  String adminRecentBlockCount(int count) {
    return '24h 内被 $count 人屏蔽';
  }

  @override
  String get adminReportStatusPending => '待处理';

  @override
  String get adminReportStatusReviewed => '已审核';

  @override
  String get adminReportStatusActioned => '已处理';

  @override
  String get adminReportStatusDismissed => '已驳回';

  @override
  String get adminNoReports => '暂无举报';

  @override
  String get adminReportTypeMessage => '消息举报';

  @override
  String get adminReportTypeUser => '用户举报';

  @override
  String get adminReportActionReview => '审核';

  @override
  String get adminReportActionAction => '处理';

  @override
  String get adminReportActionDismiss => '驳回';

  @override
  String adminAgoMin(int min) {
    return '$min 分钟前';
  }

  @override
  String adminAgoHour(int hour) {
    return '$hour 小时前';
  }

  @override
  String adminAgoDay(int day) {
    return '$day 天前';
  }

  @override
  String get liveDiagTitle => '实时诊断';

  @override
  String get liveDiagMyId => '我的 ID';

  @override
  String get liveDiagVisibility => '公开范围';

  @override
  String get liveDiagRoom => '房间';

  @override
  String get liveDiagPeers => '接收对端';

  @override
  String liveDiagPeersValue(int count) {
    return '$count 个';
  }

  @override
  String get liveDiagPresenceStatus => 'Presence 状态';

  @override
  String get liveDiagWorldStatus => 'World 状态';

  @override
  String get liveDiagLastSent => '最近发送';

  @override
  String get liveDiagSendError => '发送错误';

  @override
  String get liveDiagGps => 'GPS';

  @override
  String get liveDiagPaused => '已暂停';

  @override
  String get liveDiagActivityFailCount => '活动记录失败';

  @override
  String liveDiagActivityFailValue(int count) {
    return '$count 次';
  }

  @override
  String get liveDiagLastActivityError => '最近活动错误';

  @override
  String get liveDiagFooter => '如有问题请截图分享';

  @override
  String get liveDiagClose => '关闭';

  @override
  String get liveDiagNoProfile => '(无资料)';

  @override
  String get liveDiagNone => '(无)';

  @override
  String get liveDiagNotConnected => '(未连接)';

  @override
  String get liveDiagNotUsed => '(未使用)';

  @override
  String get liveDiagNotSent => '尚未发送';

  @override
  String liveDiagSecondsAgo(int sec) {
    return '$sec 秒前';
  }

  @override
  String liveDiagRoomLabel(String code, int count) {
    return '$code ($count 人)';
  }

  @override
  String get liveDiagGpsHas => '有';

  @override
  String get liveDiagGpsNo => '无';

  @override
  String get mpConsentLocationDenied => '请在 设置 > 位置 中允许位置权限。';

  @override
  String get mpConsentTitle => '多人功能开始前的说明';

  @override
  String get mpConsentHeading => 'Seoul Live 同意';

  @override
  String get mpConsentBody => '为了与朋友共享位置,需要您同意以下项目。每项可以单独同意/拒绝,并可随时在设置中撤回。';

  @override
  String get mpConsentItem1Title => '[必需] 个人资料处理';

  @override
  String get mpConsentItem1Detail =>
      '昵称、图钉颜色/表情、出生年份。用于服务识别和阻止 14 岁以下注册。保留至账号删除,注销时立即销毁。';

  @override
  String get mpConsentItem2Title => '[必需] 位置信息处理 (LBS 法 §18)';

  @override
  String get mpConsentItem2Detail =>
      'GPS 坐标和移动方向。会向房间成员实时共享,或在选择「公开」时向所有 Seoul Live 用户实时共享。不进行长期存储 — 通过 Realtime 通道临时传输。可随时在资料中将公开范围更改为隐身/房间/公开。';

  @override
  String get mpConsentItem3Title => '[必需] 位置基础服务使用条款';

  @override
  String get mpConsentItem3Detail => '由放通委备案运营商提供。14 岁以下不可使用。';

  @override
  String get mpConsentItem3Link => '查看条款全文';

  @override
  String get mpConsentDeclineNote => '拒绝后仅多人功能不可用,其他功能仍可正常使用。';

  @override
  String get mpConsentBackgroundNote => '应用进入后台时位置共享会自动暂停 (省电)。';

  @override
  String get mpConsentSubmit => '同意并开始';

  @override
  String get mpConsentLaterButton => '稍后';

  @override
  String get mpConsentSubmitBusy => '处理中……';

  @override
  String get mpConsentLbsTermsBody =>
      '本条款规定 Seoul Vista 提供的 Seoul Live (以下简称\"服务\") 位置基础服务的使用事项。';

  @override
  String get optTitle => '为你的设备调校';

  @override
  String get optSubtitle => '实时可视化对 GPU 负担较大。\n请根据设备选择。';

  @override
  String get optPresetHighTitle => '高画质';

  @override
  String get optPresetHighDetail => '60fps · 5 秒刷新 · 抗锯齿 ON';

  @override
  String get optPresetSmoothTitle => '流畅';

  @override
  String get optPresetSmoothDetail => '30fps · 10 秒刷新';

  @override
  String get optPresetBatteryTitle => '省电';

  @override
  String get optPresetBatteryDetail => '20fps · 30 秒刷新 · 特效 OFF';

  @override
  String get optAdvancedTitle => '高级 — 选择要显示的图层';

  @override
  String get optLayerSubway => '地铁 (实时列车位置)';

  @override
  String get optLayerSubwaySub => '首尔地铁 + 广域铁路。GPU 负担最大';

  @override
  String get optLayerBus => '市内公交';

  @override
  String get optLayerBusSub => '首尔 + 京畿市内公交实时位置';

  @override
  String get optLayerRiverBus => '汉江公交';

  @override
  String get optLayerRiverBusSub => '汉江运营船舶';

  @override
  String get optLayerFlights => '飞机';

  @override
  String get optLayerFlightsSub => '仁川机场附近的实时飞机';

  @override
  String optDetectedTier(String tier) {
    return '检测为 $tier 级';
  }

  @override
  String get optRecommended => '推荐';

  @override
  String get vehicleCongestion => '拥挤度';

  @override
  String get vehicleCongestionNone => '无信息';

  @override
  String get vehicleCongestionFree => '宽松';

  @override
  String get vehicleCongestionNormal => '一般';

  @override
  String get vehicleCongestionBusy => '拥挤';

  @override
  String get vehicleCongestionPacked => '非常拥挤';

  @override
  String get vehicleCongestionFull => '满载';

  @override
  String get vehicleStatus => '状态';

  @override
  String get vehicleStopped => '停车中';

  @override
  String get vehicleRunning => '运行中';

  @override
  String get vehicleSection => '区间';

  @override
  String vehicleSectionOrd(int ord) {
    return '第$ord站';
  }

  @override
  String get vehicleBusLowFloor => '低地板巴士';

  @override
  String get vehicleBusRegular => '普通巴士';

  @override
  String get vehiclePhaseAscent => '上升';

  @override
  String get vehiclePhaseCruise => '巡航';

  @override
  String get vehiclePhaseDescent => '下降';

  @override
  String get vehiclePhaseTakeoff => '起降';

  @override
  String get vehiclePhaseGround => '地面';

  @override
  String get vehicleAltitude => '高度';

  @override
  String get vehicleAltitudeOnGround => '地面';

  @override
  String get vehicleSpeed => '速度';

  @override
  String get vehicleHeading => '方向';

  @override
  String vehicleRiverBusRoute(String name) {
    return '汉江巴士 $name';
  }

  @override
  String get vehicleRiverDirNormal => '正向';

  @override
  String get vehicleRiverDirReverse => '反向';

  @override
  String get vehicleRiverPhaseStop => '停靠';

  @override
  String get vehicleNext => '下一站';

  @override
  String get vehicleProgress => '进度';

  @override
  String get deepLinkRoomLoginRequired => '登录后才能进入房间';

  @override
  String deepLinkRoomEntered(String code) {
    return '进入房间 — 代码 $code';
  }

  @override
  String deepLinkRoomFailure(String error) {
    return '进入房间失败: $error';
  }

  @override
  String get snsAnalysisTitle => '分析结果';

  @override
  String get snsAnalysisEmpty => '未提取到地点';

  @override
  String snsAnalysisCreatePlans(int count) {
    return '创建行程 ($count处)';
  }

  @override
  String snsAnalysisPlanFailure(String error) {
    return '行程生成失败: $error';
  }

  @override
  String snsAnalysisNearestStation(String station, int minutes) {
    return '📍 $station站 · $minutes分钟';
  }

  @override
  String get avatarMyPin => '我的图钉';

  @override
  String get avatarNoRoomHint => '加入朋友房间后,朋友们会显示在这里';

  @override
  String get avatarNoRoomMembers => '暂时没有同伴';

  @override
  String avatarRoomMembersCount(int count) {
    return '同伴 $count 人';
  }

  @override
  String get avatarNoTrack => '未在播放音乐';

  @override
  String get qrScanTitle => '扫描 QR';

  @override
  String qrScanCameraError(String error) {
    return '无法使用相机\n$error';
  }

  @override
  String get qrScanHint => '请将朋友的 QR 码对准方框';

  @override
  String get buildingOccupantsFallbackName => '建筑';

  @override
  String buildingOccupantsInside(int count) {
    return '$count 人在里面';
  }

  @override
  String get buildingOccupantsEmpty => '已离开建筑';

  @override
  String buildingOccupantsListening(String name, String artist) {
    return '🎵 正在听 $name · $artist';
  }

  @override
  String get buildingOccupantsInBuilding => '🏢 在建筑内';

  @override
  String get weatherWeeklyLabel => '一周';

  @override
  String get weatherToday => '今天';

  @override
  String get weatherDayMon => '一';

  @override
  String get weatherDayTue => '二';

  @override
  String get weatherDayWed => '三';

  @override
  String get weatherDayThu => '四';

  @override
  String get weatherDayFri => '五';

  @override
  String get weatherDaySat => '六';

  @override
  String get weatherDaySun => '日';

  @override
  String get locPermTitle => '需要位置权限';

  @override
  String get locPermBody => '为了在地图上显示您的位置,并提供周边信息和导航,\n需要位置权限。';

  @override
  String get locPermRequesting => '请求中...';

  @override
  String get locPermRequest => '允许位置权限';

  @override
  String get locPermGranted => '✓ 已允许位置权限';

  @override
  String get locPermDenied => '已拒绝 — 可在设置中手动允许';

  @override
  String get locPermRetry => '重试';

  @override
  String get groupEditorTitle => '朋友分组';

  @override
  String get groupEditorNew => '新建分组';

  @override
  String get groupEditorEmpty => '还没有分组';

  @override
  String get groupEditorEmptyHint => '用右上角的 + 创建分组并分类朋友。';

  @override
  String get groupEditorHelper => '用于分组可见性 / 聊天';

  @override
  String get groupEditorNamePlaceholder => '例如:家人、同事、社团';

  @override
  String get groupEditorCreate => '创建';

  @override
  String groupEditorFailure(String error) {
    return '失败: $error';
  }

  @override
  String groupEditorMemberCount(int count) {
    return '$count 人';
  }

  @override
  String groupEditorDeleteTitle(String name) {
    return '删除分组 $name';
  }

  @override
  String get groupEditorDeleteBody => '仅删除分组,朋友会保留。';

  @override
  String get groupEditorDelete => '删除';

  @override
  String get groupEditorAddFriendsHint => '请先添加朋友。';

  @override
  String get peerPinDestinationFallback => '目的地';

  @override
  String peerPinDestinationLabel(String name) {
    return '🎯 $name';
  }

  @override
  String get stationDetailCloseLabel => '关闭车站详情';

  @override
  String get stationDetailDeparture => '出发';

  @override
  String get stationDetailArrival => '到达';

  @override
  String get stationDetailLiveArrivals => '实时发车信息';

  @override
  String get stationDetailLoading => '加载中...';

  @override
  String get stationDetailNoArrivals => '暂无到达信息';

  @override
  String get stationDetailCrowdVery => '非常拥挤';

  @override
  String get stationDetailCrowdBusy => '拥挤';

  @override
  String get stationDetailCrowdNormal => '一般';

  @override
  String get stationDetailCrowdFree => '宽松';

  @override
  String stationDetailBoardingCount(String count) {
    return '上车 $count 人';
  }

  @override
  String stationDetailAlightingCount(String count) {
    return '下车 $count 人';
  }

  @override
  String stationDetailClosureCount(int count) {
    return '设施关闭 $count 项';
  }

  @override
  String get visitTimelineTitle => '我的足迹';

  @override
  String visitTimelineSummary(int count, String ago) {
    return '$count 处 · 最近 $ago';
  }

  @override
  String get visitTimelineEmpty => '暂无访问记录。';

  @override
  String get visitTimelineClose => '关闭';

  @override
  String visitTimelineExpand(int count) {
    return '查看更多 $count 处';
  }

  @override
  String get visitTimelineCollapse => '收起';

  @override
  String get visitTimelineDateToday => '今天';

  @override
  String get visitTimelineDateYesterday => '昨天';

  @override
  String visitTimelineDateDaysAgo(int days) {
    return '$days 天前';
  }

  @override
  String visitTimelineDateMonthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String get visitTimelineAgoNone => '无';

  @override
  String visitTimelineAgoMin(int min) {
    return '$min 分钟前';
  }

  @override
  String visitTimelineAgoHour(int hour) {
    return '$hour 小时前';
  }

  @override
  String visitTimelineAgoDay(int day) {
    return '$day 天前';
  }

  @override
  String visitTimelineVisitCount(int count) {
    return '$count 次';
  }

  @override
  String get permPageTitle => '权限设置';

  @override
  String get permPageBody => '提前一次性配置好以下权限,\n使用过程中就不会被打断。';

  @override
  String get permPageFooter => '拒绝也能使用,只是相应功能受限。';

  @override
  String get permPageRequesting => '请求中...';

  @override
  String get permPageAllGranted => '✓ 全部已允许';

  @override
  String get permPageRequestAll => '一键允许';

  @override
  String get permItemLocation => '位置';

  @override
  String get permItemLocationDesc => '在地图上显示我的位置 + 朋友房间实时共享';

  @override
  String get permItemNotification => '通知';

  @override
  String get permItemNotificationDesc => '好友申请 / 聊天 / 见面提醒';

  @override
  String get permItemCamera => '相机';

  @override
  String get permItemCameraDesc => '地点照片分析 + 朋友聊天的照片';

  @override
  String get permItemPhotos => '照片';

  @override
  String get permItemPhotosDesc => '在聊天中分享相册照片';

  @override
  String get permItemMicrophone => '麦克风';

  @override
  String get permItemMicrophoneDesc => 'AI 语音对话 + 语音消息';

  @override
  String permTapToSettings(String desc) {
    return '$desc (点击打开设置)';
  }

  @override
  String get livingCityTitle => '首尔正在跃动';

  @override
  String get livingCityBody => '点击图标,相机就会飞到那个场景。';

  @override
  String get livingCityVehSubway => '地铁';

  @override
  String get livingCityVehBus => '公交';

  @override
  String get livingCityVehRiverBus => '汉江巴士';

  @override
  String get livingCityVehFlight => '航空器';

  @override
  String get infoBarsTierFlagship => '旗舰';

  @override
  String get infoBarsTierHigh => '高端';

  @override
  String get infoBarsTierMid => '中端';

  @override
  String get infoBarsTierLow => '入门';

  @override
  String infoBarsProfileToast(String model, String tier, int fps, int pollMs) {
    return '$model · $tier\n$fps fps · 轮询 ${pollMs}ms 已应用优化';
  }

  @override
  String get navBannerNext => '下一步';

  @override
  String navBannerWalkTo(String station) {
    return '步行至 $station';
  }

  @override
  String navBannerBoardAt(String station, String line) {
    return '在 $station 乘坐 $line';
  }

  @override
  String navBannerWalkDetail(int min) {
    return '步行 $min 分钟';
  }

  @override
  String navBannerTransitDetail(String station, int min) {
    return '$station 方向 · $min 分钟';
  }

  @override
  String get readyPageTitle => '准备就绪';

  @override
  String get readyPageBody => '点击下方开始按钮,\n实时首尔即刻呈现。';

  @override
  String get welcomePageSubtitle => '用新视角看首尔';

  @override
  String get pathfindingPageTitle => '今天想要怎样的旅程?';

  @override
  String get pathfindingPageBody => 'AI 助手会根据你的心情为你定制路线。\n之后随时可以更改。';

  @override
  String riverBusStopLabel(String name) {
    return '$name 码头';
  }

  @override
  String get riverBusRouteEnded => '已停航';

  @override
  String riverBusNextTime(String time) {
    return '下一班 $time';
  }

  @override
  String get riverBusMaintenance => '维护中';

  @override
  String get riverBusDeparture => '出发';

  @override
  String get riverBusArrival => '到达';

  @override
  String get qualityPreviewDemoLabel => 'DEMO · 地铁';

  @override
  String get qualityPresetHigh => '高品质';

  @override
  String get qualityPresetMedium => '流畅';

  @override
  String get qualityPresetLow => '省电';

  @override
  String get qualityPresetHighDetail => '60 fps · 特效开启';

  @override
  String get qualityPresetMediumDetail => '30 fps · 部分特效';

  @override
  String get qualityPresetLowDetail => '10 fps · 特效关闭';
}
