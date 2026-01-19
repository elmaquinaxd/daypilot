import 'package:serverpod/serverpod.dart';

class PlanItem extends SerializableEntity {
  PlanItem({
    required this.start,
    required this.end,
    required this.title,
  });

  String start;
  String end;
  String title;

  @override
  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'title': title,
      };

  @override
  void fromJson(Map<String, dynamic> json) {
    start = json['start'] as String;
    end = json['end'] as String;
    title = json['title'] as String;
  }
}