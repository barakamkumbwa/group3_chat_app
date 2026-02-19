import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  final List<Map<String, String>> teamMembers = const [
    {"name": "BARAKA MKUMBWA", "role": "Project Lead"},
    {"name": "BENITHO A MPETE", "role": "Backend dev"},
    {"name": "ENJO MGOVANO", "role": "UI Designer"},
    {"name": "NUSURA MAKORA", "role": "Frontend dev"},
    {"name": "EMANUEL MWITA", "role": "Database Manager"},
    {"name": "WINIFIRIDA MANDELE", "role": "QA Tester"},
    {"name": "JACKLINE GEOFREY", "role": "Frontend dev"},
    {"name": "MWANAIDI SELEMAN", "role": "Security Expert"},
    {"name": "SAUMU ABDALLAH", "role": "System Analyst"},
    {"name": "LIMI BUKEBE", "role": "UI/UX Designer"},
    {"name": "DANIEL DANIEL", "role": "Developer"},
    {"name": "ZACHARIA SUGILLO", "role": "Backend dev"},
    {"name": "FELISTA SAGANDA", "role": "Frontend dev"},
    {"name": "FADHILA NAMINGA", "role": "Content Creator"},
    {"name": "LINUS KATABALO", "role": "Product Manager"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header section
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF075E54),
            iconTheme: const IconThemeData(
              color: Colors.white,
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                "G3 ChatApp v1.0",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF075E54), Color(0xFF128C7E)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.spa_rounded, size: 80, color: Colors.white),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. INTRO SECTION
                  _buildSectionHeader("Who We Are"),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.teal.shade50),
                    ),
                    child: const Text(
                      "Group 3 is a team of aspiring software developers focused on creating secure and modern digital solutions. "
                      "Through collaboration and shared technical skills, we successfully developed G3 ChatApp, "
                      "a real-time communication platform designed to connect people efficiently and securely.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF455A64),
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  _buildSectionHeader("Quick Stats"),
                  const SizedBox(height: 12),
                  _buildStatsRow(),

                  const SizedBox(height: 30),
                  _buildSectionHeader("App Information"),
                  const SizedBox(height: 12),
                  _buildAppInfoCard(),

                  const SizedBox(height: 30),
                  _buildSectionHeader("Group 3 Team Members"),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 2. TEAM GRID
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildTeamMemberCard(teamMembers[index]),
                childCount: teamMembers.length,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  _buildSectionHeader("Get In Touch"),
                  const SizedBox(height: 12),
                  _buildContactSection(),

                  const SizedBox(height: 30),
                  _buildSectionHeader("Future Roadmap"),
                  _buildRoadmapCard(),

                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "Together We Innovate.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
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

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: const Color(0xFF075E54)),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF075E54),
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _statBox("150+", "Users", Icons.people),
        _statBox("1.2k+", "Chats", Icons.message),
        _statBox("Online", "Status", Icons.bolt),
      ],
    );
  }

  Widget _statBox(String val, String label, IconData icon) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF128C7E), size: 20),
          const SizedBox(height: 5),
          Text(
            val,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _infoTile(Icons.calendar_month, "Release Date", "February 2026"),
          const Divider(height: 1, indent: 50),
          _infoTile(Icons.phone_android, "Supported Platforms", "Android Only"),
          const Divider(height: 1, indent: 50),
          _infoTile(Icons.security, "Security", "End-to-End Encrypted"),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String sub) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF075E54), size: 20),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildTeamMemberCard(Map<String, String> member) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade50),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF128C7E).withValues(alpha: 0.1),
            radius: 14,
            child: Text(
              member['name']![0],
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF075E54),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member['name']!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  member['role']!,
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      children: [
        _contactTile(
          Icons.email_outlined,
          "Support Email",
          "support@g3chatapp.com",
          Colors.blue,
        ),
        const SizedBox(height: 10),
        _contactTile(
          Icons.camera_alt_outlined,
          "Instagram",
          "@g3_chatapp_devs",
          Colors.purple,
        ),
        const SizedBox(height: 10),
        _contactTile(
          Icons.code_rounded,
          "GitHub",
          "github.com/group3-devs",
          Colors.black,
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.feedback_outlined, size: 18),
            label: const Text("Send Feedback"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF075E54),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _contactTile(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapCard() {
    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          _roadmapItem("Voice & Video Calls", "Development Stage"),
          _roadmapItem("Media Sharing (Docs)", "Upcoming Stage"),
          _roadmapItem("Dark Mode Support", "Testing Stage"),
        ],
      ),
    );
  }

  Widget _roadmapItem(String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            status,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
