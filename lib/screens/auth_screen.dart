// lib/screens/auth_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = true;
  bool _showPw = false;

  /// 중복 클릭 방지 / 로딩 인디케이터 표시
  bool _busy = false;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;

    // 간단 검증 (필요 시 확장)
    if (_email.text.isEmpty || _pw.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일과 비밀번호를 입력하세요.')),
      );
      return;
    }
    if (_isSignUp && _name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력하세요.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      if (_isSignUp) {
        // TODO: 회원가입 API 호출/검증
        // await authService.signUp(_name.text, _email.text, _pw.text);
      } else {
        // TODO: 로그인 API 호출/검증
        // await authService.signIn(_email.text, _pw.text);
      }

      if (!mounted) return; // ✅ await 후 안전 체크

      // 성공 시: 탭이 있는 메인(AppShell)으로 이동 (named route)
      Navigator.pushReplacementNamed(context, '/app');
    } catch (e) {
      if (!mounted) return; // ✅
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false); // ✅
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 그라데이션 배경
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003973), Color(0xFFE5E5BE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _glassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSignUp ? 'Create Account' : 'Welcome Back',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isSignUp
                          ? 'Sign up to get started'
                          : 'Sign in to continue',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 18),
                    if (_isSignUp) ...[
                      _field(
                        label: 'Full name',
                        icon: Icons.person_outline,
                        controller: _name,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _field(
                      label: 'Email',
                      icon: Icons.alternate_email_rounded,
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _field(
                      label: 'Password',
                      icon: Icons.lock_outline,
                      controller: _pw,
                      obscure: !_showPw,
                      suffix: IconButton(
                        onPressed: () => setState(() => _showPw = !_showPw),
                        icon: Icon(
                          _showPw ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          // 버튼도 살짝 투명한 흰색
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(_isSignUp ? 'SIGN UP' : 'SIGN IN'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 토글 버튼 (기존)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account?  Login'
                            : "Don't have an account?  Create one",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

// 간격
                    const SizedBox(height: 8),

// 신규: 상세 회원가입 화면으로 이동
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.pushNamed(context, '/register'),
                      child: const Text('회원가입(상세)'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 글래스 카드 컨테이너
  Widget _glassCard({required Widget child}) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// 공통 입력 필드
  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        filled: true,
        // 입력창 배경
        fillColor: Colors.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
    );
  }
}
