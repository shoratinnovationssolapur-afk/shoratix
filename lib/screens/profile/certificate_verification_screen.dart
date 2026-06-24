import 'package:flutter/material.dart';

class CertificateVerificationScreen extends StatefulWidget {
  const CertificateVerificationScreen({super.key});

  @override
  State<CertificateVerificationScreen> createState() => _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState extends State<CertificateVerificationScreen> {
  final _idController = TextEditingController();
  bool _isVerifying = false;

  void _verify() {
    if (_idController.text.trim().isEmpty) return;
    setState(() => _isVerifying = true);
    
    // Mock verification
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isVerifying = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Verification Successful"),
          content: const Text("This certificate (ID: SH-CERT-2023) belongs to Snehal S. for completing Java Full Stack Course."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Certificate"), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.verified_user_outlined, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Enter the Certificate ID provided on your document to verify its authenticity.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: "Certificate ID",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isVerifying ? null : _verify,
                child: _isVerifying 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("VERIFY NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
