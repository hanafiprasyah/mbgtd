import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/volunteer_bloc.dart';
import '../../bloc/volunteer_event.dart';
import '../../bloc/volunteer_state.dart';
import '../../data/repositories/volunteer_repository.dart';

class VolunteerListPage extends StatelessWidget {
  const VolunteerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VolunteerBloc(VolunteerRepository())..add(LoadVolunteer()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Volunteer')),
        body: BlocBuilder<VolunteerBloc, VolunteerState>(
          builder: (context, state) {
            if (state is VolunteerLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is VolunteerLoaded) {
              return ListView.builder(
                itemCount: state.volunteer.length,
                itemBuilder: (context, index) {
                  final r = state.volunteer[index];
                  return ListTile(
                    title: Text(r.namaLengkap),
                    subtitle: Text(r.tim),
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
            }
            return const Center(child: Text('Empty list'));
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/volunteer-add');
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
