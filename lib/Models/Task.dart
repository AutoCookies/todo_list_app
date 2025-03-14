import 'package:uuid/uuid.dart';

class Task {
  final String id; // Đổi int -> String
  String userId;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  bool isCompleted;
  bool isFavorite;
  final String type;

  Task({
    String? id, // Cho phép null, tự tạo nếu không có
    required this.userId,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.isFavorite = false,
    required this.type,
  }) : id = id ?? const Uuid().v4(); // Tạo ID mới nếu không có

  Task copyWith({
    String? id,
    String? userId, // ✅ Thêm userId vào copyWith
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool? isFavorite,
    String? type,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId, // ✅ Gán userId mới nếu có
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      type: type ?? this.type,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id:
          map['id']?.toString() ??
          const Uuid().v4(), // 🔥 Chuyển `int` -> `String`
      userId: map['userId'] ?? '',
      description: map['description'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isCompleted: map['isCompleted'] == 1,
      isFavorite: map['isFavorite'] == 1,
      type: map['type'] ?? 'General',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // ✅ Thêm userId
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'type': type,
    };
  }
}
