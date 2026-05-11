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
}
