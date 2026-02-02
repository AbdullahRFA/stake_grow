import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Loader());

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (val) => val!.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: professionController,
                decoration: const InputDecoration(labelText: "Profession"),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  child: const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}