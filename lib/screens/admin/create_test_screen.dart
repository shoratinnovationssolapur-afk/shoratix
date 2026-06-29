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
  bool _isPosting = false;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one question"), backgroundColor: Colors.orange)
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Test Paper Posted Successfully!"), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post: ${e.toString()}"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Question Paper", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFF5252),
                    child: Icon(Icons.quiz_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.event.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Branch: ${widget.event.branch} • Questions: ${_questions.length}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 35),
            
            const Text("ADD NEW QUESTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey)),
            const SizedBox(height: 15),
            
            TextField(
              controller: _questionController,
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write your question here...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5)),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("ADD TO PAPER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
            ),
            
            const SizedBox(height: 40),
            
            if (_questions.isNotEmpty) ...[
              const Text("QUESTION PAPER PREVIEW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.grey)),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Question ${index + 1}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF5252), fontSize: 12)),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
                              onPressed: () => setState(() => _questions.removeAt(index)),
                            ),
                          ],
                        ),
                        Text(_questions[index].question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                      ],
                    ),
                  );
                },
              ),
            ],
            
            const SizedBox(height: 40),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(colors: [Color(0xFFFF5252), Color(0xFFD32F2F)]),
                boxShadow: [BoxShadow(color: const Color(0xFFFF5252).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: ElevatedButton(
                onPressed: _isPosting ? null : _finishTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isPosting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("POST QUESTION PAPER", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
