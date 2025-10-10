import 'package:flutter/material.dart';
import 'lib/screens/reels_screen.dart';

void main() {
  runApp(ReelsTestApp());
}

class ReelsTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reels Display Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ReelsScreen(),
      routes: {
        '/reel-upload': (context) => const Scaffold(
          body: Center(
            child: Text('Reel Upload Screen (Mock)'),
          ),
        ),
        '/home': (context) => const Scaffold(
          body: Center(
            child: Text('Home Screen (Mock)'),
          ),
        ),
        '/live-stream': (context) => const Scaffold(
          body: Center(
            child: Text('Live Stream Screen (Mock)'),
          ),
        ),
        '/add-options': (context) => const Scaffold(
          body: Center(
            child: Text('Add Options Screen (Mock)'),
          ),
        ),
        '/profile': (context) => const Scaffold(
          body: Center(
            child: Text('Profile Screen (Mock)'),
          ),
        ),
      },
    );
  }
}
