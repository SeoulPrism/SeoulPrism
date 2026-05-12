import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/gen/app_localizations.dart';
import '../models/sns_content_models.dart';
import '../services/gemini_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/adaptive/adaptive.dart';
import '../widgets/subway_overlay.dart';
import 'sns_analysis_view.dart';
import '../core/map_interface.dart';

class SnsUploadView extends StatefulWidget {
  final VoidCallback onClose;
  final IMapController? mapController;
  final SubwayOverlayController? subwayController;
  final void Function(List<DayPlan> plans)? onPlansGenerated;

  const SnsUploadView({
    super.key,
    required this.onClose,
    this.mapController,
    this.subwayController,
    this.onPlansGenerated,
  });

  @override
  State<SnsUploadView> createState() => _SnsUploadViewState();
}

class _SnsUploadViewState extends State<SnsUploadView> {
  final _textController = TextEditingController();
  final _urlController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<String> _imagePaths = [];
  bool _loading = false;

  /// 설정 패널과 동일한 밝은 맵 감지
  bool get _isBrightMap {
    final preset = SettingsService.instance.lightPreset;
    if (preset == 'day' || preset == 'dawn') return true;
    if (preset == 'auto') {
      final env = widget.subwayController?.environment;
      if (env != null) {
        return env.lightPreset == 'day' || env.lightPreset == 'dawn';
      }
    }
    return false;
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(limit: 5);
    if (images.isNotEmpty) {
      setState(() {
        _imagePaths.addAll(images.map((x) => x.path));
        if (_imagePaths.length > 5) {
          _imagePaths.removeRange(0, _imagePaths.length - 5);
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        if (_imagePaths.length >= 5) _imagePaths.removeAt(0);
        _imagePaths.add(photo.path);
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  bool get _hasContent =>
      _imagePaths.isNotEmpty ||
      _textController.text.trim().isNotEmpty ||
      _urlController.text.trim().isNotEmpty;

  Future<void> _analyze() async {
    if (!_hasContent || _loading) return;

    setState(() => _loading = true);

    try {
      final content = SnsContent(
        imagePaths: _imagePaths,
        text: _textController.text.trim(),
        url: _urlController.text.trim(),
      );

      final result = await GeminiService.instance.analyzeContent(content);
      final geocoded = await GeminiService.instance.geocodeAll(result.places);

      if (!mounted) return;

      final analysisResult = SnsAnalysisResult(
        places: geocoded,
        overallMood: result.overallMood,
        keywords: result.keywords,
      );

      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SnsAnalysisView(
            result: analysisResult,
            mapController: widget.mapController,
            onPlansGenerated: widget.onPlansGenerated,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppL10n.of(context).snsAnalyzeError(e.toString())),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bright = Theme.of(context).brightness == Brightness.light;
    final textPrimary = bright ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.95);
    final textSecondary = bright ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.50);

    Widget content = Column(
      children: [
        // 드래그 핸들
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: bright
                    ? Colors.black.withValues(alpha: 0.20)
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 타이틀
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppL10n.of(context).snsTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppL10n.of(context).snsSubtitle,
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 컨텐츠
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 80),
            children: [
              // 이미지
              _sectionLabel(AppL10n.of(context).snsSectionPhotos, bright, cs),
              const SizedBox(height: 8),
              _buildImageSection(bright, cs),
              const SizedBox(height: 20),
              // 텍스트
              _sectionLabel(AppL10n.of(context).snsSectionDescription, bright, cs),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _textController,
                hint: AppL10n.of(context).snsTextHint,
                maxLines: 3,
                bright: bright,
                cs: cs,
              ),
              const SizedBox(height: 20),
              // URL
              _sectionLabel(AppL10n.of(context).snsSectionLink, bright, cs),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _urlController,
                hint: AppL10n.of(context).snsUrlHint,
                maxLines: 1,
                bright: bright,
                cs: cs,
              ),
              const SizedBox(height: 24),
              // 버튼
              SizedBox(
                height: 48,
                child: _loading
                    ? Center(
                        child: Platform.isIOS
                            ? const CupertinoActivityIndicator()
                            : const CircularProgressIndicator(),
                      )
                    : AdaptiveGlassButton(
                        label: AppL10n.of(context).snsAnalyzeButton,
                        onPressed: _hasContent ? _analyze : null,
                        minHeight: 48,
                      ),
              ),
            ],
          ),
        ),
      ],
    );

    // 패널 외관: 설정 패널과 동일한 스타일
    if (Platform.isAndroid) {
      return Material(
        elevation: 6,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        color: cs.surfaceContainerHigh,
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bright
                  ? [
                      Colors.white.withValues(alpha: 0.70),
                      Colors.white.withValues(alpha: 0.75),
                      Colors.white.withValues(alpha: 0.85),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.black.withValues(alpha: 0.50),
                      Colors.black.withValues(alpha: 0.65),
                    ],
            ),
            border: Border(
              top: BorderSide(
                color: bright
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.white24,
                width: 0.5,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool light, ColorScheme cs) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: light ? Colors.black.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.50),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildImageSection(bool bright, ColorScheme cs) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 추가 버튼들
          _imageAddButton(Icons.photo_library_outlined,
              AppL10n.of(context).snsImageGallery, _pickImages, bright, cs),
          const SizedBox(width: 8),
          _imageAddButton(Icons.camera_alt_outlined,
              AppL10n.of(context).snsImageCamera, _takePhoto, bright, cs),
          const SizedBox(width: 8),
          // 선택된 이미지들
          ..._imagePaths.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildImageThumbnail(entry.key, entry.value, bright, cs),
            );
          }),
        ],
      ),
    );
  }

  Widget _imageAddButton(IconData icon, String label, VoidCallback onTap, bool bright, ColorScheme cs) {
    return Material(
      color: bright
          ? Colors.white.withValues(alpha: 0.40)
          : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: cs.primary.withValues(alpha: 0.18),
        highlightColor: cs.primary.withValues(alpha: 0.08),
        child: Container(
          width: 80,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: bright ? Colors.black.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: bright ? Colors.black54 : Colors.white60),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 11,
                color: bright ? Colors.black54 : Colors.white60,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(int index, String path, bool bright, ColorScheme cs) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: 80,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.6),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required bool bright,
    required ColorScheme cs,
  }) {
    if (bright) {
      return TextField(
        controller: controller,
        maxLines: maxLines,
        cursorColor: cs.primary,
        style: TextStyle(color: cs.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
          filled: true,
          fillColor: cs.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}
