import 'package:drift_tracker/ad_helper.dart';
import 'package:drift_tracker/data.dart';
import 'package:drift_tracker/drift/drive.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedCar = carOptions.first;
  String selectedModel = '';
  String selectedWeather = weatherOptions.first;
  BannerAd? _bannerAd;

  List<Map<String, dynamic>> currentModelOptions = [];

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeLocation();
    _loadSavedModel();
    _loadAd();
  }

  Future<void> _initializeLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showLocationAlert();
    }
  }

  Future<void> _loadAd() async {
    BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _bannerAd = ad as BannerAd),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    ).load();
  }

  Future<void> _loadSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModel = prefs.getString('selectedModel');
    if (savedModel != null) {
      for (var car in carOptions) {
        if (modelMap[car]?.any((model) => model['name'] == savedModel) ??
            false) {
          setState(() {
            selectedCar = car;
            currentModelOptions = modelMap[selectedCar] ?? [];
            selectedModel = savedModel;
          });
          break;
        }
      }
    } else {
      currentModelOptions = modelMap[selectedCar] ?? [];
      selectedModel = currentModelOptions.isNotEmpty
          ? currentModelOptions.first['name']
          : '';
    }
  }

  Future<void> _saveSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedModel', selectedModel);
  }

  Future<void> _checkLocationAndProceed() async {
    if (!(await Geolocator.isLocationServiceEnabled())) {
      _showLocationAlert();
      return;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showLocationAlert();
      return;
    }

    _showTrackReady();
  }

  void _showLocationAlert() {
    _showDialog(
      title: 'Location Services Disabled',
      content: 'Please enable location services to continue.',
      actions: [
        TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop())
      ],
    );
  }

  void _showTrackReady() {
    _showDialog(
      title: 'Begin Tracking',
      content:
          'Please set your phone in an upward position where it will not be moved. Select "Ready" to start tracking.',
      actions: [
        TextButton(
          child: const Text('Ready'),
          onPressed: () {
            final selectedModelData = modelMap[selectedCar]?.firstWhere(
              (model) => model['name'] == selectedModel,
              orElse: () => {'weight': 0.0},
            );
            final modelWeight = (selectedModelData?['weight'] ?? 0).toDouble();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DrivePage(
                  carModel: selectedModel,
                  carWeight: modelWeight,
                  weatherCondition: selectedWeather,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showDialog({
    required String title,
    required String content,
    required List<Widget> actions,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.brown.shade300,
          title: Text(title),
          content: Text(content),
          actions: actions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              const SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'Traction Tracker',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              buildInputContainer(),
              if (_bannerAd != null)
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown.shade300,
        borderRadius: const BorderRadius.all(Radius.circular(10.0)),
      ),
      width: 320,
      height: 400,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildDropdownSection(
              title: 'Car',
              value: selectedCar,
              options: carOptions,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCar = newValue!;
                  currentModelOptions = modelMap[selectedCar] ?? [];
                  selectedModel = currentModelOptions.isNotEmpty
                      ? currentModelOptions.first['name']
                      : '';
                  _saveSelectedModel();
                });
              },
            ),
            buildDropdownSection(
              title: 'Model',
              value: selectedModel,
              options: currentModelOptions
                  .map((model) => model['name'] as String)
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedModel = newValue!;
                  _saveSelectedModel();
                });
              },
            ),
            buildDropdownSection(
              title: 'Weather Condition',
              value: selectedWeather,
              options: weatherOptions,
              onChanged: (String? newValue) {
                setState(() {
                  selectedWeather = newValue!;
                });
              },
            ),
            buildTrackButton(),
          ],
        ),
      ),
    );
  }

  Widget buildTrackButton() {
    return Center(
      child: Container(
        width: 180,
        height: 45,
        margin: const EdgeInsets.only(top: 20.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            elevation: 1,
          ),
          onPressed: _checkLocationAndProceed,
          child: const Text(
            'Track',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdownSection({
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.brown.shade200,
            borderRadius: BorderRadius.circular(5),
          ),
          child: DropdownButton<String>(
            isExpanded: true,
            dropdownColor: Colors.brown.shade200,
            value: value,
            icon: const Icon(Icons.arrow_drop_down),
            elevation: 16,
            style: const TextStyle(color: Colors.black),
            underline: Container(),
            onChanged: onChanged,
            items: options
                .map((String option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
