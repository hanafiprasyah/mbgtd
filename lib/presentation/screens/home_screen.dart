import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mbg_test/core/services/camera_prewarm.dart';
import 'package:mbg_test/presentation/widgets/home_tab.dart';
import 'package:mbg_test/presentation/widgets/report_tab.dart';
import 'package:mbg_test/presentation/widgets/setting_tab.dart';
import 'package:mbg_test/presentation/widgets/bricks/home/camera_widget.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? userData;
  final _controller = PersistentTabController();

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await Future.delayed(
        const Duration(milliseconds: 100),
      ).whenComplete(() => user?.reload());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load user data")),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<void> _startLoadingSequence() async {
    final user = FirebaseAuth.instance.currentUser;

    await Future.wait([_fetchUserData()]);

    final data = await getUserRole(user?.uid ?? "");

    if (!mounted) return;
    setState(() {
      userData = data;
      _isLoading = false;
    });
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

  @override
  void initState() {
    super.initState();

    _startLoadingSequence();
    if (!mounted) return;
    Future.microtask(() async {
      await CameraPrewarmService.prewarm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final role = userData?['role'] as String?;
    final isScanner =
        user != null && (role)?.toLowerCase().contains('scanner') == true;

    // Camera service prewarm with loading screen
    if (_isLoading) {
      return const CameraPrewarmWidget();
    }

    return PersistentTabView(
      gestureNavigationEnabled: true,
      stateManagement: true,
      screenTransitionAnimation: ScreenTransitionAnimation(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      ),
      resizeToAvoidBottomInset: true,
      tabs: [
        // Home Tab
        PersistentTabConfig(
          screen: buildHomeTab(
            context,
            user,
            _getGreeting(),
            userData?['role'],
            userData?['fullname'] ?? "Loading user info..",
          ),
          item: ItemConfig(icon: const Icon(Icons.home), title: "Home"),
        ),
        // Report Tab
        if (!isScanner)
          PersistentTabConfig(
            screen: buildReportTab(context),
            item: ItemConfig(
              icon: const Icon(Icons.bar_chart_rounded),
              title: "Report",
            ),
          ),
        // Settings Tab
        PersistentTabConfig(
          screen: buildSettingTab(
            context,
            user,
            _formatDate(user?.metadata.creationTime),
            _getAvatarColor(user?.email ?? "Loading user info.."),
            _relativeTime(user?.metadata.lastSignInTime),
            userData,
          ),
          item: ItemConfig(icon: const Icon(Icons.settings), title: "Settings"),
        ),
      ],
      navBarBuilder: (navBarConfig) =>
          Style2BottomNavBar(navBarConfig: navBarConfig),
      controller: _controller,
    );
  }
}
