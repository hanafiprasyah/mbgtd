import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_state.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';

const _teamOptions = [
  'Chef',
  'ASLAP',
  'Persiapan',
  'Masak',
  'Distribusi',
  'Packing',
  'Pencucian',
  'Satpam',
];

const _genderOptions = ['Laki-laki', 'Perempuan'];

class VolunteerListPage extends StatefulWidget {
  const VolunteerListPage({super.key});

  @override
  State<VolunteerListPage> createState() => _VolunteerListPageState();
}

class _VolunteerListPageState extends State<VolunteerListPage> {
  final _searchController = TextEditingController();

  String? _selectedTim;
  String? _selectedGender;
  bool _isSearching = false;
  String? _pendingDeleteName;

  int get _activeFilterCount {
    var count = 0;
    if (_selectedTim != null) count++;
    if (_selectedGender != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    context.read<VolunteerBloc>().add(LoadVolunteer());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyCurrentCriteria() {
    final query = _searchController.text.trim();
    context.read<VolunteerBloc>().add(
      SearchVolunteer(query, _selectedTim, _selectedGender),
    );
  }

  void _resetFilters() {
    if (_activeFilterCount == 0) return;

    setState(() {
      _selectedTim = null;
      _selectedGender = null;
    });
    _applyCurrentCriteria();
  }

  void _clearSearch() {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _searchController.clear();
      _isSearching = false;
    });
    _applyCurrentCriteria();
  }

  void _onSearchChanged(String value) {
    setState(() => _isSearching = value.trim().isNotEmpty);
    _applyCurrentCriteria();
  }

