import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;

import '../generated/protocol.dart';

class MealEndpoint extends Endpoint {
  Future<MealSuggestionsResponse> generateMealSuggestions(
    Session session,
    String tasks,
    String prefs,
    int minutes,
  ) async {
    final t = tasks.trim();
    final p = prefs.trim();

    if (p.isEmpty || p.length < 4) {
      return MealSuggestionsResponse(
        note: 'Write some preferences (e.g. high protein, no dairy, quick meals).',
        items: [],
      );
    }

    final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return MealSuggestionsResponse(
        note:
            'GEMINI_API_KEY not set. Set it in your system env and restart the server.',
        items: [],
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    // PROMPT
    final prompt = '''
Return ONLY valid JSON (no markdown, no extra text).
{
  "note":"string",
  "items":[
    {"label":"Breakfast","title":"string","desc":"string","ingredients":["string"]},
    {"label":"Lunch","title":"string","desc":"string","ingredients":["string"]},
    {"label":"Dinner","title":"string","desc":"string","ingredients":["string"]},
    {"label":"Snack","title":"string","desc":"string","ingredients":["string"]}
  ]
}

Tasks: "$t"
Prefs: "$p"
Minutes per meal: $minutes

Rules:
- Exactly 4 items in order: Breakfast, Lunch, Dinner, Snack.
- desc: max 90 characters, single line.
- ingredients: 3-6 items each.
''';

    try {
      // 1) First attempt
      final result = await _callGemini(session, url, prompt,
          temperature: 0.2, maxOutputTokens: 2048);

      if (result != null) return result;

      // 2) Retry with ultra strict + more tokens
      final retryPrompt =
          'ONLY JSON. No extra text. Keep strings short.\n$prompt';

      final retry = await _callGemini(session, url, retryPrompt,
          temperature: 0.0, maxOutputTokens: 3072);

      if (retry != null) return retry;

      // 3) Fallback
      return _fallbackPlan(t, p, minutes);
    } catch (e) {
      return MealSuggestionsResponse(
        note: 'Error: ${e.toString()}',
        items: _fallbackPlan(t, p, minutes).items,
      );
    }
  }

  Future<MealSuggestionsResponse?> _callGemini(
    Session session,
    Uri url,
    String prompt, {
    required double temperature,
    required int maxOutputTokens,
  }) async {
    final body = jsonEncode({
      "contents": [
        {
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
    });

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      session.log('MEAL Gemini HTTP ${resp.statusCode}: ${resp.body}');
      return null;
    }

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;

    final finishReason = (((decoded['candidates'] as List?)?.isNotEmpty ?? false)
            ? (decoded['candidates'][0]['finishReason'] as String?)
            : null) ??
        '';

    final text = (((decoded['candidates'] as List?)?.isNotEmpty ?? false)
            ? (decoded['candidates'][0]['content']['parts'][0]['text'] as String?)
            : null) ??
        '';

    session.log('MEAL finishReason=$finishReason');
    session.log('MEAL RAW:\n$text');


    final jsonString = _extractBalancedJson(text);
    if (jsonString == null) {
      session.log('MEAL PARSE FAILED. BODY:\n${resp.body}');
      return null;
    }

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final note = (data['note'] ?? '').toString().trim();
      final itemsRaw = (data['items'] as List?) ?? const [];

      final items = <MealSuggestion>[];
      for (final it in itemsRaw) {
        if (it is! Map) continue;

        final label = (it['label'] ?? '').toString().trim();
        final title = (it['title'] ?? '').toString().trim();
        final desc = (it['desc'] ?? '').toString().trim();

        final ingRaw = (it['ingredients'] as List?) ?? const [];
        final ingredients = ingRaw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (label.isEmpty || title.isEmpty) continue;

        items.add(MealSuggestion(
          label: label,
          title: title,
          desc: desc,
          ingredients: ingredients,
        ));
      }

      if (items.length < 4) {
        session.log('MEAL returned ${items.length} items (expected 4).');
        return null;
      }

      return MealSuggestionsResponse(
        note: note.isEmpty ? 'Tap a meal to open a recipe on YouTube.' : note,
        items: items,
      );
    } catch (e) {
      session.log('MEAL JSON decode error: $e');
      return null;
    }
  }

  // Extract first balanced {...} JSON object from text
  String? _extractBalancedJson(String s) {
    final start = s.indexOf('{');
    if (start == -1) return null;

    int depth = 0;
    for (int i = start; i < s.length; i++) {
      final c = s[i];
      if (c == '{') depth++;
      if (c == '}') depth--;

      if (depth == 0) {
        return s.substring(start, i + 1).trim();
      }
    }
    return null;
  }

  MealSuggestionsResponse _fallbackPlan(String tasks, String prefs, int minutes) {
    // Fallback simple pero útil para demo (no vacío).
    final quick = minutes <= 15 ||
        prefs.toLowerCase().contains('quick') ||
        prefs.toLowerCase().contains('fast');

    return MealSuggestionsResponse(
      note:
          'Fallback plan (AI response incomplete). Tap a meal to open a recipe on YouTube.',
      items: [
        MealSuggestion(
          label: 'Breakfast',
          title: quick ? 'Egg toast + fruit' : 'Oats + fruit bowl',
          desc: quick ? '10 min. Protein + carbs.' : 'Simple and filling.',
          ingredients: ['eggs', 'bread', 'fruit', 'salt/pepper'],
        ),
        MealSuggestion(
          label: 'Lunch',
          title: quick ? 'Tuna rice bowl' : 'Chicken salad bowl',
          desc: quick ? '10–12 min with pre-cooked rice.' : 'Balanced, easy prep.',
          ingredients: ['tuna', 'rice', 'veggies', 'olive oil', 'salt'],
        ),
        MealSuggestion(
          label: 'Dinner',
          title: quick ? 'Salmon pan sear + salad' : 'Chili bowl',
          desc: quick ? '15 min. Lemon + herbs.' : 'Hearty and easy.',
          ingredients: ['salmon', 'salad mix', 'lemon', 'olive oil'],
        ),
        MealSuggestion(
          label: 'Snack',
          title: 'Nuts + yogurt/tea',
          desc: 'Fast snack. Adjust for dairy preference.',
          ingredients: ['nuts', 'tea', 'yogurt (optional)'],
        ),
      ],
    );
  }
}