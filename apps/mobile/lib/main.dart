import 'package:flutter/material.dart';

void main() {
  runApp(const ChistoApp());
}

class ChistoApp extends StatelessWidget {
  const ChistoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chisto.mk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const ChistoHomePage(),
    );
  }
}

class ChistoHomePage extends StatelessWidget {
  const ChistoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'Chisto.mk',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
        ),
      ),
    );
  }
}
