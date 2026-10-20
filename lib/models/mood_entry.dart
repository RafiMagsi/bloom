class MoodEntry {
  MoodEntry({required this.date, required this.moodIndex, this.note = ''});

  final DateTime date;
  final int moodIndex;
  final String note;

  Map<String, dynamic> toMap() => {
        'date': date.millisecondsSinceEpoch,
        'moodIndex': moodIndex,
        'note': note,
      };

  factory MoodEntry.fromMap(Map<dynamic, dynamic> map) => MoodEntry(
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        moodIndex: map['moodIndex'] as int,
        note: map['note'] as String? ?? '',
      );
}
