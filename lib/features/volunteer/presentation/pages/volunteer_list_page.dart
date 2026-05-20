import 'dart:async';
import 'package:flutter/material.dart';
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
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    context.read<VolunteerBloc>().add(LoadVolunteer());
    isUiReady = false;
  }

  @override
  void dispose() {
    _uiDelay?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer'),
        actions: [
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

                            context.read<VolunteerBloc>().add(
                              SearchVolunteer('', selectedTim, selectedGender),
                            );

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
                  setState(() => isSearching = true);

                  context.read<VolunteerBloc>().add(
                    SearchVolunteer(value, selectedTim, selectedGender),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedTim,
                      hint: const Text('Team'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Persiapan',
                          child: Text('Persiapan'),
                        ),
                        DropdownMenuItem(value: 'Masak', child: Text('Masak')),
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
                        DropdownMenuItem(value: 'ASLAP', child: Text('ASLAP')),
                      ],
                      onChanged: (value) {
                        setState(() => selectedTim = value);
                        context.read<VolunteerBloc>().add(
                          SearchVolunteer(
                            searchController.text,
                            value,
                            selectedGender,
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: selectedGender,
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
                        setState(() => selectedGender = value);
                        context.read<VolunteerBloc>().add(
                          SearchVolunteer(
                            searchController.text,
                            selectedTim,
                            value,
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Reset Filter',
                    onPressed: () {
                      setState(() {
                        selectedTim = null;
                        selectedGender = null;
                      });
                      context.read<VolunteerBloc>().add(LoadVolunteer());
                    },
                  ),
                ],
              ),
            ),
            // if (isSearching) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: BlocBuilder<VolunteerBloc, VolunteerState>(
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
                                    subtitle: Text(r.tim),
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
                                                bloc.add(DeleteVolunteer(r.id));

                                                bloc.add(
                                                  SearchVolunteer(
                                                    searchController.text,
                                                    selectedTim,
                                                    selectedGender,
                                                  ),
                                                );

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
