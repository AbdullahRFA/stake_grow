import 'package:flutter/material.dart';

// সুন্দর করে এরর বা সাকসেস মেসেজ দেখানোর ফাংশন
void showSnackBar(BuildContext context, String content) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content),
      behavior: SnackBarBehavior.floating, // ভেসে থাকবে
    ),
  );
}