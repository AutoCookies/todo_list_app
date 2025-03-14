import 'package:flutter/material.dart';
import '../../db/achievementDb.dart';
import '../../Models/Acheivement.dart';
class AchievementScreen extends StatefulWidget {
  const AchievementScreen({Key? key}) : super(key: key);

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  final AchievementDb _achievementDb = AchievementDb();
  late Future<List<Achievement>> _futureAchievements;

  @override
  void initState() {
    super.initState();
    // Lấy danh sách achievement của user hiện tại
    _futureAchievements = _achievementDb.getAchievements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Achievements"),
      ),
      body: FutureBuilder<List<Achievement>>(
        future: _futureAchievements,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No achievements found."));
          }
          final achievements = snapshot.data!;
          return ListView.builder(
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              Achievement achievement = achievements[index];
              // Tính tỉ lệ tiến độ, đảm bảo không vượt quá 1.0
              double progressPercent = achievement.goal > 0 
                ? (achievement.progress / achievement.goal).clamp(0.0, 1.0) 
                : 0.0;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Sử dụng icon emoji_events làm biểu tượng thành tựu
                          const Icon(Icons.emoji_events, size: 40, color: Colors.amber),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              achievement.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(achievement.description),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: Colors.grey[300],
                        color: progressPercent >= 1.0 ? Colors.green : Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      Text("Progress: ${achievement.progress}/${achievement.goal}"),
                      if (achievement.isCompleted)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text("Completed!",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
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
