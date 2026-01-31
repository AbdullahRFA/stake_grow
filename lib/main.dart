import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stake_grow/router/router.dart'; // রাউটার ইম্পোর্ট করো
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget { // StatelessWidget -> ConsumerWidget
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // রাউটার প্রভাইডার কল করা
    final router = ref.watch(routerProvider);

    return MaterialApp.router( // MaterialApp -> MaterialApp.router
      title: 'Stake & Grow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      // এই দুই লাইন রাউটিং হ্যান্ডেল করবে
      routerConfig: router,
    );
  }
}