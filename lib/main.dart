import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:torch_light/torch_light.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isTorchOn = false;
  bool isDarkMode = false;
  int diceNumber = 1;

  StreamSubscription? _accelerometerSubscription;
  double shakeThreshold = 15.0;
  bool shakeCooldown = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
          double acceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

          // Shake 
          if (acceleration > shakeThreshold && !shakeCooldown) {
            shakeCooldown = true;
            _rollDice();

            Future.delayed(Duration(seconds: 1), () {
              shakeCooldown = false;
            });
          }

          //  Capovolgi telefono
          if (event.z < -9) {
            setState(() {
              isDarkMode = true;
            });
          } else if (event.z > 9) {
            setState(() {
              isDarkMode = false;
            });
          }
        });
  }

  void _rollDice() {
    setState(() {
      diceNumber = Random().nextInt(6) + 1;
    });
  }

  Future<void> _turnOnTorch() async {
    try {
      await TorchLight.enableTorch();
      setState(() {
        isTorchOn = true;
      });
    } catch (e) {}
  }

  Future<void> _turnOffTorch() async {
    try {
      await TorchLight.disableTorch();
      setState(() {
        isTorchOn = false;
      });
    } catch (e) {}
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Sensori App"),
          centerTitle: true,
        ),
        body: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! < 0) {
              _turnOnTorch(); // Swipe su
            } else if (details.primaryVelocity! > 0) {
              _turnOffTorch(); // Swipe giù
            }
          },
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isTorchOn ? Icons.flash_on : Icons.flash_off,
                  size: 80,
                ),
                SizedBox(height: 20),
                Text(
                  "Swipe su per accendere\nSwipe giù per spegnere",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 40),
                Text(
                  "🎲 Dado:",
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 10),
                Text(
                  "$diceNumber",
                  style: TextStyle(
                      fontSize: 60, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  "Agita il telefono per lanciare il dado",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                Text(
                  "Capovolgi il telefono per Dark Mode",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
