import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(            // --> no temas crear un MaterialApp aquí;
      debugShowCheckedModeBanner: false, //     dura sólo unos ms y evita “Theme” null.
      home: Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
