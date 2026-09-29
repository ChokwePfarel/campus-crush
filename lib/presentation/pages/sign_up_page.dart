import 'package:dating_app/core/constants/lists.dart';
import 'package:dating_app/core/utils/purple.dart';
import 'package:dating_app/core/utils/snackbar.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/core/widgets/dropdown.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/pages/home_page.dart';
import 'package:dating_app/presentation/pages/verify_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final String _nameController = '';

  bool _agreedToPolicy = false;
  bool _obscurePassword = true;

  final Map<String, String> _universityDomains = {
    'University of the Western Cape (UWC)': '@myuwc.ac.za',
    'University of Cape Town (UCT)': '@myuct.ac.za',
    'Stellenbosch University': '@sun.ac.za',
    'University of the Witwatersrand': '@students.wits.ac.za',
    'University of Johannesburg': '@student.uj.ac.za',
    'University of Pretoria': '@tuks.co.za',
    'University of KwaZulu-Natal': '@stu.ukzn.ac.za',
    'Rhodes University': '@ru.ac.za',
    'Nelson Mandela University': '@mandela.ac.za',
    'University of Limpopo': '@ul.ac.za',
    'University of Fort Hare': '@ufh.ac.za',
    'North-West University (NWU)': '@nwu.ac.za',
    'University of Mpumalanga': '@ump.ac.za',
    'Sol Plaatje University': '@spu.ac.za',
    'Walter Sisulu University': '@wsu.ac.za',
    'Cape Peninsula University of Technology (CPUT)': '@mycput.ac.za',
    'Durban University of Technology (DUT)': '@dut.ac.za',
    'Mangosuthu University of Technology (MUT)': '@mut.ac.za',
    'Tshwane University of Technology (TUT)': '@tut.ac.za',
    'Central University of Technology (CUT)': '@cut.ac.za',
    'Vaal University of Technology (VUT)': '@vut.ac.za',
  };

  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                AppSnackBar.show(
                  context,
                  'Failed to sign up, please try again',
                  type: SnackBarType.error,
                );
              }
              if (state is EmailVerificationRequired) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const VerifyPage()),
                );
              }
            },
          ),
        ],
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: screenHeight * 0.08),
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
                      "Join the community with your student email",
                      style: TextStyle(
                        fontSize: 14,
                        color: PurplePalette.primary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _pillField(
                      controller: _emailController,
                      hint: 'Student Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || !val.contains('@')) {
                          return 'Invalid email';
                        }

                        final isValid = _universityDomains.values.any(
                          (domain) => val.endsWith(domain),
                        );
                        if (!isValid) {
                          return 'Please use your official student email';
                        }
                        return null; // valid
                      },
                    ),
                    const SizedBox(height: 13),

                    _pillField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: PurplePalette.placeholder,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (val) => val == null || val.length < 6
                          ? 'Min 6 characters'
                          : null,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _agreedToPolicy,
                            onChanged: (v) =>
                                setState(() => _agreedToPolicy = v ?? false),
                            activeColor: PurplePalette.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'I agree with the privacy policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: PurplePalette.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: PurplePalette.primary,
                            ),
                          );
                        }
                        return SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppStylee.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (!_agreedToPolicy) {
                                AppSnackBar.show(
                                  context,
                                  'Please agree to the privacy policy',
                                  type: SnackBarType.info,
                                );
                                return;
                              }

                              if (_formKey.currentState!.validate()) {
                                context.read<AuthBloc>().add(
                                  SignUpRequested(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                    _nameController,
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

                    const Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: PurplePalette.fieldBorder,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
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
                            color: PurplePalette.fieldBorder,
                            thickness: 1,
                          ),
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
                              fontSize: 12,
                              color: Colors.black,
                            ),
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
                    const SizedBox(height: 32),
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
    Widget? suffixIcon,
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
        hintStyle: const TextStyle(
          color: PurplePalette.placeholder,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 18, color: PurplePalette.placeholder),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: PurplePalette.fieldBg,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: PurplePalette.fieldBorder,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: PurplePalette.fieldBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: PurplePalette.primary,
            width: 1.5,
          ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
