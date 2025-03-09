import 'package:flutter/material.dart';
import '../Models/Task.dart';
import './add_tasks_screen.dart';

class TasksScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskUpdated;
  final Function(Task) onTaskDeleted;
  final Function(Task) onTaskAdded;

  const TasksScreen({
    Key? key,
    required this.tasks,
    required this.onTaskAdded,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  }) : super(key: key);

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _sortBy = 'None'; // Tiêu chí sắp xếp

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Doing"),
              Tab(text: "Completed"),
              Tab(text: "Favorite"),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: _sortBy,
                items:
                    [
                      'None',
                      'Type (A-Z)',
                      'Type (Z-A)',
                      'Priority High to Low',
                      'Priority Low to High',
                    ].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sortBy = newValue;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildTaskList(
              widget.tasks.where((task) => !task.isCompleted).toList(),
            ),
            _buildTaskList(
              widget.tasks.where((task) => task.isCompleted).toList(),
            ),
            _buildTaskList(
              widget.tasks.where((task) => task.isFavorite).toList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => AddTaskScreen(
                      onTaskAdded: (newTask) {
                        widget.onTaskUpdated(newTask);
                      },
                    ),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Task> _sortTasks(List<Task> tasks) {
    // Định nghĩa mức độ ưu tiên
    Map<String, int> priorityMap = {
      'Urgent': 1,
      'Work': 2,
      'Personal': 3,
      'General': 4,
    };

    if (_sortBy == 'Type (A-Z)') {
      tasks.sort((a, b) => a.type.compareTo(b.type));
    } else if (_sortBy == 'Type (Z-A)') {
      tasks.sort((a, b) => b.type.compareTo(a.type));
    } else if (_sortBy == 'Priority High to Low') {
      tasks.sort(
        (a, b) =>
            (priorityMap[a.type] ?? 999).compareTo(priorityMap[b.type] ?? 999),
      );
    } else if (_sortBy == 'Priority Low to High') {
      tasks.sort(
        (a, b) =>
            (priorityMap[b.type] ?? 999).compareTo(priorityMap[a.type] ?? 999),
      );
    }

    return tasks;
  }

  Widget _buildTaskList(List<Task> taskList) {
    final Map<String, Color> taskTypeColors = {
      'General': Colors.grey,
      'Work': Colors.blue,
      'Personal': Colors.green,
      'Urgent': Colors.red,
    };

    List<Task> sortedTasks = _sortTasks(taskList);

    return ListView.builder(
      itemCount: sortedTasks.length,
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
        final taskColor = taskTypeColors[task.type] ?? Colors.grey;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: taskColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            title: Text(
              task.description,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    task.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: task.isFavorite ? Colors.red : null,
                  ),
                  onPressed: () {
                    widget.onTaskUpdated(
                      task.copyWith(isFavorite: !task.isFavorite),
                    );
                  },
                ),
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    bool newValue = value ?? false;
                    widget.onTaskUpdated(task.copyWith(isCompleted: newValue));

                    if (newValue) {
                      databaseService.updateDate(DateTime.now());
                    } else {
                      databaseService.decreaseDate(DateTime.now());
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    widget.onTaskDeleted(task);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
