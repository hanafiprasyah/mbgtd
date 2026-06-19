import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_state.dart';
import 'package:mbg_test/features/volunteer/data/models/volunteer_model.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/chip.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/field.dart';
import 'package:mbg_test/features/volunteer/presentation/widgets/state_widget.dart';

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

enum VolunteerSortOption { none, ageAscending, nameAZ }

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
  VolunteerSortOption _sortOption = VolunteerSortOption.none;
  Map<String, dynamic>? userData;

  int get _activeFilterCount {
    var count = 0;
    if (_selectedTim != null) count++;
    if (_selectedGender != null) count++;
    return count;
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

  void _onSortSelected(VolunteerSortOption option) {
    setState(() => _sortOption = option);
  }

  List<Volunteer> _sortVolunteers(List<Volunteer> volunteers) {
    if (_sortOption == VolunteerSortOption.none) return volunteers;

    final sorted = List<Volunteer>.from(volunteers);
    switch (_sortOption) {
      case VolunteerSortOption.ageAscending:
        sorted.sort(
          (a, b) => _ageFromBirthDate(
            a.tanggalLahir,
          ).compareTo(_ageFromBirthDate(b.tanggalLahir)),
        );
        break;
      case VolunteerSortOption.nameAZ:
        sorted.sort(
          (a, b) => a.namaLengkap.toLowerCase().compareTo(
            b.namaLengkap.toLowerCase(),
          ),
        );
        break;
      case VolunteerSortOption.none:
        break;
    }
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
      ..showSnackBar(
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (Navigator.canPop(context)) const BackButton(),
            _SortActionButton(
              selected: _sortOption,
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
            SearchField(
              controller: _searchController,
              isSearching: _isSearching,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
            ),
            if (_activeFilterCount > 0)
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
                      volunteers: _sortVolunteers(state.volunteer),
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
    );
  }
}

class _VolunteerFilter {
  const _VolunteerFilter({this.tim, this.gender});

  final String? tim;
  final String? gender;
}

class _SortActionButton extends StatelessWidget {
  const _SortActionButton({required this.selected, required this.onSelected});

  final VolunteerSortOption selected;
  final ValueChanged<VolunteerSortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final isActive = selected != VolunteerSortOption.none;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<VolunteerSortOption>(
      tooltip: 'Sort',
      initialValue: selected,
      onSelected: onSelected,
      icon: Icon(Icons.sort, color: isActive ? colorScheme.primary : null),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: VolunteerSortOption.none,
          checked: selected == VolunteerSortOption.none,
          child: const Text('Default'),
        ),
        CheckedPopupMenuItem(
          value: VolunteerSortOption.ageAscending,
          checked: selected == VolunteerSortOption.ageAscending,
          child: const Text('Age (Youngest First)'),
        ),
        CheckedPopupMenuItem(
          value: VolunteerSortOption.nameAZ,
          checked: selected == VolunteerSortOption.nameAZ,
          child: const Text('Name (A-Z)'),
        ),
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

    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      scrollCacheExtent: ScrollCacheExtent.pixels(500),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: volunteers.length,
      itemBuilder: (context, index) {
        final volunteer = volunteers[index];

        return VolunteerTile(
          volunteer: volunteer,
          index: index,
          onDelete: () => onDelete(volunteer),
          isDeveloper: isDeveloper,
        );
      },
    );
  }
}
