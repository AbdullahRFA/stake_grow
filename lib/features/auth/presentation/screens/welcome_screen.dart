import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light clean background
      body: Stack(
        children: [
          // 1. Background Design Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.teal.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Header Section ---
                        const SizedBox(height: 20),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.volunteer_activism, size: 60, color: Colors.teal),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "স্টেক গ্রো (Stake Grow)",
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "আপনার কমিউনিটি, আপনার প্রবৃদ্ধি",
                                style: GoogleFonts.hindSiliguri(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- How it Works Section ---
                        _buildSectionHeader("অ্যাপটি কীভাবে কাজ করে:", Icons.lightbulb_outline),
                        const SizedBox(height: 16),
                        _buildInfoCard([
                          _buildBulletPoint("কমিউনিটি তৈরি বা যুক্ত হোন: বিশ্বস্ত সদস্যদের সাথে সংযোগ স্থাপন করুন।"),
                          _buildBulletPoint("মাসিক জমা দিন: সবাই মিলে একটি যৌথ তহবিল গঠন করুন।"),
                          _buildBulletPoint("ঋণ গ্রহণ করুন: তহবিল থেকে সহজ শর্তে ঋণ নিন।"),
                          _buildBulletPoint("বিনিয়োগ করুন: যৌথ বিনিয়োগের মাধ্যমে মুনাফা অর্জন করুন।"),
                          _buildBulletPoint("হিসাব রাখুন: প্রতিটি পয়সার স্বচ্ছ লেনদেনের ইতিহাস দেখুন।"),
                        ]),

                        const SizedBox(height: 30),

                        // --- Policy Section ---
                        _buildSectionHeader("আমাদের নীতিমালা:", Icons.gavel),
                        const SizedBox(height: 16),
                        _buildInfoCard([
                          _buildBulletPoint("স্বচ্ছতা: সকল লেনদেন সদস্যদের জন্য উন্মুক্ত।"),
                          _buildBulletPoint("অঙ্গীকার: সক্রিয় থাকতে মাসিক চাঁদা প্রদান বাধ্যতামূলক।"),
                          _buildBulletPoint("নিরাপত্তা: টাকা উত্তোলন ও ঋণের জন্য অ্যাডমিনের অনুমোদন প্রয়োজন।"),
                          _buildBulletPoint("ন্যায্যতা: শেয়ারের অনুপাতে লাভ-ক্ষতি বণ্টন করা হয়।"),
                        ]),

                        const SizedBox(height: 100), // Extra space for floating buttons
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Fixed Bottom Action Bar (Glassmorphism Style)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Sign Up Button (Outlined)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/signup'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "সাইন আপ",
                        style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Login Button (Filled)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        "লগইন",
                        style: GoogleFonts.hindSiliguri(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 24),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.hindSiliguri(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.teal.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(Icons.circle, size: 8, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.hindSiliguri(
                fontSize: 15,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}