import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';
import 'qr_scan_view.dart';

/// 내 친구 코드 보기 + 공유 + 코드로 친구 추가.
class FriendCodeShareSheet extends StatefulWidget {
  final String? prefillCode;
  const FriendCodeShareSheet({super.key, this.prefillCode});

  static Future<void> show(BuildContext context, {String? prefillCode}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FriendCodeShareSheet(prefillCode: prefillCode),
    );
  }

  @override
  State<FriendCodeShareSheet> createState() => _FriendCodeShareSheetState();
}

class _FriendCodeShareSheetState extends State<FriendCodeShareSheet> {
  final _codeCtrl = TextEditingController();

  /// 입력값을 영숫자 대문자 + 8글자로 정규화. 사용자가 소문자/공백/하이픈 등을
  /// 입력해도 친구 코드 포맷에 맞춰 보정한다.
  void _onCodeChanged(String value) {
    final cleaned = value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final clamped =
        cleaned.length > 8 ? cleaned.substring(0, 8) : cleaned;
    if (clamped == _codeCtrl.text) return;
    _codeCtrl.value = TextEditingValue(
      text: clamped,
      selection: TextSelection.collapsed(offset: clamped.length),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefillCode != null) {
      _codeCtrl.text = widget.prefillCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addByCode();
      });
    }
  }
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _addByCode() async {
    final code = _codeCtrl.text.toUpperCase().trim();
    if (code.length != 8) {
      setState(() => _error = '8자리 코드를 입력해주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      final p = await MultiplayerService.instance.searchByFriendCode(code);
      if (p == null) {
        setState(() {
          _busy = false;
          _error = '코드와 일치하는 사용자를 찾을 수 없어요.';
        });
        return;
      }
      await MultiplayerService.instance.sendFriendRequest(p.userId);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _info = '${p.nickname} 님에게 친구 신청을 보냈어요.';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _scanQr() async {
    final scanned = await QrScanView.push(context);
    if (scanned == null || !mounted) return;
    _codeCtrl.text = scanned;
    await _addByCode();
  }

  Future<void> _shareCode(String code, String nickname) async {
    final text =
        '$nickname 님이 Seoul Live 친구 코드를 보냈어요!\n\n코드: $code\n'
        '바로 추가: com.seoul.prism://friend/$code';
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(ShareParams(
        text: text,
        subject: 'Seoul Live 친구 추가',
        sharePositionOrigin:
            box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      ));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) showAppSnackBar('공유 텍스트를 복사했어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final me = MultiplayerService.instance.myProfile;
    final myCode = me?.friendCode ?? '--------';
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, inset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('친구 코드',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('내 코드를 공유하거나, 친구 코드로 추가하세요.',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),

            // 내 코드.
            AdaptiveSurfaceCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('내 친구 코드',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SelectableText(
                        myCode,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                      const Spacer(),
                      AdaptiveGlassIconButton(
                        icon: Icons.copy_rounded,
                        onPressed: () async {
                          await Clipboard.setData(
                              ClipboardData(text: myCode));
                          if (!mounted) return;
                          showAppSnackBar('코드 복사됨');
                        },
                      ),
                    ],
                  ),
                  if (me?.friendCode != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: QrImageView(
                          data: 'seoulvista://friend/$myCode',
                          size: 168,
                          backgroundColor: Colors.white,
                          version: QrVersions.auto,
                          gapless: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '친구가 카메라로 스캔하면 바로 추가돼요',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AdaptiveGlassButton(
                    label: '공유하기',
                    onPressed: me == null
                        ? null
                        : () => _shareCode(myCode, me.nickname),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 친구 코드 입력.
            Text('친구 코드로 친구 추가',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('받은 8글자 코드를 입력하거나 QR 을 스캔하세요',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 12),
            AdaptiveTextField(
              controller: _codeCtrl,
              placeholder: '예: AB12CD34',
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              onChanged: _onCodeChanged,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AdaptiveGlassButton(
                    label: _busy ? '...' : '친구 신청 보내기',
                    onPressed: _busy ? null : _addByCode,
                  ),
                ),
                const SizedBox(width: 10),
                AdaptiveGlassIconButton(
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: _busy ? null : _scanQr,
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
            ],
            if (_info != null) ...[
              const SizedBox(height: 12),
              Text(_info!,
                  style: TextStyle(color: cs.primary, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
