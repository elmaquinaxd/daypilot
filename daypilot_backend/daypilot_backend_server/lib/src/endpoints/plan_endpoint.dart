import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;

import '../generated/protocol.dart';

class PlanEndpoint extends Endpoint {
  Future<PlanResponse> generatePlan(Session session, String rawTasks) async {
    final tasks = rawTasks.trim();

    if (tasks.isEmpty) {
      return PlanResponse(note: 'No tasks detected. Add tasks separated by commas.', plan: []);
    }

    final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return _fallbackPlan(tasks, note: 'AI key not set. Showing a local parsed plan.');
    }

    //gemini 2.5
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final prompt = _buildPrompt(tasks);

    // 1) attempt
    final first = await _callGemini( session, url, prompt, temperature: 0.1, maxOutputTokens: 4096,);
    if (first != null) return first;

    // 2) retry ultra strict
    final retryPrompt = 'Return ONLY JSON. No extra text.\n$prompt';
    final second = await _callGemini(session, url, retryPrompt, temperature: 0.0, maxOutputTokens: 2048);
    if (second != null) return second;

    // 3) fallback
    return _fallbackPlan(tasks, note: 'AI unavailable. Showing a local parsed plan.');
  }

String _buildPrompt(String tasks) {
  return '''
You are an intelligent daily planner.

Goal:
OPTIMIZE the day schedule, not just list tasks.

Return ONLY valid minified JSON.

Schema:
{"note":"string","plan":[{"start":"HH:MM","end":"HH:MM","title":"string"}]}

Planning rules:
- You are an intelligent day planner.
- Your job is to OPTIMIZE the schedule, not just place tasks.

- Respect fixed times IF possible.
- NEVER delete tasks.
- NEVER remove activities due to conflicts.
- If a conflict happens, SPLIT long tasks into multiple blocks.
- Long tasks (2h+) MUST be divided across the day if needed.
- All tasks MUST appear in the plan.
- Distribute work around fixed events.
- Fill gaps intelligently.
- Create the most balanced day possible.

DO NOT simply list tasks.
You must ORGANIZE and OPTIMIZE the schedule.

User input:
"$tasks"
''';
}

  Future<PlanResponse?> _callGemini(
    Session session,
    Uri url,
    String prompt, {
    required double temperature,
    required int maxOutputTokens,
  }) async {
    final reqBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": prompt}
          ]
        }
      ],
      "generationConfig": {
        "temperature": temperature,
        "maxOutputTokens": maxOutputTokens,
        "responseMimeType": "application/json"
      }
    };

    http.Response resp;
    try {
      resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reqBody), // IMPORTANT
      );
    } catch (e) {
      session.log('PLAN HTTP error: $e');
      return null;
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      session.log('PLAN Gemini HTTP ${resp.statusCode}: ${resp.body}');

      // Quota exceeded -> fallback (so demo still works)
      if (resp.statusCode == 429) return null;

      // 404 model not found -> fallback
      if (resp.statusCode == 404) return null;

      return null;
    }

    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      session.log('PLAN could not jsonDecode Gemini response body: $e');
      return null;
    }

    final text = _extractCandidateText(decoded);
    session.log('PLAN RAW TEXT:\n$text');

    final jsonString = _extractBalancedJson(text) ?? _extractBalancedJson(resp.body);
    if (jsonString == null) {
      session.log('PLAN PARSE FAILED. BODY:\n${resp.body}');
      return null;
    }

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final note = (data['note'] ?? '').toString().trim();
      final planRaw = (data['plan'] as List?) ?? const [];

      final items = <PlanItem>[];
      for (final it in planRaw) {
        if (it is! Map) continue;
        final start = (it['start'] ?? '').toString().trim();
        final end = (it['end'] ?? '').toString().trim();
        final title = (it['title'] ?? '').toString().trim();
        if (start.isEmpty || end.isEmpty || title.isEmpty) continue;
        items.add(PlanItem(start: start, end: end, title: title));
      }

      // require at least 3 items to accept
      if (items.length < 3) {
        session.log('PLAN too few items from AI: ${items.length}');
        return null;
      }

      return PlanResponse(
        note: note.isEmpty ? 'Tip: include times + durations for best results.' : note,
        plan: items,
      );
    } catch (e) {
      session.log('PLAN JSON parse error: $e');
      return null;
    }
  }

  String _extractCandidateText(Map<String, dynamic> decoded) {
    try {
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';
      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return '';
      return (parts[0]['text'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  // Extract first balanced {...} JSON block from any text
  String? _extractBalancedJson(String s) {
    final fenceStart = s.indexOf('```');
    if (fenceStart != -1) {
      final fenceEnd = s.indexOf('```', fenceStart + 3);
      if (fenceEnd != -1) {
        final inside = s.substring(fenceStart + 3, fenceEnd).trim();
        final cleaned = inside.startsWith('json') ? inside.substring(4).trim() : inside;
        final extracted = _extractBalancedJson(cleaned);
        if (extracted != null) return extracted;
      }
    }

    final start = s.indexOf('{');
    if (start == -1) return null;

    int depth = 0;
    for (int i = start; i < s.length; i++) {
      final c = s[i];
      if (c == '{') depth++;
      if (c == '}') depth--;
      if (depth == 0) return s.substring(start, i + 1).trim();
    }
    return null;
  }

  PlanResponse _fallbackPlan(String tasks, {String? note}) {
    // Very simple parser: split by commas, add 45-min blocks from 09:00
    final parts = tasks
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    int startMin = 9 * 60;
    String fmt(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

    final plan = <PlanItem>[];

    // Try to respect “HH:MM” inside items, otherwise stack them
    final timeRegex = RegExp(r'\b([01]?\d|2[0-3]):([0-5]\d)\b');
    final durRegex = RegExp(r'\b(\d{1,3})\s*min\b', caseSensitive: false);

    for (final p in parts) {
      final tm = timeRegex.firstMatch(p);
      final dm = durRegex.firstMatch(p);

      final dur = dm != null ? int.parse(dm.group(1)!) : 45;

      if (tm != null) {
        final hh = int.parse(tm.group(1)!);
        final mm = int.parse(tm.group(2)!);
        startMin = hh * 60 + mm;
      }

      final end = startMin + dur;
      plan.add(PlanItem(start: fmt(startMin), end: fmt(end), title: p.replaceAll(timeRegex, '').trim()));
      startMin = end + 10; // small buffer
      if (plan.length >= 10) break;
    }

    if (plan.isEmpty) {
      plan.add(PlanItem(start: '09:00', end: '09:30', title: 'Plan setup + priorities'));
      plan.add(PlanItem(start: '09:40', end: '10:20', title: tasks));
    }

    return PlanResponse(
      note: note ?? 'Fallback plan (AI unavailable). Use times like "Gym 09:00 60min" for best results.',
      plan: plan,
    );
  }
}