import 'package:flutter/material.dart';

import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';

/// B8 활동 분석 — 최근 7일 차트 + 최근 활동 리스트.
class ActivityDashboardView extends StatefulWidget {
  const ActivityDashboardView({super.key});

  @override
  State<ActivityDashboardView> createState() => _ActivityDashboardViewState();
}

class _ActivityDashboardViewState extends State<ActivityDashboardView> {
  bool _loading = true;
  List<({DateTime day, String kind, int cnt})> _summary = [];
  List<({DateTime at, String kind, Map<String, dynamic> payload})> _recent = [];
  List<({String userId, String nickname, String pinColor, String pinEmoji,
      int totalPoints, int meetupCount, int friendCount,
      int currentStreakDays, List<String> badges})> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = MultiplayerService.instance;
    final s = await svc.loadActivitySummary(days: 7);
    final r = await svc.loadRecentActivities(limit: 30);
    final lb = await svc.loadFriendLeaderboard();
    if (!mounted) return;
    setState(() {
      _summary = s;
      _recent = r;
      _leaderboard = lb;
      _loading = false;
    });
  }

  static const _kindLabel = {
    'meetup': '🎉 만남',
    'friend_added': '🤝 친구',
    'room_joined': '🚪 방 입장',
    'place_shared': '📍 장소 공유',
    'destination_set': '🎯 목적지',
  };

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '방금';
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    return '${d.inDays}일 전';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(title: '활동 분석'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    _WeeklyChart(summary: _summary),
                    if (_leaderboard.length > 1) ...[
                      const SizedBox(height: 16),
                      _SectionLabel(text: '친구 랭킹'),
                      _Leaderboard(
                        items: _leaderboard,
                        myId: MultiplayerService.instance.myId,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _SectionLabel(text: '최근 활동'),
                    if (_recent.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('아직 기록된 활동이 없어요',
                              style:
                                  TextStyle(color: cs.onSurfaceVariant)),
                        ),
                      )
                    else
                      AdaptiveSectionCard(
                        children: [
                          for (var i = 0; i < _recent.length; i++) ...[
                            if (i > 0)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(
                                    height: 0.5,
                                    thickness: 0.5,
                                    color: cs.outlineVariant
                                        .withValues(alpha: 0.4)),
                              ),
                            ListTile(
                              dense: true,
                              title: Text(
                                  _kindLabel[_recent[i].kind] ?? _recent[i].kind,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              subtitle: _payloadHint(_recent[i].payload),
                              trailing: Text(_ago(_recent[i].at),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant)),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget? _payloadHint(Map<String, dynamic> p) {
    if (p.containsKey('name')) {
      return Text(p['name'].toString(),
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    if (p.containsKey('code')) {
      return Text('코드 ${p['code']}',
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant));
    }
    return null;
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<({DateTime day, String kind, int cnt})> summary;
  const _WeeklyChart({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 일별 총 카운트로 압축 (kind 무관 — 단순화).
    final byDay = <DateTime, int>{};
    for (final r in summary) {
      final d = DateTime(r.day.year, r.day.month, r.day.day);
      byDay[d] = (byDay[d] ?? 0) + r.cnt;
    }

    // 오늘부터 -6일까지 순서로.
    final today = DateTime.now();
    final days = List<DateTime>.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });

    final maxCnt = byDay.values.fold<int>(0, (a, b) => a > b ? a : b);
    final scale = maxCnt == 0 ? 1.0 : 1.0 / maxCnt;

    return AdaptiveSectionCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              const Text('이번 주 활동',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('총 ${byDay.values.fold<int>(0, (a, b) => a + b)}건',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((d) {
                final cnt = byDay[d] ?? 0;
                final h = 80 * (cnt * scale).clamp(0.05, 1.0);
                final isToday = d.day == today.day &&
                    d.month == today.month &&
                    d.year == today.year;
                final wd = ['월', '화', '수', '목', '금', '토', '일'][d.weekday - 1];
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cnt > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('$cnt',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface)),
                        ),
                      Container(
                        width: 18,
                        height: h,
                        decoration: BoxDecoration(
                          color: cnt == 0
                              ? cs.surfaceContainerHighest
                              : (isToday ? cs.primary : cs.secondary),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(wd,
                          style: TextStyle(
                              fontSize: 10,
                              color: isToday ? cs.primary : cs.onSurfaceVariant,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _Leaderboard extends StatelessWidget {
  final List<({String userId, String nickname, String pinColor, String pinEmoji,
      int totalPoints, int meetupCount, int friendCount,
      int currentStreakDays, List<String> badges})> items;
  final String? myId;
  const _Leaderboard({required this.items, required this.myId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AdaptiveSectionCard(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                  height: 0.5,
                  thickness: 0.5,
                  color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
          Builder(builder: (_) {
            final isMe = items[i].userId == myId;
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(_rankPrefix(i),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: i < 3 ? cs.primary : cs.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(int.parse(
                          'FF${items[i].pinColor.substring(1)}',
                          radix: 16)),
                    ),
                    alignment: Alignment.center,
                    child: Text(items[i].pinEmoji,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${items[i].nickname}${isMe ? ' (나)' : ''}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isMe ? cs.primary : cs.onSurface)),
                        const SizedBox(height: 2),
                        Text(
                            '만남 ${items[i].meetupCount} · 친구 ${items[i].friendCount} · 연속 ${items[i].currentStreakDays}일',
                            style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text('${items[i].totalPoints}p',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isMe ? cs.primary : cs.onSurface)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  String _rankPrefix(int idx) {
    if (idx == 0) return '🥇';
    if (idx == 1) return '🥈';
    if (idx == 2) return '🥉';
    return '${idx + 1}';
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
