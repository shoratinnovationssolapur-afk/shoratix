import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../models/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isMarking = false;
  String _selectedPeriod = "All"; // All, Weekly, Monthly, Yearly

  Future<void> _handleCheckIn(String uid, DatabaseService db) async {
    setState(() => _isMarking = true);
    try {
      await db.markAttendance(uid, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Checked in successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to check in"), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isMarking = false);
  }

  List<AttendanceModel> _filterAttendance(List<AttendanceModel> all) {
    final now = DateTime.now();
    if (_selectedPeriod == "Weekly") {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return all.where((a) => a.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))).toList();
    } else if (_selectedPeriod == "Monthly") {
      return all.where((a) => a.date.year == now.year && a.date.month == now.month).toList();
    } else if (_selectedPeriod == "Yearly") {
      return all.where((a) => a.date.year == now.year).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<UserAuthProvider>(context);
    final db = DatabaseService();
    final student = auth.studentModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: _ambientGlow(const Color(0xFFFF5252).withOpacity(0.1), 300),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                
                Expanded(
                  child: StreamBuilder<List<AttendanceModel>>(
                    stream: (student?.uid == null || student!.uid.startsWith('debug'))
                        ? Stream.value([
                            AttendanceModel(
                              date: DateTime.now(),
                              isPresent: true,
                              timestamp: DateTime.now(),
                            )
                          ])
                        : db.getAttendance(student.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5252)));
                      }
                      
                      final allAttendance = snapshot.data ?? [];
                      final filteredAttendance = _filterAttendance(allAttendance);
                      
                      int total = filteredAttendance.length;
                      int present = filteredAttendance.where((a) => a.isPresent).length;
                      double percent = total == 0 ? 0 : (present / total) * 100;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsHero(percent, total, present),
                            const SizedBox(height: 20),
                            
                            _buildPeriodSelector(),
                            const SizedBox(height: 20),
                            
                            _buildCheckInCard(student?.uid ?? '', db, allAttendance),
                            
                            Padding(
                              padding: const EdgeInsets.fromLTRB(5, 30, 0, 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "ATTENDANCE LOG ($_selectedPeriod)",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (filteredAttendance.isNotEmpty)
                                    Text(
                                      "$present / $total Days",
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFF5252)),
                                    ),
                                ],
                              ),
                            ),
                            
                            filteredAttendance.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredAttendance.length,
                                    itemBuilder: (context, index) {
                                      return _buildAttendanceTile(filteredAttendance[index]);
                                    },
                                  ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          ),
          const Text(
            "Attendance Report",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: ["All", "Weekly", "Monthly", "Yearly"].map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsHero(double percent, int total, int present) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Colors.black, Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.5, 0.5],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF252525)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF5252)),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "${percent.toStringAsFixed(0)}%",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const Text(
                      "PRESENT",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white60, letterSpacing: 1),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _heroStatItem("Total", total.toString()),
                Container(width: 1, height: 25, color: Colors.white12),
                _heroStatItem("Present", present.toString()),
                Container(width: 1, height: 25, color: Colors.white12),
                _heroStatItem("Absent", (total - present).toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCheckInCard(String uid, DatabaseService db, List<AttendanceModel> history) {
    final today = DateTime.now();
    final alreadyCheckedIn = history.any((a) => 
      a.date.year == today.year && a.date.month == today.month && a.date.day == today.day
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFFFF5252), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Session",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                Text(
                  alreadyCheckedIn ? "Attendance Marked" : "Verify your presence",
                  style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: (alreadyCheckedIn || _isMarking) ? null : () => _handleCheckIn(uid, db),
            style: ElevatedButton.styleFrom(
              backgroundColor: alreadyCheckedIn ? Colors.green : Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
            ),
            child: _isMarking 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  alreadyCheckedIn ? "DONE" : "CHECK IN",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTile(AttendanceModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: a.isPresent ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              a.isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: a.isPresent ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(a.date),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                Text(
                  "Time: ${DateFormat('hh:mm a').format(a.timestamp)}",
                  style: TextStyle(color: const Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  a.isPresent ? "Class attended successfully" : (a.reason ?? "Absent from session"),
                  style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            a.isPresent ? "PRESENT" : "ABSENT",
            style: TextStyle(
              color: a.isPresent ? Colors.green : Colors.red,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.event_note_rounded, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            "No attendance logs for this period.",
            style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600),
          ),
        ],
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
}
