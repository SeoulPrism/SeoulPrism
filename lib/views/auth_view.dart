import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import '../widgets/adaptive/adaptive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'home_view.dart';

enum AuthMode { login, signUp }

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  AuthMode _mode = AuthMode.login;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;
  static bool _googleInitialized = false;

  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool get _isLogin => _mode == AuthMode.login;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    if (!isTablet) return _buildPhoneLayout(keyboardOpen);
    return _buildTabletLayout(keyboardOpen);
  }

  /// 폰: 기존 레이아웃 고정
  Widget _buildPhoneLayout(bool keyboardOpen) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      bottomNavigationBar: _buildTabBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('images/bgimg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                24, 0, 24,
                keyboardOpen
                    ? MediaQuery.of(context).viewInsets.bottom + 16
                    : MediaQuery.of(context).padding.bottom + 80,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: keyboardOpen
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _SeoulPrismLogo(),
                          const SizedBox(height: 24),
                          _buildAuthPanel(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 태블릿: 가운데 정렬 + 넓은 패널
  Widget _buildTabletLayout(bool keyboardOpen) {
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      bottomNavigationBar: _buildTabBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset('images/bgimg.png', fit: BoxFit.cover),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24, isLandscape ? 16 : 0, 24,
                  keyboardOpen
                      ? MediaQuery.of(context).viewInsets.bottom + 16
                      : MediaQuery.of(context).padding.bottom + 80,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isLandscape) ...[
                      const _SeoulPrismLogo(size: 200),
                      const SizedBox(height: 24),
                    ],
                    _buildAuthPanel(isTablet: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return AdaptiveTabBar(
      items: const [
        AdaptiveTabItem(label: '회원가입', icon: Icons.person_add_rounded),
        AdaptiveTabItem(label: '로그인', icon: Icons.login_rounded),
      ],
      currentIndex: _isLogin ? 1 : 0,
      onTap: (index) {
        setState(() {
          _mode = index == 0 ? AuthMode.signUp : AuthMode.login;
        });
      },
    );
  }

  Widget _buildAuthPanel({bool isTablet = false}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: isTablet ? 520 : 400),
      child: AdaptiveGlassContainer.rect(
        cornerRadius: 24,
        prominent: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: CustomPaint(
            painter: _GlassPanelPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _isLogin
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _buildLoginFields(),
                secondChild: _buildSignUpFields(),
                sizeCurve: Curves.easeOutCubic,
              ),
              const SizedBox(height: 20),
              AdaptiveGlassButton(
                label: _loading
                    ? '처리 중...'
                    : (_isLogin ? '로그인' : '회원가입'),
                onPressed: _loading ? null : _handleAuth,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 450),
                  opacity: _isLogin ? 1.0 : 0.0,
                  child: _isLogin
                      ? Column(
                          children: [
                            const SizedBox(height: 24),
                            _buildSnsDivider(),
                            const SizedBox(height: 20),
                            _buildSocialButtons(),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFields() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _GlassInputField(
          label: '이메일',
          hintText: '이메일을 입력해주세요',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _GlassInputField(
          label: '비밀번호',
          hintText: '비밀번호를 입력해주세요',
          controller: _passwordController,
          obscureText: _hidePassword,
          suffixIcon: _visibilityToggle(_hidePassword, () {
            setState(() => _hidePassword = !_hidePassword);
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _showFindSheet(_FindSheetMode.id),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.55),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('아이디 찾기'),
            ),
            Text(
              '|',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.30),
                fontSize: 12,
              ),
            ),
            TextButton(
              onPressed: () => _showFindSheet(_FindSheetMode.password),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.55),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('비밀번호 찾기'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignUpFields() {
    return Column(
      key: const ValueKey('signup'),
      children: [
        _GlassInputField(
          label: '아이디',
          hintText: '아이디를 입력해주세요',
          controller: _idController,
        ),
        const SizedBox(height: 16),
        _GlassInputField(
          label: '이메일',
          hintText: '이메일을 입력해주세요',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _GlassInputField(
          label: '비밀번호',
          hintText: '비밀번호를 입력해주세요',
          controller: _passwordController,
          obscureText: _hidePassword,
          suffixIcon: _visibilityToggle(_hidePassword, () {
            setState(() => _hidePassword = !_hidePassword);
          }),
        ),
        const SizedBox(height: 16),
        _GlassInputField(
          label: '비밀번호 확인',
          hintText: '비밀번호를 다시 입력해주세요',
          controller: _confirmPasswordController,
          obscureText: _hideConfirmPassword,
          suffixIcon: _visibilityToggle(_hideConfirmPassword, () {
            setState(() => _hideConfirmPassword = !_hideConfirmPassword);
          }),
        ),
      ],
    );
  }

  Widget _visibilityToggle(bool hidden, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        hidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: Colors.white.withValues(alpha: 0.60),
        size: 20,
      ),
    );
  }

  Widget _buildSnsDivider() {
    final lineDecoration = BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.40),
        ],
      ),
    );
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, decoration: lineDecoration)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'SNS 계정으로 로그인',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.40),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Google
        AdaptiveGlassIconButton(
          icon: FontAwesomeIcons.google.data,
          onPressed: _loading ? null : _signInWithGoogle,
          tint: const Color(0xFF4285F4),
          iconSize: 20,
        ),
        const SizedBox(width: 16),
        // 게스트 (익명 로그인) — 카카오 자리 대체.
        AdaptiveGlassIconButton(
          icon: FontAwesomeIcons.userSecret.data,
          onPressed: _loading ? null : _signInAnonymously,
          tint: const Color(0xFF8E8E93),
          iconSize: 20,
        ),
        const SizedBox(width: 16),
        // Apple
        AdaptiveGlassIconButton(
          icon: FontAwesomeIcons.apple.data,
          onPressed: _loading ? null : _signInWithApple,
          iconSize: 22,
        ),
      ],
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      const iosClientId =
          '846573810111-bnlgpg0flbcg5ffdqce2o7g986dpm8dc.apps.googleusercontent.com';
      const webClientId =
          '846573810111-4mtaobbv1tq60e11bte5q6j6lsfgjk7s.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await googleSignIn.initialize(
          // Android: clientId 생략 (google-services.json 또는 Credential Manager에서 자동)
          clientId: Platform.isIOS ? iosClientId : null,
          serverClientId: webClientId,
        );
        _googleInitialized = true;
      }

      final googleUser = await googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        if (mounted) _showError('Google 인증에 실패했습니다');
        return;
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on AuthException catch (e) {
      if (mounted) _showError(_translateAuthError(e.message));
    } catch (e) {
      if (mounted) _showError('Google 로그인에 실패했습니다');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 게스트(익명) 로그인 — 사용자 입력 없이 user_id 발급.
  /// main.dart 가 앱 시작 시 자동 익명 로그인을 시도하므로, 이미 로그인 됐으면 바로 home 으로.
  /// 정식 로그인 시 linkIdentity 로 연결.
  Future<void> _signInAnonymously() async {
    setState(() => _loading = true);
    try {
      if (supabase.auth.currentUser == null) {
        await supabase.auth.signInAnonymously();
      }
      // signedIn 이벤트는 새 sign-in 시점만 발동. 이미 로그인 된 채 들어온 경우엔 직접 navigate.
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (_) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) _showError(_translateAuthError(e.message));
    } catch (e) {
      if (mounted) _showError('게스트 로그인에 실패했습니다');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _loading = true);
    try {
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        if (mounted) _showError('Apple 인증에 실패했습니다');
        return;
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (mounted) _showError('Apple 로그인이 취소되었습니다');
    } on AuthException catch (e) {
      if (mounted) _showError(_translateAuthError(e.message));
    } catch (e) {
      if (mounted) _showError('Apple 로그인에 실패했습니다');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _redirectUrl {
    if (kIsWeb) return Uri.base.origin;
    return 'com.seoul.prism://login-callback';
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('이메일과 비밀번호를 입력해주세요');
      return;
    }

    if (!_isLogin) {
      final username = _idController.text.trim();
      final confirm = _confirmPasswordController.text;
      if (username.isEmpty) {
        _showError('아이디를 입력해주세요');
        return;
      }
      if (password != confirm) {
        _showError('비밀번호가 일치하지 않습니다');
        return;
      }
      if (password.length < 6) {
        _showError('비밀번호는 6자 이상이어야 합니다');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        // 네비게이션은 main.dart의 onAuthStateChange 리스너가 처리
      } else {
        final username = _idController.text.trim();
        final response = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'username': username},
        );
        if (mounted) {
          if (response.session != null) {
            // 네비게이션은 main.dart의 onAuthStateChange 리스너가 처리
          } else {
            _showConfirmEmailDialog(email);
            setState(() => _mode = AuthMode.login);
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) _showError(_translateAuthError(e.message));
    } catch (e) {
      if (mounted) _showError('오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다';
    }
    if (message.contains('already registered')) {
      return '이미 가입된 이메일입니다';
    }
    if (message.contains('invalid email')) {
      return '올바른 이메일 형식을 입력해주세요';
    }
    if (message.contains('Email not confirmed') || message.contains('email_not_confirmed')) {
      return '이메일 인증이 완료되지 않았습니다. 메일함을 확인해주세요.';
    }
    return message;
  }

  void _showConfirmEmailDialog(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('이메일 인증 필요', style: TextStyle(color: Colors.white)),
        content: Text(
          '$email로 인증 메일을 보냈습니다.\n메일함을 확인하고 인증을 완료한 후 로그인해주세요.',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: Color(0xFF6E7BFF))),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF453A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFindSheet(_FindSheetMode mode) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _FindAccountPage(mode: mode),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ));
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }
}

