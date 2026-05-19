import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mbg_test/presentation/widgets/setting_tab.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'package:mbg_test/presentation/widgets/home_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = PersistentTabController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: PersistentTabView(
        gestureNavigationEnabled: true,
        stateManagement: true,
        screenTransitionAnimation: ScreenTransitionAnimation(
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        ),
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        tabs: [
          PersistentTabConfig(
            screen: HomeTab(user: user),
            item: ItemConfig(icon: const Icon(Icons.home), title: "Home"),
          ),
          PersistentTabConfig(
            screen: SettingsTab(user: user),
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
}
