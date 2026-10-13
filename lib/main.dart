import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: VitaleApp()));
}

class VitaleApp extends StatelessWidget {
  const VitaleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vitale',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitale'),
      ),
      body: const Center(
        child: Text('Vitale - Conversión HTML/MHTML a Markdown'),
      ),
    );
  }
}