// ─── Find Account Page ──────────────────────────────────────

enum _FindSheetMode { id, password }

class _FindAccountPage extends StatefulWidget {
  const _FindAccountPage({required this.mode});

  final _FindSheetMode mode;

  @override
  State<_FindAccountPage> createState() => _FindAccountPageState();
}

class _FindAccountPageState extends State<_FindAccountPage> {
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _idController.dispose();
    super.dispose();
  }

  bool get _isIdMode => widget.mode == _FindSheetMode.id;

  Future<void> _handleFind() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('이메일을 입력해주세요', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isIdMode) {
        final result = await supabase.rpc(
          'find_username_by_email',
          params: {'lookup_email': email},
        );
        if (!mounted) return;
        if (result == null || (result as String).isEmpty) {
          _showSnack('해당 이메일로 가입된 계정을 찾을 수 없습니다', isError: true);
        } else {
          _showResultDialog(result);
        }
      } else {
        await supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: 'com.seoul.prism://login-callback',
        );
        if (!mounted) return;
        _showSnack('비밀번호 재설정 링크를 이메일로 보냈습니다');
      }
    } catch (e) {
      if (mounted) {
        _showSnack(
          _isIdMode ? '아이디 찾기에 실패했습니다' : '이메일 전송에 실패했습니다',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showResultDialog(String username) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('아이디 찾기 결과', style: TextStyle(color: Colors.white)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            children: [
              const TextSpan(text: '회원님의 아이디는 '),
              TextSpan(
                text: username,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const TextSpan(text: ' 입니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFFF453A) : const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/bgimg.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenW = MediaQuery.of(context).size.width;
                final tabletPad = screenW >= 600 ? screenW * 0.15 : 24.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(tabletPad, 12, tabletPad, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 뒤로가기 버튼
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.arrow_back_ios_rounded,
                              color: Colors.white.withValues(alpha: 0.80),
                              size: 22,
                            ),
                          ),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.08),
                        // 글라스 패널
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.12),
                                      Colors.white.withValues(alpha: 0.05),
                                      Colors.white.withValues(alpha: 0.08),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 0.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      _isIdMode ? '아이디 찾기' : '비밀번호 찾기',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isIdMode
                                          ? '가입 시 사용한 이메일을 입력하면\n아이디를 알려드립니다.'
                                          : '이메일을 입력하면\n비밀번호 재설정 링크를 보내드립니다.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.white.withValues(alpha: 0.50),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    _GlassInputField(
                                      label: '이메일',
                                      hintText: '가입한 이메일을 입력해주세요',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 24),
                                    AdaptiveGlassButton(
                                      label: _loading
                                          ? '처리 중...'
                                          : (_isIdMode ? '아이디 찾기' : '재설정 링크 받기'),
                                      onPressed: _loading ? null : _handleFind,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glass Input Field ──────────────────────────────────────

class _GlassInputField extends StatelessWidget {
  const _GlassInputField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: CustomPaint(
              painter: _GlassInputPainter(),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                cursorColor: Colors.white,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w500,
                  ),
                  suffixIcon: suffixIcon,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Logo ────────────────────────────────────────────────────

// ─── 3D Glass Panel Painter ─────────────────────────────────

class _GlassPanelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // 1. 베이스 frosted glass 틴트
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withValues(alpha: 0.03),
    );

    // 2. 상단 스펙큘러 하이라이트
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: const Alignment(0, -0.3),
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.15, 0.4],
        ).createShader(rect),
    );

    // 3. 프레넬 테두리
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.03),
            Colors.white.withValues(alpha: 0.08),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(rect),
    );

    // 4. 상단 베벨
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 0.5),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.restore();

    // 5. 하단 베벨
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 0.5, size.width, 0.5),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );
    canvas.restore();

    // 6. 좌상단 스펙큘러 포인트
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.08),
      size.width * 0.3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.01),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(
          Rect.fromCircle(
            center: Offset(size.width * 0.2, size.height * 0.08),
            radius: size.width * 0.35,
          ),
        ),
    );
    canvas.restore();

    // 7. 외부 그림자 (떠있는 느낌)
    final shadowPath = Path()..addRRect(rrect);
    canvas.drawShadow(shadowPath, Colors.black, 12, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassInputPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final radius = size.height / 2;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 1. 베이스 틴트
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );

    // 2. 상단 하이라이트 (빛이 위에서)
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5)),
    );
    canvas.restore();

    // 3. 프레넬 테두리 (상단 밝고 하단 어두움)
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.08),
          ],
        ).createShader(rect),
    );

    // 4. 상단 1px 베벨 하이라이트
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawLine(
      Offset(radius, 0.5),
      Offset(size.width - radius, 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = 0.5,
    );
    canvas.restore();

    // 5. 하단 1px 베벨 그림자
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawLine(
      Offset(radius, size.height - 0.5),
      Offset(size.width - radius, size.height - 0.5),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..strokeWidth = 0.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SeoulPrismLogo extends StatelessWidget {
  final double size;
  const _SeoulPrismLogo({this.size = 160});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/logo.png',
      width: size,
      fit: BoxFit.contain,
    );
  }
}


