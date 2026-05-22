import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/core/services/camera_prewarm.dart';
import 'package:mbg_test/presentation/widgets/home_tab.dart';
import 'package:mbg_test/presentation/widgets/setting_tab.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = PersistentTabController();

  bool _isLoading = true;
  int _loadingTextIndex = 0;

  final List<String> _loadingTexts = [
    "Welcome back,",
    "Preparing your data...",
    "Ready to go!",
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _startLoadingSequence();
    Future.microtask(() async {
      await CameraPrewarmService.prewarm();
    });
  }

  Future<void> _startLoadingSequence() async {
    // Start text animation (non-blocking)
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() => _loadingTextIndex = 1);
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() => _loadingTextIndex = 2);
    });

    // Wait for BOTH animation minimum time AND data fetching
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 3000)),
      _fetchUserData(),
    ]);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await Future.delayed(const Duration(milliseconds: 1000));
      await user?.reload();
    } catch (e) {
      debugPrint('Fetch user error: $e');
    }
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
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: MobileScanner(
                    controller: CameraPrewarmService.controller,
                  ),
                ),
              ),
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0.8, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const CircularProgressIndicator(),
                  );
                },
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _loadingTexts[_loadingTextIndex],
                  key: ValueKey(_loadingTextIndex),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
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
        PersistentTabConfig(
          screen: buildHomeTab(context, user, _getGreeting()),
          item: ItemConfig(icon: const Icon(Icons.home), title: "Home"),
        ),
        PersistentTabConfig(
          screen: buildSettingTab(
            context,
            user,
            _formatDate(user?.metadata.creationTime),
            _getAvatarColor(user?.email ?? "Loading user info"),
            _relativeTime(user?.metadata.lastSignInTime),
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
