import 'package:dating_app/core/constants/lists.dart';
import 'package:dating_app/core/utils/purple.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/widgets/dropdown.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isVerified;

  const OnboardingPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.isVerified,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late TextEditingController _residenceController;

  final List<String> _interests = [];
  String _selectedUniversity = 'University of the Western Cape (UWC)';
  String _selectedSex = 'male';



  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    _ageController = TextEditingController();
    _residenceController = TextEditingController();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _ageController.dispose();
    _residenceController.dispose();
    super.dispose();
  }

  void _submit() {
    print("SUBMIT BUTTON CLICKED");
    if (_formKey.currentState!.validate()) {

      print('Bio: ${_bioController.text}');
      print('Age: ${_ageController.text}');
      print('Residence: ${_residenceController.text}');
      print('Interests: $_interests');
      print('University: $_selectedUniversity');
      print('Sex: $_selectedSex');


      context.read<UserBloc>().add(
        UpdateUserRequested(
          name: widget.userName,
          sex: _selectedSex.toLowerCase(),
          bio: _bioController.text.trim(),
          status: 'looking',
          residence: _residenceController.text.trim(),
          university: _selectedUniversity,
          interests: _interests,
          age: int.parse(_ageController.text),
          privacySettings: null,
          isVerified: widget.isVerified,
        ),
      );

      //LOAD THE DATA SAVED SO IT CAN BE READY ON UI
      context.read<UserBloc>().add(LoadUserSubscription());


      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MyHomePage()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return Scaffold(
      backgroundColor: PurplePalette.bg,
      body: Stack(
        children: [
          // Background blobs in header area
          Positioned(
            top: -60,
            right: -60,
            child: _blob(200, PurplePalette.mid, 0.6),
          ),
          Positioned(
            top: 40,
            right: 55,
            child: _blob(90, PurplePalette.dark, 0.5),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Purple header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${widget.userName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: PurplePalette.deep,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Let's create your student profile to help you find the best matches.",
                        style: TextStyle(
                          fontSize: 13,
                          color: PurplePalette.primary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // ── Scrollable form ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          _label("How old are you?"),

                          _pillField(
                            controller: _ageController,
                            hint: 'Enter your age',
                            icon: Icons.cake_outlined,
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                          ),

                          _label("Gender"),

                          CustomDropdown<String>(
                            labelText: '',
                            items: DropDownOptions.sexOptions,
                            value:
                            DropDownOptions.sexOptions.contains(
                              _selectedSex,
                            )
                                ? _selectedSex
                                : DropDownOptions.sexOptions.first,
                            onChanged: (value) {
                              setState(() {
                                _selectedSex = value!;
                              });
                            },
                          ),

                          _label("Where do you study?"),


                          CustomDropdown<String>(
                            labelText: '',
                            items: DropDownOptions.universities,
                            value:
                            DropDownOptions.statuses.contains(
                              _selectedUniversity,
                            )
                                ? _selectedUniversity
                                : DropDownOptions.universities.first,
                            onChanged: (value) {
                              setState(() {
                                _selectedUniversity = value!;
                              });
                            },
                          ),

                          _label("Where do you stay? (Residence)"),

                          _pillField(
                            controller: _residenceController,
                            hint: 'e.g. Hector Peterson',
                            icon: Icons.home_outlined,
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                          ),

                          _label("Tell us about yourself"),
                          _pillTextArea(
                            controller: _bioController,
                            hint: 'Write a short bio...',
                          ),

                          _label("Select your interests"),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: DropDownOptions.availableInterests
                                .map((interest) {
                              final selected = _interests.contains(interest);
                              return GestureDetector(
                                onTap: () => setState(() {
                                  selected
                                      ? _interests.remove(interest)
                                      : _interests.add(interest);
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? PurplePalette.primary
                                        : PurplePalette.chipBg,
                                    border: Border.all(
                                      color: selected
                                          ? PurplePalette.primary
                                          : PurplePalette.fieldBorder,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    interest,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : PurplePalette.primary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PurplePalette.primary,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                elevation: 0,
                              ),
                              onPressed: (){
                                print("BUTTON CLICKED");
                                _submit();
                              },
                              child: const Text(
                                'FINISH SETUP',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────

  Widget _blob(double size, Color color, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withOpacity(opacity),
      shape: BoxShape.circle,
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
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
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: PurplePalette.deep),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: PurplePalette.placeholder, fontSize: 13),
            prefixIcon:
            Icon(icon, size: 18, color: PurplePalette.placeholder),
            filled: true,
            fillColor: PurplePalette.fieldBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.fieldBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.fieldBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      );

  Widget _pillDropdown<T>({
    required T value,
    required IconData icon,
    required String hint,
    required List<T> items,
    required void Function(T?) onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13, color: PurplePalette.deep),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: PurplePalette.placeholder, size: 20),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
            Icon(icon, size: 18, color: PurplePalette.placeholder),
            filled: true,
            fillColor: PurplePalette.fieldBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.fieldBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.fieldBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.primary, width: 1.5),
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem<T>(
            value: item,
            child: Text(item.toString(),
                style: const TextStyle(fontSize: 13)),
          ))
              .toList(),
        ),
      );

  Widget _pillTextArea({
    required TextEditingController controller,
    required String hint,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(fontSize: 13, color: PurplePalette.deep),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: PurplePalette.placeholder, fontSize: 13),
            filled: true,
            fillColor: PurplePalette.fieldBg,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.fieldBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.fieldBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: PurplePalette.primary, width: 1.5),
            ),
          ),
        ),
      );
}