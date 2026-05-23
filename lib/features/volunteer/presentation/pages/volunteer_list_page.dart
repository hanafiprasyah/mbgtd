import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/volunteer_bloc.dart';
import '../../bloc/volunteer_event.dart';
import '../../bloc/volunteer_state.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.list,
                  color: activeFilterCount > 0 ? Colors.blue : null,
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
                    debugPrint('Bloc error: $e');
                  }
                },
                onPressed: () async {
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
                        context.read<VolunteerBloc>().add(LoadVolunteer());
                      } catch (e) {
                        debugPrint('Bloc error: $e');
                      }
                    } else {
                      try {
                        context.read<VolunteerBloc>().add(
                          SearchVolunteer(
                            searchController.text,
                            selectedTim,
                            selectedGender,
                          ),
                        );
                      } catch (e) {
                        debugPrint('Bloc error: $e');
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
                      color: Colors.blue,
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
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
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
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            try {
                              context.read<VolunteerBloc>().add(
                                SearchVolunteer(
                                  '',
                                  selectedTim,
                                  selectedGender,
                                ),
                              );
                            } catch (e) {
                              debugPrint('Bloc error: $e');
                            }
                            if (!mounted) return;
                            setState(() => isSearching = false);
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
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
                      debugPrint('Bloc error: $e');
                    }
                  });
                },
              ),
            ),
            if (activeFilterCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (selectedTim != null)
                      Chip(
                        label: Text('Tim: $selectedTim'),
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
                            debugPrint('Bloc error: $e');
                          }
                        },
                      ),
                    if (selectedGender != null)
                      Chip(
                        label: Text('Gender: $selectedGender'),
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
                            debugPrint('Bloc error: $e');
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
                    return const Center(child: CircularProgressIndicator());
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

                      return const Center(child: CircularProgressIndicator());
                    }
                    if (isSearching) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => isSearching = false);
                        }
                      });
                    }
                    if (state.volunteer.isEmpty) {
                      return const Center(child: Text('No volunteer found'));
                    }

                    return ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      scrollCacheExtent: ScrollCacheExtent.pixels(500),
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
                                  child: ListTile(
                                    title: Text(r.namaLengkap),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.tim),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (r.isActive == true)
                                                ? Colors.green
                                                : Colors.grey,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            (r.isActive == true)
                                                ? 'Active Volunteer'
                                                : 'Inactive Volunteer',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/volunteer-detail',
                                        arguments: r,
                                      );
                                    },
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
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
                                                      Navigator.pop(ctx, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirm == true) {
                                          final bloc = context
                                              .read<VolunteerBloc>();

                                          // optimistic remove
                                          if (!mounted) return;
                                          setState(() {
                                            _removingIds.add(r.id);
                                          });

                                          final messenger =
                                              ScaffoldMessenger.of(context);

                                          final snackBar = SnackBar(
                                            content: Text(
                                              '${r.namaLengkap} deleted',
                                            ),
                                            action: SnackBarAction(
                                              label: 'Undo',
                                              onPressed: () {
                                                if (!mounted) return;
                                                setState(() {
                                                  _removingIds.remove(r.id);
                                                });
                                              },
                                            ),
                                          );

                                          messenger
                                              .showSnackBar(snackBar)
                                              .closed
                                              .then((reason) {
                                                if (!_removingIds.contains(
                                                  r.id,
                                                )) {
                                                  // undone
                                                  return;
                                                }

                                                // commit delete after snackbar closes
                                                try {
                                                  bloc.add(
                                                    DeleteVolunteer(r.id),
                                                  );
                                                } catch (e) {
                                                  debugPrint('Bloc error: $e');
                                                }

                                                try {
                                                  bloc.add(
                                                    SearchVolunteer(
                                                      searchController.text,
                                                      selectedTim,
                                                      selectedGender,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  debugPrint('Bloc error: $e');
                                                }

                                                if (!mounted) return;
                                                setState(() {
                                                  _removingIds.remove(r.id);
                                                });
                                              });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                        );
                      },
                    );
                  } else if (state is VolunteerError) {
                    return Center(child: Text(state.message));
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
