import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/student_model.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  String _generatedStudentId = "Loading...";
  bool _obscurePassword = true;
  bool _agreeTerms = false;
  String _selectedRole = "Student";

  @override
  void initState() {
    super.initState();
    _fetchNextId();
  }

  Future<void> _fetchNextId() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('metadata').doc('student_counter').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() => _generatedStudentId = "SH-${data['current'] + 1}");
      } else {
        setState(() => _generatedStudentId = "SH-1001");
      }
    } catch (e) {
      setState(() => _generatedStudentId = "SH-XXXX");
    }
  }

  void _handleRegister() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please agree to the Terms & Conditions")));
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final db = DatabaseService();
    
    // Get the final incremented ID
    String finalId = await db.getNextStudentId();

    StudentModel newStudent = StudentModel(
      uid: '', 
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      studentId: finalId,
      branch: "Franchise Management",
      role: _selectedRole.toLowerCase(),
    );

    String? error = await auth.register(_emailController.text.trim(), _passwordController.text.trim(), newStudent);

    if (error != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.redAccent));
    } else {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient Accents
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [const Color(0xFFFF5252).withOpacity(0.15), Colors.transparent]),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black)
                  ),
                  
                  const Text(
                    "Create",
                    style: TextStyle(color: Colors.black, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  const Text(
                    "Account",
                    style: TextStyle(color: Color(0xFFFF5252), fontSize: 44, fontWeight: FontWeight.w900, height: 0.9),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "ASSIGNED ID: $_generatedStudentId",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(width: 60, height: 6, color: Colors.black),
                  const SizedBox(height: 15),

                  // Role Selection
                  Row(
                    children: [
                      _roleChip("Student"),
                      const SizedBox(width: 10),
                      _roleChip("Trainer"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Heroic Form Card
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF000000), Color(0xFFFF5252)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          _buildInputField(_nameController, "Full Name", Icons.person_outline),
                          const SizedBox(height: 18),
                          _buildInputField(_emailController, "Email Address", Icons.alternate_email),
                          const SizedBox(height: 18),
                          _buildInputField(_phoneController, "Phone Number", Icons.phone_android_rounded),
                          const SizedBox(height: 18),
                          _buildInputField(_passwordController, "Password", Icons.lock_open_rounded, isPassword: true),
                          const SizedBox(height: 18),
                          _buildInputField(_confirmPasswordController, "Confirm Password", Icons.verified_user_outlined, isPassword: true),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Checkbox(
                        value: _agreeTerms,
                        activeColor: const Color(0xFFFF5252),
                        onChanged: (v) => setState(() => _agreeTerms = v!),
                      ),
                      const Text("I agree to the ", style: TextStyle(fontWeight: FontWeight.w500)),
                      const Text("Terms & Conditions", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900)),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // Heroic Register Button
                  GestureDetector(
                    onTap: auth.isLoading ? null : _handleRegister,
                    child: Container(
                      width: double.infinity,
                      height: 65,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFF000000)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Center(
                        child: auth.isLoading 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Text(
                              "CREATE ACCOUNT", 
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)
                            ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          text: "Already a member? ",
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                          children: [
                            TextSpan(
                              text: "LOG IN", 
                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5252) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? const Color(0xFFFF5252) : Colors.grey[300]!),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.3), blurRadius: 8)] : null,
          ),
          child: Center(
            child: Text(
              role.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: const Color(0xFFFF5252), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
