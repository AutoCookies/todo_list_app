class Task {
  final int id;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  bool isCompleted;
  bool isFavorite;
  final String type; // Thêm thuộc tính type

  Task({
    this.id = 0,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
    this.isFavorite = false,
    required this.type, // Bổ sung type vào constructor
  });

  Task copyWith({
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
    bool? isFavorite,
    String? type, // Thêm type vào copyWith
  }) {
    return Task(
      id: id,
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
          (map['id'] is int)
              ? map['id']
              : int.tryParse(map['id'].toString()) ?? 0,
      description: map['description'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isCompleted: map['isCompleted'] == 1,
      isFavorite: map['isFavorite'] == 1,
      type: map['type'] ?? 'General', // Mặc định 'General' nếu không có
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'type': type, // Lưu type vào database
    };
  }
}
