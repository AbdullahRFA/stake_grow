import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class SignUpScreen extends HookConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Hooks for state management
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = ref.watch(authControllerProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // 2. Logic
    void signUp() {
      if (formKey.currentState!.validate()) {
        ref.read(authControllerProvider.notifier).signUpWithEmail(
          context: context,
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          name: 'Member',
        );
      }
    }

    // 3. UI Construction
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9), // Modern neutral background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // --- Background Design Elements ---
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.teal.withOpacity(0.15), Colors.transparent],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.blue.withOpacity(0.1), Colors.transparent],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // --- Main Content ---
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 50, color: Colors.teal),
                  ),
                  const SizedBox(height: 24),

                  // Title Text
                  Text(
                    'Create Account',
                    style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2D3142),
                        letterSpacing: -0.5
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start your community growth journey today',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.blueGrey[400],
                        fontWeight: FontWeight.w500
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        children: [
                          // Email Field (High Visibility)
                          _buildLabel("EMAIL ADDRESS"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: emailController,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                            decoration: _inputDecoration('Enter your email', Icons.alternate_email_rounded),
                            validator: (val) => val!.isEmpty ? 'Email is required' : null,
                          ),
                          const SizedBox(height: 20),

                          // Password Field (High Visibility)
                          _buildLabel("PASSWORD"),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                            decoration: _inputDecoration('Min. 6 characters', Icons.lock_open_rounded),
                            validator: (val) => val!.length < 6 ? 'Password too short' : null,
                          ),
                          const SizedBox(height: 32),

                          // Sign Up Button
                          isLoading
                              ? const CircularProgressIndicator(color: Colors.teal)
                              : Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: signUp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Back to Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already a member? ",
                          style: GoogleFonts.poppins(color: Colors.blueGrey[600], fontWeight: FontWeight.w500)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Log In',
                          style: GoogleFonts.poppins(
                            color: Colors.teal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Styling Helpers ---

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.blueGrey.shade700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
      prefixIcon: Icon(icon, color: Colors.teal.shade700, size: 22),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.teal, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}