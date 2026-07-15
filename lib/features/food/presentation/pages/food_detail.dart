import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/features/food/bloc/food_bloc.dart';
import 'package:mbg_test/features/food/bloc/food_event.dart';
import 'package:mbg_test/features/food/bloc/food_state.dart';
import 'package:mbg_test/features/food/data/models/food_model.dart';

class FoodDetailScreen extends StatefulWidget {
  final Food food;
  const FoodDetailScreen({super.key, required this.food});

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  // True only while THIS screen is waiting on the result of a delete it
  // itself triggered. Without this guard, the listener below would also
  // react to unrelated "success" states -- e.g. an update finishing on the
  // Form screen pushed on top of this one, or the LoadFoods() refresh that
  // automatically follows every add/update/delete -- and pop this screen
  // too, which is what caused the "back 2 pages" bug.
  bool _isDeleting = false;

  // The food currently displayed. Starts as widget.food, but gets replaced
  // with the fresh copy from state.foods whenever the bloc reloads the
  // list (e.g. right after this item was edited), so the screen reflects
  // the saved changes without the user having to navigate away and back.
  late Food _food;

  @override
  void initState() {
    super.initState();
    _food = widget.food;
  }

  Food get food => _food;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<FoodBloc, FoodState>(
      listenWhen: (previous, current) =>
          (_isDeleting && previous.status != current.status) ||
          current.status == FoodStatus.success,
      listener: (context, state) {
        if (_isDeleting) {
          if (state.status == FoodStatus.success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Success deleted ${food.name}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            }
            _isDeleting = false;
            Navigator.pop(context);
            return;
          }
          if (state.status == FoodStatus.error) {
            _isDeleting = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
            return;
          }
        }

        // Pick up the latest version of this item from the refreshed list
        // (e.g. after an edit on the Form screen triggers LoadFoods()) so
        // the details shown here stay in sync with what was just saved.
        final updated = state.foods.firstWhere(
          (f) => f.id == _food.id,
          orElse: () => _food,
        );
        if (updated != _food) {
          setState(() => _food = updated);
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          backgroundColor: colorScheme.surfaceContainerLowest,
          surfaceTintColor: Colors.transparent,
          title: const Text('Menu Details'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(context, '/food-edit', arguments: food);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: GestureDetector(
                  onTap: () => _showFullScreenImage(context, food.photoUrl),
                  child: Hero(
                    transitionOnUserGestures: true,
                    curve: Curves.easeInOut,
                    tag: 'food-${food.id}',
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRect(
                          child: Image.network(
                            food.photoUrl ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Image.asset(
                                'assets/placeholder.jpeg',
                                fit: BoxFit.cover,
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/placeholder.jpeg',
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today, 'Period', food.periode),
                    _buildInfoRow(Icons.person, 'Created by', food.dibuatOleh),
                    _buildInfoRow(
                      Icons.restaurant,
                      'Cooked by',
                      food.dimasakOleh,
                    ),
                    _buildInfoRow(
                      Icons.verified_user,
                      'Evaluated by',
                      food.diketahuiOleh,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Nutritional Values (AKG)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildAKGCard(
                      'Carbohydrate',
                      food.karbohidrat,
                      Colors.orange,
                    ),
                    _buildAKGCard('Protein', food.protein, Colors.red),
                    _buildAKGCard('Fat', food.lemak, Colors.yellow.shade700),
                    _buildAKGCard('Energy', food.energi, Colors.green),
                    _buildAKGCard('Fiber', food.serat, Colors.teal),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAKGCard(String title, double value, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  title[0],
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 16),
            Text(title, style: TextStyle(fontSize: 16)),
            Spacer(),
            Text(
              '${value.toStringAsFixed(1)} g',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String? url) {
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.95),
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta != null &&
                        details.primaryDelta! > 12) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
              Center(
                child: Hero(
                  tag: 'food-${food.id}',
                  child: GestureDetector(
                    onTap:
                        () {}, // prevent tap from closing when tapping the image
                    child: _ZoomableImage(url: url),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Menu'),
        content: Text('Are you sure you want to delete "${food.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              context.read<FoodBloc>().add(DeleteFood(food.id!));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String url;
  const _ZoomableImage({required this.url});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTap() {
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _controller.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(2.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        minScale: 1,
        maxScale: 5,
        child: Image.network(
          widget.url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Image.asset('assets/placeholder.jpeg', fit: BoxFit.contain);
          },
        ),
      ),
    );
  }
}
