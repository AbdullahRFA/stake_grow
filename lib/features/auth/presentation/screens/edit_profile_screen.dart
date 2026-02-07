import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/auth/domain/user_model.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final professionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = await ref.read(authControllerProvider.notifier).getUserData(uid);
    if (user != null) {
      setState(() {
        currentUser = user;
        nameController.text = user.name;
        phoneController.text = user.phone ?? '';
        professionController.text = user.profession ?? '';
        isLoading = false;
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate() && currentUser != null) {
      FocusScope.of(context).unfocus();
      final updatedUser = UserModel(
        uid: currentUser!.uid,
        email: currentUser!.email,
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
        profession: professionController.text.trim(),
        createdAt: currentUser!.createdAt,
        joinedCommunities: currentUser!.joinedCommunities,
      );

      ref.read(authControllerProvider.notifier).updateProfile(updatedUser, context);
    }
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final formKeyPass = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Change Password", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKeyPass,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPassController,
                obscureText: true,
                decoration: _inputDecoration("Current Password", Icons.lock_outline),
                validator: (val) => val!.isEmpty ? "Enter current password" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: _inputDecoration("New Password", Icons.lock_reset),
                validator: (val) => val!.length < 6 ? "Minimum 6 chars" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKeyPass.currentState!.validate()) {
                ref.read(authControllerProvider.notifier).changePassword(
                  oldPassController.text.trim(),
                  newPassController.text.trim(),
                  context,
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Loader());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: Text("Profile Settings", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 32),

              // 2. Personal Information Card
              _buildLabel("PERSONAL INFORMATION"),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: _inputDecoration("Full Name", Icons.person_outline),
                      validator: (val) => val!.isEmpty ? "Name cannot be empty" : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: phoneController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: _inputDecoration("Phone Number", Icons.phone_android_rounded),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: professionController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: _inputDecoration("Profession", Icons.work_outline_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 3. Action Buttons
              _buildSaveButton(),
              const SizedBox(height: 20),

              const Divider(height: 40),

              _buildChangePasswordButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Builders ---

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.teal.shade200, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal.shade50,
                child: Text(
                  currentUser?.name.substring(0, 1).toUpperCase() ?? "U",
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          currentUser?.email ?? "",
          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text("SAVE PROFILE CHANGES", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildChangePasswordButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showChangePasswordDialog,
        icon: const Icon(Icons.lock_reset_rounded, size: 20),
        label: const Text("CHANGE ACCOUNT PASSWORD"),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: Colors.blueGrey),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: Colors.teal.shade700, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}