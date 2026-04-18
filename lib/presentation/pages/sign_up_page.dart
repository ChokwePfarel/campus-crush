import 'package:dating_app/core/utils/purple.dart';
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
      isVerified = _emailController.text.trim().endsWith('@myuwc.ac.za');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PurplePalette.bg,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Stack(
          children: [
            // Blobs
            Positioned(
              top: -60,
              right: -60,
              child: _blob(200, PurplePalette.mid, 0.85),
            ),
            Positioned(
              top: 40,
              right: 60,
              child: _blob(100, PurplePalette.primary, 0.6),
            ),

            SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 48, 28, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            "Hello! Let's join with us",
                            style: TextStyle(
                              fontSize: 14,
                              color: PurplePalette.primary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          _pillField(
                            controller: _nameController,
                            hint: 'Full Name',
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
                            validator: (val) =>
                            val == null || !val.contains('@')
                                ? 'Invalid email'
                                : null,
                          ),
                          const SizedBox(height: 13),

                          _pillField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_outline,
                            obscure: true,
                            validator: (val) =>
                            val == null || val.length < 6
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
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bottom wave + button
                    ClipPath(
                      clipper: _WaveClipper(),
                      child: Container(
                        color: PurplePalette.mid,
                        padding: const EdgeInsets.fromLTRB(28, 52, 28, 32),
                        child: Column(
                          children: [
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                if (state is AuthLoading) {
                                  return const SizedBox(
                                    height: 52,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.white),
                                    ),
                                  );
                                }
                                return SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: PurplePalette.primary,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      if (!_agreedToPolicy) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Please agree to the privacy policy'),
                                        ));
                                        return;
                                      }
                                      if (_formKey.currentState!.validate()) {
                                        _verifyEmail();
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
                                      'SIGN UP',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 18),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: RichText(
                                text: const TextSpan(
                                  text: 'Already have an account? ',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white70),
                                  children: [
                                    TextSpan(
                                      text: 'Sign in',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
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
        hintStyle: const TextStyle(color: PurplePalette.placeholder, fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: PurplePalette.placeholder),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: PurplePalette.fieldBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: PurplePalette.fieldBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: PurplePalette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width / 2, 0, size.width, 40);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}