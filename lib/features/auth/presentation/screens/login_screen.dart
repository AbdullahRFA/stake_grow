import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:stake_grow/features/auth/presentation/auth_controller.dart';
import 'package:stake_grow/core/common/loader.dart';
import 'package:stake_grow/features/auth/presentation/screens/signup_screen.dart'; // এটা পরের স্টেপে বানাবো

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Hooks: টেক্সট কন্ট্রোলার অটোমেটিক ম্যানেজ হচ্ছে (No dispose needed!)
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    // 2. State Watch: কন্ট্রোলার লোডিং অবস্থায় আছে কিনা চেক করা
    final isLoading = ref.watch(authControllerProvider);

    // 3. Form Key: ভ্যালিডেশনের জন্য
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // লগিন বাটন চাপলে যা হবে
    void login() {
      if (formKey.currentState!.validate()) {
        ref.read(authControllerProvider.notifier).loginWithEmail(
          context: context,
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Loader() // লোডিং হলে চাকা ঘুরবে
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome Back! 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Log In'),
                ),
              ),
              const SizedBox(height: 16),

              // Sign Up Link (Temporary Navigation)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}