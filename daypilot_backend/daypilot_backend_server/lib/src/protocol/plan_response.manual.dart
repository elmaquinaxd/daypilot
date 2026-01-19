import 'package:serverpod/serverpod.dart';
import 'plan_item.dart';

class PlanResponse extends SerializableEntity {
  PlanResponse({
    required this.focusPlan,
    required this.chillPlan,
    required this.note,
  });

  List<PlanItem> focusPlan;
  List<PlanItem> chillPlan;
  String note;

  @override
  Map<String, dynamic> toJson() => {
        'focusPlan': focusPlan.map((e) => e.toJson()).toList(),
        'chillPlan': chillPlan.map((e) => e.toJson()).toList(),
        'note': note,
      };

  @override
  void fromJson(Map<String, dynamic> json) {
    focusPlan = (json['focusPlan'] as List)
        .map((e) => PlanItem(start: '', end: '', title: '')..fromJson(e))
        .toList();

    chillPlan = (json['chillPlan'] as List)
        .map((e) => PlanItem(start: '', end: '', title: '')..fromJson(e))
        .toList();

    note = json['note'] as String;
  }
}