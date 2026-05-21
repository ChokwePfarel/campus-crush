import 'package:dating_app/core/utils/purple.dart';
import 'package:dating_app/core/utils/snackbar.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import 'onboarding_page.dart' hide PurplePalette;

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _agreedToPolicy = false;
  bool isVerified = false;

  void _verifyEmail() {
    setState(() {
      isVerified = _emailEmail(); // Trigger update
    });
  }

  bool _emailEmail() => _emailController.text.trim().endsWith('@myuwc.ac.za');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OnboardingPage(
                  userId: state.user.id,
                  userName: _nameController.text.trim(),
                  isVerified: isVerified,
                ),
              ),
            );
          } else if (state is AuthError) {
            AppSnackBar.show(context, 'Incorrect email or password',
                type: SnackBarType.warning);

          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.15),
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: PurplePalette.deep,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "with your student email to get verified",
                      style: TextStyle(
                        fontSize: 14,
                        color: PurplePalette.primary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    _pillField(
                      controller: _nameController,
                      hint: 'User Name',
                      icon: Icons.person_outline,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 13),

                    _pillField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || !val.contains('@')
                          ? 'Invalid email'
                          : null,
                    ),
                    const SizedBox(height: 13),

                    _pillField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: false,
                      validator: (val) => val == null || val.length < 6
                          ? 'Min 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Privacy policy checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _agreedToPolicy,
                          onChanged: (v) =>
                              setState(() => _agreedToPolicy = v ?? false),
                          activeColor: PurplePalette.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const Text(
                          'I agree with the privacy policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: PurplePalette.primary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenHeight * 0.2),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return  SizedBox(
                            height: 52,
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppStylee.primaryColor),
                            ),
                          );
                        }
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStylee.primaryColor,
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            onPressed: () {
                              _verifyEmail();

                              if(!isVerified){

                                AppSnackBar.show(context,'Use your student email', type: SnackBarType.info);

                                return;
                              }


                              if (!_agreedToPolicy) {
                                AppSnackBar.show(context, 'Please agree to the privacy policy', type: SnackBarType.info);

                                return;
                              }
                              if (_formKey.currentState!.validate()) {
                                /*setState(() {
                                  isVerified = _emailEmail();
                                });*/
                                context.read<AuthBloc>().add(
                                      SignUpRequested(
                                        _emailController.text.trim(),
                                        _passwordController.text.trim(),
                                        _nameController.text.trim(),
                                      ),
                                    );
                              }
                            },
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // OR divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                              color: PurplePalette.fieldBorder, thickness: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'or',
                            style: TextStyle(
                              fontSize: 13,
                              color: PurplePalette.placeholder,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                              color: PurplePalette.fieldBorder, thickness: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black),
                            children: [
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppStylee.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32), // Bottom padding for scroll
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pillField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: PurplePalette.deep),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: PurplePalette.placeholder, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: PurplePalette.placeholder),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: PurplePalette.fieldBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: PurplePalette.fieldBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: PurplePalette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
