import 'dart:ui';

import 'package:cupertino_native_better/cupertino_native_better.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      bottomNavigationBar: CNTabBar(
        items: const [
          CNTabBarItem(
            label: '회원가입',
            customIcon: Icons.person_add_rounded,
          ),
          CNTabBarItem(
            label: '로그인',
            customIcon: Icons.login_rounded,
          ),
        ],
        currentIndex: _isLogin ? 1 : 0,
        onTap: (index) {
          setState(() {
            _mode = index == 0 ? AuthMode.signUp : AuthMode.login;
          });
        },
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'images/bgimg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
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
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!keyboardOpen) ...[
                            const _SeoulPrismLogo(),
                            const SizedBox(height: 24),
                          ],
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

  Widget _buildAuthPanel() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: LiquidGlassContainer(
        config: const LiquidGlassConfig(
          effect: CNGlassEffect.prominent,
          shape: CNGlassEffectShape.rect,
          cornerRadius: 24,
          interactive: true,
        ),
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
              CNButton(
                label: _isLogin ? '로그인' : '회원가입',
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const HomeView(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 500),
                    ),
                  );
                },
                config: const CNButtonConfig(
                  style: CNButtonStyle.glass,
                  minHeight: 50,
                ),
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
          label: '아이디',
          hintText: '아이디를 입력해주세요',
          controller: _idController,
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
        CNButton.icon(
          customIcon: IconData(FontAwesomeIcons.google.codePoint, fontFamily: FontAwesomeIcons.google.fontFamily, fontPackage: FontAwesomeIcons.google.fontPackage),
          onPressed: () {},
          tint: const Color(0xFF4285F4),
          config: const CNButtonConfig(
            style: CNButtonStyle.glass,
            customIconSize: 20,
          ),
        ),
        const SizedBox(width: 16),
        // Facebook
        CNButton.icon(
          customIcon: IconData(FontAwesomeIcons.facebookF.codePoint, fontFamily: FontAwesomeIcons.facebookF.fontFamily, fontPackage: FontAwesomeIcons.facebookF.fontPackage),
          onPressed: () {},
          tint: const Color(0xFF1877F2),
          config: const CNButtonConfig(
            style: CNButtonStyle.glass,
            customIconSize: 20,
          ),
        ),
        const SizedBox(width: 16),
        // Apple
        CNButton.icon(
          customIcon: IconData(FontAwesomeIcons.apple.codePoint, fontFamily: FontAwesomeIcons.apple.fontFamily, fontPackage: FontAwesomeIcons.apple.fontPackage),
          onPressed: () {},
          config: const CNButtonConfig(
            style: CNButtonStyle.glass,
            customIconSize: 22,
          ),
        ),
      ],
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

  @override
  void dispose() {
    _emailController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIdMode = widget.mode == _FindSheetMode.id;

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
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
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
                                      isIdMode ? '아이디 찾기' : '비밀번호 찾기',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isIdMode
                                          ? '가입 시 사용한 이메일을 입력하면\n아이디를 알려드립니다.'
                                          : '아이디와 이메일을 입력하면\n비밀번호 재설정 링크를 보내드립니다.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.white.withValues(alpha: 0.50),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    if (!isIdMode) ...[
                                      _GlassInputField(
                                        label: '아이디',
                                        hintText: '아이디를 입력해주세요',
                                        controller: _idController,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    _GlassInputField(
                                      label: '이메일',
                                      hintText: '가입한 이메일을 입력해주세요',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 24),
                                    CNButton(
                                      label: isIdMode ? '아이디 찾기' : '재설정 링크 받기',
                                      onPressed: () => Navigator.pop(context),
                                      config: const CNButtonConfig(
                                        style: CNButtonStyle.glass,
                                        minHeight: 50,
                                      ),
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
  const _SeoulPrismLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'images/logo.png',
      width: 160,
      fit: BoxFit.contain,
    );
  }
}


