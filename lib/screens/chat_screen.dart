import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  bool _sending = false;
  final List<_Msg> _messages = []; // 간단한 메모리 채팅 히스토리

  Future<void> _send() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(_Msg(role: 'user', content: q));
      _controller.clear();
    });

    try {
      final res = await http
          .post(
            ApiConfig.u(ApiConfig.chat),
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'question': q}),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        String answer;
        try {
          final m =
              jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
          answer = m['챗봇 응답']?.toString() ?? utf8.decode(res.bodyBytes);
        } catch (_) {
          answer = utf8.decode(res.bodyBytes);
        }
        setState(() => _messages.add(_Msg(role: 'assistant', content: answer)));
      } else {
        setState(() => _messages.add(_Msg(
            role: 'assistant',
            content: '❌ 오류: ${res.statusCode} ${res.body}')));
      }
    } catch (e) {
      setState(
          () => _messages.add(_Msg(role: 'assistant', content: '네트워크 오류: $e')));
    } finally {
      setState(() => _sending = false);
      await Future.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDF6),
      appBar: AppBar(title: const Text('챗봇')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepPurple.shade200 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.content),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: '질문을 입력하세요…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('전송'),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  final String role; // 'user' | 'assistant'
  final String content;
  _Msg({required this.role, required this.content});
}
