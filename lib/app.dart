import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mbg_test/data/repositories/auth_repository.dart';
import 'logic/auth/auth_bloc.dart';
import 'core/routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      child: BlocProvider(
        create: (context) => AuthBloc(context.read<AuthRepository>()),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          onGenerateRoute: AppRoutes.generateRoute,
        ),
      ),
    );
  }
}
