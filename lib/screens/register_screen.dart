// lib/screens/register_screen.dart
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../models/auth_models.dart'; // RegisterRequest 정의되어 있어야 함

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // 입력 컨트롤러
  final _name = TextEditingController();
  final _school = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _refCode = TextEditingController();

  // 상태값
  String _studentCount = '10명 이하'; // 드롭다운
  String _interest = '모의고사영어'; // 라디오
  bool _agreeAll = false;
  bool _agreeMarketing = false; // 선택
  bool _agreeTos = false; // 필수
  bool _agreePrivacy = false; // 필수
  bool _loading = false;

  final _service = AuthService.instance;

  @override
  void dispose() {
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

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? '필수 입력 항목입니다.' : null;

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

  void _syncAgreeAll() {
    final all = _agreeMarketing && _agreeTos && _agreePrivacy;
    if (all != _agreeAll) {
      setState(() => _agreeAll = all);
    }
  }

  // 학생 수 → gradeBand(백엔드 필드 매핑용) 간단 변환
  String _mapStudentCountToGradeBand(String s) {
    switch (s) {
      case '10명 이하':
        return '초5~6';
      case '30명 이하':
        return '중1~3';
      case '50명 이상':
        return '고1~3';
      default:
        return '초5~6';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTos || !_agreePrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관(이용약관/개인정보)에 동의해주세요.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final req = RegisterRequest(
        name: _name.text.trim(),
        school: _school.text.trim(),
        gradeBand: _mapStudentCountToGradeBand(_studentCount),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        username: _username.text.trim(),
        password: _password.text,
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
          content:
              Text('회원가입 완료: ${resp['user']?['username'] ?? _username.text}'),
        ),
      );
      // 가입 완료 후 로그인 화면으로 복귀
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).size.width > 520 ? 24.0 : 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(pad),
            children: [
              // 성함
              TextFormField(
                controller: _name,
                validator: _req,
                decoration: const InputDecoration(
                  labelText: '성함 *',
                  hintText: '성함을 입력해주세요.',
                ),
              ),
              const SizedBox(height: 12),

              // 학원명 / 학교
              TextFormField(
                controller: _school,
                validator: _req,
                decoration: const InputDecoration(
                  labelText: '학원명 / 학교 *',
                  hintText: '학원명 또는 학교명을 입력해주세요.',
                ),
              ),
              const SizedBox(height: 12),

              // 학생 수 (드롭다운)
              DropdownButtonFormField<String>(
                value: _studentCount,
                items: const [
                  DropdownMenuItem(value: '10명 이하', child: Text('10명 이하')),
                  DropdownMenuItem(value: '30명 이하', child: Text('30명 이하')),
                  DropdownMenuItem(value: '50명 이상', child: Text('50명 이상')),
                ],
                onChanged: (v) => setState(() => _studentCount = v!),
                decoration: const InputDecoration(
                  labelText: '학생 수 *',
                ),
              ),
              const SizedBox(height: 12),

              // 이메일
              TextFormField(
                controller: _email,
                validator: _req,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일 *',
                  hintText: '예) name@example.com',
                ),
              ),
              const SizedBox(height: 12),

              // 휴대폰 + 인증요청 버튼 (동작은 TODO)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      validator: _req,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '휴대폰 번호 *',
                        hintText: '숫자만 입력',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('인증 요청 기능은 추후 연결 예정입니다.')),
                      );
                    },
                    child: const Text('인증 요청'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 아이디
              TextFormField(
                controller: _username,
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return '아이디를 입력하세요.';
                  if ((v ?? '').length < 4 || (v ?? '').length > 20) {
                    return '아이디는 4~20자로 입력하세요.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'ID *',
                  hintText: '4~20자',
                ),
              ),
              const SizedBox(height: 12),

              // 비밀번호/확인
              TextFormField(
                controller: _password,
                obscureText: true,
                validator: _pwValidator,
                decoration: const InputDecoration(
                  labelText: '비밀번호 *',
                  hintText: '8자 이상',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordConfirm,
                obscureText: true,
                validator: _pwConfirmValidator,
                decoration: const InputDecoration(
                  labelText: '비밀번호 확인 *',
                ),
              ),
              const SizedBox(height: 16),

              // 관심 분야 라디오
              Text('가장 관심 있는 분야를 하나만 선택해주세요. *',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              _InterestRadio(
                value: _interest,
                onChanged: (v) => setState(() => _interest = v),
              ),
              const SizedBox(height: 12),

              // 추천인 ID
              TextFormField(
                controller: _refCode,
                decoration: const InputDecoration(
                  labelText: '추천인 ID (선택)',
                  hintText: '없으면 비워두세요.',
                ),
              ),
              const SizedBox(height: 16),

              // 동의 체크
              CheckboxListTile(
                value: _agreeAll,
                onChanged: _toggleAgreeAll,
                title: const Text('전체 동의'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _agreeMarketing,
                onChanged: (v) {
                  setState(() => _agreeMarketing = v ?? false);
                  _syncAgreeAll();
                },
                title: const Text('[선택] 마케팅 정보 수신 동의'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _agreeTos,
                onChanged: (v) {
                  setState(() => _agreeTos = v ?? false);
                  _syncAgreeAll();
                },
                title: const Text('[필수] 이용약관 동의'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: _agreePrivacy,
                onChanged: (v) {
                  setState(() => _agreePrivacy = v ?? false);
                  _syncAgreeAll();
                },
                title: const Text('[필수] 개인정보 수집 및 이용 동의'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              // 신청하기 버튼
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('신청하기'),
                ),
              ),
              const SizedBox(height: 8),

              // 이미 계정이 있나요? → 로그인 이동
              TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        Navigator.pop(context); // 로그인 화면으로 복귀
                      },
                child: const Text('이미 계정이 있으신가요? 로그인으로'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestRadio extends StatelessWidget {
  const _InterestRadio({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile<String>(
          value: '모의고사영어',
          groupValue: value,
          onChanged: (v) => onChanged(v!),
          title: const Text('모의고사영어'),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: '내신대비',
          groupValue: value,
          onChanged: (v) => onChanged(v!),
          title: const Text('내신대비'),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          value: '기타',
          groupValue: value,
          onChanged: (v) => onChanged(v!),
          title: const Text('기타'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
