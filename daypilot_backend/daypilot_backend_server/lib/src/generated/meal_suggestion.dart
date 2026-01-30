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
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:daypilot_backend_server/src/generated/protocol.dart' as _i2;

abstract class MealSuggestion
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  MealSuggestion._({
    required this.label,
    required this.title,
    required this.desc,
    required this.ingredients,
  });

  factory MealSuggestion({
    required String label,
    required String title,
    required String desc,
    required List<String> ingredients,
  }) = _MealSuggestionImpl;

  factory MealSuggestion.fromJson(Map<String, dynamic> jsonSerialization) {
    return MealSuggestion(
      label: jsonSerialization['label'] as String,
      title: jsonSerialization['title'] as String,
      desc: jsonSerialization['desc'] as String,
      ingredients: _i2.Protocol().deserialize<List<String>>(
        jsonSerialization['ingredients'],
      ),
    );
  }

  String label;

  String title;

  String desc;

  List<String> ingredients;

  /// Returns a shallow copy of this [MealSuggestion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MealSuggestion copyWith({
    String? label,
    String? title,
    String? desc,
    List<String>? ingredients,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MealSuggestion',
      'label': label,
      'title': title,
      'desc': desc,
      'ingredients': ingredients.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MealSuggestion',
      'label': label,
      'title': title,
      'desc': desc,
      'ingredients': ingredients.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _MealSuggestionImpl extends MealSuggestion {
  _MealSuggestionImpl({
    required String label,
    required String title,
    required String desc,
    required List<String> ingredients,
  }) : super._(
         label: label,
         title: title,
         desc: desc,
         ingredients: ingredients,
       );

  /// Returns a shallow copy of this [MealSuggestion]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MealSuggestion copyWith({
    String? label,
    String? title,
    String? desc,
    List<String>? ingredients,
  }) {
    return MealSuggestion(
      label: label ?? this.label,
      title: title ?? this.title,
      desc: desc ?? this.desc,
      ingredients: ingredients ?? this.ingredients.map((e0) => e0).toList(),
    );
  }
}
