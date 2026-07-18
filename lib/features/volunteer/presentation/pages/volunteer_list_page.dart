import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/core/helper/global_scaffold_messenger.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_state.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/chip.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/field.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/state_widget.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Watches route changes so we can dismiss the keyboard whenever a new
/// route (e.g. the volunteer detail page) is pushed on top of this page.
/// Register this in your app's `MaterialApp(navigatorObservers: [...])` —
/// see note in `_VolunteerListPageState.didChangeDependencies`.
final RouteObserver<ModalRoute<void>> volunteerRouteObserver =
    RouteObserver<ModalRoute<void>>();

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

enum VolunteerSortField { none, age, name }

class VolunteerListPage extends StatefulWidget {
  const VolunteerListPage({super.key});

  @override
  State<VolunteerListPage> createState() => _VolunteerListPageState();
}

class _VolunteerListPageState extends State<VolunteerListPage> with RouteAware {
  final _searchController = TextEditingController();

  String? _selectedTim;
  String? _selectedGender;
  bool? _selectedIsActive;
  bool _isSearching = false;
  String? _pendingDeleteName;
  VolunteerSortField _sortField = VolunteerSortField.none;
  bool _sortAscending = true;
  bool _isSearchVisible = false;
  Map<String, dynamic>? userData;

  int get _activeFilterCount {
    var count = 0;
    if (_selectedTim != null) count++;
    if (_selectedGender != null) count++;
    if (_selectedIsActive != null) count++;
    return count;
  }

  List<Volunteer> _filterByStatus(List<Volunteer> volunteers) {
    if (_selectedIsActive == null) return volunteers;
    return volunteers.where((v) => v.isActive == _selectedIsActive).toList();
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
      _selectedIsActive = null;
    });
    _applyCurrentCriteria();
  }

  void _onSortSelected(VolunteerSortField field) {
    setState(() {
      if (_sortField == field && field != VolunteerSortField.none) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  List<Volunteer> _sortVolunteers(List<Volunteer> volunteers) {
    if (_sortField == VolunteerSortField.none) return volunteers;

    final sorted = List<Volunteer>.from(volunteers);
    switch (_sortField) {
      case VolunteerSortField.age:
        sorted.sort(
          (a, b) => _ageFromBirthDate(
            a.tanggalLahir,
          ).compareTo(_ageFromBirthDate(b.tanggalLahir)),
        );
        break;
      case VolunteerSortField.name:
        sorted.sort(
          (a, b) => a.namaLengkap.toLowerCase().compareTo(
            b.namaLengkap.toLowerCase(),
          ),
        );
        break;
      case VolunteerSortField.none:
        break;
    }
    if (!_sortAscending) return sorted.reversed.toList();
    return sorted;
  }

  int _ageFromBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final birthdayPassedThisYear =
        now.month > birthDate.month ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!birthdayPassedThisYear) age--;
    return age;
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      _isSearchVisible = false;
    });
    _applyCurrentCriteria();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _isSearching = false;
      }
    });
    if (!_isSearchVisible) _applyCurrentCriteria();
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
        var tempIsActive = _selectedIsActive;

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
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<bool>(
                    isExpanded: true,
                    initialValue: tempIsActive,
                    hint: const Text('Status'),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('Active')),
                      DropdownMenuItem(value: false, child: Text('Inactive')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => tempIsActive = value);
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
                      tempIsActive = null;
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
                      _VolunteerFilter(
                        tim: tempTim,
                        gender: tempGender,
                        isActive: tempIsActive,
                      ),
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
      _selectedIsActive = result.isActive;
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
    GlobalScaffoldMessenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  Future<Map<String, dynamic>?> _getUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> _startLoadingSequence() async {
    final user = FirebaseAuth.instance.currentUser;
    final data = await _getUserRole(user?.uid ?? "");
    if (!mounted) return;
    setState(() {
      userData = data;
    });
  }

  @override
  void initState() {
    super.initState();
    context.read<VolunteerBloc>().add(LoadVolunteer());
    _startLoadingSequence();
    if (!mounted) return;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      volunteerRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    volunteerRouteObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    // Fires when a new route (e.g. volunteer detail page) is pushed on top
    // of this page, no matter where that push is triggered from (including
    // inside VolunteerTile). Dismiss the keyboard so it doesn't linger.
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final role = userData?['role'] as String?;

    final isAslap =
        user != null && role != null && role.toLowerCase().contains('aslap');
    final isDeveloper =
        user != null &&
        role != null &&
        role.toLowerCase().contains('developer');

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Volunteers'),
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: Navigator.canPop(context) ? 96 : 48,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (Navigator.canPop(context)) const BackButton(),
            _SortActionButton(
              selectedField: _sortField,
              ascending: _sortAscending,
              onSelected: _onSortSelected,
            ),
          ],
        ),
        actions: [
          FilterActionButton(
            count: _activeFilterCount,
            onPressed: _openFilterDialog,
            onLongPress: _resetFilters,
          ),

          if (isAslap || isDeveloper)
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1,
                  child: child,
                ),
              ),
              child: _isSearchVisible
                  ? SearchField(
                      key: const ValueKey('search-field'),
                      controller: _searchController,
                      isSearching: _isSearching,
                      onChanged: _onSearchChanged,
                      onClear: _clearSearch,
                    )
                  : const SizedBox.shrink(key: ValueKey('search-hidden')),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _activeFilterCount > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ActiveFilterChips(
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
                        if (_selectedIsActive != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: InputChip(
                              label: Text(
                                _selectedIsActive == true
                                    ? 'Active'
                                    : 'Inactive',
                              ),
                              onDeleted: () {
                                setState(() => _selectedIsActive = null);
                              },
                            ),
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
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
                      volunteers: _sortVolunteers(
                        _filterByStatus(state.volunteer),
                      ),
                      onDelete: _confirmDelete,
                      isDeveloper: isDeveloper,
                    );
                  }

                  if (state is VolunteerError) {
                    return ErrorState(message: state.message);
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
      floatingActionButton: _SearchFab(
        isActive: _isSearchVisible,
        onPressed: _toggleSearch,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _VolunteerFilter {
  const _VolunteerFilter({this.tim, this.gender, this.isActive});

  final String? tim;
  final String? gender;
  final bool? isActive;
}

class _SortActionButton extends StatelessWidget {
  const _SortActionButton({
    required this.selectedField,
    required this.ascending,
    required this.onSelected,
  });

  final VolunteerSortField selectedField;
  final bool ascending;
  final ValueChanged<VolunteerSortField> onSelected;

  String _labelFor(VolunteerSortField field) {
    final isSelected = selectedField == field;
    switch (field) {
      case VolunteerSortField.age:
        final youngestFirst = isSelected ? ascending : true;
        return youngestFirst ? 'Age (Youngest First)' : 'Age (Oldest First)';
      case VolunteerSortField.name:
        final aToZ = isSelected ? ascending : true;
        return aToZ ? 'Name (A-Z)' : 'Name (Z-A)';
      case VolunteerSortField.none:
        return 'Default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = selectedField != VolunteerSortField.none;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<VolunteerSortField>(
      tooltip: 'Sort',
      initialValue: selectedField,
      onSelected: onSelected,
      icon: Icon(Icons.sort, color: isActive ? colorScheme.primary : null),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: VolunteerSortField.none,
          checked: selectedField == VolunteerSortField.none,
          child: const Text('Default'),
        ),
        CheckedPopupMenuItem(
          value: VolunteerSortField.age,
          checked: selectedField == VolunteerSortField.age,
          child: _SortMenuLabel(
            label: _labelFor(VolunteerSortField.age),
            showDirection: selectedField == VolunteerSortField.age,
            ascending: ascending,
          ),
        ),
        CheckedPopupMenuItem(
          value: VolunteerSortField.name,
          checked: selectedField == VolunteerSortField.name,
          child: _SortMenuLabel(
            label: _labelFor(VolunteerSortField.name),
            showDirection: selectedField == VolunteerSortField.name,
            ascending: ascending,
          ),
        ),
      ],
    );
  }
}

