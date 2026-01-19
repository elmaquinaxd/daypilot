import 'package:flutter/material.dart';
import 'package:daypilot_backend_client/daypilot_backend_client.dart';

late Client client;

void main() {
  client = Client('http://localhost:8080/');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PlannerPage(),
    );
  }
}

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final _controller = TextEditingController(text: 'Gym, edit video, client call');

  bool loading = false;
  String? error;

  PlanResponse? plan;

  Future<void> generatePlan() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final rawTasks = _controller.text.trim();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _section(String title, List<PlanItem> items) {
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('- (empty)')
            else
              ...items.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${p.start}-${p.end}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p.title)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final note = plan?.note;

    return Scaffold(
      appBar: AppBar(title: const Text('DayPilot')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Today’s tasks',
                hintText: 'e.g. Gym, edit video, client call',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : generatePlan,
                child: Text(loading ? 'Generating...' : 'Generate plan'),
              ),
            ),

            // Área de resultados
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  if (error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Error: $error',
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    )
                  else if (plan == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Enter your tasks and tap "Generate plan".'),
                      ),
                    )
                  else ...[
                    if (note != null && note.trim().isNotEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            note,
                            style: const TextStyle(fontSize: 14, height: 1.35),
                          ),
                        ),
                      ),
                    _section('FOCUS', plan!.focusPlan),
                    _section('CHILL', plan!.chillPlan),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}