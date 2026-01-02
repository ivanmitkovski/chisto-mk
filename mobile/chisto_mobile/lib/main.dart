import 'package:flutter/material.dart';

void main() {
  runApp(const ChistoMk());
}

class ChistoMk extends StatelessWidget {
  const ChistoMk({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            "Chisto.mk Initial Commit Screen. \n Let's do this!",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
