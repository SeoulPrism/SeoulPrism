import 'package:flutter/material.dart';

import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';

/// Seoul Vista 운영팀 전용 — 멀티플레이 일일 지표 + 어뷰즈 신호 + 신고 처리.
/// 진입점: MultiplayerSettingsView 의 admin email 한정 카드.
class AdminMonitorView extends StatefulWidget {
  const AdminMonitorView({super.key});

  @override
  State<AdminMonitorView> createState() => _AdminMonitorViewState();
}

class _AdminMonitorViewState extends State<AdminMonitorView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  Map<String, int>? _metrics;
  List<Map<String, dynamic>> _abuse = [];
  List<Map<String, dynamic>> _reports = [];
  String _reportFilter = 'pending';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = MultiplayerService.instance;
      final results = await Future.wait([
        svc.adminFetchMetrics(),
        svc.adminFetchAbuseSignals(),
        svc.adminFetchReports(status: _reportFilter),
      ]);
      if (!mounted) return;
      setState(() {
        _metrics = results[0] as Map<String, int>;
        _abuse = results[1] as List<Map<String, dynamic>>;
        _reports = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _setReportStatus(String id, String status) async {
    try {
      await MultiplayerService.instance.adminUpdateReportStatus(id, status);
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar('실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(
        title: '운영 모니터',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _refresh,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: '지표'),
              Tab(text: '어뷰즈'),
              Tab(text: '신고'),
            ],
          ),
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: cs.errorContainer,
              child: Text(_error!,
                  style: TextStyle(color: cs.onErrorContainer)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tab,
                    children: [
                      _metricsTab(cs),
                      _abuseTab(cs),
                      _reportsTab(cs),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metricsTab(ColorScheme cs) {
    final m = _metrics ?? const {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricCard(
          icon: Icons.people_alt_rounded,
          label: '전체 프로필',
          value: m['total_profiles']?.toString() ?? '-',
          tone: cs.primaryContainer,
        ),
        const SizedBox(height: 10),
        _MetricCard(
          icon: Icons.meeting_room_rounded,
          label: '활성 친구방',
          value: m['active_rooms']?.toString() ?? '-',
          tone: cs.secondaryContainer,
        ),
        const SizedBox(height: 10),
        _MetricCard(
          icon: Icons.celebration_rounded,
          label: '오늘 만남',
          value: m['meetups_today']?.toString() ?? '-',
          tone: cs.tertiaryContainer,
        ),
        const SizedBox(height: 10),
        _MetricCard(
          icon: Icons.block_rounded,
          label: '오늘 차단',
          value: m['blocks_today']?.toString() ?? '-',
          tone: cs.errorContainer,
        ),
        const SizedBox(height: 10),
        _MetricCard(
          icon: Icons.flag_rounded,
          label: '오늘 신고',
          value: m['reports_today']?.toString() ?? '-',
          tone: cs.errorContainer,
        ),
      ],
    );
  }

  Widget _abuseTab(ColorScheme cs) {
    if (_abuse.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('의심 신호 없음 (24시간 내 3건 이상 차단당한 사용자 X)',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _abuse.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final r = _abuse[i];
        return AdaptiveSurfaceCard(
          borderRadius: 14,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: cs.error),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (r['nickname'] as String?) ??
                          (r['user_id'] as String).substring(0, 8),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '24h 내 ${r['recent_block_count']}명에게 차단됨',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _reportsTab(ColorScheme cs) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: AdaptiveSegmented<String>(
            selected: _reportFilter,
            onSelected: (v) {
              setState(() => _reportFilter = v);
              _refresh();
            },
            segments: const [
              AdaptiveSegment(value: 'pending', label: '대기'),
              AdaptiveSegment(value: 'reviewed', label: '검토'),
              AdaptiveSegment(value: 'actioned', label: '조치'),
              AdaptiveSegment(value: 'dismissed', label: '기각'),
            ],
          ),
        ),
        Expanded(
          child: _reports.isEmpty
              ? Center(
                  child: Text('표시할 신고가 없어요',
                      style: TextStyle(color: cs.onSurfaceVariant)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReportCard(
                    data: _reports[i],
                    onChangeStatus: _setReportStatus,
                    cs: cs,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AdaptiveSurfaceCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: tone,
            ),
            child: Icon(icon, color: cs.onSurface),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14, color: cs.onSurfaceVariant)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function(String id, String status) onChangeStatus;
  final ColorScheme cs;
  const _ReportCard(
      {required this.data, required this.onChangeStatus, required this.cs});

  @override
  Widget build(BuildContext context) {
    final id = data['id'] as String;
    final type = data['target_type'] as String;
    final reporter = (data['reporter_nickname'] as String?) ?? '?';
    final target = (data['target_nickname'] as String?) ??
        ((data['target_user_id'] as String?)?.substring(0, 8) ?? '-');
    final preview = data['target_message_body'] as String?;
    final reason = data['reason'] as String;
    final status = data['status'] as String;
    final createdAt = DateTime.parse(data['created_at'] as String);

    return AdaptiveSurfaceCard(
      borderRadius: 14,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                type == 'message'
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.person_outline_rounded,
                size: 18,
                color: cs.error,
              ),
              const SizedBox(width: 6),
              Text(
                type == 'message' ? '메시지 신고' : '사용자 신고',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.error),
              ),
              const Spacer(),
              Text(_relTime(createdAt),
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$reporter → $target',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
          if (preview != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
            ),
          ],
          const SizedBox(height: 8),
          Text(reason,
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface,
                  height: 1.4)),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusBadge(status: status, cs: cs),
              const Spacer(),
              if (status != 'reviewed')
                TextButton(
                  onPressed: () => onChangeStatus(id, 'reviewed'),
                  child: const Text('검토'),
                ),
              if (status != 'actioned')
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: cs.error),
                  onPressed: () => onChangeStatus(id, 'actioned'),
                  child: const Text('조치'),
                ),
              if (status != 'dismissed')
                TextButton(
                  onPressed: () => onChangeStatus(id, 'dismissed'),
                  child: const Text('기각'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _relTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    return '${d.inDays}일 전';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final ColorScheme cs;
  const _StatusBadge({required this.status, required this.cs});
  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      'pending' => ('대기', cs.errorContainer, cs.onErrorContainer),
      'reviewed' => ('검토됨', cs.secondaryContainer, cs.onSecondaryContainer),
      'actioned' => ('조치됨', cs.tertiaryContainer, cs.onTertiaryContainer),
      'dismissed' => ('기각', cs.surfaceContainerHighest, cs.onSurfaceVariant),
      _ => (status, cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
