import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/gen/app_localizations.dart';

/// QR 스캐너 — 8자리 친구 코드 또는 seoulvista://friend/<code> 형식 인식.
/// 인식 즉시 코드 문자열 반환하며 pop. 권한 거부/오류는 호출 측에서 처리.
class QrScanView extends StatefulWidget {
  const QrScanView({super.key});

  static Future<String?> push(BuildContext context) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrScanView()),
    );
  }

  @override
  State<QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<QrScanView> {
  final _controller = MobileScannerController(
    formats: [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _handled = false;

  static final _codeRegex = RegExp(r'^[A-Z0-9]{8}$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      String? code;
      // seoulvista://friend/<CODE> 형식 우선.
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.scheme == 'seoulvista' && uri.host == 'friend') {
        final seg = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.first.toUpperCase()
            : null;
        if (seg != null && _codeRegex.hasMatch(seg)) code = seg;
      }
      // 8자리 plain 코드도 허용.
      code ??= _codeRegex.hasMatch(raw.toUpperCase()) ? raw.toUpperCase() : null;
      if (code != null) {
        _handled = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(AppL10n.of(context).qrScanTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (ctx, err) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppL10n.of(ctx).qrScanCameraError(
                      err.errorDetails?.message ?? err.errorCode.name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
          // 가이드 프레임 — 화면 가운데 정사각형 + 각 모서리 강조.
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  AppL10n.of(context).qrScanHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
