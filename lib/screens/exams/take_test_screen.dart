import 'package:flutter/material.dart';
import '../../models/trainer_model.dart';
import '../../services/database_service.dart';

class TakeTestScreen extends StatefulWidget {
  final HubEvent test;
  const TakeTestScreen({super.key, required this.test});

  @override
  State<TakeTestScreen> createState() => _TakeTestScreenState();
}

class _TakeTestScreenState extends State<TakeTestScreen> {
  final List<TextEditingController> _answerControllers = [];

  @override
  void initState() {
    super.initState();
    for (var _ in widget.test.questions) {
      _answerControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (var c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitTest() async {
    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Test Submitted Successfully!"), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.test.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("EXAMINATION GUIDELINES", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  const Text(
                    "Please answer all questions clearly. Your responses are being recorded and will be evaluated by your trainer.",
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 35),
            
            ...widget.test.questions.asMap().entries.map((entry) {
              int idx = entry.key;
              TestQuestion q = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${idx + 1}.", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF5252), fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _answerControllers[idx],
                      maxLines: 5,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: "Enter your answer here...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.black, width: 1.2)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 20),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(colors: [Colors.black, Color(0xFF333333)]),
              ),
              child: ElevatedButton(
                onPressed: _submitTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("SUBMIT EXAMINATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
