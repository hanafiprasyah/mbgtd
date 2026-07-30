import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/users/bloc/user_bloc.dart';
import 'package:mbg_test/features/users/bloc/user_event.dart';
import 'package:mbg_test/features/users/bloc/user_state.dart';
import 'package:mbg_test/features/users/data/models/user_model.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  Timer? _debounce;

  final List<String> _roles = const [
    'developer',
    'sppi',
    'accountant',
    'nutritionist',
    'aslap',
    'admin',
    'scanner',
    'chef',
    'volunteer',
  ];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String? _selectedRole;
  bool _isSearching = false;
  bool _isSearchFieldVisible = false;

  final _scrollController = ScrollController();
  bool _isFabGroupVisible = true;
  double _lastScrollOffset = 0;

  int get _activeFilterCount {
    var count = 0;
    if (_selectedRole != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _applyCriteria();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.position.pixels;

    // Always show the floating group near the top of the list.
    if (offset <= 20) {
      if (!_isFabGroupVisible) setState(() => _isFabGroupVisible = true);
      _lastScrollOffset = offset;
      return;
    }

    final delta = offset - _lastScrollOffset;
    const threshold = 8.0;
    if (delta > threshold && _isFabGroupVisible) {
      setState(() => _isFabGroupVisible = false);
    } else if (delta < -threshold && !_isFabGroupVisible) {
      setState(() => _isFabGroupVisible = true);
    }
    _lastScrollOffset = offset;
  }

  void _applyCriteria() {
    final query = _searchController.text.trim();

    context.read<UserBloc>().add(SearchUser(query, _selectedRole));
  }

  void _onSearchChanged(String value) {
    setState(() => _isSearching = value.trim().isNotEmpty);

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _applyCriteria();
    });
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _searchController.clear();
      _isSearching = false;
    });

    _applyCriteria();
  }

  void _toggleSearchField() {
    final willShow = !_isSearchFieldVisible;

    setState(() => _isSearchFieldVisible = willShow);

    if (willShow) {
      // Wait for the field to be laid out before requesting focus, so we
      // never focus a node that isn't attached to the tree yet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isSearchFieldVisible) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      // Drop focus first to dismiss the keyboard, then clear any active
      // query so the list isn't left silently filtered while the field
      // is hidden.
      _searchFocusNode.unfocus();
      _clearSearch();
    }
  }

  Future<void> _showRoleFilterSheet() async {
    String? tempRole = _selectedRole;
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by role',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: tempRole == null,
                        onSelected: (_) => setSheetState(() => tempRole = null),
                      ),
                      ..._roles.map(
                        (role) => FilterChip(
                          label: Text(role.toUpperCase()),
                          selected: tempRole == role,
                          onSelected: (_) =>
                              setSheetState(() => tempRole = role),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(sheetContext, '__CANCEL__'),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, tempRole),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (mounted && result != '__CANCEL__') {
      setState(() {
        _selectedRole = result as String?;
      });
      _applyCriteria();
    }
  }

  Future<bool> _confirmDelete(UserModel user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete user'),
          content: Text(
            'Are you sure you want to delete "${user.fullname}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return confirm == true;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFilterActive = _selectedRole != null && _selectedRole!.isNotEmpty;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manage Users'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _applyCriteria(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _isSearchFieldVisible
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search users, email, role...',
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: _isSearching
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              suffixIcon: _isSearching
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        size: 20,
                                      ),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.3),
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              if (_isSearchFieldVisible) SizedBox(height: AppSpacing.md),
              if (isFilterActive)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.xs,
                    left: AppSpacing.lg,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FilterChip(
                      onSelected: (value) => _showRoleFilterSheet(),
                      label: Text(
                        _selectedRole!.toUpperCase(),
                        style: TextStyle(fontSize: 12),
                      ),
                      onDeleted: () {
                        setState(() => _selectedRole = null);
                        _applyCriteria();
                      },
                      deleteIcon: const Icon(Icons.close, size: 16),
                    ),
                  ),
                ),
              Expanded(
                child: BlocConsumer<UserBloc, UserState>(
                  listener: (context, state) {
                    if (state is UserError) {
                      _showErrorSnackBar(state.message);
                    }
                    if (state is UserSuccess) {
                      final message = state.user == null
                          ? 'User deleted successfully'
                          : 'User saved successfully';
                      _showSuccessSnackBar(message);
                      _applyCriteria();
                    }
                  },
                  builder: (context, state) {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _buildContent(state),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _FloatingActionGroup(
        isVisible: _isFabGroupVisible,
        filterCount: _activeFilterCount,
        isSearchActive: _isSearchFieldVisible,
        onSearchPressed: _toggleSearchField,
        onFilterPressed: _showRoleFilterSheet,
        onFilterLongPress: () {
          setState(() => _selectedRole = null);
          _applyCriteria();
        },
        onAddPressed: () async {
          await Navigator.pushNamed(context, '/user-add');
          if (mounted) _applyCriteria();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildContent(UserState state) {
    if (state is UserLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }
    if (state is UserLoaded) {
      if (state.users.isEmpty) {
        return _buildEmptyState();
      }
      return _buildUserList(state.users);
    }
    if (state is UserError) {
      return _buildErrorState(state.message);
    }
    return const Center(
      key: ValueKey('initial'),
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('empty'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No users found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try changing the filter or add a new user',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      key: const ValueKey('error'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load users',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: colorScheme.error),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () {
              if (mounted) _applyCriteria();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users) {
    return AnimationLimiter(
      key: const ValueKey('list'),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        itemCount: users.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final user = users[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 40,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(
                curve: Curves.easeOut,
                child: _UserCard(
                  user: user,
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      '/user-detail',
                      arguments: user.id,
                    );
                    if (mounted) _applyCriteria();
                  },
                  onEdit: () async {
                    await Navigator.pushNamed(
                      context,
                      '/user-edit',
                      arguments: user,
                    );
                    if (mounted) _applyCriteria();
                  },
                  onDelete: () async {
                    final confirmed = await _confirmDelete(user);
                    if (mounted && confirmed) {
                      context.read<UserBloc>().add(DeleteUser(user.id));
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== Custom Widget for User Card ====================

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  String _getInitials(String fullname) {
    if (fullname.trim().isEmpty) return '?';
    final parts = fullname.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = _getInitials(user.fullname);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Avatar with gradient background
                Container(
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
                    radius: 28,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullname,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.apps_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit user',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        foregroundColor: colorScheme.primary,
                      ),
                      onPressed: onEdit,
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.delete_outline),
                    //   tooltip: 'Delete user',
                    //   color: Colors.redAccent,
                    //   onPressed: onDelete,
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A pill-shaped floating group that combines the "Filter by Role" and
/// "Add Staff User" actions, styled the same way as the one on the
/// volunteer list page: a semi-transparent primary-color pill with
/// bright, bold icons that hides on scroll down and reappears on scroll
/// up.
class _FloatingActionGroup extends StatelessWidget {
  const _FloatingActionGroup({
    required this.isVisible,
    required this.filterCount,
    required this.isSearchActive,
    required this.onSearchPressed,
    required this.onFilterPressed,
    required this.onFilterLongPress,
    required this.onAddPressed,
  });

  final bool isVisible;
  final int filterCount;
  final bool isSearchActive;
  final VoidCallback onSearchPressed;
  final VoidCallback onFilterPressed;
  final VoidCallback onFilterLongPress;
  final VoidCallback onAddPressed;

  static const _iconColor = Colors.white;
  static const _iconShadows = [Shadow(color: Colors.black45, blurRadius: 4)];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        offset: isVisible ? Offset.zero : const Offset(0, 1.6),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          opacity: isVisible ? 1 : 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: isSearchActive ? 'Close search' : 'Search users',
                  onPressed: onSearchPressed,
                  style: isSearchActive
                      ? IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                        )
                      : null,
                  icon: Icon(
                    isSearchActive ? Icons.close_rounded : Icons.search_rounded,
                    color: _iconColor,
                    size: 24,
                    shadows: _iconShadows,
                  ),
                ),
                IconButton(
                  tooltip: 'Filter by Role',
                  onPressed: onFilterPressed,
                  onLongPress: onFilterLongPress,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        color: _iconColor,
                        size: 24,
                        shadows: _iconShadows,
                      ),
                      if (filterCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: _CountBadge(count: filterCount),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Add staff user',
                  onPressed: onAddPressed,
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: _iconColor,
                    size: 24,
                    shadows: _iconShadows,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small circular badge showing an active filter count, styled to stay
/// legible against the bright icons on the semi-transparent pill.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }
}
