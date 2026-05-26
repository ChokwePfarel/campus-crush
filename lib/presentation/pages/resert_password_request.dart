import 'package:dating_app/core/utils/purple.dart';
import 'package:dating_app/core/utils/snackbar.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:dating_app/presentation/bloc/auth/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestPasswordReset extends StatefulWidget {
  const RequestPasswordReset({super.key});

  @override
  State<RequestPasswordReset> createState() => _RequestPasswordResetState();
}

class _RequestPasswordResetState extends State<RequestPasswordReset> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSending = false;

  @override
  void dispose() {

    _emailController.dispose();
    super.dispose();
  }

  void _sendPasswordReset(String email) {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      context.read<AuthBloc>().add(SendPasswordResetRequested(email));

      setState(() {
        _isSending = false;
      });

      AppSnackBar.show(
        context,
        'Password reset email sent',
        type: SnackBarType.success,
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      AppSnackBar.show(
        context,
        'Failed to send password reset email',
        type: SnackBarType.error,
      );

      debugPrint("Password reset request failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [


              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: PurplePalette.placeholder,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: PurplePalette.fieldBorder,
                      width: 1.5,
                    ),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) =>
                    val == null || !val.contains('@') ? 'Invalid email' : null,
              ),

              const SizedBox(height: 32),


              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStylee.primaryColor,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _sendPasswordReset(_emailController.text.trim());
                  },
                  child: _isSending
                      ? CircularProgressIndicator.adaptive()
                      : const Text(
                          'Request Password Reset',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
