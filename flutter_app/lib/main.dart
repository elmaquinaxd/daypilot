import 'package:flutter/material.dart';
import 'package:daypilot_backend_client/daypilot_backend_client.dart';

import 'meal_plan_page.dart';

late Client client;
const accentColor = Color(0xFF1E88E5);

void main() {
  client = Client(
  'http://localhost:8080/',
  connectionTimeout: const Duration(seconds: 60),
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.black,
      ),
      home: const PlannerPage(),
      routes: {
        '/meals': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final tasks = args is String ? args : null;
          return MealPlanPage(tasks: tasks);
        },
      },
    );
  }
}

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final _controller =
      TextEditingController(text: 'Gym 09:00 60min, work, study');

  bool loading = false;
  String? error;
  PlanResponse? plan;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> generatePlan() async {
    setState(() {
      loading = true;
      error = null;
      plan = null;
    });

    final rawTasks = _controller.text.trim();
    if (rawTasks.isEmpty || rawTasks.length < 3) {
      setState(() {
        loading = false;
        error =
            'Add tasks (e.g. "Gym 09:00 60min, meeting 14:00, groceries 30min").';
      });
      return;
    }

    final count = rawTasks
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .length;

    if (count < 2) {
      setState(() {
        loading = false;
        error = 'Add at least 2 tasks separated by commas.';
      });
      return;
    }

    try {
      final result = await client.plan.generatePlan(rawTasks);

      if (!mounted) return;
      setState(() {
        plan = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        plan = null;
        error = e.toString();
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _background() {
    return const Positioned.fill(
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
    );
  }

  Widget _tipCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Tip: be specific for the best results (e.g. "Gym 09:00 60min, meeting 14:00, groceries 30min").',
          style: TextStyle(height: 1.35),
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

  Widget _planSkeletonCard(int index) {
    final titleW = index.isEven ? 220.0 : 180.0;
    final descW = index.isEven ? 260.0 : 240.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonLine(h: 14, w: 60),
                const SizedBox(height: 8),
                _skeletonLine(h: 12, w: 50),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonLine(h: 14, w: titleW),
                  const SizedBox(height: 8),
                  _skeletonLine(h: 12, w: descW),
                ],
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
                  Text('Generating your plan…'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(6, _planSkeletonCard),
        ],
      ),
    );
  }

  Widget _planList(List<PlanItem> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No items yet.'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) =>
          PlanItemCard(item: items[i], accent: accentColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksText = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('DayPilot'),
        actions: [
          IconButton(
            tooltip: 'Meal Suggestions',
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () {
              Navigator.of(context).pushNamed('/meals', arguments: tasksText);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    enabled: !loading,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Today's tasks",
                      hintText:
                          'e.g. Gym 09:00 60min, meeting 14:00, groceries 30min',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _tipCard(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : generatePlan,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(loading ? 'Generating...' : 'Generate my day'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ✅ NEW: Loading skeleton
                  if (loading)
                    _loadingSkeletonList()
                  else
                    Expanded(
                      child: Column(
                        children: [
                          if (error != null)
                            Card(
                              color: Colors.red.shade50,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Error: $error',
                                      style:
                                          TextStyle(color: Colors.red.shade800),
                                    ),
                                    const SizedBox(height: 10),
                                    OutlinedButton.icon(
                                      onPressed: generatePlan,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (plan == null)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                    'Enter your tasks and tap "Generate my day".'),
                              ),
                            )
                          else ...[
                            if (plan!.note.trim().isNotEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    plan!.note,
                                    style: const TextStyle(height: 1.35),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Expanded(child: _planList(plan!.plan)),
                          ],
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

class PlanItemCard extends StatelessWidget {
  final PlanItem item;
  final Color accent;

  const PlanItemCard({
    super.key,
    required this.item,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 44,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.start,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                Text(
                  item.end,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}