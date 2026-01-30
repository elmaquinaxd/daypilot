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
import 'meal_suggestion.dart' as _i2;
import 'package:daypilot_backend_client/src/protocol/protocol.dart' as _i3;

abstract class MealSuggestionsResponse implements _i1.SerializableModel {
  MealSuggestionsResponse._({
    required this.note,
    required this.items,
  });

  factory MealSuggestionsResponse({
    required String note,
    required List<_i2.MealSuggestion> items,
  }) = _MealSuggestionsResponseImpl;

  factory MealSuggestionsResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return MealSuggestionsResponse(
      note: jsonSerialization['note'] as String,
      items: _i3.Protocol().deserialize<List<_i2.MealSuggestion>>(
        jsonSerialization['items'],
      ),
    );
  }

  String note;

  List<_i2.MealSuggestion> items;

  /// Returns a shallow copy of this [MealSuggestionsResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MealSuggestionsResponse copyWith({
    String? note,
    List<_i2.MealSuggestion>? items,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MealSuggestionsResponse',
      'note': note,
      'items': items.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _MealSuggestionsResponseImpl extends MealSuggestionsResponse {
  _MealSuggestionsResponseImpl({
    required String note,
    required List<_i2.MealSuggestion> items,
  }) : super._(
         note: note,
         items: items,
       );

  /// Returns a shallow copy of this [MealSuggestionsResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MealSuggestionsResponse copyWith({
    String? note,
    List<_i2.MealSuggestion>? items,
  }) {
    return MealSuggestionsResponse(
      note: note ?? this.note,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
    );
  }
}
