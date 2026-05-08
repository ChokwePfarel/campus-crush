import 'package:dating_app/core/constants/lists.dart';
import 'package:dating_app/core/utils/screen_size.dart';
import 'package:dating_app/core/utils/snackbar.dart';
import 'package:dating_app/core/utils/theme.dart';
import 'package:dating_app/core/widgets/confirmDialog.dart';
import 'package:dating_app/core/widgets/dropdown.dart';
import 'package:dating_app/data/models/privacy_settings_model.dart';
import 'package:dating_app/data/models/user_model.dart';
import 'package:dating_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:dating_app/presentation/bloc/auth/auth_event.dart';
import 'package:dating_app/presentation/bloc/image/image_bloc.dart';
import 'package:dating_app/presentation/bloc/image/image_event.dart';
import 'package:dating_app/presentation/bloc/user/user_bloc.dart';
import 'package:dating_app/presentation/bloc/user/user_event.dart';
import 'package:dating_app/presentation/pages/login_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileEdit extends StatefulWidget {
  final UserModel user;

  const ProfileEdit({super.key, required this.user});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _ageController;
  late TextEditingController _residenceController;
  late TextEditingController _majorController;
  late String _selectedStatus;
  late String _selectedSex;
  late List<String> _interests;
  late bool _isPrivate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
    _ageController = TextEditingController(text: widget.user.age.toString());
    _residenceController = TextEditingController(text: widget.user.residence);
    _majorController = TextEditingController(text: widget.user.major);
    _selectedStatus = widget.user.status.isNotEmpty
        ? widget.user.status
        : 'Single';
    _selectedSex = widget.user.sex.isNotEmpty ? widget.user.sex : 'Male';
    _interests = List.from(widget.user.interests);
    _isPrivate = widget.user.privacySettings.isProfilePrivate;

    _nameController.addListener(_markAsDirty);
    _bioController.addListener(_markAsDirty);
    _ageController.addListener(_markAsDirty);
    _residenceController.addListener(_markAsDirty);

    /*_nameController.addListener(() => _markAsDirty);
    _bioController.addListener(() => _markAsDirty);
    _ageController.addListener(() => _markAsDirty);
    _residenceController.addListener(() => _markAsDirty);*/
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _residenceController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }


  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Log out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.grey
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
              TextButton(
                child: const Text('Log out',
                  style: TextStyle(
                      color: Colors.red
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuthBloc>().add(LogoutRequested());

                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (context) =>
                      const LoginPage()), (route) => false);})
            ],
          ),
    );
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final residence = _residenceController.text.trim();
    final int? age = int.tryParse(_ageController.text);

    if (name.isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    if (name.length < 2) {
      _showError('Name is too short');
      return;
    }

    if (age == null || age < 18 || age > 100) {
      _showError('Enter a valid age (18 - 100)');
      return;
    }

    if (bio.length > 150) {
      _showError('Bio must be under 150 characters');
      return;
    }

    if (residence.isEmpty) {
      _showError('Residence cannot be empty');
      return;
    }

    if (_interests.isEmpty) {
      _showError('Please select at least one interest');
      return;
    }

    context.read<UserBloc>().add(
      UpdateUserRequested(
        name: name,
        sex: _selectedSex,
        bio: bio,
        status: _selectedStatus,
        residence: residence,
        university: widget.user.university,
        interests: _interests,
        age: age,
        privacySettings: PrivacySettingsModel(isProfilePrivate: _isPrivate),
        isVerified: widget.user.isVerified,
      ),
    );

    AppSnackBar.show(context, 'Updating profile...');


    Navigator.of(context).pop();
  }

  void _showAddInterestSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppStylee.connerRadius),
        ),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(SizeConfig.widthPercent(5)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Interests',
                style: TextStyle(
                  fontSize: SizeConfig.widthPercent(5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: SizeConfig.heightPercent(2)),
              Wrap(
                spacing: 8,
                children: DropDownOptions.availableInterests
                    .where((i) => !_interests.contains(i))
                    .map((interest) {
                  return ActionChip(
                    label: Text(interest),
                    onPressed: () {
                      setState(() {
                        _interests.add(interest);
                      });
                      _markAsDirty();
                      Navigator.pop(context);
                    },
                  );
                })
                    .toList(),
              ),
              SizedBox(height: SizeConfig.heightPercent(4)),
            ],
          ),
        );
      },
    );
  }

  bool _hasChanges = false;

  void _markAsDirty() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Pop succeeded (because _hasChanges was false)
        if (!mounted) return;

        // --- Pop was blocked (changes exist) ---

        // 1. Show the confirmation dialog
        final action = await showUnsavedChangesDialog(
          context: context,
          onSave: () => _saveProfile(),
          titleStyle: TextStyle(fontWeight: FontWeight.bold),
          buttonStyle: TextStyle(fontWeight: FontWeight.bold),
        );

        // 2. Act based on the user's choice from the dialog
        if (!mounted) return;

        if (action == 'DISCARD') {
          // User chose to discard -> Manually pop the current screen (goes to MyProducts)
          Navigator.of(context).pop();
        } else if (action == 'SAVE') {
          // User chose to save -> Call the save function which uses pushReplacement
          _saveProfile();
        }
        // If action is 'CANCEL' or null, the dialog closes, and the user remains on the EditProduct screen.
      },

      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
