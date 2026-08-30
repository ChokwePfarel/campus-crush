import 'package:dating_app/core/constants/lists.dart';
import 'package:dating_app/core/utils/purple.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/core/widgets/dropdown.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/bloc/user/user_state.dart';
import 'package:dating_app/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';

class CreateAccountProfilePage extends StatefulWidget {
  const CreateAccountProfilePage({super.key});

  @override
  State<CreateAccountProfilePage> createState() =>
      _CreateAccountProfilePageState();
}

class _CreateAccountProfilePageState extends State<CreateAccountProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  String _selectedSex = DropDownOptions.sexOptions.first;
  String _selectedUniversity = DropDownOptions.universities.first;

  bool _isVerified = true;
  bool _isLoading = false;


  void _createUser() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: MultiBlocListener(
        listeners: [
          BlocListener<UserBloc, UserState>(
            listener: (context, state) {

              // Only react if we are currently creating the profile
              if (!_isLoading) return;

              if (state is UserLoaded && mounted) {
                setState(() => _isLoading = false);

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MyHomePage()),
                      (route) => false,
                );
              }

              if (state is UserError && mounted) {
                setState(() => _isLoading = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          )
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
                      'Complete Profile',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: PurplePalette.deep,
                        height: 1.15,
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

                    _label("Where do you study?"),
                    CustomDropdown<String>(
                      labelText: '',
                      items: DropDownOptions.universities,
                      value: _selectedUniversity,
                      onChanged: (value) {
                        setState(() {
                          _selectedUniversity = value!;
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

                    const SizedBox(height: 40),

                    SizedBox(
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
                        onPressed: _isLoading
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            _createUser();
                          }
                        },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
}
