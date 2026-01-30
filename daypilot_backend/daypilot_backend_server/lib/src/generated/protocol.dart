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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'greetings/greeting.dart' as _i5;
import 'meal_suggestion.dart' as _i6;
import 'meal_suggestions_response.dart' as _i7;
import 'plan_item.dart' as _i8;
import 'plan_response.dart' as _i9;
export 'greetings/greeting.dart';
export 'meal_suggestion.dart';
export 'meal_suggestions_response.dart';
export 'plan_item.dart';
export 'plan_response.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i5.Greeting) {
      return _i5.Greeting.fromJson(data) as T;
    }
    if (t == _i6.MealSuggestion) {
      return _i6.MealSuggestion.fromJson(data) as T;
    }
    if (t == _i7.MealSuggestionsResponse) {
      return _i7.MealSuggestionsResponse.fromJson(data) as T;
    }
    if (t == _i8.PlanItem) {
      return _i8.PlanItem.fromJson(data) as T;
    }
    if (t == _i9.PlanResponse) {
      return _i9.PlanResponse.fromJson(data) as T;
    }
    if (t == _i1.getType<_i5.Greeting?>()) {
      return (data != null ? _i5.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.MealSuggestion?>()) {
      return (data != null ? _i6.MealSuggestion.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.MealSuggestionsResponse?>()) {
      return (data != null ? _i7.MealSuggestionsResponse.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.PlanItem?>()) {
      return (data != null ? _i8.PlanItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.PlanResponse?>()) {
      return (data != null ? _i9.PlanResponse.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i6.MealSuggestion>) {
      return (data as List)
              .map((e) => deserialize<_i6.MealSuggestion>(e))
              .toList()
          as T;
    }
    if (t == List<_i8.PlanItem>) {
      return (data as List).map((e) => deserialize<_i8.PlanItem>(e)).toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i5.Greeting => 'Greeting',
      _i6.MealSuggestion => 'MealSuggestion',
      _i7.MealSuggestionsResponse => 'MealSuggestionsResponse',
      _i8.PlanItem => 'PlanItem',
      _i9.PlanResponse => 'PlanResponse',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'daypilot_backend.',
        '',
      );
    }

    switch (data) {
      case _i5.Greeting():
        return 'Greeting';
      case _i6.MealSuggestion():
        return 'MealSuggestion';
      case _i7.MealSuggestionsResponse():
        return 'MealSuggestionsResponse';
      case _i8.PlanItem():
        return 'PlanItem';
      case _i9.PlanResponse():
        return 'PlanResponse';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i5.Greeting>(data['data']);
    }
    if (dataClassName == 'MealSuggestion') {
      return deserialize<_i6.MealSuggestion>(data['data']);
    }
    if (dataClassName == 'MealSuggestionsResponse') {
      return deserialize<_i7.MealSuggestionsResponse>(data['data']);
    }
    if (dataClassName == 'PlanItem') {
      return deserialize<_i8.PlanItem>(data['data']);
    }
    if (dataClassName == 'PlanResponse') {
      return deserialize<_i9.PlanResponse>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'daypilot_backend';
}
