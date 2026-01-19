import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class PlanEndpoint extends Endpoint {
  Future<PlanResponse> generatePlan(Session session, String rawTasks) async {
    final tasks = rawTasks.trim();
    if (tasks.isEmpty) {
      return PlanResponse(
        focusPlan: [],
        chillPlan: [],
        note: 'No tasks detected. Add tasks separated by commas.',
      );
    }

    final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return PlanResponse(
        focusPlan: [],
        chillPlan: [],
        note: 'GEMINI_API_KEY not set. Set it in your system env and restart the server.',
      );
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
      );

      final prompt = '''
You are a scheduling assistant.

Given these tasks: "$tasks"

Return ONLY valid JSON with this exact shape:
{
  "note": "string",
  "focusPlan": [{"start":"HH:MM","end":"HH:MM","title":"string"}],
  "chillPlan": [{"start":"HH:MM","end":"HH:MM","title":"string"}]
}

Rules:
- Use 24h format HH:MM.
- Provide 3-6 items in each list.
- Times must be realistic and strictly increasing in each list.
- Titles should reference the given tasks.
''';

      Map<String, dynamic> buildBody() => {
            "contents": [
              {
                "role": "user",
                "parts": [
                  {"text": prompt}
                ]
              }
            ],
            "generationConfig": {
              "temperature": 0.3,
              "maxOutputTokens": 1200,
              "responseMimeType": "application/json",
              // Si el modelo/tu cuenta lo soporta, esto reduce muchísimo respuestas raras.
              "responseSchema": {
                "type": "OBJECT",
                "properties": {
                  "note": {"type": "STRING"},
                  "focusPlan": {
                    "type": "ARRAY",
                    "items": {
                      "type": "OBJECT",
                      "properties": {
                        "start": {"type": "STRING"},
                        "end": {"type": "STRING"},
                        "title": {"type": "STRING"}
                      },
                      "required": ["start", "end", "title"]
                    }
                  },
                  "chillPlan": {
                    "type": "ARRAY",
                    "items": {
                      "type": "OBJECT",
                      "properties": {
                        "start": {"type": "STRING"},
                        "end": {"type": "STRING"},
                        "title": {"type": "STRING"}
                      },
                      "required": ["start", "end", "title"]
                    }
                  }
                },
                "required": ["note", "focusPlan", "chillPlan"]
              }
            }
          };

      Future<Map<String, dynamic>> doRequest() async {
        final resp = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(buildBody()),
        );

        if (resp.statusCode < 200 || resp.statusCode >= 300) {
          session.log(
            'Gemini error ${resp.statusCode}: ${resp.body}',
            level: LogLevel.error,
          );
          throw Exception('Gemini HTTP ${resp.statusCode}');
        }

        // Temporary DEBUG
        // session.log('RAW HTTP BODY:\n${resp.body}');

        return jsonDecode(resp.body) as Map<String, dynamic>;
      }

      // 1) request + retry if it appear trucated
      Map<String, dynamic> decoded = await doRequest();
      String rawModelText = _extractModelText(decoded);
      String cleaned = _stripCodeFences(rawModelText);

      if (cleaned.isNotEmpty && _extractFirstJsonObject(cleaned) == null) {
        session.log('Gemini looked truncated, retrying once...', level: LogLevel.warning);
        decoded = await doRequest();
        rawModelText = _extractModelText(decoded);
        cleaned = _stripCodeFences(rawModelText);
      }

      session.log('CLEANED:\n$cleaned');

      // 2) decode JSON
      dynamic planDecoded;
      try {
        planDecoded = jsonDecode(cleaned);
      } catch (_) {
        final extracted = _extractFirstJsonObject(cleaned);
        if (extracted == null) {
          session.log(
            'Gemini response appears truncated or not JSON.\nRAW:\n$rawModelText',
            level: LogLevel.error,
          );
          return PlanResponse(
            focusPlan: [],
            chillPlan: [],
            note: 'Gemini returned a truncated response. Try again.',
          );
        }
        session.log('EXTRACTED JSON:\n$extracted');
        planDecoded = jsonDecode(extracted);
      }

      Map<String, dynamic> planJson;
      if (planDecoded is List && planDecoded.isNotEmpty) {
        planJson = (planDecoded.first as Map).cast<String, dynamic>();
      } else if (planDecoded is Map) {
        planJson = planDecoded.cast<String, dynamic>();
      } else {
        session.log(
          'Unexpected JSON type: ${planDecoded.runtimeType}\n$planDecoded',
          level: LogLevel.error,
        );
        return PlanResponse(
          focusPlan: [],
          chillPlan: [],
          note: 'Gemini returned unexpected JSON format. Check server logs.',
        );
      }

      final note = (planJson['note'] ?? 'Plan generated.').toString();
      final focusPlan = _parseItems(planJson['focusPlan']);
      final chillPlan = _parseItems(planJson['chillPlan']);

      return PlanResponse(
        focusPlan: focusPlan,
        chillPlan: chillPlan,
        note: note,
      );
    } catch (e, st) {
      session.log('Gemini exception: $e\n$st', level: LogLevel.error);
      return PlanResponse(
        focusPlan: [],
        chillPlan: [],
        note: 'Gemini exception: $e',
      );
    }
  }

  // ---------------- Helpers ----------------

  static String _extractModelText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is List && candidates.isNotEmpty) {
      final first = candidates.first;
      if (first is Map) {
        final content = first['content'];
        if (content is Map) {
          final parts = content['parts'];
          if (parts is List && parts.isNotEmpty) {
            final p0 = parts.first;
            if (p0 is Map && p0['text'] != null) {
              return p0['text'].toString();
            }
          }
        }
      }
    }
    return '';
  }

  static String _stripCodeFences(String s) {
    var cleaned = s.trim();
    cleaned = cleaned
        .replaceAll(RegExp(r'```(?:json)?', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();
    return cleaned;
  }

  static String? _extractFirstJsonObject(String s) {
    final start = s.indexOf('{');
    if (start == -1) return null;

    var depth = 0;
    for (var i = start; i < s.length; i++) {
      final ch = s[i];
      if (ch == '{') depth++;
      if (ch == '}') depth--;
      if (depth == 0) {
        return s.substring(start, i + 1);
      }
    }
    return null;
  }

  static List<PlanItem> _parseItems(dynamic list) {
    if (list is! List) return [];
    return list.map((e) {
      if (e is! Map) {
        return PlanItem(start: '', end: '', title: e.toString());
      }
      final m = e.cast<String, dynamic>();
      return PlanItem(
        start: (m['start'] ?? '').toString(),
        end: (m['end'] ?? '').toString(),
        title: (m['title'] ?? '').toString(),
      );
    }).toList();
  }
}