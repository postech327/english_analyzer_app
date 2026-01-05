// lib/screens/coin_log_screen.dart
import 'package:flutter/material.dart';

import '../models/coin_log.dart';
import '../services/user_api.dart';

class CoinLogScreen extends StatefulWidget {
  final int userId;

  const CoinLogScreen({super.key, required this.userId});

  @override
  State<CoinLogScreen> createState() => _CoinLogScreenState();
}

class _CoinLogScreenState extends State<CoinLogScreen> {
  List<CoinLog> _logs = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await UserApi.fetchCoinLogs(widget.userId);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '코인 로그 로드 실패: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('코인 로그'),
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
              : _logs.isEmpty
                  ? const Center(child: Text('코인 로그가 없습니다.'))
                  : RefreshIndicator(
                      onRefresh: _loadLogs,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final isEarn = log.action == 'earn';

                          return ListTile(
                            leading: Icon(
                              isEarn
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                            ),
                            title: Text(
                              '${isEarn ? '+' : '-'}${log.amount} 코인',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isEarn ? Colors.green : Colors.red,
                              ),
                            ),
                            subtitle: Text(
                              log.reason ?? '사유 없음',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              // yyyy-MM-dd 형태로 간단히 표시
                              '${log.createdAt.year}-'
                              '${log.createdAt.month.toString().padLeft(2, '0')}-'
                              '${log.createdAt.day.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
