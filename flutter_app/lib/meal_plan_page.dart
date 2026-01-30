import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart' show client;
import 'package:daypilot_backend_client/daypilot_backend_client.dart';

class MealPlanPage extends StatefulWidget {
  final String? tasks;

  const MealPlanPage({super.key, this.tasks});

  @override
  State<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends State<MealPlanPage> {
  final _prefs = TextEditingController(
    text: 'High protein, 2000 kcal, quick meals, no dairy',
  );

  bool loading = false;
  String? error;
  MealSuggestionsResponse? mealPlan;

  int minutes = 15;

  final List<String> _presetTokens = const [
    'quick meals',
    'high protein',
    'no dairy',
    'low sugar',
    'vegetarian',
  ];

  bool _smartDefaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _applySmartDefaultsFromTasksOnce();
  }

  void _applySmartDefaultsFromTasksOnce() {
    if (_smartDefaultsApplied) return;
    _smartDefaultsApplied = true;

    final tasks = (widget.tasks ?? '').toLowerCase();

    if (tasks.trim().isEmpty) return;

    final gymWords = ['gym', 'workout', 'training', 'lift', 'weights', 'run', 'cardio'];
    final busyWords = ['work', 'study', 'meeting', 'class', 'school', 'shift', 'errand', 'deadline'];

    final hasGym = gymWords.any(tasks.contains);
    final hasBusy = busyWords.any(tasks.contains);

  
    final parts = _prefs.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    bool containsToken(String t) =>
        parts.any((p) => p.toLowerCase() == t.toLowerCase());

    if (hasGym && !containsToken('high protein')) {
      parts.add('high protein');
    }
    if (hasBusy && !containsToken('quick meals')) {
      parts.add('quick meals');
    }

  
    final newText = parts.join(', ');
    if (newText != _prefs.text) {
      _prefs.text = newText;
      _prefs.selection = TextSelection.fromPosition(
        TextPosition(offset: _prefs.text.length),
      );
      setState(() {});
    }
  }

  IconData _mealIcon(String label) {
    switch (label.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.local_dining;
    }
  }

  String _prefsLower() => _prefs.text.toLowerCase();
  bool _hasToken(String token) => _prefsLower().contains(token.toLowerCase());

  void _toggleToken(String token) {
    final current = _prefs.text.trim();

    final parts = current
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final exists = parts.any((p) => p.toLowerCase() == token.toLowerCase());

    if (exists) {
      parts.removeWhere((p) => p.toLowerCase() == token.toLowerCase());
    } else {
      parts.add(token);
    }

    _prefs.text = parts.join(', ');
    _prefs.selection = TextSelection.fromPosition(
      TextPosition(offset: _prefs.text.length),
    );
    setState(() {});
  }

  void _clearPrefs() {
    _prefs.text = '';
    _prefs.selection = TextSelection.fromPosition(
      const TextPosition(offset: 0),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  Future<void> generateMealPlan() async {
    setState(() {
      loading = true;
      error = null;
      mealPlan = null;
    });

    final prefsRaw = _prefs.text.trim();
    if (prefsRaw.length < 4) {
      setState(() {
        loading = false;
        error = 'Write some preferences (e.g. high protein, no dairy, quick meals).';
      });
      return;
    }

    try {
      final tasks = (widget.tasks ?? '').trim();
      final result = await client.meal.generateMealSuggestions(
        tasks,
        prefsRaw,
        minutes,
      );

      if (!mounted) return;
      setState(() {
        mealPlan = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        mealPlan = null;
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openRecipe(String mealTitle) async {
    final q = Uri.encodeComponent('$mealTitle easy quick recipe');
    final url = Uri.parse('https://www.youtube.com/results?search_query=$q');

    final ok = await launchUrl(
      url,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  Widget _noteCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(text, style: const TextStyle(height: 1.35)),
      ),
    );
  }

  Widget _errorCard(String text) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error: $text', style: TextStyle(color: Colors.red.shade800)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: loading ? null : generateMealPlan,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mealCard(MealSuggestion m) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_mealIcon(m.label), size: 20),
                const SizedBox(width: 8),
                Chip(
                  label: Text(m.label),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Open on YouTube',
                  onPressed: () => openRecipe(m.title),
                  icon: const Icon(Icons.open_in_new),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              m.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(m.desc, style: const TextStyle(height: 1.3)),
            if (m.ingredients.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: m.ingredients
                    .take(8)
                    .map((x) => Chip(label: Text(x), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skeletonLine({double h = 12, double w = double.infinity}) {
    return Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _mealSkeletonCard(int index) {
    // Para que no todas las cards se vean idénticas
    final titleW = index.isEven ? 220.0 : 180.0;
    final descW = index.isEven ? 260.0 : 240.0;

    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.black12,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const SizedBox(width: 70, height: 10),
                ),
                const Spacer(),
                const Icon(Icons.open_in_new, color: Colors.black26),
              ],
            ),
            const SizedBox(height: 10),
            _skeletonLine(h: 14, w: titleW),
            const SizedBox(height: 10),
            _skeletonLine(h: 12, w: descW),
            const SizedBox(height: 8),
            _skeletonLine(h: 12, w: descW - 40),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(
                5,
                (i) => Container(
                  width: 60 + (i * 6).toDouble(),
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingSkeletonList() {
    return Expanded(
      child: ListView(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Generating suggestions…'),
                ],
              ),
            ),
          ),
          ...List.generate(4, _mealSkeletonCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksText = (widget.tasks ?? '').trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Suggestions'),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FAFC),
                    Color(0xFFF1F5F9),
                    Color(0xFFF8FAFC),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (tasksText.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's tasks",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(tasksText),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: _prefs,
                    enabled: !loading,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Preferences',
                      hintText: 'high protein, quick meals, no dairy...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text('Presets:'),
                      const Spacer(),
                      TextButton(
                        onPressed: loading ? null : _clearPrefs,
                        child: const Text('Clear prefs'),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presetTokens.map((t) {
                        final selected = _hasToken(t);
                        return FilterChip(
                          selected: selected,
                          label: Text(t),
                          onSelected: loading ? null : (_) => _toggleToken(t),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Text('Time available:'),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: minutes,
                        items: const [
                          DropdownMenuItem(value: 10, child: Text('10 min')),
                          DropdownMenuItem(value: 15, child: Text('15 min')),
                          DropdownMenuItem(value: 20, child: Text('20 min')),
                          DropdownMenuItem(value: 30, child: Text('30 min')),
                        ],
                        onChanged: loading ? null : (v) => setState(() => minutes = v ?? 15),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : generateMealPlan,
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Generate meal suggestions'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (loading)
                    _loadingSkeletonList()
                  else if (error != null)
                    _errorCard(error!)
                  else if (mealPlan == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Busy day? Write your constraints and generate quick meals for today.'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        children: [
                          if (mealPlan!.note.trim().isNotEmpty) _noteCard(mealPlan!.note),
                          ...mealPlan!.items.map(_mealCard),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}