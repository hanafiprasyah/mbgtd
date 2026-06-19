import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _loadViewMode();
    context.read<FoodBloc>().add(LoadFoods());
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

  void _openSearchModal() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchModal(initialValue: _searchQuery),
    );
    if (result != null) {
      setState(() {
        _searchQuery = result;
      });
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearchModal,
          ),
          IconButton(
            icon: _isGrid ? Icon(Icons.view_list) : Icon(Icons.grid_view),
            tooltip: _isGrid ? 'Switch to List' : 'Switch to Grid',
            onPressed: () async {
              setState(() {
                _isGrid = !_isGrid;
              });
              await _saveViewMode();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FoodFormScreen()),
              );
            },
            tooltip: 'Add new menu',
          ),
        ],
      ),
      body: BlocConsumer<FoodBloc, FoodState>(
        listener: (context, state) {
          if (state.status == FoodStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
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
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (state.status == FoodStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: colorScheme.error),
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

          final foods = state.foods;
          final Map<String, List<Food>> groupedFoods = {};
          for (var food in foods) {
            final key = food.periode.split('-').first.trim();
            if (!groupedFoods.containsKey(key)) {
              groupedFoods[key] = [];
            }
            groupedFoods[key]!.add(food);
          }
          final sortedKeys = groupedFoods.keys.toList()
            ..sort((a, b) {
              final numA =
                  int.tryParse(RegExp(r'\d+').firstMatch(a)?.group(0) ?? '') ??
                  0;
              final numB =
                  int.tryParse(RegExp(r'\d+').firstMatch(b)?.group(0) ?? '') ??
                  0;
              return numA.compareTo(numB);
            });

          if (foods.isEmpty) {
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
                                  duration: const Duration(milliseconds: 700),
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
                                                  FoodDetailScreen(food: food),
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
                                            backgroundColor: Colors.transparent,
                                            builder: (_) {
                                              return Container(
                                                padding: const EdgeInsets.all(
                                                  20,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.surface,
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          24,
                                                        ),
                                                      ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
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
                                                          color: Colors.grey
                                                              .withValues(
                                                                alpha: 0.3,
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
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.calendar_today,
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
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.person_outline,
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
                                                    const SizedBox(height: 16),
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
                                                  BorderRadius.circular(6),
                                              border:
                                                  _selectedFoodId ==
                                                      food.id.toString()
                                                  ? Border.all(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                      width: 2,
                                                    )
                                                  : null,
                                              boxShadow:
                                                  _selectedFoodId ==
                                                      food.id.toString()
                                                  ? [
                                                      BoxShadow(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withValues(
                                                              alpha: 0.25,
                                                            ),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
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
                                    duration: const Duration(milliseconds: 700),
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
                                                  BorderRadius.circular(20),
                                            ),
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(20),
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
                                                padding: const EdgeInsets.all(
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
                                                        child: _buildFoodImage(
                                                          food.photoUrl,
                                                          food,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
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
                                                                      FontWeight
                                                                          .w700,
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
                                                                      color: colorScheme
                                                                          .onSurfaceVariant,
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
                                                                      color: colorScheme
                                                                          .onSurfaceVariant,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const Icon(
                                                      Icons.arrow_forward_ios,
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

class _SearchModal extends StatefulWidget {
  final String initialValue;
  const _SearchModal({this.initialValue = ''});

  @override
  State<_SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends State<_SearchModal> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _controller.text);
        }
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Search field
              TextField(
                controller: _controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Looking for Chef/Menu/Period?",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.grey[900],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white),
                          tooltip: 'Clear',
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                            context.read<FoodBloc>().add(SearchMenu(''));
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  if (_debounce?.isActive ?? false) _debounce!.cancel();

                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    context.read<FoodBloc>().add(SearchMenu(value));
                  });
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
