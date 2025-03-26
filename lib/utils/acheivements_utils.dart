import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/Acheivement.dart';
import '../db/achievementDb.dart';

class AchievementUtils {
  final AchievementDb _achievementDb = AchievementDb();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Cập nhật tiến trình của achievements sau một hành động nào đó.
  Future<void> updateAchievementsAfterAction(String actionType) async {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return;

    CollectionReference achievementsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('achievements');

    QuerySnapshot snapshot = await achievementsRef.get();

    for (DocumentSnapshot doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String achievementName = data['name'];
      int goal = data['goal'] ?? 0;
      int currentProgress = data['progress'] ?? 0;
      bool isCompleted = data['isCompleted'] ?? false;

      // Kiểm tra achievement có liên quan đến actionType không
      if (isCompleted) continue;

      if (_isRelevantAchievement(achievementName, actionType)) {
        int increment = _getIncrementValue(achievementName);
        int newProgress = currentProgress + increment;
        bool updatedCompletion = newProgress >= goal;

        await achievementsRef.doc(doc.id).update({
          'progress': newProgress,
          'isCompleted': updatedCompletion,
        });
      }
    }
  }

  /// Xác định achievement có liên quan đến actionType không
  bool _isRelevantAchievement(String achievementName, String actionType) {
    Map<String, List<String>> achievementActions = {
      "Task Starter": ["task_completed"],
      "Task Enthusiast": ["task_completed"],
      "Task Master": ["task_completed"],
      "Your First Strike": ["consecutive_days"],
      "The Noob Striker": ["consecutive_days"],
    };

    return achievementActions[achievementName]?.contains(actionType) ?? false;
  }

  /// Xác định giá trị cần tăng cho achievement
  int _getIncrementValue(String achievementName) {
    if (achievementName.contains("Strike")) {
      return 1; // Đếm số ngày liên tiếp
    }
    return 1; // Đếm số task đã hoàn thành
  }
}
