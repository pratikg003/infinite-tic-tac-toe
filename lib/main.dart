import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:infinite_tictactoe/screens/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Already initialized — safe to ignore
  }

  runApp(const MaterialApp(home: HomeScreen()));
}