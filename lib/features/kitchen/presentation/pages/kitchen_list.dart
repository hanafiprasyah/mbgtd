import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_bloc.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_event.dart';
import 'package:mbg_test/features/kitchen/bloc/kitchen_state.dart';
import 'package:mbg_test/features/kitchen/data/models/kitchen_model.dart';

class KitchenListScreen extends StatelessWidget {
  const KitchenListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => KitchenBloc()..add(const LoadKitchens()),
      child: const _KitchenListView(),
    );
  }
}

class _KitchenListView extends StatefulWidget {
  const _KitchenListView();

  @override
  State<_KitchenListView> createState() => _KitchenListViewState();
}

class _KitchenListViewState extends State<_KitchenListView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  String _query = '';
  bool _isSearchVisible = false;
  bool _isFabGroupVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
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

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _query = '';
    });
  }

  List<KitchenModel> _filterKitchens(List<KitchenModel> kitchens) {
    if (_query.trim().isEmpty) return kitchens;
    final query = _query.trim().toLowerCase();
    return kitchens
        .where(
          (kitchen) =>
              kitchen.name.toLowerCase().contains(query) ||
              kitchen.id.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocConsumer<KitchenBloc, KitchenState>(
        listener: (context, state) {
          if (state is KitchenError) {
            GlobalScaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 1),
              ),
            );
          }
          if (state is KitchenOperationSuccess) {
            GlobalScaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 1),
              ),
            );
            context.read<KitchenBloc>().add(const LoadKitchens());
          }
        },
        builder: (context, state) {
          final allKitchens = state is KitchenLoaded
              ? state.kitchens
              : <KitchenModel>[];
          final kitchens = _filterKitchens(allKitchens);

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar.large(
                title: const Text('Manage Kitchens'),
                centerTitle: false,
                scrolledUnderElevation: 0,
                pinned: true,
              ),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      alignment: Alignment.topCenter,
                      child: child,
                    ),
                  ),
                  child: _isSearchVisible
                      ? Padding(
                          key: const ValueKey('search-field'),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: InputDecoration(
                              hintText: 'Search by name or ID',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: _clearSearch,
                                    )
                                  : null,
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLow,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('search-hidden')),
                ),
              ),
              if (state is KitchenLoading || state is KitchenInitial)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is KitchenError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon: Icons.error_outline_rounded,
                    iconColor: colorScheme.error,
                    title: 'Something went wrong',
                    message: state.message,
                  ),
                )
              else if (allKitchens.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon: Icons.storefront_outlined,
                    title: 'No kitchens yet',
                    message: 'Add your first kitchen to get started.',
                  ),
                )
              else if (kitchens.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _StateMessage(
                    icon: Icons.search_off_rounded,
                    title: 'No results found',
                    message: 'No kitchen matches "$_query".',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    96, // leave room so the floating pill never covers content
                  ),
                  sliver: AnimationLimiter(
                    child: SliverList.separated(
                      itemCount: kitchens.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final kitchen = kitchens[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 32,
                            child: FadeInAnimation(
                              child: _KitchenCard(kitchen: kitchen),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: _KitchenFabGroup(
        isVisible: _isFabGroupVisible,
        isSearchActive: _isSearchVisible,
        onSearchPressed: _toggleSearch,
        onAddPressed: () => Navigator.pushNamed(context, '/kitchen-add'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// A pill-shaped floating group combining the search and add-kitchen
/// actions, matching the pattern used on the volunteer list page. Sits on
/// a semi-transparent primary background and hides itself when the list
/// is scrolled down, reappearing when scrolled back up.
class _KitchenFabGroup extends StatelessWidget {
  const _KitchenFabGroup({
    required this.isVisible,
    required this.isSearchActive,
    required this.onSearchPressed,
    required this.onAddPressed,
  });

  final bool isVisible;
  final bool isSearchActive;
  final VoidCallback onSearchPressed;
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
                  tooltip: isSearchActive ? 'Hide Search' : 'Search',
                  onPressed: onSearchPressed,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      isSearchActive
                          ? Icons.search_off_rounded
                          : Icons.search_rounded,
                      key: ValueKey(isSearchActive),
                      color: _iconColor,
                      size: 24,
                      shadows: _iconShadows,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Add Kitchen',
                  onPressed: onAddPressed,
                  icon: const Icon(
                    Icons.add_business_rounded,
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

class _KitchenCard extends StatelessWidget {
  final KitchenModel kitchen;
  const _KitchenCard({required this.kitchen});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initial = kitchen.name.isNotEmpty
        ? kitchen.name.characters.first.toUpperCase()
        : '?';

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/kitchen-detail',
            arguments: kitchen.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  initial,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kitchen.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Head: ${kitchen.ketua}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          kitchen.id,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String message;

  const _StateMessage({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: iconColor ?? colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
