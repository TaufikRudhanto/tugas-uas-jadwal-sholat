import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math' as math;

class CompassPage extends StatelessWidget {
  const CompassPage({super.key}); // Perbaikan: Tambahkan parameter key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compass Page'),
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: StreamBuilder<CompassEvent>(
          stream: FlutterCompass.events,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(); // Perbaikan: Tampilkan indicator loading jika data belum tersedia
            }
            
            // Perbaikan: Tangani jika snapshot.data null
            final double direction = snapshot.data?.heading ?? 0.0;

            return Transform.rotate(
              angle: ((direction * math.pi) / 180.0) * -1,
              child: Image.asset('assets/images/compasw.png'),
            );
          },
        ),
      ),
    );
  }
}
