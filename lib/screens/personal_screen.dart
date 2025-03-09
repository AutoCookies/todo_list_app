import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/db.dart';
import '../Models/Task.dart';

class PersonalScreen extends StatefulWidget {
  const PersonalScreen({Key? key}) : super(key: key);

  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final database = DatabaseService();
  int completedTasks = 0;
  int pendingTasks = 0;
  int completeToday = 0;

  Map<DateTime, int> completedTasksByDate = {};
  DateTime startDate = DateTime.now().subtract(const Duration(days: 15));

  @override
  void initState() {
    super.initState();
    _loadTaskStats();
  }

  Future<void> _loadTaskStats() async {
    List<Task> allTasks = await database.getTasks();
    Map<DateTime, int> taskCountMap = await database.getCompletedTasksByDate();

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    int completed = 0;
    int pending = 0;
    int completedTodayCount =
        taskCountMap[today] ?? 0; // Lấy số task hoàn thành hôm nay

    for (var task in allTasks) {
      if (task.endDate.isAfter(firstDayOfMonth) &&
          task.endDate.isBefore(lastDayOfMonth)) {
        if (task.isCompleted) {
          completed++;
        } else {
          pending++;
        }
      }
    }

    if (mounted) {
      setState(() {
        completedTasks = completed;
        pendingTasks = pending;
        completeToday = completedTodayCount;
        completedTasksByDate = taskCountMap;
      });
    }
  }

  void _changeDateRange(int days) {
    setState(() {
      startDate = startDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Personal Statistics")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTaskCard("Tasks Pending", pendingTasks, Colors.orange),
                _buildTaskCard("Tasks Completed", completedTasks, Colors.green),
                _buildTaskCard("Completed Today", completeToday, Colors.blue),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _changeDateRange(-15),
                  child: const Text("← Previous 15 Days"),
                ),
                ElevatedButton(
                  onPressed: () => _changeDateRange(15),
                  child: const Text("Next 15 Days →"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(child: _buildChart()), // Biểu đồ
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    List<BarChartGroupData> barGroups = [];
    DateTime now = DateTime.now();
    DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    DateTime adjustedStartDate =
        startDate.isBefore(firstDayOfMonth) ? firstDayOfMonth : startDate;

    List<DateTime> selectedDays = [];
    for (int i = 0; i < 15; i++) {
      DateTime day = adjustedStartDate.add(Duration(days: i));
      if (day.isAfter(lastDayOfMonth)) break;
      selectedDays.add(day);
    }

    double maxY = 5; // Giá trị tối thiểu
    for (var day in selectedDays) {
      int count = completedTasksByDate[day] ?? 0;
      maxY = count > maxY ? count.toDouble() : maxY;

      barGroups.add(
        BarChartGroupData(
          x: selectedDays.indexOf(day),
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: Colors.blue,
              width: 12,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Completed Tasks (${selectedDays.first.day}-${selectedDays.last.day})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY + 1, // Để có khoảng trống trên biểu đồ
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < selectedDays.length) {
                            DateTime day = selectedDays[value.toInt()];
                            return Text(
                              "${day.day}",
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
