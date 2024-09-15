import 'dart:async';
import 'dart:math';
import 'package:drift_tracker/drift/filling_box.dart';
import 'package:drift_tracker/home/home.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class DrivePage extends StatefulWidget {
  final String carModel;
  final double carWeight;
  final String weatherCondition;

  const DrivePage({
    super.key,
    required this.carModel,
    required this.carWeight,
    required this.weatherCondition,
  });

  @override
  DrivePageState createState() => DrivePageState();
}

class DrivePageState extends State<DrivePage> {
  UserAccelerometerEvent? _userAccelerometerEvent;
  DateTime? _userAccelerometerUpdateTime;
  double gForce = 0.0;
  double speed = 0.0;
  DateTime? lastDataAddedTime;
  late SharedPreferences prefs;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  final player = AudioPlayer();
  static const Duration _ignoreDuration = Duration(milliseconds: 5);

  @override
  void initState() {
    super.initState();
    player.setAsset('assets/audio/beep.mp3');
    _initializeLocation();
    _initializeSensors();
  }

  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _streamSubscriptions.add(
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).listen((Position position) {
        setState(() {
          speed = position.speed;
        });
      }),
    );
  }

  void _initializeSensors() {
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          final now = DateTime.now();
          setState(() {
            _userAccelerometerEvent = event;
            gForce = calculateGForces();
            if (_userAccelerometerUpdateTime != null) {
              final interval = now.difference(_userAccelerometerUpdateTime!);
              if (interval > _ignoreDuration) {
                _checkGForceThreshold();
              }
            }
          });
          _userAccelerometerUpdateTime = now;
        },
        onError: (e) {
          showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                title: Text("Sensor Not Found"),
                content: Text(
                    "It seems that your device doesn't support User Accelerometer Sensor"),
              );
            },
          );
        },
        cancelOnError: true,
      ),
    );
  }

  double calculateGForces() {
    if (_userAccelerometerEvent == null) {
      return 0.0;
    } else {
      double speedFactor = speed / 2.0;
      return (sqrt(_userAccelerometerEvent!.x * _userAccelerometerEvent!.x +
                  _userAccelerometerEvent!.y * _userAccelerometerEvent!.y +
                  _userAccelerometerEvent!.z * _userAccelerometerEvent!.z) /
              9.81) +
          speedFactor;
    }
  }

  void _checkGForceThreshold() async {
    double gForceThreshold;
    switch (widget.weatherCondition.toLowerCase()) {
      case 'rainy':
        gForceThreshold = 1.5;
        break;
      case 'snowy':
        gForceThreshold = 1.2;
        break;
      default:
        gForceThreshold = 2.0;
        break;
    }

    if (gForce > gForceThreshold) {
      await player.seek(Duration.zero);
      await player.play();
    }
  }

  @override
  void dispose() {
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: const Alignment(-0.8, -0.8),
                  stops: const [0.0, 0.5, 0.5, 1],
                  colors: [
                    Colors.brown,
                    Colors.brown,
                    Colors.brown.shade900,
                    Colors.brown.shade900,
                  ],
                  tileMode: TileMode.repeated,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FillingBox(
                  weight: widget.carWeight,
                  speed: speed,
                  lateralAcceleration: gForce,
                  weatherCondition: widget.weatherCondition,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.brown.shade300,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Car Model: ${widget.carModel}',
                          style: const TextStyle(
                              fontSize: 20, color: Colors.black87),
                        ),
                        Text(
                          'Current G-Force: ${gForce.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20, color: Colors.black87),
                        ),
                        Text(
                          'Speed: ${speed.toStringAsFixed(2)} m/s',
                          style: const TextStyle(
                              fontSize: 20, color: Colors.black87),
                        ),
                        Text(
                          'Weather: ${widget.weatherCondition}',
                          style: const TextStyle(
                              fontSize: 20, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      elevation: 1,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyHomePage()),
                      );
                    },
                    child: const Center(
                      child: Text(
                        'Finish',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
