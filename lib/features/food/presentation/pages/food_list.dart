import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/food/bloc/food_bloc.dart';
import 'package:mbg_test/features/food/bloc/food_event.dart';
import 'package:mbg_test/features/food/bloc/food_state.dart';
import 'package:mbg_test/features/food/data/models/food_model.dart';
import 'package:mbg_test/features/food/presentation/pages/food_detail.dart';
import 'package:mbg_test/features/food/presentation/pages/food_form.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FoodListScreen extends StatefulWidget {
  const FoodListScreen({super.key});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  bool _isGrid = false;
  final _storage = const FlutterSecureStorage();
  static const _viewKey = 'food_view_mode';
  String? _selectedFoodId;
  String? _selectedPeriod;

  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearchVisible = false;

  final _scrollController = ScrollController();
  bool _isFabGroupVisible = true;
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    context.read<FoodBloc>().add(LoadFoods());
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
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

  Future<void> _loadViewMode() async {
    final value = await _storage.read(key: _viewKey);
    if (value != null) {
      setState(() {
        _isGrid = value == 'grid';
      });
    }
  }

  Future<void> _saveViewMode() async {
    await _storage.write(key: _viewKey, value: _isGrid ? 'grid' : 'list');
  }

  void _toggleSearch() {
    setState(() => _isSearchVisible = !_isSearchVisible);

    if (!_isSearchVisible && _searchController.text.isNotEmpty) {
      _searchDebounce?.cancel();
      _searchController.clear();
      context.read<FoodBloc>().add(SearchMenu(''));
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      context.read<FoodBloc>().add(SearchMenu(value));
    });
  }

  void _onSearchClear() {
    _searchDebounce?.cancel();
    setState(() => _searchController.clear());
    context.read<FoodBloc>().add(SearchMenu(''));
  }

  static String _periodKey(String periode) => periode.split('-').first.trim();

  static int _periodSortValue(String key) {
    return int.tryParse(RegExp(r'\d+').firstMatch(key)?.group(0) ?? '') ?? 0;
  }

  void _onSelectPeriod(String? period) {
    setState(() => _selectedPeriod = period);
  }

  Future<void> _showPeriodFilterSheet(List<String> periods) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                'Filter by Period',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Periods'),
                    selected: _selectedPeriod == null,
                    onSelected: (_) {
                      _onSelectPeriod(null);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  ...periods.map((period) {
                    return ChoiceChip(
                      label: Text(period),
                      selected: _selectedPeriod == period,
                      onSelected: (_) {
                        _onSelectPeriod(period);
                        Navigator.pop(sheetContext);
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Food Bank'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _isSearchVisible
                ? _FoodSearchField(
                    key: const ValueKey('search-visible'),
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onClear: _onSearchClear,
                  )
                : const SizedBox.shrink(key: ValueKey('search-hidden')),
          ),
          Expanded(
            child: BlocConsumer<FoodBloc, FoodState>(
              listener: (context, state) {
                if (state.status == FoodStatus.error) {
                  GlobalScaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${state.errorMessage ?? 'Something went wrong'}',
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state.status == FoodStatus.loading) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }

                if (state.status == FoodStatus.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Oops! Something went wrong.',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.errorMessage ?? 'Please try again later.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {
                            context.read<FoodBloc>().add(LoadFoods());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final allFoods = state.foods;

                final foods = _selectedPeriod == null
                    ? allFoods
                    : allFoods
                          .where(
                            (f) => _periodKey(f.periode) == _selectedPeriod,
                          )
                          .toList();

                final Map<String, List<Food>> groupedFoods = {};
                for (var food in foods) {
                  final key = _periodKey(food.periode);
                  if (!groupedFoods.containsKey(key)) {
                    groupedFoods[key] = [];
                  }
                  groupedFoods[key]!.add(food);
                }
                final sortedKeys = groupedFoods.keys.toList()
                  ..sort(
                    (a, b) =>
                        _periodSortValue(a).compareTo(_periodSortValue(b)),
                  );

                if (foods.isEmpty && _selectedPeriod != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.filter_alt_off_rounded,
                            size: 72,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No menu items for "$_selectedPeriod"',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _onSelectPeriod(null),
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text('Clear filter'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (allFoods.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primaryContainer.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              size: 80,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No menu items yet',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Start by adding your first delicious dish!\nTap the New Menu button to get started.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                }

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ...sortedKeys.map((key) {
                      final groupTitle = key;
                      final items = groupedFoods[key]!;

                      return SliverMainAxisGroup(
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyHeaderDelegate(
                              title: groupTitle,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            sliver: _isGrid
                                ? SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 3,
                                          crossAxisSpacing: 3,
                                          childAspectRatio: 1,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final food = items[index];
                                      return AnimationConfiguration.staggeredGrid(
                                        position: index,
                                        duration: const Duration(
                                          milliseconds: 700,
                                        ),
                                        columnCount: 3,
                                        child: ScaleAnimation(
                                          scale: 0.9,
                                          curve: Curves.easeOutBack,
                                          child: FadeInAnimation(
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        FoodDetailScreen(
                                                          food: food,
                                                        ),
                                                  ),
                                                );
                                              },
                                              onLongPress: () {
                                                setState(() {
                                                  _selectedFoodId = food.id
                                                      .toString();
                                                });
                                                HapticFeedback.mediumImpact();
                                                showModalBottomSheet(
                                                  context: context,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  builder: (_) {
                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            20,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.surface,
                                                        borderRadius:
                                                            const BorderRadius.vertical(
                                                              top:
                                                                  Radius.circular(
                                                                    24,
                                                                  ),
                                                            ),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Center(
                                                            child: Container(
                                                              width: 40,
                                                              height: 4,
                                                              margin:
                                                                  const EdgeInsets.only(
                                                                    bottom: 16,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .grey
                                                                    .withValues(
                                                                      alpha:
                                                                          0.3,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            food.name,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .titleLarge
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .calendar_today,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  food.periode,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 8,
                                                          ),
                                                          Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .person_outline,
                                                                size: 16,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  'By ${food.dibuatOleh}',
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ).whenComplete(() {
                                                  setState(() {
                                                    _selectedFoodId = null;
                                                  });
                                                });
                                              },
                                              child: AnimatedScale(
                                                scale:
                                                    _selectedFoodId ==
                                                        food.id.toString()
                                                    ? 1.04
                                                    : 1.0,
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                curve: Curves.easeOutCubic,
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 220,
                                                  ),
                                                  curve: Curves.easeOutCubic,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border:
                                                        _selectedFoodId ==
                                                            food.id.toString()
                                                        ? Border.all(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary,
                                                            width: 2,
                                                          )
                                                        : null,
                                                    boxShadow:
                                                        _selectedFoodId ==
                                                            food.id.toString()
                                                        ? [
                                                            BoxShadow(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                      .withValues(
                                                                        alpha:
                                                                            0.25,
                                                                      ),
                                                              blurRadius: 12,
                                                              spreadRadius: 1,
                                                            ),
                                                          ]
                                                        : [],
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    child: AnimatedOpacity(
                                                      duration: const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                      opacity:
                                                          _selectedFoodId ==
                                                              food.id.toString()
                                                          ? 0.92
                                                          : 1.0,
                                                      child: _buildFoodImage(
                                                        food.photoUrl,
                                                        food,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }, childCount: items.length),
                                  )
                                : SliverList(
                                    delegate: SliverChildListDelegate(
                                      items.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final food = entry.value;
                                        return AnimationConfiguration.staggeredList(
                                          position: index,
                                          duration: const Duration(
                                            milliseconds: 700,
                                          ),
                                          child: SlideAnimation(
                                            verticalOffset: 80.0,
                                            curve: Curves.easeOutCubic,
                                            child: FadeInAnimation(
                                              curve: Curves.easeIn,
                                              child: ScaleAnimation(
                                                scale: 0.92,
                                                curve: Curves.easeOutBack,
                                                child: Card(
                                                  margin: const EdgeInsets.only(
                                                    bottom: 16,
                                                  ),
                                                  elevation: 2,
                                                  shadowColor: Colors.black
                                                      .withValues(alpha: 0.08),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              FoodDetailScreen(
                                                                food: food,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            12.0,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                            child: SizedBox(
                                                              width: 72,
                                                              height: 72,
                                                              child:
                                                                  _buildFoodImage(
                                                                    food.photoUrl,
                                                                    food,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 16,
                                                          ),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  food.name,
                                                                  style: textTheme
                                                                      .titleMedium
                                                                      ?.copyWith(
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                        color: colorScheme
                                                                            .onSurface,
                                                                      ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .calendar_today,
                                                                      size: 14,
                                                                      color: colorScheme
                                                                          .onSurfaceVariant,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 4,
                                                                    ),
                                                                    Text(
                                                                      food.periode,
                                                                      style: textTheme
                                                                          .bodySmall
                                                                          ?.copyWith(
                                                                            color:
                                                                                colorScheme.onSurfaceVariant,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                  height: 4,
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .person_outline,
                                                                      size: 14,
                                                                      color: colorScheme
                                                                          .onSurfaceVariant,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 4,
                                                                    ),
                                                                    Text(
                                                                      'By ${food.dibuatOleh}',
                                                                      style: textTheme
                                                                          .bodySmall
                                                                          ?.copyWith(
                                                                            color:
                                                                                colorScheme.onSurfaceVariant,
                                                                          ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          const Icon(
                                                            Icons
                                                                .arrow_forward_ios,
                                                            size: 16,
                                                            color: Colors.grey,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<FoodBloc, FoodState>(
        buildWhen: (previous, current) => previous.foods != current.foods,
        builder: (context, state) {
          final periods =
              state.foods.map((f) => _periodKey(f.periode)).toSet().toList()
                ..sort(
                  (a, b) => _periodSortValue(a).compareTo(_periodSortValue(b)),
                );

          return _FloatingActionGroup(
            isVisible: _isFabGroupVisible,
            isGrid: _isGrid,
            isSearchActive: _isSearchVisible,
            isFilterActive: _selectedPeriod != null,
            onSearchPressed: _toggleSearch,
            onToggleView: () async {
              setState(() => _isGrid = !_isGrid);
              await _saveViewMode();
            },
            onFilterPressed: () => _showPeriodFilterSheet(periods),
            onAddPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoodFormScreen()),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// Builds image widget with optimized loading strategy
  /// Uses FadeInImage for smooth transition and placeholder
  Widget _buildFoodImage(String? photoUrl, Food food) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Image.asset('assets/placeholder.jpeg', fit: BoxFit.cover);
    }

    return Hero(
      transitionOnUserGestures: true,
      curve: Curves.easeInOut,
      tag: 'food-${food.id}',
      child: FadeInImage.assetNetwork(
        placeholder: 'assets/placeholder.jpeg',
        image: photoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 250,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        filterQuality: FilterQuality.low,
        imageErrorBuilder: (context, error, stackTrace) {
          return Image.asset('assets/placeholder.jpeg', fit: BoxFit.cover);
        },
      ),
    );
  }
}

/// A pill-shaped floating group that combines the Search, Grid/List
/// toggle, and Add New Menu actions, styled the same way as the one on
/// the volunteer list page: a semi-transparent primary-color pill with
/// bright, bold icons that hides on scroll down and reappears on scroll
/// up.
class _FloatingActionGroup extends StatelessWidget {
  const _FloatingActionGroup({
    required this.isVisible,
    required this.isGrid,
    required this.isSearchActive,
    required this.isFilterActive,
    required this.onSearchPressed,
    required this.onToggleView,
    required this.onFilterPressed,
    required this.onAddPressed,
  });

  final bool isVisible;
  final bool isGrid;
  final bool isSearchActive;
  final bool isFilterActive;
  final VoidCallback onSearchPressed;
  final VoidCallback onToggleView;
  final VoidCallback onFilterPressed;
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
                  tooltip: isGrid ? 'Switch to List' : 'Switch to Grid',
                  onPressed: onToggleView,
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      isGrid
                          ? Icons.view_list_rounded
                          : Icons.grid_view_rounded,
                      key: ValueKey(isGrid),
                      color: _iconColor,
                      size: 24,
                      shadows: _iconShadows,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: isFilterActive
                      ? 'Filter active (tap to change)'
                      : 'Filter by period',
                  onPressed: onFilterPressed,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        isFilterActive
                            ? Icons.filter_alt_rounded
                            : Icons.filter_alt_outlined,
                        color: _iconColor,
                        size: 24,
                        shadows: _iconShadows,
                      ),
                      if (isFilterActive)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.amberAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Add new menu',
                  onPressed: onAddPressed,
                  icon: const Icon(
                    Icons.add_rounded,
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  _StickyHeaderDelegate({
    required this.title,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: colorScheme.surfaceContainerLowest,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}

/// Inline, toggleable search field styled to match the volunteer list's
/// `SearchField` widget: a soft-shadowed pill with a tinted search icon
/// and a clear button, so the look stays consistent across features.
class _FoodSearchField extends StatelessWidget {
  const _FoodSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search menu...',
            prefixIcon: Padding(
              padding: const EdgeInsets.all(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear search',
                    onPressed: onClear,
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
