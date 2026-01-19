/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class PlanItem implements _i1.SerializableModel {
  PlanItem._({
    required this.start,
    required this.end,
    required this.title,
  });

  factory PlanItem({
    required String start,
    required String end,
    required String title,
  }) = _PlanItemImpl;

  factory PlanItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return PlanItem(
      start: jsonSerialization['start'] as String,
      end: jsonSerialization['end'] as String,
      title: jsonSerialization['title'] as String,
    );
  }

  String start;

  String end;

  String title;

  /// Returns a shallow copy of this [PlanItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PlanItem copyWith({
    String? start,
    String? end,
    String? title,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PlanItem',
      'start': start,
      'end': end,
      'title': title,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PlanItemImpl extends PlanItem {
  _PlanItemImpl({
    required String start,
    required String end,
    required String title,
  }) : super._(
         start: start,
         end: end,
         title: title,
       );

  /// Returns a shallow copy of this [PlanItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PlanItem copyWith({
    String? start,
    String? end,
    String? title,
  }) {
    return PlanItem(
      start: start ?? this.start,
      end: end ?? this.end,
      title: title ?? this.title,
    );
  }
}
