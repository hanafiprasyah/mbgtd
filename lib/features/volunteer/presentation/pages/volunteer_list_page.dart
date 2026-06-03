import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/core/helper/design_system.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_bloc.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_event.dart';
import 'package:mbg_test/features/volunteer/bloc/volunteer_state.dart';

class VolunteerListPage extends StatefulWidget {
  const VolunteerListPage({super.key});

  @override
  State<VolunteerListPage> createState() => _VolunteerListPageState();
}

class _VolunteerListPageState extends State<VolunteerListPage> {
  final TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  String? selectedTim;
  String? selectedGender;
  bool isUiReady = false;
  Timer? _uiDelay;
  Timer? _debounce;
  final Set<String> _removingIds = {};

  int get activeFilterCount {
    int count = 0;
    if (selectedTim != null) count++;
    if (selectedGender != null) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    context.read<VolunteerBloc>().add(LoadVolunteer());
    isUiReady = false;
  }

  @override
  void dispose() {
    _uiDelay?.cancel();
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
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
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: activeFilterCount > 0 ? colorScheme.primary : null,
                ),
                tooltip: 'Filter',
                onLongPress: () {
                  if (!mounted) return;
                  setState(() {
                    selectedTim = null;
                    selectedGender = null;
                  });
                  try {
                    context.read<VolunteerBloc>().add(LoadVolunteer());
                  } catch (e) {
                    debugPrint('BLOC error on volunteer list page: $e');
                  }
                },
                onPressed: () async {
                  final bloc = context.read<VolunteerBloc>();
                  String? tempTim = selectedTim;
                  String? tempGender = selectedGender;

                  final result = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      return StatefulBuilder(
                        builder: (ctx, setStateDialog) {
                          return AlertDialog(
                            title: const Text('Filter Volunteer'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: tempTim,
                                  hint: const Text('Team'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Chef',
                                      child: Text('Chef'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ASLAP',
                                      child: Text('ASLAP'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Persiapan',
                                      child: Text('Persiapan'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Masak',
                                      child: Text('Masak'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Distribusi',
                                      child: Text('Distribusi'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Packing',
                                      child: Text('Packing'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Pencucian',
                                      child: Text('Pencucian'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Satpam',
                                      child: Text('Satpam'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setStateDialog(() => tempTim = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: tempGender,
                                  hint: const Text('Gender'),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Laki-laki',
                                      child: Text('Laki-laki'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Perempuan',
                                      child: Text('Perempuan'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setStateDialog(() => tempGender = value);
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  // reset temp values inside dialog
                                  setStateDialog(() {
                                    tempTim = null;
                                    tempGender = null;
                                  });
                                },
                                child: const Text('Reset'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, 'cancel'),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, 'apply'),
                                child: const Text('Apply'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );

                  if (result == 'apply') {
                    if (!mounted) return;
                    setState(() {
                      selectedTim = tempTim;
                      selectedGender = tempGender;
                    });

                    final isNoFilter =
                        selectedTim == null &&
                        selectedGender == null &&
                        searchController.text.isEmpty;
                    if (isNoFilter) {
                      try {
                        bloc.add(LoadVolunteer());
                      } catch (e) {
                        debugPrint('BLOC error on volunteer list page: $e');
                      }
                    } else {
                      try {
                        bloc.add(
                          SearchVolunteer(
                            searchController.text,
                            selectedTim,
                            selectedGender,
                          ),
                        );
                      } catch (e) {
                        debugPrint('BLOC error on volunteer list page: $e');
                      }
                    }
                  } else if (result == 'cancel') {
                    // do nothing
                  }
                },
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      activeFilterCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Volunteer',
            onPressed: () {
              Navigator.pushNamed(context, '/volunteer-add');
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search volunteer...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
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
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              searchController.clear();

                              final bloc = context.read<VolunteerBloc>();

                              final isNoFilter =
                                  selectedTim == null && selectedGender == null;

                              try {
                                if (isNoFilter) {
                                  bloc.add(LoadVolunteer());
                                } else {
                                  bloc.add(
                                    SearchVolunteer(
                                      '',
                                      selectedTim,
                                      selectedGender,
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                  'BLOC error on volunteer list page: $e',
                                );
                              }

                              if (!mounted) return;
                              setState(() => isSearching = false);
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() => isSearching = true);
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      try {
                        context.read<VolunteerBloc>().add(
                          SearchVolunteer(value, selectedTim, selectedGender),
                        );
                      } catch (e) {
                        debugPrint('BLOC error on volunteer list page: $e');
                      }
                    });
                  },
                ),
              ),
            ),
            if (activeFilterCount > 0)
              Padding(
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
                        onDeleted: () {
                          if (!mounted) return;
                          setState(() => selectedTim = null);
                          try {
                            context.read<VolunteerBloc>().add(
                              SearchVolunteer(
                                searchController.text,
                                selectedTim,
                                selectedGender,
                              ),
                            );
                          } catch (e) {
                            debugPrint('BLOC error on volunteer list page: $e');
                          }
                        },
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
                        onDeleted: () {
                          if (!mounted) return;
                          setState(() => selectedGender = null);
                          try {
                            context.read<VolunteerBloc>().add(
                              SearchVolunteer(
                                searchController.text,
                                selectedTim,
                                selectedGender,
                              ),
                            );
                          } catch (e) {
                            debugPrint('BLOC error on volunteer list page: $e');
                          }
                        },
                      ),
                  ],
                ),
              ),
            Expanded(
              child: BlocBuilder<VolunteerBloc, VolunteerState>(
                buildWhen: (previous, current) => previous != current,
                builder: (context, state) {
                  if (state is VolunteerLoading && !isSearching) {
                    isUiReady = false;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    );
                  } else if (state is VolunteerLoaded) {
                    if (!isUiReady) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_uiDelay?.isActive ?? false) return;

                        _uiDelay = Timer(
                          const Duration(milliseconds: 1000),
                          () {
                            if (mounted) {
                              setState(() => isUiReady = true);
                            }
                          },
                        );
                      });

                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 3),
                      );
                    }
                    if (isSearching) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => isSearching = false);
                        }
                      });
                    }
                    if (state.volunteer.isEmpty) {
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
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.xl,
                                  ),
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
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Try a different keyword or filter.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      scrollCacheExtent: ScrollCacheExtent.pixels(500),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                      itemCount: state.volunteer.length,
                      itemBuilder: (context, index) {
                        final r = state.volunteer[index];
                        final delay = (index * 50).clamp(0, 500);
                        final shouldAnimate = isUiReady;
                        final isRemoving = _removingIds.contains(r.id);

                        return AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: isRemoving
                              ? const SizedBox.shrink()
                              : TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: shouldAnimate
                                      ? Duration(milliseconds: 300 + delay)
                                      : const Duration(milliseconds: 0),
                                  curve: Curves.easeOut,
                                  builder: (context, value, child) {
                                    if (!shouldAnimate) return child!;
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - value) * 20),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Hero(
                                      tag: 'volunteer_card_${r.id}',
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/volunteer-detail',
                                              arguments: r,
                                            );
                                          },
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.lg,
                                                  ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.shadow
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 10),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                AppSpacing.sm,
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 42,
                                                    height: 42,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          colorScheme.primary,
                                                          colorScheme.primary
                                                              .withValues(
                                                                alpha: 0.68,
                                                              ),
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            AppRadius.lg,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        r.namaLengkap.isNotEmpty
                                                            ? r.namaLengkap[0]
                                                                  .toUpperCase()
                                                            : '?',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: AppSpacing.md,
                                                  ),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                r.namaLengkap,
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: Theme.of(context)
                                                                    .textTheme
                                                                    .labelLarge
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    (r.isActive ==
                                                                        true)
                                                                    ? Colors
                                                                          .green
                                                                          .withValues(
                                                                            alpha:
                                                                                0.14,
                                                                          )
                                                                    : colorScheme
                                                                          .surfaceContainerHighest,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      999,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                (r.isActive ==
                                                                        true)
                                                                    ? 'Active'
                                                                    : 'Inactive',
                                                                style: TextStyle(
                                                                  color:
                                                                      (r.isActive ==
                                                                          true)
                                                                      ? Colors
                                                                            .green
                                                                            .shade700
                                                                      : colorScheme
                                                                            .onSurfaceVariant,
                                                                  fontSize: 8,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        Wrap(
                                                          spacing: 4,
                                                          runSpacing: 4,
                                                          children: [
                                                            _VolunteerMetaChip(
                                                              icon: Icons
                                                                  .groups_rounded,
                                                              label: r.tim,
                                                            ),
                                                            _VolunteerMetaChip(
                                                              icon: Icons
                                                                  .badge_outlined,
                                                              label: r
                                                                  .jenisKelamin,
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color: colorScheme.error,
                                                    ),
                                                    tooltip: 'Delete',
                                                    onPressed: () async {
                                                      final bloc = context
                                                          .read<
                                                            VolunteerBloc
                                                          >();
                                                      final messenger =
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          );
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (ctx) {
                                                          return AlertDialog(
                                                            title: const Text(
                                                              'Confirm Delete',
                                                            ),
                                                            content: Text(
                                                              'Are you sure you want to delete ${r.namaLengkap}?',
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      false,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Cancel',
                                                                    ),
                                                              ),
                                                              FilledButton(
                                                                onPressed: () =>
                                                                    Navigator.pop(
                                                                      ctx,
                                                                      true,
                                                                    ),
                                                                child:
                                                                    const Text(
                                                                      'Delete',
                                                                    ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                      if (confirm == true) {
                                                        if (!mounted) return;
                                                        setState(() {
                                                          _removingIds.add(
                                                            r.id,
                                                          );
                                                        });
                                                        final snackBar = SnackBar(
                                                          content: Text(
                                                            '${r.namaLengkap} deleted',
                                                          ),
                                                          action: SnackBarAction(
                                                            label: 'Undo',
                                                            onPressed: () {
                                                              if (!mounted) {
                                                                return;
                                                              }
                                                              setState(() {
                                                                _removingIds
                                                                    .remove(
                                                                      r.id,
                                                                    );
                                                              });
                                                            },
                                                          ),
                                                        );
                                                        messenger
                                                            .showSnackBar(
                                                              snackBar,
                                                            )
                                                            .closed
                                                            .then((reason) {
                                                              if (!_removingIds
                                                                  .contains(
                                                                    r.id,
                                                                  )) {
                                                                return;
                                                              }
                                                              try {
                                                                bloc.add(
                                                                  DeleteVolunteer(
                                                                    r.id,
                                                                  ),
                                                                );
                                                              } catch (e) {
                                                                debugPrint(
                                                                  'BLOC error on volunteer list page: $e',
                                                                );
                                                              }
                                                              try {
                                                                bloc.add(
                                                                  SearchVolunteer(
                                                                    searchController
                                                                        .text,
                                                                    selectedTim,
                                                                    selectedGender,
                                                                  ),
                                                                );
                                                              } catch (e) {
                                                                debugPrint(
                                                                  'BLOC error on volunteer list page: $e',
                                                                );
                                                              }
                                                              if (!mounted) {
                                                                return;
                                                              }
                                                              setState(() {
                                                                _removingIds
                                                                    .remove(
                                                                      r.id,
                                                                    );
                                                              });
                                                            });
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        );
                      },
                    );
                  } else if (state is VolunteerError) {
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
                              state.message,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton removed
    );
  }
}

class _VolunteerMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _VolunteerMetaChip({required this.icon, required this.label});

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
