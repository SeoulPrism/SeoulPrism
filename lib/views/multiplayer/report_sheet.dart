import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/multiplayer_models.dart';
import '../../services/multiplayer_service.dart';
import '../../widgets/adaptive/adaptive.dart';
import '../../widgets/app_snackbar.dart';

/// 사용자 또는 메시지 신고 시트.
class ReportSheet extends StatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String? targetLabel; // 닉네임 또는 메시지 미리보기

  const ReportSheet._({
    required this.targetType,
    required this.targetId,
    this.targetLabel,
  });

  static Future<void> showForUser(BuildContext context, String userId,
      {String? nickname}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportSheet._(
        targetType: ReportTargetType.user,
        targetId: userId,
        targetLabel: nickname,
      ),
    );
  }

  static Future<void> showForMessage(BuildContext context, String messageId,
      {String? preview}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReportSheet._(
        targetType: ReportTargetType.message,
        targetId: messageId,
        targetLabel: preview,
      ),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  String? _selected;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  // ARB key 로 lookup 해야 해서 const 가 아니라 build 시점에 생성.
  List<String> _reasons(BuildContext ctx) {
    final l = AppL10n.of(ctx);
    return [
      l.reportReasonSpam,
      l.reportReasonHate,
      l.reportReasonSexual,
      l.reportReasonHarass,
      l.reportReasonFakeLocation,
      l.reportReasonMinorAbuse,
      l.reportReasonOther,
    ];
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selected == null) {
      setState(() => _error = AppL10n.of(context).reportSelectReason);
      return;
    }
    final reason = _reasonCtrl.text.trim().isEmpty
        ? _selected!
        : '$_selected\n${_reasonCtrl.text.trim()}';
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.targetType == ReportTargetType.user) {
        await MultiplayerService.instance
            .reportUser(widget.targetId, reason);
      } else {
        await MultiplayerService.instance
            .reportMessage(widget.targetId, reason);
      }
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnackBar(AppL10n.of(context).reportSubmitted);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppL10n.of(context);
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final title = widget.targetType == ReportTargetType.user
        ? l.reportTitleUser(widget.targetLabel ?? l.reportFallbackUser)
        : l.reportTitleMessage;
    final reasons = _reasons(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, inset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(l.reportNote,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            const SizedBox(height: 16),

            if (widget.targetLabel != null &&
                widget.targetType == ReportTargetType.message)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(widget.targetLabel!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurfaceVariant)),
              ),

            ...reasons.map((r) => _RadioRow(
                  label: r,
                  selected: _selected == r,
                  onTap: () => setState(() => _selected = r),
                )),

            const SizedBox(height: 12),
            AdaptiveTextField(
              controller: _reasonCtrl,
              placeholder: l.reportExtraPlaceholder,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
            ],

            const SizedBox(height: 20),
            AdaptiveGlassButton(
              label: _saving ? l.reportSubmitting : l.reportSubmit,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioRow(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurface,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
