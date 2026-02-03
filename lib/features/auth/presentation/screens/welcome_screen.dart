import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or your app's background color
      body: Stack(
        children: [
          // 1. Main Content (Description & Policy) - Centered/Scrollable
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 100), // Bottom padding for buttons
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Logo or Title
                  const Center(
                    child: Icon(Icons.volunteer_activism, size: 80, color: Colors.teal),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "Stake Grow",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 1. How the App Works
                  const Text(
                    "How it Works:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Stake Grow is a community-based financial growth platform. \n\n"
                        "• Create or Join a Community: Connect with trusted members.\n"
                        "• Contribute Monthly: Build a collective fund together.\n"
                        "• Request Loans: Access interest-free or low-cost loans from the pool.\n"
                        "• Invest: Use the fund for collective investments and share profits.\n"
                        "• Track Everything: Transparent transaction history for every penny.",
                    style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),

                  const SizedBox(height: 30),

                  // 2. App Policy
                  const Text(
                    "Our Policy:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "• Transparency: All transactions are visible to members.\n"
                        "• Commitment: Monthly contributions are mandatory for active status.\n"
                        "• Security: Admin approval is required for withdrawals and loans.\n"
                        "• Fair Play: Profit and loss are distributed based on share percentage.",
                    style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // 3. Login & Signup Buttons - Corner (Bottom Right)
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Login Button
                ElevatedButton(
                  onPressed: () => context.push('/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),

                // Signup Button (Text or Outlined for variety)
                TextButton(
                  onPressed: () => context.push('/signup'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("New here? Sign Up"),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}