import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import 'login_required_gate.dart';

const _kCommunityGuidelinesUrl =
    'https://seoulprism.github.io/SeoulPrism_Docs/community-guidelines.html';

/// Seoul Live 첫 진입 시 1회 노출. 위치정보보호법(LBS) + PIPA 컴플라이언스.
class MultiplayerConsentView extends StatefulWidget {
  final VoidCallback onConsented;
  const MultiplayerConsentView({super.key, required this.onConsented});

  @override
  State<MultiplayerConsentView> createState() => _MultiplayerConsentViewState();
}

class _MultiplayerConsentViewState extends State<MultiplayerConsentView> {
  bool _agreeProfile = false;
  bool _agreeLocation = false;
  bool _agreeLbsTerms = false;
  bool _agreeCommunityGuidelines = false;
  bool _busy = false;
  String? _error;

  bool get _allRequired =>
      _agreeProfile &&
      _agreeLocation &&
      _agreeLbsTerms &&
      _agreeCommunityGuidelines;

  Future<void> _proceed() async {
    if (!_allRequired) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _busy = false;
        _error = AppL10n.of(context).mpConsentLocationDenied;
      });
      return;
    }

    await MultiplayerService.setConsent(true);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onConsented();
  }

  @override
  Widget build(BuildContext context) {
    return LoginRequiredGate(builder: _buildConsent);
  }

  Widget _buildConsent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AdaptiveAppBar(title: l.mpConsentTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(l.mpConsentHeading,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 6),
            Text(
              l.mpConsentBody,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 20),

            AdaptiveSectionCard(
              children: [
                _ConsentRow(
                  title: l.mpConsentItem1Title,
                  detail: l.mpConsentItem1Detail,
                  value: _agreeProfile,
                  onChanged: (v) => setState(() => _agreeProfile = v),
                ),
                const _Divider(),
                _ConsentRow(
                  title: l.mpConsentItem2Title,
                  detail: l.mpConsentItem2Detail,
                  value: _agreeLocation,
                  onChanged: (v) => setState(() => _agreeLocation = v),
                ),
                const _Divider(),
                _ConsentRow(
                  title: l.mpConsentItem3Title,
                  detail: l.mpConsentItem3Detail,
                  value: _agreeLbsTerms,
                  onChanged: (v) => setState(() => _agreeLbsTerms = v),
                  linkText: l.mpConsentItem3Link,
                  onLinkTap: () => _showFullTerms(context),
                ),
                const _Divider(),
                _ConsentRow(
                  title: l.mpConsentItem4Title,
                  detail: l.mpConsentItem4Detail,
                  value: _agreeCommunityGuidelines,
                  onChanged: (v) =>
                      setState(() => _agreeCommunityGuidelines = v),
                  linkText: l.mpConsentItem4Link,
                  onLinkTap: () => launchUrl(
                    Uri.parse(_kCommunityGuidelinesUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.mpConsentDeclineNote,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.battery_saver_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.mpConsentBackgroundNote,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
            ],

            const SizedBox(height: 24),
            AdaptiveGlassButton(
              label: _busy ? l.mpConsentSubmitBusy : l.mpConsentSubmit,
              onPressed: (_allRequired && !_busy) ? _proceed : null,
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.mpConsentLaterButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullTerms(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        expand: false,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          child: const Text(_lbsTermsBody, style: TextStyle(height: 1.6)),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? linkText;
  final VoidCallback? onLinkTap;

  const _ConsentRow({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.linkText,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AdaptiveCheckbox(value: value, onChanged: onChanged),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Text(detail,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          height: 1.5)),
                  if (linkText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onLinkTap,
                        child: Text(linkText!),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(
          height: 0.5, thickness: 0.5, color: cs.outlineVariant.withValues(alpha: 0.5)),
    );
  }
}

const _lbsTermsBody = '''
위치기반서비스 이용약관 (Seoul Vista — Seoul Live)

제1조 (목적)
이 약관은 Seoul Vista 가 제공하는 Seoul Live(이하 "서비스")의 위치기반서비스 이용에 관한 사항을 정합니다.

제2조 (이용약관의 효력 및 변경)
1. 이 약관은 회사가 서비스 화면에 게시하거나 기타 방법으로 공지함으로써 효력이 발생합니다.
2. 약관 변경 시 적용일자 및 사유를 명시하여 적용일자 7일 전부터 공지합니다.

제3조 (서비스 내용)
회사는 이용자가 친구방에 입장한 동안 다른 멤버에게 본인의 위치정보(GPS 좌표, 이동 방향)를 전송·공유하는 서비스를 제공합니다.

제4조 (개인위치정보의 이용 또는 제공)
1. 회사는 개인위치정보를 이용·제공할 경우 미리 본인의 동의를 받습니다.
2. 회사는 본인의 동의가 있는 경우, 본인이 지정한 친구방 멤버에게 위치정보를 제공합니다.
3. 회사는 위치정보를 영구 저장하지 않으며, Realtime 채널을 통한 휘발 전송으로 처리합니다.

제5조 (보유 기간)
회사는 회원의 개인위치정보를 영구 저장하지 않으며, 친구방 입장 중에만 다른 멤버에게 실시간 전송됩니다. 방 퇴장 또는 앱 종료 즉시 송신이 중단됩니다.

제6조 (이용자의 권리)
1. 이용자는 언제든지 동의의 일부 또는 전부를 철회할 수 있습니다.
2. 이용자는 언제든지 ghost(비공개) 모드로 전환하여 송신을 중지할 수 있습니다.
3. 동의 철회는 앱 내 설정에서 가능하며, 회사는 10일 이내 처리합니다.

제7조 (법정대리인의 권리)
회사는 만 14세 미만의 가입을 차단합니다.

제8조 (위치정보관리책임자)
- 책임자: Seoul Vista 운영팀
- 연락처: rush94434@gmail.com

부칙
본 약관은 2026년 5월 10일부터 시행됩니다.
''';