//
            onPressed: () async {
              if (!_hasChanges) {
                Navigator.of(context).pop();
                return;
              }

              final action = await showUnsavedChangesDialog(
                context: context,
                onSave: () => _saveProfile(),
                titleStyle: TextStyle(fontWeight: FontWeight.bold),
                buttonStyle: TextStyle(fontWeight: FontWeight.bold),
              );

              if (!mounted) return;

              if (action == 'DISCARD') {
                Navigator.of(context).pop();
              } else if (action == 'SAVE') {
                _saveProfile();
              }
            }
            ,

            //
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: Color(0xFF1A1A2E),
            ),
          ),
          elevation: 0,
          foregroundColor: Colors.black,
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                icon: const Icon(
                  Icons.arrow_forward, color: Colors.red, size: 24,))
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.widthPercent(5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: SizeConfig.heightPercent(2)),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: SizeConfig.widthPercent(15),
                      backgroundImage: widget.user.profileImageUrl.isNotEmpty
                          ? NetworkImage(widget.user.profileImageUrl)
                          : null,
                      child: widget.user.profileImageUrl.isEmpty
                          ? Icon(
                        Icons.person,
                        size: SizeConfig.widthPercent(15),
                      )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppStylee.collor,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (picked == null || !context.mounted) return;

                            context.read<ImagesBloc>().add(
                              UploadProfileImage(
                                userId: widget.user.id,
                                image: File(picked.path),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.heightPercent(1.5)),
              const Center(
                child: Column(
                  children: [
                    Text(
                      "Change Profile Photo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Tap to upload new picture",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.heightPercent(3)),
              Text(
                'PERSONAL DETAILS',
                style: TextStyle(
                  color: AppStylee.collor,
                  fontWeight: FontWeight.bold,
                  fontSize: SizeConfig.widthPercent(3.5),
                ),
              ),
              SizedBox(height: SizeConfig.heightPercent(2)),

              _buildTextField("Full Name", _nameController,
                  onChangedCallback: _markAsDirty),

              SizedBox(height: SizeConfig.heightPercent(2)),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      "Age",
                      _ageController,
                      keyboardType: TextInputType.number,
                      onChangedCallback: _markAsDirty,

                    ),
                  ),

                  SizedBox(width: SizeConfig.widthPercent(4)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),

                        CustomDropdown<String>(
                          labelText: '',
                          items: DropDownOptions.statuses,
                          value:
                          DropDownOptions.statuses.contains(
                            widget.user.status,
                          )
                              ? widget.user.status
                              : DropDownOptions.statuses.first,
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                              _markAsDirty();
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                ],
              ),
              SizedBox(height: SizeConfig.heightPercent(2)),

              _buildTextField("Course", _majorController,
                  onChangedCallback: _markAsDirty),

              SizedBox(height: SizeConfig.heightPercent(2)),

              _buildTextField("Residence", _residenceController,
                  onChangedCallback: _markAsDirty),

              SizedBox(height: SizeConfig.heightPercent(2)),

              _buildTextField(
                  "About Me", _bioController, onChangedCallback: _markAsDirty,
                  maxLines: 3),
              SizedBox(height: SizeConfig.heightPercent(3)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INTERESTS',
                    style: TextStyle(
                      color: AppStylee.collor,
                      fontWeight: FontWeight.bold,
                      fontSize: SizeConfig.widthPercent(3.5),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showAddInterestSheet,
                    label: const Text('Add Interest'),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(SizeConfig.widthPercent(2)),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppStylee.connerRadius),
                ),
                child: Wrap(
                  spacing: 8,
                  children: _interests.map((interest) {
                    return Chip(
                      label: Text(interest),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() {
                          _interests.remove(interest);
                          _markAsDirty();
                        });
                      },
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: AppStylee.collor.withOpacity(0.2),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: SizeConfig.heightPercent(5)),

              _buildPrivateAccountSwitch(context, _isPrivate),

              SizedBox(height: SizeConfig.heightPercent(5)),

              SizedBox(
                width: double.infinity,
                height: SizeConfig.heightPercent(6),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStylee.collor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppStylee.connerRadius,
                      ),
                    ),
                  ),
                  onPressed: _hasChanges ? _saveProfile : null,
                  child: const Text(
                    'Save All Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.heightPercent(5)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: EdgeInsets.all(SizeConfig.widthPercent(4)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppStylee.connerRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppStylee.connerRadius),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildTextField(String label,
      TextEditingController controller, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        VoidCallback? onChangedCallback, // new parameter
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 5),

        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: _inputDecoration(label),
          onChanged: (_) {
            // call the callback if provided
            if (onChangedCallback != null) {
              onChangedCallback();
            }
          },
        ),
      ],
    );
  }


  Widget _buildPrivateAccountSwitch(BuildContext context, bool isPrivate) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppStylee.connerRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Private Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _isPrivate
                    ? 'Your account is private'
                    : 'Your account is public',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          Switch(
            value: _isPrivate,
            onChanged: (value) {
              setState(() {
                _isPrivate = value;
                _markAsDirty();
              });
            },
          ),
        ],
      ),
    );
  }
}