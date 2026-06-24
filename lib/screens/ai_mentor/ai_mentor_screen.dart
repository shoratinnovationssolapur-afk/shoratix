import 'package:flutter/material.dart';

class AIMentorScreen extends StatefulWidget {
  const AIMentorScreen({super.key});

  @override
  State<AIMentorScreen> createState() => _AIMentorScreenState();
}

class _AIMentorScreenState extends State<AIMentorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "assistant", "content": "Hello! I am Akshay, your AI Mentor. How can I help you with your studies today?"}
  ];

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({"role": "user", "content": _controller.text});
      // Mock response
      _messages.add({"role": "assistant", "content": "I'm thinking... (Integrating Gemini/OpenAI soon!)"});
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Akshay AI Mentor"),
        backgroundColor: Colors.red[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.red[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(msg["content"]!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Ask me anything...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: Colors.red[700],
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
