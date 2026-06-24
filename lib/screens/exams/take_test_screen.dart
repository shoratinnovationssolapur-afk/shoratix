import 'package:flutter/material.dart';
import '../../models/trainer_model.dart';
import '../../services/database_service.dart';

class TakeTestScreen extends StatefulWidget {
  final dynamic test;
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
    // Here you would normally save the answers to Firestore
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Test Submitted Successfully!"), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.test.title, style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TEST INSTRUCTIONS", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  const Text(
                    "Please answer all questions in the space provided. Ensure your responses are concise and clear.",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            ...widget.test.questions.asMap().entries.map((entry) {
              int idx = entry.key;
              TestQuestion q = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${idx + 1}.", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF5252), fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("YOUR ANSWER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _answerControllers[idx],
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Type your answer here...",
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 5,
              ),
              child: const Text("SUBMIT TEST", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
