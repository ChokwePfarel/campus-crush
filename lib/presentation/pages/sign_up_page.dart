import 'package:dating_app/core/constants/lists.dart';
import 'package:dating_app/core/utils/purple.dart';
import 'package:dating_app/core/utils/snackbar.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/core/widgets/dropdown.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/pages/home_page.dart';
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

  String _selectedSex = DropDownOptions.sexOptions.first;
  String _selectedUniversity = DropDownOptions.universities.first;

  bool _agreedToPolicy = false;
  bool _isVerified = false;
  bool _obscurePassword = true;

  // Mapping of universities to their expected email domains
  final Map<String, String> _universityDomains = {
    'University of the Western Cape (UWC)': '@myuwc.ac.za',
    'University of Cape Town (UCT)': '@myuct.ac.za',
    'Stellenbosch University': '@sun.ac.za',
    'University of the Witwatersrand': '@students.wits.ac.za',
    'University of Johannesburg': '@student.uj.ac.za',
    'University of Pretoria': '@tuks.co.za',
    'University of KwaZulu-Natal': '@stu.ukzn.ac.za',
    'Rhodes University': '@ruconnect.ru.ac.za',
  };

  @override
  void initState() {
    super.initState();
    // Re-verify email when text changes
   // _emailController.addListener(_updateVerificationStatus);
  }

 /* void _updateVerificationStatus() {
    final status = _checkIfVerified();
    if (status != _isVerified) {
      setState(() => _isVerified = status);
    }
  }

  bool _checkIfVerified() {
    final email = _emailController.text.trim().toLowerCase();
    // Check if the email matches the selected university's domain
    final expectedDomain = _universityDomains[_selectedUniversity];
    if (expectedDomain == null) return false;
    return email.endsWith(expectedDomain);
  }*/

  void _createUser() {
    if (_formKey.currentState!.validate()) {
      context.read<UserBloc>().add(
        UpdateUserRequested(
          name: _nameController.text.trim(),
          sex: _selectedSex,
          bio: 'No Bio',
          status: 'Looking',
          residence: '',
          university: _selectedUniversity,
          interests: ['Music'],
          age: 0,
          privacySettings: null,
          isVerified: _isVerified,
          coins: 30,
        ),
      );
    }
  }

  @override
  void dispose() {
   // _emailController.removeListener(_updateVerificationStatus);
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
              if (state is Authenticated) {

                context.read<UserBloc>().add(LoadUserSubscription());

                _createUser();
              }
            },
          ),
          BlocListener<UserBloc, UserState>(
            listener: (context, state) {
              if (state is UserLoaded) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MyHomePage()),
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
                      controller: _nameController,
                      hint: 'Display Name',
                      icon: Icons.person_outline,
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                    ),

                    const SizedBox(height: 13),

                    _label("Where do you study?"),

                    CustomDropdown<String>(
                      labelText: '',
                      items: DropDownOptions.universities,
                      value: _selectedUniversity,
                      onChanged: (value) {
                        setState(() {
                          _selectedUniversity = value!;
                          //_updateVerificationStatus();
                        });
                      },
                    ),

                    const SizedBox(height: 13),

                    _label("Gender"),

                    CustomDropdown<String>(
                      labelText: '',
                      items: DropDownOptions.sexOptions,
                      value: _selectedSex,
                      onChanged: (value) {
                        setState(() {
                          _selectedSex = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 13),

                    _pillField(
                      controller: _emailController,
                      hint: 'Student Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || !val.contains('@')) return 'Invalid email';
                        return null;
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
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                                borderRadius: BorderRadius.circular(
                                  16,
                                ),
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

                              if (!_isVerified) {
                                final domain = _universityDomains[_selectedUniversity] ?? "correct student domain";
                                AppSnackBar.show(
                                  context,
                                  'Exclusive to students. Please use your $domain email.',
                                  type: SnackBarType.info,
                                );
                                return;
                              }

                              if (_formKey.currentState!.validate()) {
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

                    Row(
                      children: [
                        const Expanded(child: Divider(color: PurplePalette.fieldBorder, thickness: 1)),
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
                        const Expanded(child: Divider(color: PurplePalette.fieldBorder, thickness: 1)),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: PurplePalette.deep,
      ),
    ),
  );

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
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
}
