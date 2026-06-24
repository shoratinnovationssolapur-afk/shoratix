import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  String _selectedRole = "student"; // student or trainer
  String _selectedBranch = "Franchise Management";

  final List<String> _branches = [
    "Franchise Management",
    "Solapur",
    "Ahilya",
    "Ahmednagar",
    "Pune"
  ];

  void _handleLogin() async {
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    
    String? error = await auth.signIn(
      _emailController.text,
      _passwordController.text,
      _selectedRole,
      _selectedBranch,
    );

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        if (_selectedRole == 'trainer') {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.trainerDashboard, (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFFFF5252).withOpacity(0.2), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset('assets/images/logo.png', height: 50),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Welcome",
                    style: TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                  const Text(
                    "BACK HUB",
                    style: TextStyle(color: Color(0xFFFF5252), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 30),

                  // Role Selector
                  Row(
                    children: [
                      _roleTab("STUDENT", "student"),
                      const SizedBox(width: 15),
                      _roleTab("TRAINER", "trainer"),
                    ],
                  ),

                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFF000000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Select Branch"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBranch,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF5252)),
                                items: _branches.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))).toList(),
                                onChanged: (v) => setState(() => _selectedBranch = v!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildLabel(_selectedRole == 'student' ? "Student ID or Email" : "Trainer Email"),
                          _buildInputField(
                            controller: _emailController,
                            hint: _selectedRole == 'student' ? "Enter ID or Email" : "Enter Trainer Email",
                            icon: Icons.alternate_email,
                          ),
                          const SizedBox(height: 20),
                          _buildLabel("Password"),
                          _buildInputField(
                            controller: _passwordController,
                            hint: "••••••••",
                            icon: Icons.lock_open_rounded,
                            isPassword: true,
                            obscureText: _obscureText,
                            onToggleVisibility: () => setState(() => _obscureText = !_obscureText),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                              child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  InkWell(
                    onTap: auth.isLoading ? null : _handleLogin,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF000000), Color(0xFFFF5252)]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: Center(
                        child: auth.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("ENTER HUB", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  if (_selectedRole == 'student')
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                      child: RichText(
                        text: const TextSpan(
                          text: "New here? ",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          children: [
                            TextSpan(text: "JOIN COMMUNITY", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, decoration: TextDecoration.underline))
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTab(String label, String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5252) : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? const Color(0xFFFF5252) : Colors.grey[300]!),
          ),
          child: Text(
            label,
            style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 10, letterSpacing: 1.5)),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)),
      child: TextField(
        controller: controller,
        obscureText: isPassword && obscureText,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, color: const Color(0xFFFF5252), size: 20),
          suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 18), onPressed: onToggleVisibility) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
