import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0; 

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const AdminLoginPage()), (route) => false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), 
      body: Row(
        children: [
          Container(
            width: 280,
            color: const Color(0xFF1F2937), 
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Emergency & Safety\nMonitoring",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 30),
                _sidebarItem(0, Icons.analytics_outlined, "Overview"),
                _sidebarItem(1, Icons.gpp_maybe_outlined, "Emergency"),
                _sidebarItem(2, Icons.people_outline, "Driver Approvals"),
                _sidebarItem(3, Icons.star_outline, "Review Management"),
                const Spacer(),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text("Logout", style: TextStyle(color: Colors.white70)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      _tabButton(0, Icons.bolt, "Overview"),
                      _tabButton(1, Icons.warning_amber, "Emergency"),
                      _tabButton(2, Icons.how_to_reg, "Users"),
                      _tabButton(3, Icons.reviews, "Reviews"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: const [
                      _OverviewContent(),
                      _EmergencyAlertCenter(),
                      _DriverApprovalsTab(),
                      _ReviewManagementTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Unipool Admin Dashboard", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text("Manage your carpooling platform", style: TextStyle(color: Colors.grey)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.notifications_none, color: Colors.grey),
              const SizedBox(width: 20),
              const CircleAvatar(backgroundColor: Color(0xFF15273C), child: Text("AD", style: TextStyle(color: Colors.white))),
            ],
          )
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      onTap: () => setState(() => _selectedIndex = index),
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white60),
      title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white60)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selected: isSelected,
      selectedTileColor: Colors.white10,
    );
  }

  Widget _tabButton(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ================= OVERVIEW =================
class _OverviewContent extends StatelessWidget {
  const _OverviewContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Row(
            children: [
              _StatCard("Total Users", "1,090", "↑ 12%", "234 drivers, 856 passengers"),
              _StatCard("Active Trips", "23", "↑ 8%", "67 passengers in transit"),
              _StatCard("Monthly Revenue", "\$11,125", "↑ 15%", "890 trips this month"),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _EmergencyAlertCenter(isSmall: true)),
              const SizedBox(width: 24),
              const Expanded(flex: 2, child: _DriverApprovalsTab(isSmall: true)),
            ],
          )
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, trend, subtext;
  const _StatCard(this.title, this.value, this.trend, this.subtext);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // FIX 1: Changed BorderSide to Border.all
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(trend, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtext, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ================= EMERGENCY =================
class _EmergencyAlertCenter extends StatelessWidget {
  final bool isSmall;
  const _EmergencyAlertCenter({this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        // FIX 1: Changed BorderSide to Border.all
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Emergency Alert Center", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (isSmall) const Text("View All", style: TextStyle(color: Colors.blue)),
            ],
          ),
          const Text("Monitor and respond to safety incidents in real-time", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('reports').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final reports = snapshot.data!.docs;
              if (reports.isEmpty) return const Text("No active alerts.");

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: isSmall ? 1 : reports.length,
                itemBuilder: (context, index) {
                  var data = reports[index].data() as Map<String, dynamic>;
                  bool isSOS = data['type'] == 'SOS_EMERGENCY';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSOS ? const Color(0xFFFFFBFA) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSOS ? Colors.red.shade100 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle, color: Colors.red, size: 10),
                            const SizedBox(width: 8),
                            Text("Emergency Alert - Trip #${reports[index].id.substring(0, 5)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            const Text("2 minutes ago", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Reported by: ${data['reporterName']} (passenger)  •  Driver: ${data['driverName'] ?? 'N/A'}", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(data['currentLocation'] ?? "Main Street & 5th Ave", style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.phone, size: 16),
                              label: const Text("Contact User"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.map, size: 16), label: const Text("View Location")),
                            const Spacer(),
                            TextButton.icon(onPressed: () => reports[index].reference.delete(), icon: const Icon(Icons.check), label: const Text("Mark Resolved")),
                          ],
                        )
                      ],
                    ),
                  );
                },
              );
            },
          )
        ],
      ),
    );
  }
}

// ================= REVIEWS =================
class _ReviewManagementTab extends StatelessWidget {
  const _ReviewManagementTab();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Review Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Moderate ratings and reviews from users", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('reviews').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final reviews = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var data = reviews[index].data() as Map<String, dynamic>;
                    double rating = (data['rating'] ?? 5.0).toDouble();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: rating < 3 ? const Color(0xFFFFFBEB) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: rating < 3 ? Colors.amber.shade200 : Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.flag_outlined, color: Colors.amber, size: 18),
                              const SizedBox(width: 8),
                              Text("Trip #${reviews[index].id.substring(0, 5)}", style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              if (rating < 3) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)), child: const Text("Flagged", style: TextStyle(fontSize: 10, color: Colors.amber))),
                              const Spacer(),
                              const Text("2024-12-16", style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text("${data['passengerName']} reviewed ${data['driverName']}", style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Row(children: List.generate(5, (i) => Icon(Icons.star, size: 16, color: i < rating ? Colors.amber : Colors.grey.shade300))),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade100), borderRadius: BorderRadius.circular(8)),
                            child: Text("\"${data['comment']}\"", style: const TextStyle(fontStyle: FontStyle.italic)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              const Text("Flagged for: Low Rating / Complaint", style: TextStyle(color: Colors.amber, fontSize: 12)),
                              const Spacer(),
                              TextButton(onPressed: () {}, child: const Text("View Details")),
                              const SizedBox(width: 8),
                              ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Colors.green), foregroundColor: Colors.green), child: const Text("Approve")),
                              const SizedBox(width: 8),
                              ElevatedButton(onPressed: () => reviews[index].reference.delete(), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Colors.red), foregroundColor: Colors.red), child: const Text("Remove")),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================= DRIVER APPROVALS =================
class _DriverApprovalsTab extends StatelessWidget {
  final bool isSmall;
  const _DriverApprovalsTab({this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12), 
        // FIX 1: Changed BorderSide to Border.all
        border: Border.all(color: Colors.grey.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pending Verifications", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (isSmall) const Text("View All", style: TextStyle(color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').where('isAdminApproved', isEqualTo: false).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final drivers = snapshot.data!.docs;
              if (drivers.isEmpty) return const Text("No pending drivers.");

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: isSmall ? 1 : drivers.length,
                itemBuilder: (context, index) {
                  var data = drivers[index].data() as Map<String, dynamic>;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: Color(0xFF1F2937), child: Text("AR", style: TextStyle(color: Colors.white))),
                    title: Text(data['name'] ?? "No Name", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(data['email'] ?? "Email N/A"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.visibility_outlined), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green), onPressed: () => drivers[index].reference.update({'isAdminApproved': true})),
                        IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.red), onPressed: () => drivers[index].reference.delete()),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
