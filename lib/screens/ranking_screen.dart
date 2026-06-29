import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../config/auth_store.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<dynamic>> _rankingFuture;

  @override
  void initState() {
    super.initState();
    _rankingFuture = CommunityService.fetchRanking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🏆 랭킹")),
      body: FutureBuilder<List<dynamic>>(
        future: _rankingFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ranking = snapshot.data!;

          return ListView.builder(
            itemCount: ranking.length,
            itemBuilder: (context, index) {
              final user = ranking[index]; // 👈 반드시 있어야 함
              final myNickname = AuthStore.nickname;
              final isMe = user['nickname'] == myNickname;

              return Card(
                color: isMe ? Colors.blue.withOpacity(0.15) : null,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Text(
                    "#${user['rank']}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: user['rank'] == 1
                          ? Colors.amber
                          : user['rank'] == 2
                              ? Colors.grey
                              : user['rank'] == 3
                                  ? Colors.brown
                                  : Colors.black,
                    ),
                  ),
                  title: Text(
                    user['nickname'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Level ${user['level']} • ${user['points']} pts",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
