import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import 'package:mbg_test/core/helper/design_system.dart';

class SettingsTab extends StatefulWidget {
  final User? user;
  const SettingsTab({super.key, required this.user});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
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
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                              user.email ?? "loading user",
                            );

                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    avatarColor.withValues(alpha: 0.7),
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
                        const SizedBox(height: AppSpacing.md),
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

                  const SizedBox(height: AppSpacing.lg),

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
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () {},
                          child: Builder(
                            builder: (context) {
                              final isDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;

                              return Card(
                                elevation: isDark ? 0 : 3,
                                color: Theme.of(context).cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  side: isDark
                                      ? BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          width: 1,
                                        )
                                      : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
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
                                      const SizedBox(height: AppSpacing.xs),
                                      const Text(
                                        "Your account is securely authenticated via Cloudflare and Firebase.",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _confirmLogout(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        elevation: 6,
                        backgroundColor: Colors.redAccent,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, color: Colors.white),
                          SizedBox(width: AppSpacing.lg),
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
