import 'package:flutter/material.dart';
import '../../models/trainer_model.dart';
import '../../services/database_service.dart';

class CreateTestScreen extends StatefulWidget {
  final HubEvent event;
  const CreateTestScreen({super.key, required this.event});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final List<TestQuestion> _questions = [];
  final _questionController = TextEditingController();
  final DatabaseService _db = DatabaseService();

  void _addQuestion() {
    if (_questionController.text.isEmpty) return;
    
    final newQuestion = TestQuestion(
      question: _questionController.text.trim(),
      type: 'subjective',
    );

    setState(() {
      _questions.add(newQuestion);
      _questionController.clear();
    });
  }

  Future<void> _finishTest() async {
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one question")));
      return;
    }

    final updatedEvent = HubEvent(
      id: widget.event.id,
      title: widget.event.title,
      description: widget.event.description,
      dateTime: widget.event.dateTime,
      type: widget.event.type,
      branch: widget.event.branch,
      meetLink: widget.event.meetLink,
      questions: _questions,
      isCompleted: true,
    );

    await _db.scheduleEvent(updatedEvent);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Create Test: ${widget.event.title}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_add, color: Color(0xFFFF5252), size: 30),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Step 2: Add Questions", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Questions Added: ${_questions.length}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text("ADD NEW QUESTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black54)),
            const SizedBox(height: 15),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _questionController,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: "Question Description",
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintText: "Enter the question here...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text("ADD TO PAPER", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            if (_questions.isNotEmpty) ...[
              const Text("QUESTION PAPER PREVIEW", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black54)),
              const SizedBox(height: 15),
              ..._questions.asMap().entries.map((entry) {
                int idx = entry.key;
                TestQuestion q = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Question ${idx + 1}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF5252), fontSize: 12)),
                        const SizedBox(height: 8),
                        Text(q.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                        const SizedBox(height: 15),
                        Container(
                          height: 40,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Text("Student response space will appear here", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _finishTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, 
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
                shadowColor: Colors.black.withValues(alpha: 0.4),
              ),
              child: const Text("POST QUESTION PAPER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
