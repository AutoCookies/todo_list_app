import 'package:flutter/material.dart';
import 'screens/tasks_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/personal_screen.dart';
import 'Models/Task.dart';
import 'package:audioplayers/audioplayers.dart';
import "./db/db.dart";
import 'dart:io';
import './screens/settings_screen.dart';
import './utils/image_picker_utils.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

final databaseService = DatabaseService();

class _MainAppState extends State<MainApp> {
  List<Task> tasks = [];
  File? _profileImage; // Biến lưu ảnh đại diện của người dùng
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // print("InitState called!");
    _loadTasks();

    // Trì hoãn việc gọi checkDeadlineTask để đảm bảo context hợp lệ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        checkDeadlineTask(context);
      }
    });
    _loadImageOnStartup();
  }

  Future<void> checkDeadlineTask(BuildContext context) async {
    final db = await databaseService.database;
    List<Task> taskListNearDeadLine = [];
    DateTime today = DateTime.now();
    final player = AudioPlayer(); // Tạo player để phát âm thanh

    List<Map<String, dynamic>> results = await db.query(
      'tasks',
      orderBy: 'startDate ASC',
    );

    for (Map<String, dynamic> result in results) {
      if (result['endDate'] == null || result['endDate'].toString().isEmpty) {
        continue;
      }

      DateTime endDate;
      try {
        endDate = DateTime.parse(result['endDate']);
      } catch (e) {
        // print("Lỗi chuyển đổi ngày tháng: $e");
        continue;
      }

      int diffDays = endDate.difference(today).inDays;

      if (diffDays <= 3 && diffDays >= 0) {
        taskListNearDeadLine.add(Task.fromMap(result));
      }
    }

    if (taskListNearDeadLine.isNotEmpty) {
      print("🔔 Show dialog & play sound!");

      // 🔊 Phát âm thanh
      await player.play(
        AssetSource('sounds/announcement-sound-effect-254037.mp3'),
      );

      // 🏆 Hiển thị Dialog sau khi UI đã dựng xong
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Upcoming Deadlines"),
                content: Text(
                  "You have ${taskListNearDeadLine.length} tasks near deadline!",
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      player.stop(); // Dừng âm thanh khi đóng thông báo
                      Navigator.of(context).pop();
                    },
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
        }
      });
    }
  }

  Future<void> cleanOldCompletedTasks() async {
    final db = await databaseService.database;

    List<Map<String, dynamic>> results = await db.query(
      'completed_tasks',
      orderBy: 'date ASC',
    );

    if (results.length > 60) {
      int deleteCount = results.length - 60;
      for (int i = 0; i < deleteCount; i++) {
        String dateToDelete = results[i]['date'];
        await db.delete(
          'completed_tasks',
          where: 'date = ?',
          whereArgs: [dateToDelete],
        );
        print("Deleted completed tasks for date: $dateToDelete");
      }
    }
  }

  void _loadTasks() async {
    await cleanOldCompletedTasks(); // Xóa các ngày cũ nếu quá 60 ngày
    List<Task> loadedTasks = await databaseService.getTasks();
    setState(() {
      tasks = loadedTasks;
    });
  }

  void _addTask(Task newTask) async {
    // Ở đây bên code bên add_tasks_screen đã có add rồi nên nếu gọi thêm sẽ bị lặp lại cho nên ta comment ra
    // await databaseService.addTask(newTask); // Thêm vào database
    _loadTasks(); // Cập nhật lại danh sách tasks từ database
  }

  void _deleteTask(Task deletedTask) async {
    await databaseService.deleteTask(deletedTask.id);

    // Xóa task trực tiếp khỏi danh sách trước khi cập nhật database
    setState(() {
      tasks.removeWhere((task) => task.id == deletedTask.id);
    });

    _loadTasks(); // Cập nhật danh sách từ database
    // print("Deleted task: ${deletedTask.description}");
  }

  void _updateTask(Task updatedTask) async {
    await databaseService.updateTask(updatedTask); // Lưu vào database
    _loadTasks(); // Cập nhật lại danh sách từ database

    // Debugging
    // print("Updated task: ${updatedTask.description}");
  }

  void _pickImage() async {
    File? pickedImage = await pickImage();
    if (pickedImage != null) {
      await deleteOldImage(); // Xóa ảnh cũ trước khi lưu ảnh mới
      File savedImage = await saveImage(pickedImage);
      await saveImagePath(savedImage.path);

      setState(() {
        _profileImage = savedImage;
      });
    }
  }

  void _loadImageOnStartup() async {
    File? savedImage = await loadSavedImage();
    if (savedImage != null) {
      setState(() {
        _profileImage = savedImage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200], // Nền nhẹ nhàng
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Todo App"),
          centerTitle: true,
          backgroundColor: Colors.blueAccent,
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // 🖼️ Drawer Header với ảnh user
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Colors.blueAccent),
                accountName: const Text(
                  "Cookiescooker",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                accountEmail: const Text("cookiescooker@example.com"),
                currentAccountPicture: GestureDetector(
                  onTap: _pickImage, // Nhấn để chọn ảnh mới
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        _profileImage != null
                            ? FileImage(_profileImage!) as ImageProvider
                            : const AssetImage("assets/images/user_avatar.png"),
                    child:
                        _profileImage == null
                            ? const Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                ),
              ),

              // ⚙️ Settings
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.black87),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context); // Đóng Drawer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.fireplace, color: Colors.red),
                title: Text(
                  "Urgent Tasks: ${tasks.where((task) => task.type == 'Urgent' && task.isCompleted == false).length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.blue),
                title: Text(
                  "Work Tasks: ${tasks.where((task) => task.type == 'Work' && task.isCompleted == false).length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.home, color: Colors.green),
                title: Text(
                  "Person Tasks: ${tasks.where((task) => task.type == 'Personal' && task.isCompleted == false).length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(
                  Icons.work,
                  color: Colors.grey,
                ), // Icon công việc bình thường
                title: Text(
                  "Normal Tasks: ${tasks.where((task) => task.type == 'General' && task.isCompleted == false).length}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(),

              // Logout
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Xử lý đăng xuất
                },
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Nội dung chính
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child:
                  _currentIndex == 0
                      ? TasksScreen(
                        key: const ValueKey(0),
                        tasks: tasks,
                        onTaskDeleted: _deleteTask,
                        onTaskAdded: _addTask,
                        onTaskUpdated: _updateTask,
                      )
                      : _currentIndex == 1
                      ? const CalendarScreen(key: ValueKey(1))
                      : const PersonalScreen(key: ValueKey(2)),
            ),
          ],
        ),

        // 🔹 Bottom Navigation với hiệu ứng đẹp mắt
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: BottomNavigationBar(
              backgroundColor: Colors.white,
              currentIndex: _currentIndex,
              selectedItemColor: Colors.blueAccent,
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.task, size: 28),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month, size: 28),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person, size: 28),
                  label: 'Personal',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
