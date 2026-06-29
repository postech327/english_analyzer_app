// lib/screens/register_screen.dart
import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';

const _interestOptions = <_InterestOption>[
  _InterestOption('mock_exam_english', '모의고사 영어'),
  _InterestOption('school_exam', '내신 대비'),
  _InterestOption('other', '기타'),
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _school = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _refCode = TextEditingController();

  String? _role;
  String _interest = 'mock_exam_english';
  bool _agreeAll = false;
  bool _agreeMarketing = false;
  bool _agreeTos = false;
  bool _agreePrivacy = false;
  bool _loading = false;
  bool _checkingUsername = false;
  bool _usernameChecked = false;
  bool _usernameAvailable = false;
  bool _showPassword = false;
  bool _showPasswordConfirm = false;
  String _usernameCheckMessage = '';

  final _service = AuthService.instance;

  @override
  void initState() {
    super.initState();
    _username.addListener(_resetUsernameCheck);
  }

  @override
  void dispose() {
    _username.removeListener(_resetUsernameCheck);
    _name.dispose();
    _school.dispose();
    _email.dispose();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _refCode.dispose();
    super.dispose();
  }

  void _resetUsernameCheck() {
    if (!_usernameChecked &&
        !_usernameAvailable &&
        _usernameCheckMessage.isEmpty) {
      return;
    }
    setState(() {
      _usernameChecked = false;
      _usernameAvailable = false;
      _usernameCheckMessage = '';
    });
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? '필수 입력 항목입니다.' : null;

  String? _emailValidator(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return '이메일을 입력하세요.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    if (!ok) return '이메일 형식을 확인해 주세요.';
    return null;
  }

  String? _phoneValidator(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '휴대폰 번호를 입력하세요.';
    if (digits.length < 10) return '휴대폰 번호를 확인해 주세요.';
    return null;
  }

  String? _usernameValidator(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return '아이디를 입력하세요.';
    if (text.length < 4 || text.length > 20) {
      return '아이디는 4~20자로 입력하세요.';
    }
    if (!RegExp(r'^[A-Za-z0-9_]+$').hasMatch(text)) {
      return '아이디는 영문, 숫자, 밑줄만 사용할 수 있습니다.';
    }
    return null;
  }

  String? _pwValidator(String? v) {
    if (v == null || v.isEmpty) return '비밀번호를 입력하세요.';
    if (v.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    return null;
  }

  String? _pwConfirmValidator(String? v) {
    if (v == null || v.isEmpty) return '비밀번호 확인을 입력하세요.';
    if (v != _password.text) return '비밀번호가 일치하지 않습니다.';
    return null;
  }

  void _toggleAgreeAll(bool? v) {
    final val = v ?? false;
    setState(() {
      _agreeAll = val;
      _agreeMarketing = val;
      _agreeTos = val;
      _agreePrivacy = val;
    });
  }

  void _setAgreement({
    bool? marketing,
    bool? tos,
    bool? privacy,
  }) {
    setState(() {
      if (marketing != null) _agreeMarketing = marketing;
      if (tos != null) _agreeTos = tos;
      if (privacy != null) _agreePrivacy = privacy;
      _agreeAll = _agreeMarketing && _agreeTos && _agreePrivacy;
    });
  }

  Future<void> _checkUsername() async {
    final error = _usernameValidator(_username.text);
    if (error != null) {
      setState(() {
        _usernameChecked = false;
        _usernameAvailable = false;
        _usernameCheckMessage = error;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameCheckMessage = '';
    });

    try {
      final result = await _service.checkUsername(_username.text.trim());
      final available = result['available'] == true;
      final message = result['message']?.toString() ??
          (available ? '사용 가능한 아이디입니다.' : '이미 사용 중인 아이디입니다.');

      if (!mounted) return;
      setState(() {
        _usernameChecked = true;
        _usernameAvailable = available;
        _usernameCheckMessage = message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _usernameChecked = false;
        _usernameAvailable = false;
        _usernameCheckMessage = _cleanException(e);
      });
    } finally {
      if (mounted) setState(() => _checkingUsername = false);
    }
  }

  String _cleanException(Object error) {
    final text = error.toString();
    return text.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState!.validate();

    if (_role == null) {
      _showError('학생 또는 선생님 가입 유형을 선택해 주세요.');
      return;
    }
    if (!formOk) return;
    if (!_usernameChecked || !_usernameAvailable) {
      _showError('아이디 중복 확인을 완료해 주세요.');
      return;
    }
    if (!_agreeTos || !_agreePrivacy) {
      _showError('필수 약관에 동의해 주세요.');
      return;
    }

    setState(() => _loading = true);
    try {
      final req = RegisterRequest(
        name: _name.text.trim(),
        school: _school.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
        role: _role!,
        interest: _interest,
        refCode: _refCode.text.trim().isEmpty ? null : _refCode.text.trim(),
        marketingOptIn: _agreeMarketing,
        tos: _agreeTos,
        privacy: _agreePrivacy,
      );

      final resp = await _service.register(req);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '회원가입이 완료되었습니다. ${resp['user']?['username'] ?? _username.text} 계정으로 로그인해 주세요.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(_cleanException(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        title: const Text(
          '회원가입',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _introCard(),
                      const SizedBox(height: 16),
                      _RoleSelector(
                        value: _role,
                        onChanged: (value) => setState(() => _role = value),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        icon: Icons.badge_outlined,
                        title: '기본 정보',
                        subtitle: _role == 'teacher'
                            ? '선생님 계정 생성을 위한 기본 정보를 입력해 주세요.'
                            : '학생 계정 생성을 위한 기본 정보를 입력해 주세요.',
                        child: Column(
                          children: [
                            _field(
                              controller: _name,
                              label: '이름 *',
                              hint: '홍길동',
                              icon: Icons.person_outline_rounded,
                              validator: _req,
                            ),
                            const SizedBox(height: 14),
                            _field(
                              controller: _school,
                              label: '학교명 또는 학원명 *',
                              hint: '예: 도안고 또는 열린아카데미',
                              icon: Icons.apartment_rounded,
                              validator: _req,
                            ),
                            const SizedBox(height: 14),
                            _field(
                              controller: _email,
                              label: '이메일 *',
                              hint: 'name@example.com',
                              icon: Icons.mail_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 14),
                            _phoneField(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        icon: Icons.lock_outline_rounded,
                        title: '계정 정보',
                        subtitle: '로그인에 사용할 ID와 비밀번호를 설정해 주세요.',
                        child: Column(
                          children: [
                            _usernameField(),
                            const SizedBox(height: 14),
                            _field(
                              controller: _password,
                              label: '비밀번호 *',
                              hint: '8자 이상',
                              icon: Icons.password_rounded,
                              obscure: !_showPassword,
                              validator: _pwValidator,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _showPassword = !_showPassword,
                                  );
                                },
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _field(
                              controller: _passwordConfirm,
                              label: '비밀번호 확인 *',
                              hint: '비밀번호를 한 번 더 입력하세요.',
                              icon: Icons.check_circle_outline_rounded,
                              obscure: !_showPasswordConfirm,
                              validator: _pwConfirmValidator,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(
                                    () => _showPasswordConfirm =
                                        !_showPasswordConfirm,
                                  );
                                },
                                icon: Icon(
                                  _showPasswordConfirm
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        icon: Icons.interests_outlined,
                        title: _role == 'teacher' ? '담당 영역' : '관심 분야',
                        subtitle: '가장 관심 있는 학습 분야를 하나 선택해 주세요.',
                        child: _InterestSelector(
                          value: _interest,
                          onChanged: (v) => setState(() => _interest = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        icon: Icons.verified_user_outlined,
                        title: '약관 및 추천인',
                        subtitle: '필수 약관 동의 후 회원가입을 완료할 수 있습니다.',
                        child: Column(
                          children: [
                            _field(
                              controller: _refCode,
                              label: '추천인 ID (선택)',
                              hint: '없으면 비워두세요.',
                              icon: Icons.card_giftcard_rounded,
                            ),
                            const SizedBox(height: 14),
                            _AgreementTile(
                              value: _agreeAll,
                              title: '전체 동의',
                              subtitle: '필수 약관과 선택 수신 동의를 함께 설정합니다.',
                              strong: true,
                              onChanged: _toggleAgreeAll,
                            ),
                            const SizedBox(height: 8),
                            _AgreementTile(
                              value: _agreeTos,
                              title: '[필수] 이용약관 동의',
                              onChanged: (v) => _setAgreement(tos: v ?? false),
                            ),
                            const SizedBox(height: 8),
                            _AgreementTile(
                              value: _agreePrivacy,
                              title: '[필수] 개인정보 수집 및 이용 동의',
                              onChanged: (v) =>
                                  _setAgreement(privacy: v ?? false),
                            ),
                            const SizedBox(height: 8),
                            _AgreementTile(
                              value: _agreeMarketing,
                              title: '[선택] 마케팅 정보 수신 동의',
                              onChanged: (v) =>
                                  _setAgreement(marketing: v ?? false),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('회원가입'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          onPressed:
                              _loading ? null : () => Navigator.pop(context),
                          child: const Text('이미 계정이 있으신가요? 로그인으로'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'English Analyzer 시작하기',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '학생과 선생님 가입 흐름을 분리했습니다. 필요한 정보만 입력하면 바로 학습을 시작할 수 있습니다.',
            style: TextStyle(
              color: Color(0xFF64748B),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _phoneField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final field = _field(
          controller: _phone,
          label: '휴대폰 번호 *',
          hint: '숫자만 입력',
          icon: Icons.phone_iphone_rounded,
          keyboardType: TextInputType.phone,
          validator: _phoneValidator,
        );

        final button = SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('인증 기능은 준비 중입니다. 가입은 계속 진행할 수 있습니다.')),
              );
            },
            style: _outlineButtonStyle(),
            child: const Text('인증 요청'),
          ),
        );

        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field,
              const SizedBox(height: 10),
              button,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: 10),
            button,
          ],
        );
      },
    );
  }

  Widget _usernameField() {
    final messageColor =
        _usernameAvailable ? const Color(0xFF15803D) : const Color(0xFFDC2626);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final field = _field(
              controller: _username,
              label: 'ID *',
              hint: '영문, 숫자, 밑줄 4~20자',
              icon: Icons.alternate_email_rounded,
              validator: _usernameValidator,
            );

            final button = SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: _checkingUsername ? null : _checkUsername,
                style: _outlineButtonStyle(),
                child: _checkingUsername
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('중복 확인'),
              ),
            );

            if (constraints.maxWidth < 430) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field,
                  const SizedBox(height: 10),
                  button,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: field),
                const SizedBox(width: 10),
                button,
              ],
            );
          },
        ),
        if (_usernameCheckMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _usernameAvailable
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: messageColor,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _usernameCheckMessage,
                  style: TextStyle(
                    color: messageColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF2563EB),
      side: const BorderSide(color: Color(0xFFBFDBFE)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffix: suffix,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      labelStyle: const TextStyle(
        color: Color(0xFF475569),
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD7DFEA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.account_circle_outlined,
      title: '어떤 계정으로 가입하시나요?',
      subtitle: '가입 유형에 따라 학생용/선생님용 화면으로 안내됩니다.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            _RoleCard(
              selected: value == 'student',
              icon: Icons.school_rounded,
              title: '학생으로 가입',
              subtitle: 'Final Touch와 모의고사 학습을 진행합니다.',
              onTap: () => onChanged('student'),
            ),
            _RoleCard(
              selected: value == 'teacher',
              icon: Icons.workspace_premium_rounded,
              title: '선생님으로 가입',
              subtitle: '분석 자료와 학생 학습 결과를 관리합니다.',
              onTap: () => onChanged('teacher'),
            ),
          ];

          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                cards[0],
                const SizedBox(height: 10),
                cards[1],
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 10),
              Expanded(child: cards[1]),
            ],
          );
        },
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2563EB) : const Color(0xFF64748B);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFD7DFEA),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5EAF3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InterestOption {
  const _InterestOption(this.value, this.label);

  final String value;
  final String label;
}

class _InterestSelector extends StatelessWidget {
  const _InterestSelector({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _interestOptions.map((option) {
        final selected = option.value == value;
        return InkWell(
          onTap: () => onChanged(option.value),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFD7DFEA),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  option.label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF334155),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AgreementTile extends StatelessWidget {
  const _AgreementTile({
    required this.value,
    required this.title,
    required this.onChanged,
    this.subtitle,
    this.strong = false,
  });

  final bool value;
  final String title;
  final String? subtitle;
  final bool strong;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: strong ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        activeColor: const Color(0xFF2563EB),
        title: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
      ),
    );
  }
}
