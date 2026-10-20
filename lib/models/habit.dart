/// Which routine a habit belongs to.
enum RoutineType { morning, evening }

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.routine,
  });

  final String id;
  final String name;
  final String emoji;
  final RoutineType routine;

  Habit copyWith({String? name, String? emoji, RoutineType? routine}) {
    return Habit(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      routine: routine ?? this.routine,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'routine': routine.name,
      };

  factory Habit.fromMap(Map<dynamic, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String? ?? '🌸',
      routine: map['routine'] == RoutineType.evening.name
          ? RoutineType.evening
          : RoutineType.morning,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Habit && other.id == id && other.name == name && other.emoji == emoji && other.routine == routine;

  @override
  int get hashCode => Object.hash(id, name, emoji, routine);
}
