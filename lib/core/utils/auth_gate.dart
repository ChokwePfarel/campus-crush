import 'package:dating_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:dating_app/presentation/bloc/auth/auth_state.dart' as auth_st;
import 'package:dating_app/presentation/pages/home_page.dart';
import 'package:dating_app/presentation/pages/login_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, auth_st.AuthState>(
      builder: (context, state) {
        if (state is auth_st.Authenticated) {
          return const MyHomePage();
        }

        return const LoginPage();
      },
    );
  }
}
