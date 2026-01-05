// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/user_api.dart';
import 'coin_log_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile; // ✅ nullable
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await UserApi.fetchProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '프로필 로드 실패: $e';
        _isLoading = false;
      });
    }
  }

  /// 테스트용 코인 적립 버튼 (예: 출석 보상)
  Future<void> _earnTestCoins() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updated = await UserApi.earnCoins(
        userId: widget.userId,
        amount: 30,
        reason: '출석 보상(테스트)',
      );

      if (!mounted) return;
      setState(() {
        _profile = updated; // ✅ UserProfile -> UserProfile? OK
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('+30 코인 적립 완료!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '코인 적립 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 프로필'),
        backgroundColor: cs.surface,
        elevation: 0,
      ),
      backgroundColor: cs.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _profile == null
                  ? const Center(child: Text('프로필 정보가 없습니다.'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ───── 기본 정보 ─────
                          Text(
                            _profile!.nickname,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _profile!.levelLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _profile!.region ?? '지역 정보 없음',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),

                          // ───── 코인 표시 ─────
                          Row(
                            children: [
                              const Icon(Icons.monetization_on_outlined),
                              const SizedBox(width: 8),
                              Text('코인: ${_profile!.coins}'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ───── 코인 내역 / 출석 보상 버튼들 ─────
                          Row(
                            children: [
                              // 코인 내역 보기
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CoinLogScreen(
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('코인 내역 보기'),
                              ),
                              const SizedBox(width: 12),

                              // 출석 보상 코인 적립
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _earnTestCoins,
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('출석 보상 코인 +30 (테스트)'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Divider(),
                          const SizedBox(height: 8),

                          // ───── 이메일/가입일 ─────
                          Text(
                            '이메일: ${_profile!.email}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '가입일: '
                            '${_profile!.createdAt.year}-'
                            '${_profile!.createdAt.month.toString().padLeft(2, '0')}-'
                            '${_profile!.createdAt.day.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
    );
  }
}
