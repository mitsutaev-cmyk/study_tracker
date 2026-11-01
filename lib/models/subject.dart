int toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

class Subject {
  final int id;
  final String name;
  final String color;
  final int totalSeconds;

  const Subject({
    required this.id,
    required this.name,
    required this.color,
    this.totalSeconds = 0,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: toInt(json['id']),
        name: (json['name'] ?? '').toString(),
        color: (json['color'] ?? '#2196F3').toString(),
        totalSeconds: toInt(json['total_seconds']),
      );

  Subject copyWith({String? name, String? color, int? totalSeconds}) => Subject(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        totalSeconds: totalSeconds ?? this.totalSeconds,
      );
}
