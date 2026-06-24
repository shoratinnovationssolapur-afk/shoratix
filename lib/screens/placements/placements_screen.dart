import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/placement_model.dart';

class PlacementsScreen extends StatelessWidget {
  const PlacementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Placements & Careers"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.red,
            tabs: [
              Tab(text: "Openings"),
              Tab(text: "Schedules"),
              Tab(text: "Placed"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OpeningsTab(),
            SchedulesTab(),
            PlacedGalleryTab(),
          ],
        ),
      ),
    );
  }
}

class SchedulesTab extends StatelessWidget {
  const SchedulesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _scheduleCard("TCS Interview", "Round 1: Technical", "25 Oct • 10:00 AM"),
        _scheduleCard("Infosys HR Round", "Final Selection", "28 Oct • 02:30 PM"),
      ],
    );
  }

  Widget _scheduleCard(String company, String round, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: const Icon(Icons.event, color: Colors.blue),
        title: Text(company, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(round),
        trailing: Text(time, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

class OpeningsTab extends StatelessWidget {
  const OpeningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return StreamBuilder<List<PlacementModel>>(
      stream: db.placements,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final placements = snapshot.data!;
        if (placements.isEmpty) return const Center(child: Text("No active openings right now."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: placements.length,
          itemBuilder: (context, index) {
            final p = placements[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(p.companyLogoUrl),
                  backgroundColor: Colors.grey[200],
                ),
                title: Text(p.position, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${p.companyName} • ${p.location}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Package: ${p.package}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                        const SizedBox(height: 8),
                        Text(p.description),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () {}, // Link to applyUrl
                            child: const Text("Apply Now"),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class PlacedGalleryTab extends StatelessWidget {
  const PlacedGalleryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    return StreamBuilder<List<PlacedStudent>>(
      stream: db.placedStudents,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final placed = snapshot.data!;
        if (placed.isEmpty) return const Center(child: Text("Gallery will be updated soon."));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: placed.length,
          itemBuilder: (context, index) {
            final s = placed[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.network(
                      s.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Container(color: Colors.red[50], child: const Icon(Icons.person, size: 50)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(s.company, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        Text(s.package, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