class _SortMenuLabel extends StatelessWidget {
  const _SortMenuLabel({
    required this.label,
    required this.showDirection,
    required this.ascending,
  });

  final String label;
  final bool showDirection;
  final bool ascending;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(child: Text(label)),
        if (showDirection)
          Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16),
      ],
    );
  }
}

class _VolunteerList extends StatelessWidget {
  const _VolunteerList({
    required this.volunteers,
    required this.onDelete,
    required this.isDeveloper,
  });

  final List<Volunteer> volunteers;
  final Future<void> Function(Volunteer volunteer) onDelete;
  final bool isDeveloper;

  @override
  Widget build(BuildContext context) {
    if (volunteers.isEmpty) {
      return const EmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        scrollCacheExtent: ScrollCacheExtent.pixels(500),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: volunteers.length,
        itemBuilder: (context, index) {
          final volunteer = volunteers[index];

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 300),
            child: SlideAnimation(
              verticalOffset: 60.0,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(
                curve: Curves.easeIn,
                child: ScaleAnimation(
                  scale: 0.94,
                  curve: Curves.easeOutBack,
                  child: VolunteerTile(
                    volunteer: volunteer,
                    index: index,
                    onDelete: () => onDelete(volunteer),
                    isDeveloper: isDeveloper,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchFab extends StatelessWidget {
  const _SearchFab({required this.isActive, required this.onPressed});

  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: isActive ? 'Hide Search' : 'Search',
        backgroundColor: isActive ? colorScheme.primary : null,
        foregroundColor: isActive ? colorScheme.onPrimary : null,
        elevation: isActive ? 0 : 4,
        mini: true,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            isActive ? Icons.search_off_rounded : Icons.search_rounded,
            key: ValueKey(isActive),
          ),
        ),
      ),
    );
  }
}
