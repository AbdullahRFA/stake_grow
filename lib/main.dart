import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart'; // এই ফাইলটি অটোমেটিক জেনারেট হয়েছে
import 'package:stake_grow/features/auth/presentation/screens/login_screen.dart';

void main() async {
  // ১. ফ্ল্যাটার ইঞ্জিন চালু না হওয়া পর্যন্ত অপেক্ষা করো (নেটিভ কোড লোড করার জন্য)
  WidgetsFlutterBinding.ensureInitialized();

  // ২. ফায়ারবেস ইনিশিয়ালাইজ করো (Current Platform অনুযায়ী অপশন নিয়ে)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ৩. অ্যাপ রান করো (ProviderScope দিয়ে র‍্যাপ করা হলো Riverpod এর জন্য)
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stake & Grow',
      debugShowCheckedModeBanner: false, // Debug ব্যানার সরালাম
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginScreen(), // <--- এখানে পরিবর্তন
    );
  }
}