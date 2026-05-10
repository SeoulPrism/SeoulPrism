import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/adaptive/adaptive.dart';
import '../auth_view.dart';

/// 멀티플레이는 정식 로그인 필수.
/// 익명(게스트) 세션이면 로그인 안내 화면을 대신 표시.
///
/// 이유:
/// - 익명 계정은 30일 미사용 시 자동 삭제 (privacy-policy 명시) → 친구 관계/방 소실 위험
/// - 친구 추가/차단 등은 안정적인 식별자 필요
/// - LBS법상 위치정보 동의 주체 명확화 필요
class LoginRequiredGate extends StatefulWidget {
  final WidgetBuilder builder;
  const LoginRequiredGate({super.key, required this.builder});

  @override
  State<LoginRequiredGate> createState() => _LoginRequiredGateState();
}

class _LoginRequiredGateState extends State<LoginRequiredGate> {
  late final _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
    if (mounted) setState(() {});
  });

  @override
  void initState() {
    super.initState();
    _sub; // ignite
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  bool get _isLoggedIn {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null && !user.isAnonymous;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) return widget.builder(context);
    return const _LoginRequiredView();
  }
}

class _LoginRequiredView extends StatelessWidget {
  const _LoginRequiredView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const AdaptiveAppBar(title: 'Seoul Live'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C5CFF), Color(0xFF5CC8FF)],
                  ),
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text('로그인이 필요해요',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(height: 10),
              Text(
                '멀티플레이는 정식 로그인 사용자만 이용할 수 있어요.\n'
                '게스트(익명) 계정은 30일 미사용 시 자동 삭제되어\n'
                '친구·방 정보가 사라질 수 있기 때문이에요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 28),
              AdaptiveGlassButton(
                label: '로그인하기',
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AuthView()));
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('나중에'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
