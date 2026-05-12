import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import 'package:mbg_test/features/volunteer/presentation/pages/volunteer_list_page.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = PersistentTabController();

  Color _getAvatarColor(String seed) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[seed.hashCode % colors.length];
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 15) return "Good afternoon";
    if (hour < 18) return "Good evening";
    return "Good night";
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "-";
    final formatter = DateFormat('MMMM d, yyyy', 'en_US');
    return formatter.format(date.toLocal());
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return "-";

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} minutes ago";
    if (diff.inHours < 24) return "${diff.inHours} hours ago";
    if (diff.inDays < 7) return "${diff.inDays} days ago";

    return _formatDate(date);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await FlutterPlatformAlert.showAlert(
      windowTitle: "Confirmation",
      text: "Are you sure you want to log out?",
      alertStyle: AlertButtonStyle.yesNo,
    );

    if (result == AlertButton.yesButton) {
      context.read<AuthBloc>().add(AuthLoggedOut());
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: PersistentTabView(
        tabs: [
          PersistentTabConfig(
            screen: _buildHomeTab(user),
            item: ItemConfig(icon: const Icon(Icons.home), title: "Home"),
          ),
          PersistentTabConfig(
            screen: _buildSettingsTab(user),
            item: ItemConfig(
              icon: const Icon(Icons.settings),
              title: "Settings",
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) =>
            Style2BottomNavBar(navBarConfig: navBarConfig),
        controller: _controller,
      ),
    );
  }

  Widget _buildHomeTab(User? user) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_getGreeting()}, ${user?.email ?? 'User'}!",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Go to volunteer list'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VolunteerListPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(User? user) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: user == null
            ? const Center(child: Text("User not found"))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + Email Header
                  Center(
                    child: Column(
                      children: [
                        Builder(
                          builder: (_) {
                            final avatarColor = _getAvatarColor(
                              user.email ?? "user",
                            );

                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    avatarColor.withOpacity(0.7),
                                    avatarColor,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  (user.email != null && user.email!.isNotEmpty)
                                      ? user.email![0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.email ?? "-",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  MouseRegion(
                    onEnter: (_) => setState(() {}),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: 1),
                      duration: const Duration(milliseconds: 150),
                      builder: (context, scale, child) {
                        return Transform.scale(scale: 0.98, child: child);
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {},
                          child: Card(
                            elevation: 3,
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _buildSectionTitle("Account"),
                                  _buildInfoRow(
                                    icon: Icons.email,
                                    label: "Email",
                                    value: user.email ?? "-",
                                    isCopyable: false,
                                  ),
                                  Divider(
                                    color: Theme.of(context).dividerColor,
                                  ),

                                  _buildSectionTitle("Activity"),
                                  _buildInfoRow(
                                    icon: Icons.calendar_today,
                                    label: "Created At",
                                    value: _formatDate(
                                      user.metadata.creationTime,
                                    ),
                                  ),
                                  Divider(
                                    color: Theme.of(context).dividerColor,
                                  ),
                                  _buildInfoRow(
                                    icon: Icons.access_time,
                                    label: "Last Sign In",
                                    value: _relativeTime(
                                      user.metadata.lastSignInTime,
                                    ),
                                  ),
                                  Divider(
                                    color: Theme.of(context).dividerColor,
                                  ),

                                  _buildSectionTitle("Security"),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Your account is securely authenticated via Firebase.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirmLogout(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isCopyable = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
