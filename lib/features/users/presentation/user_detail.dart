import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/users/bloc/user_bloc.dart';
import 'package:mbg_test/features/users/bloc/user_event.dart';
import 'package:mbg_test/features/users/bloc/user_state.dart';
import 'package:mbg_test/features/users/data/models/user_model.dart';

class UserDetailPage extends StatefulWidget {
  final String id;

  const UserDetailPage({super.key, required this.id});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  // Local copies of what THIS page cares about. We deliberately do not
  // render straight off the shared UserBloc's state anymore: that bloc is
  // also used by the Users List page, whose `LoadUser` handler keeps a
  // live Firestore `.snapshots()` listener running for as long as the
  // bloc is alive (nothing cancels it when you leave the List page). Any
  // edit made here causes that listener to fire a `UserLoaded` (list)
  // state into the SAME bloc shortly after our own `GetUserById` result
  // comes back — and previously that stray state fell through to the
  // loading-skeleton fallback, causing the shimmer flash. Now we only
  // react to states that are actually about this detail load/delete and
  // ignore everything else.
  UserModel? _user;
  String? _errorMessage;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    setState(() => _errorMessage = null);
    context.read<UserBloc>().add(GetUserById(widget.id));
  }

  String _getInitials(String fullname) {
    if (fullname.trim().isEmpty) return '?';
    final parts = fullname.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<bool> _confirmDelete(UserModel user) async {
    final isVolunteer = user.role.trim().toLowerCase() == 'volunteer';
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete User'),
            content: Text(
              isVolunteer
                  ? 'Are you sure you want to delete "${user.fullname}"?\n\n'
                        'This will remove their user record and unlink their '
                        'volunteer profile. Their Firebase Authentication '
                        'login still needs to be removed manually from the '
                        'Firebase Console.'
                  : 'Are you sure you want to delete "${user.fullname}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('User Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
      ),
      body: BlocListener<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserDetailLoaded && state.user.id == widget.id) {
            setState(() {
              _user = state.user;
              _errorMessage = null;
            });
            return;
          }
          if (_isDeleting && state is UserSuccess && state.user == null) {
            _isDeleting = false;
            _showSuccessSnackBar('User deleted successfully');
            Navigator.pop(context, true);
            return;
          }
          if (state is UserError) {
            // Only an error we care about if it's either the very first
            // load (we have no user yet) or a delete we just triggered.
            // Errors from unrelated bloc activity (list page, other
            // screens sharing this bloc) must not blank this page out.
            if (_user == null || _isDeleting) {
              _isDeleting = false;
              setState(() => _errorMessage = state.message);
              _showErrorSnackBar(state.message);
            }
            return;
          }
          // Anything else (UserLoaded list snapshots, UserSuccess from an
          // add/update happening elsewhere, UserLoading from unrelated
          // events, etc.) is not about this page — ignore it so the UI
          // doesn't flicker back to a loading skeleton.
        },
        child: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: _buildContent(),
            ),
            if (_isDeleting)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    GlobalScaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    GlobalScaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildContent() {
    if (_user != null) {
      // We already have data — always prefer showing it. This is what
      // stops the shimmer from flashing back in on unrelated bloc
      // activity: once loaded, only an explicit reload (_loadUser, which
      // clears _errorMessage but keeps the old _user visible until the
      // new one arrives) or a delete changes what's on screen.
      return _buildUserDetailContent(_user!);
    }
    if (_errorMessage != null) {
      return _buildErrorContent(_errorMessage!);
    }
    return _buildLoadingSkeleton();
  }

  Widget _buildLoadingSkeleton() {
    final colorScheme = Theme.of(context).colorScheme;

    Widget bar({double? width, double height = 14, double radius = 8}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return _ShimmerLoading(
      key: const ValueKey('loading'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      bar(width: 180, height: 22),
                      const SizedBox(height: AppSpacing.sm),
                      bar(width: 100, height: 26, radius: 20),
                      const SizedBox(height: AppSpacing.lg),
                      bar(width: double.infinity),
                      const SizedBox(height: AppSpacing.sm),
                      bar(width: double.infinity),
                      const SizedBox(height: AppSpacing.md),
                      bar(width: double.infinity),
                      const SizedBox(height: AppSpacing.sm),
                      bar(width: 160),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(child: bar(height: 48, radius: AppRadius.md)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: bar(height: 48, radius: AppRadius.md)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserDetailContent(UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      key: const ValueKey('detail'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (child) => SlideAnimation(
                  verticalOffset: 30,
                  curve: Curves.easeOutCubic,
                  child: FadeInAnimation(curve: Curves.easeOut, child: child),
                ),
                children: [
                  // Avatar Section with gradient
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: colorScheme.surface,
                      child: Text(
                        _getInitials(user.fullname),
                        style: textTheme.displaySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // User Info Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullname,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Role Chip
                          Chip(
                            label: Text(user.role.toUpperCase()),
                            backgroundColor: colorScheme.primaryContainer,
                            side: BorderSide.none,
                            labelStyle: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            avatar: Icon(
                              Icons.badge,
                              size: 18,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const Divider(height: AppSpacing.lg),

                          // Detail Items
                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildInfoTile(
                            icon: Icons.person_outline,
                            label: 'Username',
                            value: user.username,
                            colorScheme: colorScheme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () async {
                            final updated = await Navigator.pushNamed(
                              context,
                              '/user-edit',
                              arguments: user,
                            );
                            if (!mounted) return;
                            if (updated != null) _loadUser();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () async {
                            final confirmed = await _confirmDelete(user);
                            if (!mounted) return;
                            if (confirmed) {
                              setState(() => _isDeleting = true);
                              context.read<UserBloc>().add(DeleteUser(user.id));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Failed to load user',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _loadUser,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Lightweight shimmer for loading skeleton ====================

class _ShimmerLoading extends StatefulWidget {
  final Widget child;

  const _ShimmerLoading({super.key, required this.child});

  @override
  State<_ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<_ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = _controller.value * 2 - 1;
            return LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(dx - 1, 0),
              end: Alignment(dx + 1, 0),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
