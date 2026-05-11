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

  @override
  void initState() {
    super.initState();
    context.read<VolunteerBloc>().add(LoadVolunteer());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer'),
        actions: [
          SizedBox(
            width: 250,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Cari relawan...',
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
                            context.read<VolunteerBloc>().add(LoadVolunteer());
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

                  context.read<VolunteerBloc>().add(SearchVolunteer(value));

                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (mounted) {
                      setState(() => isSearching = false);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isSearching) const LinearProgressIndicator(minHeight: 2),

          Expanded(
            child: BlocBuilder<VolunteerBloc, VolunteerState>(
              builder: (context, state) {
                if (state is VolunteerLoading && !isSearching) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is VolunteerLoaded) {
                  if (state.volunteer.isEmpty) {
                    return const Center(child: Text('Tidak ada data relawan'));
                  }

                  return ListView.builder(
                    itemCount: state.volunteer.length,
                    itemBuilder: (context, index) {
                      final r = state.volunteer[index];
                      return ListTile(
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
                          onPressed: () {
                            context.read<VolunteerBloc>().add(
                              DeleteVolunteer(r.id),
                            );
                          },
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/volunteer-add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
