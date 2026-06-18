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
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: GestureDetector(
                  onTap: () => _showFullScreenImage(context, food.photoUrl),
                  child: Hero(
                    tag: 'food-${food.id}',
                    child: food.photoUrl != null
                        ? Image.network(food.photoUrl!, fit: BoxFit.cover)
                        : Container(color: Colors.grey[300]),
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
    if (url == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
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
