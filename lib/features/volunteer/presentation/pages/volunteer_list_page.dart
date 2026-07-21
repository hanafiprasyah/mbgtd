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
  final _scrollController = ScrollController();

  String? _selectedTim;
  String? _selectedGender;
  bool? _selectedIsActive;
  bool _isSearching = false;
  String? _pendingDeleteName;
  VolunteerSortField _sortField = VolunteerSortField.none;
  bool _sortAscending = true;
  bool _isSearchVisible = false;
  bool _isFabGroupVisible = true;
  double _lastScrollOffset = 0;
  Map<String, dynamic>? userData;
  List<Volunteer>? _cachedVolunteers;

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
    _scrollController.addListener(_handleScroll);
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
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    _dismissKeyboard();
  }

  @override
  void didPopNext() {
    _dismissKeyboard();
  }

  void _dismissKeyboard() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(FocusNode());
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
                  alignment: Alignment.topCenter,
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
                  if ((state is VolunteerLoaded || state is VolunteerError) &&
                      _isSearching) {
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
                    _cachedVolunteers = state.volunteer;
                  }

                  if (state is VolunteerError) {
                    return ErrorState(message: state.message);
                  }

                  final volunteers = state is VolunteerLoaded
                      ? state.volunteer
                      : _cachedVolunteers;

                  if (volunteers == null) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    );
                  }

                  return _VolunteerList(
                    volunteers: _sortVolunteers(_filterByStatus(volunteers)),
                    onDelete: _confirmDelete,
                    isDeveloper: isDeveloper,
                    scrollController: _scrollController,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _FloatingActionGroup(
        isVisible: _isFabGroupVisible,
        sortField: _sortField,
        sortAscending: _sortAscending,
        onSortSelected: _onSortSelected,
        filterCount: _activeFilterCount,
        onFilterPressed: _openFilterDialog,
        onFilterLongPress: _resetFilters,
        showAddButton: isAslap || isDeveloper,
        onAddPressed: () => Navigator.pushNamed(context, '/volunteer-add'),
        isSearchActive: _isSearchVisible,
        onSearchPressed: _toggleSearch,
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
    this.brightIcon = false,
  });

  final VolunteerSortField selectedField;
  final bool ascending;
  final ValueChanged<VolunteerSortField> onSelected;

  /// When true, forces a bright white, bold-looking icon suited for
  /// sitting on top of the semi-transparent primary-color floating pill.
  final bool brightIcon;

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

    final icon = Icon(
      Icons.sort_rounded,
      color: brightIcon
          ? Colors.white
          : (isActive ? colorScheme.primary : null),
      size: brightIcon ? 24 : null,
      shadows: brightIcon
          ? const [Shadow(color: Colors.black45, blurRadius: 4)]
          : null,
    );

    return PopupMenuButton<VolunteerSortField>(
      tooltip: 'Sort',
      initialValue: selectedField,
      onSelected: onSelected,
      icon: brightIcon && isActive
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                icon,
                const Positioned(right: -1, top: -1, child: _ActiveDot()),
              ],
            )
          : icon,
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

/// Represents a single row rendered inside the volunteer list: either a
/// section header (e.g. "Active Volunteer") or an actual volunteer entry.
class _VolunteerListRow {
  _VolunteerListRow.header(this.headerLabel) : volunteer = null;
  _VolunteerListRow.volunteer(Volunteer this.volunteer) : headerLabel = null;

  final String? headerLabel;
  final Volunteer? volunteer;

  bool get isHeader => headerLabel != null;
}

class _VolunteerSectionHeader extends StatelessWidget {
  const _VolunteerSectionHeader({
    required this.label,
    required this.topSpacing,
  });

  final String label;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(4, topSpacing, 4, 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerList extends StatelessWidget {
  const _VolunteerList({
    required this.volunteers,
    required this.onDelete,
    required this.isDeveloper,
    required this.scrollController,
  });

  final List<Volunteer> volunteers;
  final Future<void> Function(Volunteer volunteer) onDelete;
  final bool isDeveloper;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    if (volunteers.isEmpty) {
      return const EmptyState();
    }

    // Keep active volunteers up top and inactive ones in their own section
    // at the bottom. `volunteers` may already be sorted/filtered/searched
    // by the caller — partitioning here preserves that order within each
    // group, so sort/search/filter keep working exactly as before.
    final activeVolunteers = volunteers.where((v) => v.isActive).toList();
    final inactiveVolunteers = volunteers.where((v) => !v.isActive).toList();
    final showSections =
        activeVolunteers.isNotEmpty && inactiveVolunteers.isNotEmpty;

    final rows = <_VolunteerListRow>[
      if (showSections)
        _VolunteerListRow.header(
          'Active Volunteer (${activeVolunteers.length})',
        ),
      for (final v in activeVolunteers) _VolunteerListRow.volunteer(v),
      if (showSections)
        _VolunteerListRow.header(
          'Inactive Volunteer (${inactiveVolunteers.length})',
        ),
      for (final v in inactiveVolunteers) _VolunteerListRow.volunteer(v),
    ];

    return AnimationLimiter(
      child: ListView.builder(
        controller: scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        scrollCacheExtent: ScrollCacheExtent.pixels(500),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];

          if (row.isHeader) {
            return _VolunteerSectionHeader(
              label: row.headerLabel!,
              topSpacing: index == 0 ? 0 : 20,
            );
          }

          final volunteer = row.volunteer!;

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
                  child: Opacity(
                    opacity: volunteer.isActive ? 1 : 0.6,
                    child: VolunteerTile(
                      volunteer: volunteer,
                      index: index,
                      onDelete: () => onDelete(volunteer),
                      isDeveloper: isDeveloper,
                    ),
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

/// A pill-shaped floating group that combines the sort, filter, add
/// volunteer, and search actions. It sits on a semi-transparent primary
/// color background and hides itself when the list is scrolled down,
/// reappearing when scrolled back up.
class _FloatingActionGroup extends StatelessWidget {
  const _FloatingActionGroup({
    required this.isVisible,
    required this.sortField,
    required this.sortAscending,
    required this.onSortSelected,
    required this.filterCount,
    required this.onFilterPressed,
    required this.onFilterLongPress,
    required this.showAddButton,
    required this.onAddPressed,
    required this.isSearchActive,
    required this.onSearchPressed,
  });

  final bool isVisible;
  final VolunteerSortField sortField;
  final bool sortAscending;
  final ValueChanged<VolunteerSortField> onSortSelected;
  final int filterCount;
  final VoidCallback onFilterPressed;
  final VoidCallback onFilterLongPress;
  final bool showAddButton;
  final VoidCallback onAddPressed;
  final bool isSearchActive;
  final VoidCallback onSearchPressed;

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
                _SortActionButton(
                  selectedField: sortField,
                  ascending: sortAscending,
                  onSelected: onSortSelected,
                  brightIcon: true,
                ),
                IconButton(
                  tooltip: 'Filter',
                  onPressed: onFilterPressed,
                  onLongPress: onFilterLongPress,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.filter_alt_rounded,
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
                if (showAddButton)
                  IconButton(
                    tooltip: 'Add Volunteer',
                    onPressed: onAddPressed,
                    icon: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: _iconColor,
                      size: 24,
                      shadows: _iconShadows,
                    ),
                  ),
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

/// Small dot indicating an action (e.g. sort) is currently active.
class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
