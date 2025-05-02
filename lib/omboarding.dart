import 'package:famlink/features/maps/map_page.dart';
import 'package:flutter/material.dart';

class Omboarding extends StatelessWidget {
  const Omboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'FamLink',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Conectando você a quem você ama!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MapPage()),
                );
              },
              child: const Text('Começar'),
            ),
          ],
        ),
      ),
    );
  }
}