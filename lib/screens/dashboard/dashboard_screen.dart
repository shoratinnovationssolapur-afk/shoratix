import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/database_service.dart';
import '../../services/branch_content_service.dart';
import '../../models/content_models.dart';
import '../../models/fee_model.dart';
import '../../models/trainer_model.dart';
import '../../models/student_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  Timer? _heartbeatTimer;
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerHeartbeat();
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _triggerHeartbeat();
    });
  }

  void _triggerHeartbeat() {
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final student = auth.studentModel;
    if (student != null && !student.uid.startsWith('debug')) {
      _db.updateHeartbeat(student.uid);
    }
  }

  List<String> _getInterests(StudentModel student) {
    List<String> interests = ['all'];
    if (student.branch.isNotEmpty) interests.add(student.branch);
    interests.addAll(student.enrolledCourses);
    return interests.toSet().toList(); // Unique values
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<UserAuthProvider>(context);
    final student = authProvider.studentModel;

    if (student == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF5252))),
      );
    }

    final interests = _getInterests(student);
      final _branchService = BranchContentService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        centerTitle: false,
        title: Image.asset('assets/images/logo.png', height: 35),
        actions: [
          _buildAppBarAction(Icons.notifications_active_outlined, () => Navigator.pushNamed(context, AppRoutes.notifications)),
          const SizedBox(width: 8),
          _buildProfileAvatar(context, student.profileImageUrl),
          const SizedBox(width: 15),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            right: -100,
            child: _ambientGlow(const Color(0xFFFF5252).withValues(alpha: 0.08), 300),
          ),
          Positioned(
            bottom: 50,
            left: -100,
            child: _ambientGlow(Colors.black.withOpacity(0.04), 400),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(
                  student.name.isEmpty ? "Student" : student.name, 
                  student.studentId.isEmpty ? "..." : student.studentId, 
                  student.branch.isEmpty ? "Main" : student.branch,
                ),

                StreamBuilder<FeeModel>(
                  stream: (student.uid.isEmpty || student.uid.startsWith('debug'))
                      ? Stream.value(FeeModel(totalFees: 50000, paidAmount: 0, monthlyAmount: 5000))
                      : _db.getFees(student.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isDueSoon) {
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.fees),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 15),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: const Color(0xFFFF5252).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.priority_high_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Fee payment is due! Please clear it to avoid access issues.",
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
                          child: _glassStatCard(
                            "Attendance",
                            "${student.attendancePercentage.toStringAsFixed(0)}%",
                            Icons.query_stats_rounded,
                            const Color(0xFFFF5252),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _glassStatCard(
                          "Performance",
                          "Elite",
                          Icons.workspace_premium_rounded,
                          const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (student.enrolledCourses.isEmpty)
                  _buildFirstTimeEnrollmentPrompt(context)
                else
                  _buildEnrolledCoursesSection(context, student.enrolledCourses),

                const SizedBox(height: 20),
                if (student.enrolledCourses.isNotEmpty) _buildUpcomingClassesSection(interests),
                const SizedBox(height: 20),

                // Recent Notes
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Notes", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.notes), child: const Text("SEE ALL", style: TextStyle(color: Color(0xFFFF5252))))
                    ],
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: StreamBuilder<List<NoteModel>>(
                    stream: _branchService.notesForBranch(student.branch),
                    builder: (context, snapshot) {
                      final notes = snapshot.data ?? [];
                      if (notes.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("No notes yet.", style: TextStyle(color: Colors.grey)));
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: notes.length < 5 ? notes.length : 5,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Expanded(child: Text(note.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                            ]),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Recent Videos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Recent Videos", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      TextButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.lectures), child: const Text("SEE ALL", style: TextStyle(color: Color(0xFFFF5252))))
                    ],
                  ),
                ),
                SizedBox(
                  height: 140,
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _db.getLectures(interests),
                    builder: (context, snapshot) {
                      final lectures = snapshot.data ?? [];
                      final videos = lectures.where((l) => l['type'] == 'recorded').toList();
                      if (videos.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("No videos yet.", style: TextStyle(color: Colors.grey)));
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: videos.length < 5 ? videos.length : 5,
                        itemBuilder: (context, index) {
                          final v = videos[index];
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(height: 90, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black12), child: v['thumbnail'] != null ? Image.network(v['thumbnail'], fit: BoxFit.cover, width: double.infinity) : const Icon(Icons.play_circle_fill, size: 48)),
                              const SizedBox(height: 8),
                              Text(v['title'] ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                            ]),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // Shared Links + Upcoming Tests compact row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Row(children: [
                    Expanded(
                      child: StreamBuilder<List<LinkModel>>(
                        stream: _branchService.linksForBranch(student.branch),
                        builder: (context, snapshot) {
                          final links = snapshot.data ?? [];
                          if (links.isEmpty) return const Text("No shared links.", style: TextStyle(color: Colors.grey));
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("Shared Links", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            Text(links.first.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]);
                        },
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: StreamBuilder<List<TestModel>>(
                        stream: _branchService.testsForBranch(student.branch),
                        builder: (context, snapshot) {
                          final tests = snapshot.data ?? [];
                          if (tests.isEmpty) return const Text("No upcoming tests.", style: TextStyle(color: Colors.grey));
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text("Upcoming Tests", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            Text(tests.first.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]);
                        },
                      ),
                    ),
                  ]),
                ),


                const Padding(
                  padding: EdgeInsets.fromLTRB(25, 25, 20, 12),
                  child: Text(
                    "CORE MODULES",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2, // Significantly flatter boxes
                  children: [
                    _moduleCard(context, "Notes", Icons.description_rounded, const Color(0xFFFF5252), AppRoutes.notes),
                    _moduleCard(context, "Lectures", Icons.video_library_rounded, const Color(0xFF1A1A1A), AppRoutes.lectures),
                    _moduleCard(context, "Live Hub", Icons.live_tv_rounded, const Color(0xFFFF5252), AppRoutes.liveSessions),
                    _moduleCard(context, "Exams", Icons.assignment_rounded, const Color(0xFF1A1A1A), AppRoutes.exams),
                    _moduleCard(context, "AI Mentor", Icons.psychology_rounded, const Color(0xFFFF5252), AppRoutes.aiAssistant),
                    _moduleCard(context, "Support", Icons.forum_rounded, const Color(0xFF1A1A1A), AppRoutes.doubtSupport),
                  ],
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassesSection(List<String> interests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Text("UPCOMING CLASSES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<HubEvent>>(
          stream: _db.getEvents(interests),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final now = DateTime.now();
            final events = snapshot.data!
                .where((e) => e.dateTime.isAfter(now) || (e.type == 'meeting' && e.dateTime.add(const Duration(hours: 2)).isAfter(now)))
                .toList();
            if (events.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("No upcoming classes scheduled.", style: TextStyle(color: Colors.grey, fontSize: 12)));
            
            return SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                itemBuilder: (context, index) => _classCard(events[index]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _classCard(HubEvent event) {
    return GestureDetector(
      onTap: () {
        if (event.type == 'test') {
          Navigator.pushNamed(context, AppRoutes.exams);
        }
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 15, bottom: 5),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (event.type == 'test' ? Colors.orange : const Color(0xFFFF5252)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9, 
                      fontWeight: FontWeight.w900, 
                      color: event.type == 'test' ? Colors.orange : const Color(0xFFFF5252), 
                      letterSpacing: 1
                    ),
                  ),
                ),
                if (event.type == 'meeting' && event.meetLink.isNotEmpty)
                  const Icon(Icons.videocam, color: Colors.blue, size: 20)
                else if (event.type == 'test')
                  const Icon(Icons.assignment_late_rounded, color: Colors.orange, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_filled, size: 12, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  DateFormat('MMM d, hh:mm a').format(event.dateTime),
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                if (event.type == 'test') ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.help_outline_rounded, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    "${event.questions.length} Questions",
                    style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyAddedResources(List<String> interests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("NEW RESOURCES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notes),
                child: const Text("SEE ALL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF5252))),
              ),
            ],
          ),
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _db.getLectures(interests),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final lectures = snapshot.data!.take(3).toList();
            if (lectures.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 25), child: Text("No resources added yet.", style: TextStyle(color: Colors.grey, fontSize: 12)));
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: lectures.length,
              itemBuilder: (context, index) => _resourceItem(lectures[index]),
            );
          },
        ),
      ],
    );
  }

  Widget _resourceItem(Map<String, dynamic> data) {
    final type = data['type'] ?? 'recorded';
    IconData icon = Icons.play_circle_fill;
    if (type == 'file' || type == 'manual_note') icon = Icons.description_rounded;
    if (type == 'link') icon = Icons.link_rounded;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF5252)),
        title: Text(data['title'] ?? 'Untitled Resource', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(type.toUpperCase(), style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          if (type == 'manual_note') {
            Navigator.pushNamed(context, AppRoutes.notes);
          } else if (data['url'] != null && data['url'].toString().isNotEmpty) {
            final uri = Uri.parse(data['url'].toString());
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
      ),
    );
  }


  Widget _ambientGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black87, size: 20),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 35, minHeight: 35),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFF5252), width: 1.2),
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty ? const Icon(Icons.person, size: 18, color: Colors.black87) : null,
      ),
    );
  }

  Widget _buildHeroHeader(String name, String id, String branch) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 15),
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Colors.black, Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.5, 0.5],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF252525)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SHORAT PLATFORM",
              style: TextStyle(color: Color(0xFFFF5252), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            Text(
              "Hey, ${name.split(' ')[0]}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoTag("ID: $id"),
                const SizedBox(width: 6),
                _infoTag(branch.toUpperCase()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 9),
      ),
    );
  }

  Widget _glassStatCard(String label, String value, IconData icon, Color accent) {
    return HoverItem(
      child: Container(
        padding: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Colors.black, Color(0xFFFF5252)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.5, 0.5],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: accent, size: 16),
                  ),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstTimeEnrollmentPrompt(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context, listen: false);
    final List<String> courses = [
      "Java Full Stack", "Python Full Stack", "Data Science", "Data Analytics",
      "AI and Machine Learning", "Software Testing", "Android Dev", "Flutter Dev",
      "MERN / MEAN Stack", "Web Development"
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Colors.black, Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rocket_launch_rounded, color: Color(0xFFFF5252), size: 28),
                SizedBox(width: 12),
                Text(
                  "STEP 1: CHOOSE YOUR PATH",
                  style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              "Select your Course",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
            ),
            const Text(
              "You must enroll in a course to start your learning journey and access the hub features.",
              style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: courses.map((course) => GestureDetector(
                onTap: () => _confirmEnrollment(context, auth.user!.uid, course),
                child: HoverItem(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      course,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmEnrollment(BuildContext context, String uid, String courseName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enroll in $courseName?"),
        content: const Text("Once you enroll, your learning dashboard will be activated and your fee schedule will begin."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseService().enrollInCourse(uid, courseName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Successfully enrolled in $courseName!"), backgroundColor: Colors.green),
                );
              }
            }, 
            child: const Text("CONFIRM ENROLL"),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledCoursesSection(BuildContext context, List<String> enrolledCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(25, 5, 20, 12),
          child: Text(
            "YOUR ENROLLED COURSES",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 2.0,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: enrolledCourses.length,
            itemBuilder: (context, index) {
              return HoverItem(
                child: _enrolledCourseCard(context, enrolledCourses[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _enrolledCourseCard(BuildContext context, String courseName) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Colors.black, Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, color: Color(0xFFFF5252), size: 24),
            const SizedBox(height: 10),
            Text(
              courseName,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            const Text(
              "Continue Learning",
              style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard(BuildContext context, String title, IconData icon, Color color, String? route) {
    return HoverItem(
      child: Container(
        padding: const EdgeInsets.all(1), // Thinner border
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Colors.black, Color(0xFFFF5252)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.5, 0.5],
          ),
        ),
        child: InkWell(
          onTap: () => route != null ? Navigator.pushNamed(context, route) : null,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row( // Changed to Row to save vertical space
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 9, letterSpacing: 0.5),
                    maxLines: 1,
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
}

class HoverItem extends StatefulWidget {
  final Widget child;
  const HoverItem({super.key, required this.child});

  @override
  State<HoverItem> createState() => _HoverItemState();
}

class _HoverItemState extends State<HoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _isHovered 
          ? (Matrix4.identity()..setTranslationRaw(0.0, -4.0, 0.0)..scale(1.02, 1.02, 1.0))
          : Matrix4.identity(),
        child: widget.child,
      ),
    );
  }
}
