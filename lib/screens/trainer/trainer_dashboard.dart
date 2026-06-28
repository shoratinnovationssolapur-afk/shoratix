import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../models/trainer_model.dart';

class TrainerDashboard extends StatefulWidget {
  const TrainerDashboard({super.key});

  @override
  State<TrainerDashboard> createState() => _TrainerDashboardState();
}

class _TrainerDashboardState extends State<TrainerDashboard> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final trainer = auth.trainerModel;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset('assets/images/logo.png', height: 35),
        actions: [
          IconButton(
            onPressed: () async {
              await auth.signOut();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                      (route) => false,
                );
              }
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.black,
              size: 22,
            ),
          )
        ],
      ),
      body: trainer == null 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? size.width * 0.1 : 20, 
              vertical: 20
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TRAINER PANEL",
                  style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 12),
                ),
                Text(
                  "Welcome, ${trainer.name}",
                  style: TextStyle(
                    fontSize: isWide ? 32 : 24, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: -0.5
                  ),
                ),
                const SizedBox(height: 30),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isWide ? 4 : (isTablet ? 3 : 2),
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: isWide ? 1.8 : 2.0,
                  children: [
                    _trainerCard(context, "Upload Notes", Icons.upload_file_rounded, const Color(0xFFFF5252), () => Navigator.pushNamed(context, AppRoutes.uploadNotes)),
                    _trainerCard(context, "Create Notes", Icons.edit_note_rounded, Colors.black, () => Navigator.pushNamed(context, AppRoutes.uploadNotes)), 
                    _trainerCard(context, "Share Links", Icons.link_rounded, const Color(0xFFFF5252), () => Navigator.pushNamed(context, AppRoutes.uploadNotes)),
                    _trainerCard(context, "Live Hub", Icons.video_call_rounded, Colors.black, () => Navigator.pushNamed(context, AppRoutes.liveHub)),
                    _trainerCard(context, "Lectures", Icons.video_library_rounded, const Color(0xFFFF5252), () => Navigator.pushNamed(context, AppRoutes.lecturesHub)),
                    _trainerCard(context, "Create Test", Icons.quiz_rounded, Colors.black, () => _openGoogleForm(context)),
                    _trainerCard(context, "Performance", Icons.analytics_rounded, const Color(0xFFFF5252), () => Navigator.pushNamed(context, AppRoutes.performance)),
                    _trainerCard(context, "Announcements", Icons.campaign_rounded, Colors.black, () => Navigator.pushNamed(context, AppRoutes.announcementsHub)),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _openGoogleForm(BuildContext context) async {
    final titleController = TextEditingController();
    final linkController = TextEditingController();
    final branchController = TextEditingController();
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final trainer = auth.trainerModel;

    if (trainer != null) {
      branchController.text = trainer.branch;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Post External Test"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Step 1: Create your form on Google Forms.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => launchUrl(Uri.parse('https://docs.google.com/forms/'), mode: LaunchMode.externalApplication),
                child: const Text("OPEN GOOGLE FORMS"),
              ),
              const Divider(height: 30),
              const Text("Step 2: Paste the link here to share it.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              TextField(controller: titleController, decoration: const InputDecoration(labelText: "Test Title")),
              TextField(controller: linkController, decoration: const InputDecoration(labelText: "Google Form Link")),
              TextField(controller: branchController, decoration: const InputDecoration(labelText: "Target Branch")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              if (titleController.text.isEmpty || linkController.text.isEmpty) return;

              final event = HubEvent(
                id: "TEST-${DateTime.now().millisecondsSinceEpoch}",
                title: titleController.text,
                description: "External Test via Google Forms",
                dateTime: DateTime.now(),
                type: 'test',
                branch: branchController.text,
                meetLink: linkController.text, // Store the Form link here
              );

              await DatabaseService().scheduleEvent(event);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Test posted successfully!")),
                );
              }
            }, 
            child: const Text("POST TEST"),
          ),
        ],
      ),
    );
  }


  Widget _trainerCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              colors: [Colors.black, Color(0xFFFF5252)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.5, 0.5],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: constraints.maxWidth * 0.12 > 24 ? 24 : constraints.maxWidth * 0.12),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          color: Colors.black, 
                          fontSize: constraints.maxWidth * 0.055 > 13 ? 13 : constraints.maxWidth * 0.055, 
                          letterSpacing: 0.5
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}
