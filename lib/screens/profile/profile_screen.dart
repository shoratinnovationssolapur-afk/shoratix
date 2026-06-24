import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final student = auth.studentModel;

    if (student == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => auth.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.red[100],
                    backgroundImage: student.profileImageUrl.isNotEmpty ? NetworkImage(student.profileImageUrl) : null,
                    child: student.profileImageUrl.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.red) : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.red,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        onPressed: () {},
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(student?.name ?? "Student", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Student ID: ${student?.studentId ?? 'N/A'}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
            
            const SizedBox(height: 30),
            
            _profileItem(Icons.email, "Email", student?.email ?? "N/A"),
            _profileItem(Icons.phone, "Phone", student?.phone ?? "N/A"),
            _profileItem(Icons.location_city, "Branch", student?.branch ?? "N/A"),
            
            const Divider(height: 40),
            
            _actionItem(Icons.card_membership, "My Certificates", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No certificates available for download yet.")));
            }),
            _actionItem(Icons.verified, "Verify Certificate", () {
              Navigator.pushNamed(context, AppRoutes.verifyCertificate);
            }),
            _actionItem(Icons.lock, "Change Password", () {}),
            _actionItem(Icons.help_outline, "Help & Support", () {}),
            _actionItem(Icons.info_outline, "About Shorat Student Hub", () {}),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