  Future<void> _openFilterDialog() async {
    final result = await showDialog<_VolunteerFilter>(
      context: context,
      builder: (dialogContext) {
        var tempTim = _selectedTim;
        var tempGender = _selectedGender;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Volunteer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: tempTim,
                    hint: const Text('Team'),
                    items: _teamOptions
                        .map(
                          (team) =>
                              DropdownMenuItem(value: team, child: Text(team)),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => tempTim = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: tempGender,
                    hint: const Text('Gender'),
                    items: _genderOptions
                        .map(
                          (gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => tempGender = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      tempTim = null;
                      tempGender = null;
                    });
                  },
                  child: const Text('Reset'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      _VolunteerFilter(tim: tempTim, gender: tempGender),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      _selectedTim = result.tim;
      _selectedGender = result.gender;
    });
    _applyCurrentCriteria();
  }

  Future<void> _confirmDelete(Volunteer volunteer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete ${volunteer.namaLengkap}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    _pendingDeleteName = volunteer.namaLengkap;
    context.read<VolunteerBloc>().add(DeleteVolunteer(volunteer.id));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Volunteer'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          _FilterActionButton(
            count: _activeFilterCount,
            onPressed: _openFilterDialog,
            onLongPress: _resetFilters,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Volunteer',
            onPressed: () => Navigator.pushNamed(context, '/volunteer-add'),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _SearchField(
              controller: _searchController,
              isSearching: _isSearching,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
            if (_activeFilterCount > 0)
              _ActiveFilterChips(
                selectedTim: _selectedTim,
                selectedGender: _selectedGender,
                onRemoveTim: () {
                  setState(() => _selectedTim = null);
                  _applyCurrentCriteria();
                },
                onRemoveGender: () {
                  setState(() => _selectedGender = null);
                  _applyCurrentCriteria();
                },
              ),
            Expanded(
              child: BlocConsumer<VolunteerBloc, VolunteerState>(
                listener: (context, state) {
                  if (state is VolunteerLoaded || state is VolunteerError) {
                    setState(() => _isSearching = false);
                  }

                  if (state is VolunteerSuccess && state.volunteer == null) {
                    final name = _pendingDeleteName;
                    _pendingDeleteName = null;
                    if (name != null) {
                      _showSnackBar('$name deleted');
                    }
                  }

                  if (state is VolunteerError) {
                    _pendingDeleteName = null;
                    _showSnackBar(state.message);
                  }
                },
                builder: (context, state) {
                  if (state is VolunteerLoaded) {
                    return _VolunteerList(
                      volunteers: state.volunteer,
                      onDelete: _confirmDelete,
                    );
                  }

                  if (state is VolunteerError) {
                    return _ErrorState(message: state.message);
                  }

                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VolunteerFilter {
  const _VolunteerFilter({this.tim, this.gender});

  final String? tim;
  final String? gender;
}

class _FilterActionButton extends StatelessWidget {
  const _FilterActionButton({
    required this.count,
    required this.onPressed,
    required this.onLongPress,
  });

  final int count;
  final VoidCallback onPressed;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.tune_rounded,
            color: count > 0 ? colorScheme.primary : null,
          ),
          tooltip: 'Filter',
          onPressed: onPressed,
          onLongPress: onLongPress,
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isSearching,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isSearching;
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
          decoration: InputDecoration(
            hintText: 'Search volunteer...',
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
            suffixIcon: isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : controller.text.isNotEmpty
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

class _ActiveFilterChips extends StatelessWidget {
  const _ActiveFilterChips({
    required this.selectedTim,
    required this.selectedGender,
    required this.onRemoveTim,
    required this.onRemoveGender,
  });

  final String? selectedTim;
  final String? selectedGender;
  final VoidCallback onRemoveTim;
  final VoidCallback onRemoveGender;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (selectedTim != null)
            Chip(
              label: Text('Tim: $selectedTim'),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: colorScheme.primaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
              onDeleted: onRemoveTim,
            ),
          if (selectedGender != null)
            Chip(
              label: Text('Gender: $selectedGender'),
              deleteIcon: const Icon(Icons.close_rounded, size: 18),
              backgroundColor: colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
              onDeleted: onRemoveGender,
            ),
        ],
      ),
    );
  }
}

class _VolunteerList extends StatelessWidget {
  const _VolunteerList({required this.volunteers, required this.onDelete});

  final List<Volunteer> volunteers;
  final Future<void> Function(Volunteer volunteer) onDelete;

  @override
  Widget build(BuildContext context) {
    if (volunteers.isEmpty) {
      return const _EmptyState();
    }

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      scrollCacheExtent: ScrollCacheExtent.pixels(500),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: volunteers.length,
      itemBuilder: (context, index) {
        final volunteer = volunteers[index];

        return _VolunteerTile(
          volunteer: volunteer,
          index: index,
          onDelete: () => onDelete(volunteer),
        );
      },
    );
  }
}

class _VolunteerTile extends StatelessWidget {
  const _VolunteerTile({
    required this.volunteer,
    required this.index,
    required this.onDelete,
  });

  final Volunteer volunteer;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final delay = Duration(milliseconds: (index * 40).clamp(0, 320));

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 240 + delay.inMilliseconds),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Hero(
          tag: 'volunteer_card_${volunteer.id}',
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/volunteer-detail',
                  arguments: volunteer,
                );
              },
              child: Ink(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _VolunteerAvatar(volunteer: volunteer),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _VolunteerSummary(volunteer: volunteer)),
                      IconButton(
                        icon: Icon(
                          Icons.qr_code_rounded,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Generate QR',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/qr-generator',
                            arguments: volunteer,
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: colorScheme.error,
                        ),
                        tooltip: 'Delete',
                        onPressed: onDelete,
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
  }
}

class _VolunteerAvatar extends StatelessWidget {
  const _VolunteerAvatar({required this.volunteer});

  final Volunteer volunteer;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = volunteer.isActive;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          volunteer.namaLengkap.trim().isNotEmpty
              ? volunteer.namaLengkap.trim()[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _VolunteerSummary extends StatelessWidget {
  const _VolunteerSummary({required this.volunteer});

  final Volunteer volunteer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          volunteer.namaLengkap,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            _VolunteerMetaChip(
              icon: Icons.groups_rounded,
              label: volunteer.tim,
            ),
            _VolunteerMetaChip(
              icon: Icons.badge_outlined,
              label: volunteer.jenisKelamin,
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 36,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No volunteer found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different keyword or filter.',
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _VolunteerMetaChip extends StatelessWidget {
  const _VolunteerMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
